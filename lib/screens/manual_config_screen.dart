import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:sm_vpn/services/v2ray_service.dart';
import 'package:sm_vpn/theme/app_theme.dart';

/// Manual configuration editor: paste a share-link or JSON, pick a protocol,
/// and add the resulting config to the saved server list.
class ManualConfigScreen extends StatefulWidget {
  const ManualConfigScreen({super.key});

  @override
  State<ManualConfigScreen> createState() => _ManualConfigScreenState();
}

class _ManualConfigScreenState extends State<ManualConfigScreen> {
  static const List<String> _protocols = [
    'VMess',
    'VLESS',
    'Trojan',
    'Shadowsocks',
    'SOCKS',
    'HTTP',
  ];

  /// URI scheme per protocol, used to auto-fix a pasted link that is missing
  /// its scheme prefix.
  static const Map<String, String> _schemeByProtocol = {
    'VMess': 'vmess://',
    'VLESS': 'vless://',
    'Trojan': 'trojan://',
    'Shadowsocks': 'ss://',
    'SOCKS': 'socks://',
    'HTTP': 'http://',
  };

  final TextEditingController _textController = TextEditingController();
  String _selectedProtocol = 'VMess';
  bool _isAdding = false;

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  /// Normalizes the entered text: when a raw config body is pasted without a
  /// scheme, the scheme of the selected protocol is prepended so the parser
  /// can recognize it.
  String _normalizeInput(String input) {
    final trimmed = input.trim();
    final scheme = _schemeByProtocol[_selectedProtocol]!;
    if (trimmed.toLowerCase().contains('://') ||
        trimmed.startsWith('{') ||
        trimmed.startsWith('[')) {
      return trimmed;
    }
    return '$scheme$trimmed';
  }

  Future<void> _pasteFromClipboard() async {
    final clipboardData = await Clipboard.getData(Clipboard.kTextPlain);
    final text = clipboardData?.text;
    if (text == null || text.isEmpty) {
      _showSnackBar('Clipboard is empty', isError: true);
      return;
    }
    _textController.text = text;
    _showSnackBar('Pasted from clipboard');
  }

  Future<void> _addConfiguration() async {
    final rawText = _textController.text.trim();
    if (rawText.isEmpty) {
      _showSnackBar('Please enter a configuration first', isError: true);
      return;
    }

    setState(() => _isAdding = true);

    try {
      final service = Provider.of<V2RayService>(context, listen: false);
      final normalized = _normalizeInput(rawText);
      final config = await service.parseConfigFromClipboard(normalized);

      if (!mounted) return;

      if (config != null) {
        _showSnackBar('Configuration added successfully');
        Navigator.of(context).pop(config);
      } else {
        _showSnackBar('Invalid configuration', isError: true);
      }
    } catch (e) {
      if (!mounted) return;
      _showSnackBar('Invalid configuration', isError: true);
    } finally {
      if (mounted) setState(() => _isAdding = false);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.clearSnackBars();
    messenger.showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // The host app is a FluentApp, which injects a Material theme but not a
    // ScaffoldMessenger/Directionality pair. Wrap the Material UI in the
    // minimal providers it needs.
    return Directionality(
      textDirection: TextDirection.ltr,
      child: ScaffoldMessenger(
        child: Scaffold(
          backgroundColor: AppTheme.lightBackground,
          appBar: AppBar(
            title: const Text('Add Configuration'),
            backgroundColor: AppTheme.primary,
            foregroundColor: Colors.white,
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                DropdownButtonFormField<String>(
                  initialValue: _selectedProtocol,
                  decoration: InputDecoration(
                    labelText: 'Protocol',
                    labelStyle: const TextStyle(fontWeight: FontWeight.w600),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: AppTheme.primary,
                        width: 2,
                      ),
                    ),
                  ),
                  items: _protocols
                      .map((protocol) => DropdownMenuItem(
                            value: protocol,
                            child: Text(protocol),
                          ))
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _selectedProtocol = value);
                    }
                  },
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _textController,
                  maxLines: 10,
                  decoration: InputDecoration(
                    labelText: 'Paste config link or JSON here',
                    alignLabelWithHint: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: AppTheme.primary,
                        width: 2,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: _pasteFromClipboard,
                  icon: const Icon(Icons.paste),
                  label: const Text('Paste from Clipboard'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.primary,
                    side: const BorderSide(color: AppTheme.primary),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _isAdding ? null : _addConfiguration,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: AppTheme.primary.withOpacity(0.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isAdding
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Add Configuration',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
