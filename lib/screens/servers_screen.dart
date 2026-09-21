import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/material.dart' as m;
import 'package:provider/provider.dart';
import 'package:sm_vpn/services/v2ray_service.dart';
import 'package:sm_vpn/models/v2ray_config.dart';
import 'package:sm_vpn/theme/app_theme.dart';
import 'package:sm_vpn/screens/manual_config_screen.dart';
import 'package:sm_vpn/screens/qr_scanner_screen.dart';
import 'package:flutter/services.dart';

class ServersScreen extends StatefulWidget {
  const ServersScreen({super.key});

  @override
  State<ServersScreen> createState() => _ServersScreenState();
}

class _ServersScreenState extends State<ServersScreen> {
  List<V2RayConfig> _configs = [];
  bool _isLoading = true;
  bool _isSorting = false;
  bool _showAddSheet = false;
  String _searchQuery = '';
  final Map<String, int?> _pingResults = {};
  String? _selectedConfigId;

  @override
  void initState() {
    super.initState();
    _loadConfigs();
    _loadSelectedConfig();
  }

  Future<void> _loadSelectedConfig() async {
    final service = Provider.of<V2RayService>(context, listen: false);
    final selected = await service.loadSelectedConfig();
    if (selected != null && mounted) {
      setState(() {
        _selectedConfigId = selected.id;
      });
    }
  }

  Future<void> _loadConfigs() async {
    setState(() {
      _isLoading = true;
    });

    final service = Provider.of<V2RayService>(context, listen: false);
    final configs = await service.loadConfigs();

    if (mounted) {
      setState(() {
        _configs = configs;
        _isLoading = false;
      });
    }
  }

  Future<void> _pingAllServers() async {
    setState(() {
      _isSorting = true;
      _pingResults.clear();
    });

    final service = Provider.of<V2RayService>(context, listen: false);

    for (int i = 0; i < _configs.length; i++) {
      final config = _configs[i];
      try {
        final ping = await service.getServerDelay(config);
        if (mounted) {
          setState(() {
            _pingResults[config.id] = ping ?? -1;
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _pingResults[config.id] = -1;
          });
        }
      }

      await Future.delayed(const Duration(milliseconds: 100));
    }

    if (mounted) {
      _sortByPing();
      setState(() {
        _isSorting = false;
      });
    }
  }

  void _sortByPing() {
    setState(() {
      _configs.sort((a, b) {
        final pingA = _pingResults[a.id] ?? 999999;
        final pingB = _pingResults[b.id] ?? 999999;

        if (pingA == -1 && pingB == -1) return 0;
        if (pingA == -1) return 1;
        if (pingB == -1) return -1;

        return pingA.compareTo(pingB);
      });
    });
  }

