import 'dart:ui';

import 'package:flutter_v2ray_client/flutter_v2ray.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:material_symbols_icons/symbols.dart' as m;
import 'package:provider/provider.dart';

import 'package:sm_vpn/models/v2ray_config.dart';
import 'package:sm_vpn/services/v2ray_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isBusy = false;

  Future<void> _handleConnectionToggle() async {
    if (_isBusy) return;

    final service = context.read<V2RayService>();

    setState(() {
      _isBusy = true;
    });

    try {
      if (service.isConnected) {
        await service.disconnect();
        return;
      }

      final V2RayConfig? selectedConfig = await service.loadSelectedConfig();

      if (selectedConfig == null) {
        final configs = await service.loadConfigs();

        if (!mounted) return;

        if (configs.isEmpty) {
          await _showMessage(
            title: 'No Servers',
            message: 'No VPN server is configured yet.',
          );
          return;
        }

        await _showMessage(
          title: 'No Server Selected',
          message: 'Please select a server before connecting.',
        );
        return;
      }

      final success = await service.connect(selectedConfig);

      if (!success && mounted) {
        await _showMessage(
          title: 'Connection Failed',
          message: 'Unable to establish the VPN connection.',
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isBusy = false;
        });
      }
    }
  }

  Future<void> _showMessage({
    required String title,
    required String message,
  }) async {
    if (!mounted) return;

    await showDialog<void>(
      context: context,
      builder: (context) {
        return ContentDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            Button(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<V2RayService>(
      builder: (context, service, child) {
        final bool connected = service.isConnected;
        final V2RayConfig? activeConfig = service.activeConfig;
        final V2RayStatus? status = service.currentStatus;

        return ScaffoldPage(
          padding: EdgeInsets.zero,
          content: SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 32),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 620),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildHeader(context),
                          const SizedBox(height: 30),
                          _buildConnectionSection(
                            context,
                            connected: connected,
                            status: status,
                          ),
                          const SizedBox(height: 30),
                          if (activeConfig != null)
                            _buildServerCard(context, activeConfig)
                          else
                            _buildNoServerCard(context),
                          const SizedBox(height: 18),
                          _buildStatsSection(
                            context,
                            status: status,
                            connected: connected,
                          ),
                          const SizedBox(height: 24),
                          _buildConnectionButton(
                            context,
                            connected: connected,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context) {
    final theme = FluentTheme.of(context);
    final brightness = theme.brightness;

    final Color secondaryText = brightness == Brightness.dark
        ? const Color(0xFF94A3B8)
        : const Color(0xFF64748B);

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Secure connection',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  color: theme.typography.title?.color,
                  letterSpacing: -0.6,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                'S-M VPN',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: secondaryText,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          icon: const Icon(m.Symbols.settings_rounded, size: 24),
          onPressed: () {
            // Settings navigation will be connected later.
          },
        ),
      ],
    );
  }

  Widget _buildConnectionSection(
    BuildContext context, {
    required bool connected,
    required V2RayStatus? status,
  }) {
    final theme = FluentTheme.of(context);

    final String stateText;
    if (_isBusy) {
      stateText = 'Connecting...';
    } else if (connected) {
      stateText = 'Protected';
    } else if (status?.state.toUpperCase() == 'CONNECTING') {
      stateText = 'Connecting...';
    } else {
      stateText = 'Not connected';
    }

    final Color stateColor;
    if (_isBusy) {
      stateColor = const Color(0xFF6366F1);
    } else if (connected) {
      stateColor = const Color(0xFF10B981);
    } else {
      stateColor = const Color(0xFF64748B);
    }

    return Column(
      children: [
        Text(
          stateText,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: stateColor,
          ),
        ),
        const SizedBox(height: 18),
        _ConnectionBlob(
          connected: connected,
          connecting: _isBusy,
          onPressed: _handleConnectionToggle,
        ),
        const SizedBox(height: 16),
        Text(
          connected
              ? 'Your connection is encrypted'
              : 'Tap to connect securely',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13,
            color: theme.typography.body?.color,
          ),
        ),
      ],
    );
  }

  Widget _buildServerCard(BuildContext context, V2RayConfig config) {
    final theme = FluentTheme.of(context);
    final brightness = theme.brightness;

    final Color secondaryText = brightness == Brightness.dark
        ? const Color(0xFF94A3B8)
        : const Color(0xFF64748B);

    return _GlassCard(
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: const Color(0xFF6366F1).withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              m.Symbols.dns_rounded,
              color: Color(0xFF6366F1),
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  config.remark.isEmpty ? 'VPN Server' : config.remark,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: theme.typography.bodyStrong?.color,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  '${config.address}:${config.port}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    color: secondaryText,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              config.protocolDisplay,
              style: const TextStyle(
                color: Color(0xFF10B981),
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoServerCard(BuildContext context) {
    final theme = FluentTheme.of(context);

    return _GlassCard(
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: const Color(0xFF64748B).withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              m.Symbols.cloud_off_rounded,
              color: Color(0xFF64748B),
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'No server selected',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: theme.typography.bodyStrong?.color,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Choose a server to start a secure connection.',
                  style: TextStyle(
                    fontSize: 12,
                    color: theme.typography.body?.color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  Widget _buildStatsSection(
    BuildContext context, {
    required V2RayStatus? status,
    required bool connected,
  }) {
    final V2RayStatus current = status ?? V2RayStatus();

    return Row(
      children: [
        Expanded(
          child: _LiveStatCard(
            icon: m.Symbols.arrow_upward_rounded,
            label: 'Upload',
            value: connected ? _formatSpeed(current.uploadSpeed) : '--',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _LiveStatCard(
            icon: m.Symbols.arrow_downward_rounded,
            label: 'Download',
            value: connected ? _formatSpeed(current.downloadSpeed) : '--',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _LiveStatCard(
            icon: m.Symbols.schedule_rounded,
            label: 'Duration',
            value: connected ? _formatDuration(current.duration) : '--',
          ),
        ),
      ],
    );
  }

  Widget _buildConnectionButton(
    BuildContext context, {
    required bool connected,
  }) {
    final String label;
    if (_isBusy) {
      label = 'Please wait...';
    } else if (connected) {
      label = 'Disconnect';
    } else {
      label = 'Connect';
    }

    return SizedBox(
      height: 50,
      child: FilledButton(
        onPressed: _isBusy ? null : _handleConnectionToggle,
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) {
              return const Color(0xFF94A3B8);
            }
            if (connected) {
              return const Color(0xFFEF4444);
            }
            return const Color(0xFF6366F1);
          }),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              connected
                  ? m.Symbols.power_settings_new_rounded
                  : m.Symbols.lock_rounded,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatSpeed(int bytesPerSecond) {
    if (bytesPerSecond <= 0) {
      return '0 B/s';
    }

    const units = ['B/s', 'KB/s', 'MB/s', 'GB/s'];
    double value = bytesPerSecond.toDouble();
    int unitIndex = 0;

    while (value >= 1024 && unitIndex < units.length - 1) {
      value /= 1024;
      unitIndex++;
    }

    if (unitIndex == 0) {
      return '${value.toStringAsFixed(0)} ${units[unitIndex]}';
    }
    return '${value.toStringAsFixed(1)} ${units[unitIndex]}';
  }

  String _formatDuration(String duration) {
    if (duration.isEmpty) {
      return '00:00';
    }

    final parts = duration.split(':');
    if (parts.length == 3 && parts[0] == '00') {
      return '${parts[1]}:${parts[2]}';
    }
    return duration;
  }
}

class _GlassCard extends StatelessWidget {
  const _GlassCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final brightness = FluentTheme.of(context).brightness;

    final Color background = brightness == Brightness.dark
        ? const Color(0xFF111827).withValues(alpha: 0.72)
        : const Color(0xFFFFFFFF).withValues(alpha: 0.72);

    final Color border = brightness == Brightness.dark
        ? const Color(0xFFFFFFFF).withValues(alpha: 0.08)
        : const Color(0xFF0F172A).withValues(alpha: 0.06);

    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: border),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF000000).withValues(alpha: 0.04),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

class _LiveStatCard extends StatelessWidget {
  const _LiveStatCard({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);

    return _GlassCard(
      child: SizedBox(
        height: 82,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 20, color: const Color(0xFF6366F1)),
            const SizedBox(height: 7),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: theme.typography.bodyStrong?.color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: theme.typography.caption?.color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ConnectionBlob extends StatefulWidget {
  const _ConnectionBlob({
    required this.connected,
    required this.connecting,
    required this.onPressed,
  });

  final bool connected;
  final bool connecting;
  final VoidCallback onPressed;

  @override
  State<_ConnectionBlob> createState() => _ConnectionBlobState();
}

class _ConnectionBlobState extends State<_ConnectionBlob>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );

    if (widget.connected || widget.connecting) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant _ConnectionBlob oldWidget) {
    super.didUpdateWidget(oldWidget);

    final bool shouldAnimate = widget.connected || widget.connecting;

    if (shouldAnimate && !_controller.isAnimating) {
      _controller.repeat();
    } else if (!shouldAnimate && _controller.isAnimating) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Color primary = widget.connected
        ? const Color(0xFF10B981)
        : const Color(0xFF6366F1);

    final Color secondary = widget.connected
        ? const Color(0xFF34D399)
        : const Color(0xFFA78BFA);

    final IconData centerIcon = widget.connecting
        ? m.Symbols.progress_activity_rounded
        : widget.connected
            ? m.Symbols.verified_rounded
            : m.Symbols.shield_rounded;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final double pulse = widget.connected || widget.connecting
            ? 1 + (_controller.value * 0.035)
            : 1;

        return Transform.scale(
          scale: pulse,
          child: GestureDetector(
            onTap: widget.connecting ? null : widget.onPressed,
            child: Container(
              width: 190,
              height: 190,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: primary.withValues(alpha: 0.20),
                    blurRadius: 38,
                    spreadRadius: 8,
                  ),
                ],
              ),
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    center: const Alignment(0.35, -0.35),
                    radius: 1.1,
                    colors: [
                      secondary.withValues(alpha: 0.28),
                      primary.withValues(alpha: 0.12),
                      const Color(0x00000000),
                    ],
                    stops: const [0.0, 0.55, 1.0],
                  ),
                ),
                child: Center(
                  child: Container(
                    width: 132,
                    height: 132,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [primary, secondary],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: primary.withValues(alpha: 0.45),
                          blurRadius: 28,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Center(
                      child: widget.connecting
                          ? const SizedBox(
                              width: 40,
                              height: 40,
                              child: ProgressRing(),
                            )
                          : Icon(
                              centerIcon,
                              size: 56,
                              color: const Color(0xFFFFFFFF),
                            ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
