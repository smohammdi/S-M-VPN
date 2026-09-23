import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/services.dart';
import 'package:material_symbols_icons/symbols.dart' as m;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:sm_vpn/services/v2ray_service.dart';
import 'package:sm_vpn/theme/app_theme.dart';
import 'package:sm_vpn/l10n/app_strings.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:sm_vpn/screens/per_app_proxy_screen.dart';
import 'package:sm_vpn/widgets/floating_bottom_nav.dart';

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

  late Future<PackageInfo> _packageInfoFuture;

  @override
  void initState() {
    super.initState();
    _packageInfoFuture = PackageInfo.fromPlatform();
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
      header: PageHeader(
        title: Text(S.of(context, 'settings_title'),
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
      ),
      content: Directionality(
        textDirection: Directionality.of(context),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(0, 30, 0, 150),
          children: [
            _buildSection(
              S.of(context, 'set_general'),
              m.Symbols.settings_rounded,
              [
                _buildSettingTile(
                  S.of(context, 'set_autoconnect'),
                  S.of(context, 'set_autoconnect_desc'),
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
                  S.of(context, 'set_killswitch'),
                  S.of(context, 'set_killswitch_desc'),
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
              S.of(context, 'set_network'),
              m.Symbols.wifi_rounded,
              [
                _buildNavigationTile(
                  S.of(context, 'set_perapp'),
                  S.of(context, 'set_perapp_desc'),
                  m.Symbols.tune_rounded,
                  () {
                    HapticFeedback.lightImpact().ignore();
                    Navigator.push(
                      context,
                      fadeSlideRoute(const PerAppProxyScreen()),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 4),
            _buildSection(
              S.of(context, 'set_appearance'),
              m.Symbols.palette_rounded,
              [
                _buildSettingTile(
                  S.of(context, 'set_darkmode'),
                  S.of(context, 'set_darkmode_desc'),
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
                _buildPaletteTile(context),
                _buildLanguageTile(context),
              ],
            ),
            const SizedBox(height: 4),
            _buildSection(
              S.of(context, 'set_data'),
              m.Symbols.storage_rounded,
              [
                _buildActionTile(
                  S.of(context, 'set_clear_cache'),
                  S.of(context, 'set_clear_cache_desc'),
                  m.Symbols.cached_rounded,
                  () => _clearCache(),
                ),
                _buildActionTile(
                  S.of(context, 'set_clear_all'),
                  S.of(context, 'set_clear_all_desc'),
                  m.Symbols.delete_forever_rounded,
                  () => _clearAllData(),
                  danger: true,
                ),
              ],
            ),
            const SizedBox(height: 4),
            _buildSection(
              S.of(context, 'set_about'),
              m.Symbols.info_rounded,
              [
                _buildInfoTile(S.of(context, 'set_appname'), 'S-M'),
                _buildInfoTile(
                  S.of(context, 'set_version'),
                  '',
                  valueWidget: _buildVersionText((info) => info.version),
                ),
                _buildInfoTile(
                  S.of(context, 'set_build'),
                  '',
                  valueWidget: _buildVersionText((info) => info.buildNumber),
                ),
                _buildNavigationTile(
                  S.of(context, 'set_privacy'),
                  S.of(context, 'set_privacy_desc'),
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
          child: Text(S.of(context, 'set_execute')),
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

  Widget _buildPaletteTile(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final langProvider = context.watch<LanguageProvider>();
    final palette = themeProvider.palette;

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
            child: Icon(m.Symbols.palette_rounded, color: AppTheme.primary, size: 22),
          ),
        ),
        title: Text(
          S.of(context, 'set_palette'),
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          '${S.of(context, 'set_palette_desc')} • ${palette.name(langProvider.code)}',
          style: TextStyle(fontSize: 12, color: _secondaryText(context)),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ...palette.dots.map(
              (c) => Container(
                width: 18,
                height: 18,
                margin: const EdgeInsets.only(left: 4),
                decoration: BoxDecoration(
                  color: c,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFFFFFFFF).withValues(alpha: 0.6),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 6),
            Icon(
              m.Symbols.chevron_right_rounded,
              size: 22,
              color: _secondaryText(context),
            ),
          ],
        ),
        onPressed: () => _showPaletteDialog(context),
      ),
    );
  }

  Widget _buildLanguageTile(BuildContext context) {
    final langProvider = context.watch<LanguageProvider>();
    final String current = langProvider.language == AppLanguage.system
        ? S.of(context, 'lang_system')
        : langProvider.language == AppLanguage.english
            ? S.of(context, 'lang_english')
            : S.of(context, 'lang_persian');

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
            child: Icon(m.Symbols.language_rounded, color: AppTheme.primary, size: 22),
          ),
        ),
        title: Text(
          S.of(context, 'set_language'),
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          '${S.of(context, 'set_language_desc')} • $current',
          style: TextStyle(fontSize: 12, color: _secondaryText(context)),
        ),
        trailing: Icon(
          m.Symbols.chevron_right_rounded,
          size: 22,
          color: _secondaryText(context),
        ),
        onPressed: () => _showLanguageDialog(context),
      ),
    );
  }

  Future<void> _showPaletteDialog(BuildContext context) async {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final langProvider = Provider.of<LanguageProvider>(context, listen: false);
    final bool isDark =
        FluentTheme.of(context).brightness == Brightness.dark;
    final Color inactiveBorder =
        isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);

    await showDialog(
      context: context,
      builder: (context) => ContentDialog(
        title: Text(S.of(context, 'set_palette_title')),
        content: SizedBox(
          width: 360,
          child: GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 2.4,
            children: AppPalettes.all.map((palette) {
              final bool active = palette.id == themeProvider.palette.id;
              return GestureDetector(
                onTap: () async {
                  HapticFeedback.selectionClick().ignore();
                  await themeProvider.setPalette(
                    AppPalettes.all.indexOf(palette),
                  );
                  if (context.mounted) Navigator.pop(context);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: active
                          ? const Color(0xFF6366F1)
                          : inactiveBorder,
                      width: active ? 2.5 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      ...palette.dots.map(
                        (c) => Container(
                          width: 18,
                          height: 18,
                          margin: const EdgeInsets.only(right: 4),
                          decoration: BoxDecoration(
                            color: c,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          palette.name(langProvider.code),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        actions: [
          Button(
            onPressed: () => Navigator.pop(context),
            child: Text(S.of(context, 'set_cancel')),
          ),
        ],
      ),
    );
  }

  Future<void> _showLanguageDialog(BuildContext context) async {
    final langProvider = Provider.of<LanguageProvider>(context, listen: false);

    String label(AppLanguage option) {
      if (option == AppLanguage.system) return S.of(context, 'lang_system');
      if (option == AppLanguage.english) return S.of(context, 'lang_english');
      return S.of(context, 'lang_persian');
    }

    await showDialog(
      context: context,
      builder: (context) => ContentDialog(
        title: Text(S.of(context, 'set_language_title')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: AppLanguage.values.map((option) {
            final bool active = langProvider.language == option;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                title: Text(
                  label(option),
                  style: TextStyle(
                    fontWeight: active ? FontWeight.w700 : FontWeight.w400,
                  ),
                ),
                trailing: active
                    ? Icon(m.Symbols.check_rounded,
                        color: AppTheme.primary, size: 22)
                    : null,
                onPressed: () async {
                  HapticFeedback.selectionClick().ignore();
                  await langProvider.setLanguage(option);
                  if (context.mounted) Navigator.pop(context);
                },
              ),
            );
          }).toList(),
        ),
        actions: [
          Button(
            onPressed: () => Navigator.pop(context),
            child: Text(S.of(context, 'set_cancel')),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoTile(String label, String value, {Widget? valueWidget}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 14, color: _secondaryText(context)),
          ),
          valueWidget ??
              Text(
                value,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
        ],
      ),
    );
  }

  Widget _buildVersionText(String Function(PackageInfo info) pick) {
    return FutureBuilder<PackageInfo>(
      future: _packageInfoFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Text(
            '…',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          );
        }
        if (snapshot.hasError) {
          return Text(
            S.of(context, 'version_unknown'),
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          );
        }
        final info = snapshot.data;
        if (info == null) {
          return const Text(
            '…',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          );
        }
        return Text(
          pick(info),
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        );
      },
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
          return InfoBar(
            title: Text(S.of(context, 'set_open_fail_title')),
            content: Text(S.of(context, 'set_open_fail_msg')),
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
        title: Text(S.of(context, 'set_cache_title')),
        content: Text(S.of(context, 'set_cache_msg')),
        actions: [
          Button(
            onPressed: () {
              Navigator.pop(context);
            },
            child: Text(S.of(context, 'set_cancel')),
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
                    return InfoBar(
                      title: Text(S.of(context, 'set_cache_done')),
                      severity: InfoBarSeverity.success,
                    );
                  },
                  duration: const Duration(seconds: 2),
                );
              }
            },
            child: Text(S.of(context, 'set_clear')),
          ),
        ],
      ),
    );
  }

  Future<void> _clearAllData() async {
    await showDialog(
      context: context,
      builder: (context) => ContentDialog(
        title: Text(S.of(context, 'set_alldata_title')),
        content: Text(S.of(context, 'set_alldata_msg')),
        actions: [
          Button(
            onPressed: () {
              Navigator.pop(context);
            },
            child: Text(S.of(context, 'set_cancel')),
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
                    return InfoBar(
                      title: Text(S.of(context, 'set_all_done')),
                      severity: InfoBarSeverity.warning,
                    );
                  },
                  duration: const Duration(seconds: 2),
                );
              }
            },
            child: Text(S.of(context, 'set_clear_all_btn')),
          ),
        ],
      ),
    );
  }
}
