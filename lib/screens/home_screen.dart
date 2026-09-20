import 'package:fluent_ui/fluent_ui.dart';
import 'package:provider/provider.dart';
import 'package:sm_vpn/services/v2ray_service.dart';
import 'package:sm_vpn/theme/app_theme.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isConnecting = false;

  @override
  Widget build(BuildContext context) {
    return Consumer<V2RayService>(
      builder: (context, v2rayService, child) {
        final isConnected = v2rayService.isConnected;
        final activeConfig = v2rayService.activeConfig;
        final status = v2rayService.currentStatus;

        return ScaffoldPage(
          header: PageHeader(
            title: const Text(
              'S-M VPN',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
          ),
          content: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 500),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      margin: AppTheme.cardMargin,
                      padding: AppTheme.cardPadding,
                      decoration: AppTheme.neoCardDecoration(
                        borderRadius: 24,
                        brightness: FluentTheme.of(context).brightness,
                      ),
                      child: Column(
                        children: [
                          Stack(
                            alignment: Alignment.center,
                            children: [
                              Container(
                                width: 220,
                                height: 220,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: RadialGradient(
                                    colors: [
                                      AppTheme.primary.withOpacity(0.18),
                                      AppTheme.primary.withOpacity(0.06),
                                      Colors.transparent,
                                    ],
                                  ),
                                ),
                              ),
                              GestureDetector(
                                onTap: _isConnecting
                                    ? null
                                    : () => _handleConnectionToggle(v2rayService),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 300),
                                  width: 168,
                                  height: 168,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: LinearGradient(
                                      colors: isConnected
                                          ? [
                                              AppTheme.primaryDark,
                                              AppTheme.primary,
                                            ]
                                          : [
                                              AppTheme.primary,
                                              AppTheme.primaryLight,
                                            ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppTheme.primary.withOpacity(0.45),
                                        blurRadius: 28,
                                        spreadRadius: 6,
                                      ),
                                    ],
                                  ),
                                  child: Center(
                                    child: _isConnecting
                                        ? const SizedBox(
                                            width: 48,
                                            height: 48,
                                            child: ProgressRing())
                                        : Icon(
                                            isConnected
                                                ? FluentIcons.plug_disconnected
                                                : FluentIcons.plug_connected,
                                            size: 62,
                                            color: Colors.white,
                                          ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          Text(
                            isConnected ? 'Connected' : 'Disconnected',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              color: isConnected
                                  ? AppTheme.primary
                                  : AppTheme.lightTextPrimary,
                            ),
                          ),
                          const SizedBox(height: 16),
                          if (activeConfig != null) ...[
                            Text(
                              activeConfig.remark,
                              style: const TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.w400),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${activeConfig.address}:${activeConfig.port}',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w400,
                                color: AppTheme.lightTextSecondary,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: AppTheme.primary.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Text(
                                activeConfig.protocolDisplay,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.primaryDark,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (isConnected && status != null)
                      Container(
                        margin: AppTheme.cardMargin,
                        padding: AppTheme.cardPadding,
                        decoration: AppTheme.neoCardDecoration(
                          borderRadius: 24,
                          brightness: FluentTheme.of(context).brightness,
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                _buildStatCard(
                                  'Upload',
                                  AppTheme.formatSpeed(status.uploadSpeed),
                                  FluentIcons.up,
                                  AppTheme.primary,
                                ),
                                const SizedBox(width: 12),
                                _buildStatCard(
                                  'Download',
                                  AppTheme.formatSpeed(status.downloadSpeed),
                                  FluentIcons.down,
                                  AppTheme.secondary,
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                _buildStatCard(
                                  'Uploaded',
                                  AppTheme.formatBytes(status.upload),
                                  FluentIcons.cloud_upload,
                                  AppTheme.primaryLight,
                                ),
                                const SizedBox(width: 12),
                                _buildStatCard(
                                  'Downloaded',
                                  AppTheme.formatBytes(status.download),
                                  FluentIcons.cloud_download,
                                  AppTheme.accent,
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Duration: ${_formatDuration(status.duration)}',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w400,
                                color: AppTheme.lightTextSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withOpacity(0.14),
              ),
              child: Center(
                child: Icon(icon, color: color, size: 22),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppTheme.lightTextSecondary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDuration(String duration) {
    try {
      final parts = duration.split(':');
      if (parts.length == 3) {
        return '${parts[0]}h ${parts[1]}m ${parts[2]}s';
      }
      return duration;
    } catch (e) {
      return duration;
    }
  }

  Future<void> _handleConnectionToggle(V2RayService service) async {
    setState(() {
      _isConnecting = true;
    });

    try {
      if (service.isConnected) {
        await service.disconnect();
      } else {
        final selectedConfig = await service.loadSelectedConfig();
        if (selectedConfig == null) {
          final configs = await service.loadConfigs();
          if (configs.isEmpty) {
            if (mounted) {
              await displayInfoBar(
                context,
                builder: (context, close) {
                  return const InfoBar(
                    title: Text('No Servers'),
                    content: Text('Please add servers from the Servers tab'),
                    severity: InfoBarSeverity.warning,
                  );
                },
                duration: const Duration(seconds: 3),
              );
            }
          } else {
            if (mounted) {
              await displayInfoBar(
                context,
                builder: (context, close) {
                  return const InfoBar(
                    title: Text('No Server Selected'),
                    content: Text('Please select a server from the Servers tab'),
                    severity: InfoBarSeverity.info,
                  );
                },
                duration: const Duration(seconds: 3),
              );
            }
          }
        } else {
          final success = await service.connect(selectedConfig);
          if (mounted) {
            await displayInfoBar(
              context,
              builder: (context, close) {
                return InfoBar(
                  title: Text(success ? 'Connected' : 'Connection Failed'),
                  content: Text(success
                      ? 'Connected to ${selectedConfig.remark}'
                      : 'Failed to connect to server'),
                  severity: success ? InfoBarSeverity.success : InfoBarSeverity.error,
                );
              },
              duration: const Duration(seconds: 2),
            );
          }
        }
      }
    } finally {
      if (mounted) {
        setState(() {
          _isConnecting = false;
        });
      }
    }
  }
}