  List<V2RayConfig> get _filteredConfigs {
    if (_searchQuery.isEmpty) return _configs;
    return _configs.where((config) {
      return config.remark.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          config.address.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          config.configType.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();
  }

  List<V2RayConfig> get _manualConfigs {
    return _filteredConfigs.where((config) => config.source == 'manual').toList();
  }

  List<V2RayConfig> get _subscriptionConfigs {
    return _filteredConfigs.where((config) => config.source == 'subscription').toList();
  }

  Future<void> _importFromClipboard() async {
    final service = Provider.of<V2RayService>(context, listen: false);
    try {
      final clipboardData = await Clipboard.getData(Clipboard.kTextPlain);
      if (!mounted) return;
      if (clipboardData == null || clipboardData.text == null || clipboardData.text!.isEmpty) {
        if (mounted) {
          await displayInfoBar(
            context,
            builder: (context, close) {
              return const InfoBar(
                title: Text('Empty Clipboard'),
                content: Text('Please copy a config first'),
                severity: InfoBarSeverity.warning,
              );
            },
            duration: const Duration(seconds: 2),
          );
        }
        return;
      }

      final clipboardText = clipboardData.text!;
      final config = await service.parseConfigFromClipboard(clipboardText);

      if (config != null) {
        if (await service.configExists(config)) {
          if (mounted) {
            await displayInfoBar(
              context,
              builder: (context, close) {
                return const InfoBar(
                  title: Text('Duplicate Server'),
                  content: Text('This server already exists'),
                  severity: InfoBarSeverity.warning,
                );
              },
              duration: const Duration(seconds: 2),
            );
          }
          return;
        }
        await service.saveConfig(config);
        await _loadConfigs();
        if (mounted) {
          await displayInfoBar(
            context,
            builder: (context, close) {
              return InfoBar(
                title: const Text('Config Added'),
                content: Text('${config.remark} added successfully'),
                severity: InfoBarSeverity.success,
              );
            },
            duration: const Duration(seconds: 2),
          );
        }
      } else {
        if (mounted) {
          await displayInfoBar(
            context,
            builder: (context, close) {
              return const InfoBar(
                title: Text('Invalid Configuration'),
                content: Text('The clipboard content is not a valid config'),
                severity: InfoBarSeverity.error,
              );
            },
            duration: const Duration(seconds: 2),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        await displayInfoBar(
          context,
          builder: (context, close) {
            return InfoBar(
              title: const Text('Import Failed'),
              content: Text(e.toString()),
              severity: InfoBarSeverity.error,
            );
          },
          duration: const Duration(seconds: 3),
        );
      }
    }
  }

  Future<void> _navigateToManualConfig() async {
    setState(() => _showAddSheet = false);
    await Navigator.push(
      context,
      FluentPageRoute(
        builder: (context) => const ManualConfigScreen(),
      ),
    );
    await _loadConfigs();
  }

  Future<void> _navigateToQrScanner() async {
    setState(() => _showAddSheet = false);
    await Navigator.push(
      context,
      FluentPageRoute(
        builder: (context) => const QrScannerScreen(),
      ),
    );
    await _loadConfigs();
  }

  Future<void> _confirmDelete(V2RayConfig config) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => ContentDialog(
        title: const Text('Delete Server'),
        content: Text('Delete "${config.remark}"? This cannot be undone.'),
        actions: [
          Button(
            child: const Text('Cancel'),
            onPressed: () => Navigator.pop(context, false),
          ),
          FilledButton(
            style: ButtonStyle(
              backgroundColor: WidgetStatePropertyAll(AppTheme.disconnectedRed),
            ),
            child: const Text('Delete'),
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await _handleDelete(config);
    }
  }

  Future<void> _handleDelete(V2RayConfig config) async {
    final service = Provider.of<V2RayService>(context, listen: false);
    await service.deleteConfig(config.id);
    setState(() {
      _configs.removeWhere((c) => c.id == config.id);
      _pingResults.remove(config.id);
      if (_selectedConfigId == config.id) _selectedConfigId = null;
    });
    if (mounted) {
      await displayInfoBar(
        context,
        builder: (context, close) {
          return InfoBar(
            title: const Text('Server Deleted'),
            content: Text('${config.remark} has been deleted'),
            severity: InfoBarSeverity.error,
          );
        },
        duration: const Duration(seconds: 2),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldPage(
      header: PageHeader(
        title: const Text('Servers', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
        commandBar: DropDownButton(
          title: const Text('Menu'),
          leading: const Icon(m.Icons.more_vert, size: 16),
          items: [
            MenuFlyoutItem(
              leading: const Icon(m.Icons.refresh, size: 16),
              text: const Text('Refresh'),
              onPressed: () {
                _loadConfigs();
              },
            ),
            MenuFlyoutItem(
              leading: const Icon(m.Icons.speed, size: 16),
              text: Text(_isSorting ? 'Pinging...' : 'Ping All'),
              onPressed: _isSorting
                  ? null
                  : () {
                      _pingAllServers();
                    },
            ),
            const MenuFlyoutSeparator(),
            MenuFlyoutItem(
              leading: const Icon(m.Icons.content_paste, size: 16),
              text: const Text('Paste from Clipboard'),
              onPressed: () {
                _importFromClipboard();
              },
            ),
          ],
        ),
      ),
      content: Stack(
        children: [
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: TextBox(
                  placeholder: 'Search servers...',
                  prefix: const Padding(
                    padding: EdgeInsets.only(left: 12),
                    child: Icon(m.Icons.search, size: 16),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                ),
              ),
              Expanded(
                child: _isLoading
                    ? const Center(child: ProgressRing())
                    : _filteredConfigs.isEmpty
                        ? _buildEmptyState()
                        : ListView(
                            padding: const EdgeInsets.fromLTRB(0, 8, 0, AppTheme.bottomNavHeight + 96),
                            children: [
                              if (_manualConfigs.isNotEmpty) ...[
                                _buildSectionHeader(m.Icons.edit_note, 'Manual Configs (${_manualConfigs.length})'),
                                ..._manualConfigs.map((config) => _buildServerCard(config)),
                                const SizedBox(height: 24),
                              ],
                              if (_subscriptionConfigs.isNotEmpty) ...[
                                _buildSectionHeader(m.Icons.cloud_outlined, 'Subscriptions (${_subscriptionConfigs.length})'),
                                ..._subscriptionConfigs.map((config) => _buildServerCard(config)),
                              ],
                            ],
                          ),
              ),
            ],
          ),
          Positioned(
            right: 16,
            bottom: AppTheme.bottomNavHeight + 16,
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppTheme.primary,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primary.withOpacity(0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: IconButton(
                icon: const Icon(m.Icons.add, color: Colors.white, size: 28),
                onPressed: () {
                  setState(() => _showAddSheet = true);
                },
              ),
            ),
          ),
          if (_showAddSheet) _buildAddSheet(),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(IconData icon, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Row(
        children: [
          Icon(icon, size: 16),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildAddSheet() {
    return Positioned.fill(
      child: Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              onTap: () => setState(() => _showAddSheet = false),
              child: Container(color: Colors.black.withOpacity(0.4)),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppTheme.lightBorder,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('Add Server', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: FilledButton(
                      onPressed: _navigateToManualConfig,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(m.Icons.edit_note, size: 20),
                          SizedBox(width: 8),
                          Text('Add Manually'),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: FilledButton(
                      onPressed: _navigateToQrScanner,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(m.Icons.qr_code_scanner, size: 20),
                          SizedBox(width: 8),
                          Text('Scan QR'),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: Button(
                      onPressed: () {
                        setState(() => _showAddSheet = false);
                        _importFromClipboard();
                      },
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(m.Icons.content_paste, size: 20),
                          SizedBox(width: 8),
                          Text('Paste'),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              color: AppTheme.primary.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Icon(
                m.Icons.dns_outlined,
                size: 100,
                color: AppTheme.primary.withOpacity(0.45),
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'No servers yet',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          const Text(
            'Add your first server manually, scan a QR code, or paste a config from clipboard',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 15, color: AppTheme.lightTextSecondary),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: FilledButton(
              onPressed: _navigateToManualConfig,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(m.Icons.edit_note, size: 20),
                  SizedBox(width: 8),
                  Text('Add Manually'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: FilledButton(
              onPressed: _navigateToQrScanner,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(m.Icons.qr_code_scanner, size: 20),
                  SizedBox(width: 8),
                  Text('Scan QR'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: Button(
              onPressed: _importFromClipboard,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(m.Icons.content_paste, size: 20),
                  SizedBox(width: 8),
                  Text('Paste'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServerCard(V2RayConfig config) {
    final ping = _pingResults[config.id];
    final service = Provider.of<V2RayService>(context, listen: false);
    final isConnected = service.activeConfig?.id == config.id;
    final isSelected = _selectedConfigId == config.id;

    return Container(
      height: 80,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: AppTheme.neoCardDecoration(
        borderRadius: 24,
        brightness: FluentTheme.of(context).brightness,
        color: isConnected
            ? AppTheme.primary.withOpacity(0.08)
            : (isSelected ? AppTheme.primary.withOpacity(0.04) : null),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppTheme.getPingColor(ping).withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Icon(
                _getProtocolIcon(config.configType),
                color: AppTheme.getPingColor(ping),
                size: 24,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  config.remark,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                Text(
                  '${config.address}:${config.port} \u2022 ${config.protocolDisplay}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 14),
                ),
              ],
            ),
          ),
          if (ping != null && ping >= 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.getPingColor(ping).withOpacity(0.2),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                '${ping}ms',
                style: TextStyle(
                  color: AppTheme.getPingColor(ping),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          if (ping != null && ping == -1)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.2),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Text(
                '-1 ms',
                style: TextStyle(
                  color: Colors.grey,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          if (ping == null)
            IconButton(
              icon: const Icon(m.Icons.speed, size: 24),
              onPressed: () => _pingSingleServer(config),
            ),
          if (!isConnected)
            IconButton(
              icon: Icon(
                isSelected ? m.Icons.radio_button_checked : m.Icons.radio_button_unchecked,
                color: isSelected ? AppTheme.primary : null,
                size: 24,
              ),
              onPressed: () => _handleSelectConfig(config),
            ),
          IconButton(
            icon: Icon(
              isConnected ? m.Icons.stop : m.Icons.play_arrow,
              size: 24,
            ),
            onPressed: () => _handleConnect(config),
          ),
          IconButton(
            onPressed: () => _confirmDelete(config),
            icon: Icon(m.Icons.delete_outline, color: Colors.red, size: 24),
          ),
        ],
      ),
    );
  }

  Future<void> _handleSelectConfig(V2RayConfig config) async {
    setState(() {
      _selectedConfigId = config.id;
    });

    final service = Provider.of<V2RayService>(context, listen: false);
    await service.saveSelectedConfig(config);

    if (mounted) {
      await displayInfoBar(
        context,
        builder: (context, close) {
          return InfoBar(
            title: const Text('Server Selected'),
            content: Text('${config.remark} is now selected'),
            severity: InfoBarSeverity.success,
          );
        },
        duration: const Duration(seconds: 2),
      );
    }
  }

  IconData _getProtocolIcon(String type) {
    switch (type.toLowerCase()) {
      case 'vmess':
        return m.Icons.shield_outlined;
      case 'vless':
        return m.Icons.verified_user_outlined;
      case 'trojan':
        return m.Icons.security_outlined;
      case 'shadowsocks':
        return m.Icons.lock_outline;
      default:
        return m.Icons.dns_outlined;
    }
  }

  Future<void> _pingSingleServer(V2RayConfig config) async {
    final service = Provider.of<V2RayService>(context, listen: false);
    final ping = await service.getServerDelay(config);
    if (mounted) {
      setState(() {
        _pingResults[config.id] = ping;
      });
    }
  }

  Future<void> _handleConnect(V2RayConfig config) async {
    final service = Provider.of<V2RayService>(context, listen: false);

    if (service.activeConfig?.id == config.id) {
      await service.disconnect();
      if (mounted) {
        await displayInfoBar(
          context,
          builder: (context, close) {
            return const InfoBar(
              title: Text('Disconnected'),
              severity: InfoBarSeverity.info,
            );
          },
          duration: const Duration(seconds: 2),
        );
      }
    } else {
      if (service.isConnected) {
        await service.disconnect();
      }

      final success = await service.connect(config);
      if (mounted) {
        await displayInfoBar(
          context,
          builder: (context, close) {
            return InfoBar(
              title: Text(success ? 'Connected' : 'Connection Failed'),
              content: Text(
                success ? 'Connected to ${config.remark}' : 'Failed to connect to server',
              ),
              severity: success ? InfoBarSeverity.success : InfoBarSeverity.error,
            );
          },
          duration: const Duration(seconds: 2),
        );
      }
    }
  }
}
