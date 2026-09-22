import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sm_vpn/theme/app_theme.dart';
import 'package:sm_vpn/l10n/app_strings.dart';

class PerAppProxyScreen extends StatefulWidget {
  const PerAppProxyScreen({super.key});

  @override
  State<PerAppProxyScreen> createState() => _PerAppProxyScreenState();
}

class _PerAppProxyScreenState extends State<PerAppProxyScreen> {
  List<Map<String, dynamic>> _apps = [];
  List<String> _selectedApps = [];
  bool _isLoading = true;
  String _searchQuery = '';

  static const MethodChannel _appListChannel = MethodChannel('com.zedsecure.vpn/app_list');

  @override
  void initState() {
    super.initState();
    _loadApps();
  }

  Future<void> _loadApps() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      _selectedApps = prefs.getStringList('blocked_apps') ?? [];

      final List<dynamic> result = await _appListChannel.invokeMethod('getInstalledApps');
      
      setState(() {
        _apps = result
            .map((app) => {
                  'packageName': app['packageName'] as String,
                  'name': app['name'] as String,
                  'isSystemApp': app['isSystemApp'] as bool,
                })
            .toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveSelection() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('blocked_apps', _selectedApps);
  }

  List<Map<String, dynamic>> get _filteredApps {
    if (_searchQuery.isEmpty) return _apps;
    return _apps.where((app) {
      return app['name'].toString().toLowerCase().contains(_searchQuery.toLowerCase()) ||
          app['packageName'].toString().toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldPage(
      header: PageHeader(
        title: Text(S.of(context, 'perapp_title'), style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
        commandBar: FilledButton(
          onPressed: () async {
            await _saveSelection();
            if (context.mounted) {
              await displayInfoBar(
                context,
                builder: (context, close) {
                  return InfoBar(
                    title: Text(S.of(context, 'perapp_saved_title')),
                    content: Text(S.of(context, 'perapp_saved_msg')),
                    severity: InfoBarSeverity.success,
                  );
                },
                duration: const Duration(seconds: 2),
              );
            }
          },
          child: Text(S.of(context, 'perapp_save')),
        ),
      ),
      content: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  S.of(context, 'perapp_guide'),
                  style: TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 12),
                TextBox(
                  placeholder: S.of(context, 'perapp_search_hint'),
                  prefix: const Padding(
                    padding: EdgeInsets.only(left: 12),
                    child: Icon(FluentIcons.search),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(S.of(context, 'perapp_selected', {'count': '${_selectedApps.length}'})),
                Row(
                  children: [
                    Button(
                      onPressed: () {
                        setState(() {
                          _selectedApps = _apps.map((app) => app['packageName'] as String).toList();
                        });
                      },
                      child: Text(S.of(context, 'perapp_select_all')),
                    ),
                    const SizedBox(width: 8),
                    Button(
                      onPressed: () {
                        setState(() {
                          _selectedApps.clear();
                        });
                      },
                      child: Text(S.of(context, 'perapp_clear_all')),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: _isLoading
                ? const Center(child: ProgressRing())
                : _filteredApps.isEmpty
                    ? Center(
                        child: Text(S.of(context, 'perapp_empty')),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(
                            0, 4, 0, AppTheme.bottomNavHeight),
                        itemCount: _filteredApps.length,
                        itemBuilder: (context, index) {
                          final app = _filteredApps[index];
                          final packageName = app['packageName'] as String;
                          final isSelected = _selectedApps.contains(packageName);

                          return Container(
                            margin: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 6),
                            decoration: AppTheme.neoCardDecoration(
                              borderRadius: 24,
                              brightness: FluentTheme.of(context).brightness,
                              color: isSelected
                                  ? AppTheme.primary.withValues(alpha: 0.08)
                                  : null,
                            ),
                            child: ListTile(
                              title: Text(app['name'] as String),
                              subtitle: Text(packageName),
                              trailing: Checkbox(
                                checked: isSelected,
                                onChanged: (value) {
                                  setState(() {
                                    if (value == true) {
                                      _selectedApps.add(packageName);
                                    } else {
                                      _selectedApps.remove(packageName);
                                    }
                                  });
                                },
                              ),
                              onPressed: () {
                                setState(() {
                                  if (isSelected) {
                                    _selectedApps.remove(packageName);
                                  } else {
                                    _selectedApps.add(packageName);
                                  }
                                });
                              },
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

