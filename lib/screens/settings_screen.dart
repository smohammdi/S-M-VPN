import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/services.dart';
import 'package:material_symbols_icons/symbols.dart' as m;
import 'package:provider/provider.dart';
import 'package:sm_vpn/services/v2ray_service.dart';
import 'package:sm_vpn/theme/app_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:sm_vpn/screens/per_app_proxy_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _autoConnect = false;
  bool _killSwitch = false;
  bool _darkMode = true;

  static const Color _danger = Color(0xFFEF4444);

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _autoConnect = prefs.getBool('auto_connect') ?? false;
      _killSwitch = prefs.getBool('kill_switch') ?? false;
      _darkMode = prefs.getBool('dark_mode') ?? true;
    });
  }

  Future<void> _saveSetting(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  Color _secondaryText(BuildContext context) {
    return FluentTheme.of(context).brightness == Brightness.dark
        ? const Color(0xFF94A3B8)
        : const Color(0xFF64748B);
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldPage(
      header: const PageHeader(
        title: Text('Settings', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
      ),
      content: Directionality(
        textDirection: Directionality.of(context),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(0, 8, 0, AppTheme.bottomNavHeight),
          children: [
            _buildSection(
              'General',
              m.Symbols.settings_rounded,
              [
                _buildSettingTile(
                  'Auto Connect',
                  'Automatically connect on app start',
                  m.Symbols.bolt_rounded,
                  _autoConnect,
                  (value) {
                    HapticFeedback.selectionClick().ignore();
                    setState(() {
                      _autoConnect = value;
                    });
                    _saveSetting('auto_connect', value);
                  },
                ),
                _buildSettingTile(
                  'Kill Switch',
                  'Block internet if VPN disconnects',
                  m.Symbols.shield_rounded,
                  _killSwitch,
                  (value) {
                    HapticFeedback.selectionClick().ignore();
                    setState(() {
                      _killSwitch = value;
                    });
                    _saveSetting('kill_switch', value);
                  },
                ),
              ],
            ),
            const SizedBox(height: 4),
            _buildSection(
              'Network',
              m.Symbols.wifi_rounded,
              [
                _buildNavigationTile(
                  'Per-App Proxy',
                  'Choose which apps use VPN',
                  m.Symbols.tune_rounded,
                  () {
                    HapticFeedback.lightImpact().ignore();
                    Navigator.push(
                      context,
                      FluentPageRoute(builder: (context) => const PerAppProxyScreen()),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 4),
            _buildSection(
              'Appearance',
              m.Symbols.palette_rounded,
              [
                _buildSettingTile(
                  'Dark Mode',
                  'Use dark theme',
                  m.Symbols.dark_mode_rounded,
                  _darkMode,
                  (value) {
                    HapticFeedback.selectionClick().ignore();
                    setState(() {
                      _darkMode = value;
                    });
                    _saveSetting('dark_mode', value);
                  },
                ),
              ],
            ),
            const SizedBox(height: 4),
            _buildSection(
              'Data',
              m.Symbols.storage_rounded,
              [
                _buildActionTile(
                  'Clear Server Cache',
                  'Clear all cached server data',
                  m.Symbols.cached_rounded,
                  () => _clearCache(),
                ),
                _buildActionTile(
                  'Clear All Data',
                  'Reset all settings and servers',
                  m.Symbols.delete_forever_rounded,
                  () => _clearAllData(),
                  danger: true,
                ),
              ],
            ),
            const SizedBox(height: 4),
            _buildSection(
              'About',
              m.Symbols.info_rounded,
              [
                _buildInfoTile('App Name', 'S-M'),
                _buildInfoTile('Version', '1.0.0'),
                _buildInfoTile('Build', '1'),
                _buildNavigationTile(
                  'Privacy Policy',
                  'View our privacy policy',
                  m.Symbols.description_rounded,
                  () {
                    HapticFeedback.lightImpact().ignore();
                    _launchUrl('https://smohammdi.github.io/S-M-Privacy-Policy/');
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, IconData icon, List<Widget> children) {
    return Container(
      margin: AppTheme.cardMargin,
      padding: AppTheme.cardPadding,
      decoration: AppTheme.neoCardDecoration(
        borderRadius: 24,
        brightness: FluentTheme.of(context).brightness,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Icon(icon, color: AppTheme.primary, size: 20),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildSettingTile(
    String title,
    String subtitle,
    IconData icon,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppTheme.primary.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Center(
            child: Icon(icon, color: AppTheme.primary, size: 22),
          ),
        ),
        title: Text(
          title,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(fontSize: 12, color: _secondaryText(context)),
        ),
        trailing: ToggleSwitch(
          checked: value,
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildActionTile(
    String title,
    String subtitle,
    IconData icon,
    VoidCallback onPressed, {
    bool danger = false,
  }) {
    final Color tint = danger ? _danger : AppTheme.primary;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: tint.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Center(
            child: Icon(icon, color: tint, size: 22),
          ),
        ),
        title: Text(
          title,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(fontSize: 12, color: _secondaryText(context)),
        ),
        trailing: OutlinedButton(
          onPressed: () {
            HapticFeedback.lightImpact().ignore();
            onPressed();
          },
          style: ButtonStyle(
            foregroundColor: WidgetStateProperty.all(tint),
            padding: WidgetStateProperty.all(
              const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            ),
            shape: WidgetStateProperty.all(
              RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          child: const Text('Execute'),
        ),
      ),
    );
  }

  Widget _buildNavigationTile(
    String title,
    String subtitle,
    IconData icon,
    VoidCallback onPressed,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppTheme.primary.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Center(
            child: Icon(icon, color: AppTheme.primary, size: 22),
          ),
        ),
        title: Text(
          title,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(fontSize: 12, color: _secondaryText(context)),
        ),
        trailing: Icon(
          m.Symbols.chevron_right_rounded,
          size: 22,
          color: _secondaryText(context),
        ),
        onPressed: onPressed,
      ),
    );
  }

  Widget _buildInfoTile(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 14, color: _secondaryText(context)),
          ),
          Text(
            value,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else if (mounted) {
      await displayInfoBar(
        context,
        builder: (context, close) {
          return const InfoBar(
            title: Text('Unable to open'),
            content: Text('Could not open the privacy policy link'),
            severity: InfoBarSeverity.error,
          );
        },
        duration: const Duration(seconds: 2),
      );
    }
  }

  Future<void> _clearCache() async {
    await showDialog(
      context: context,
      builder: (context) => ContentDialog(
        title: const Text('Clear Cache'),
        content: const Text('This will clear all cached server data including ping results.'),
        actions: [
          Button(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(context);

              final service = Provider.of<V2RayService>(context, listen: false);
              service.clearPingCache();

              if (mounted) {
                await displayInfoBar(
                  context,
                  builder: (context, close) {
                    return const InfoBar(
                      title: Text('Cache Cleared'),
                      severity: InfoBarSeverity.success,
                    );
                  },
                  duration: const Duration(seconds: 2),
                );
              }
            },
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }

  Future<void> _clearAllData() async {
    await showDialog(
      context: context,
      builder: (context) => ContentDialog(
        title: const Text('Clear All Data'),
        content: const Text('This will delete all servers, subscriptions, and settings. This action cannot be undone.'),
        actions: [
          Button(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(context);

              final service = Provider.of<V2RayService>(context, listen: false);
              await service.saveConfigs([]);
              await service.saveSubscriptions([]);
              service.clearPingCache();

              final prefs = await SharedPreferences.getInstance();
              await prefs.clear();

              if (mounted) {
                await displayInfoBar(
                  context,
                  builder: (context, close) {
                    return const InfoBar(
                      title: Text('All Data Cleared'),
                      severity: InfoBarSeverity.warning,
                    );
                  },
                  duration: const Duration(seconds: 2),
                );
              }
            },
            child: const Text('Clear All'),
          ),
        ],
      ),
    );
  }
}
