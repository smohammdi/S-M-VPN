import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter_v2ray_client/flutter_v2ray.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/services.dart';
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
                          _buildHeader(context, connected: connected),
                          const SizedBox(height: 26),
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

  Widget _buildHeader(BuildContext context, {required bool connected}) {
    final theme = FluentTheme.of(context);
    final brightness = theme.brightness;

    final Color secondaryText = brightness == Brightness.dark
        ? const Color(0xFF94A3B8)
        : const Color(0xFF64748B);

    final Color statusDot = _isBusy
        ? const Color(0xFF6366F1)
        : connected
            ? const Color(0xFF10B981)
            : const Color(0xFFF59E0B);
    final String statusLabel =
        _isBusy ? 'Connecting' : connected ? 'Connected' : 'Not connected';

    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF6366F1), Color(0xFFA78BFA)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF6366F1).withValues(alpha: 0.35),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: const Icon(
            m.Symbols.shield_rounded,
            color: Color(0xFFFFFFFF),
            size: 24,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'S-M VPN',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: theme.typography.title?.color,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Fast and secure connection',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: secondaryText,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: statusDot.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: statusDot.withValues(alpha: 0.30),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: statusDot,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                statusLabel,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: statusDot,
                ),
              ),
            ],
          ),
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
    final direction = Directionality.of(context);

    final String stateText;
    if (_isBusy) {
      stateText = 'Connecting...';
    } else if (connected) {
      stateText = 'Connected';
    } else if (status?.state.toUpperCase() == 'CONNECTING') {
      stateText = 'Connecting...';
    } else {
      stateText = 'Not connected';
    }

    final String helperText;
    if (_isBusy) {
      helperText = 'Please wait while we secure your connection.';
    } else if (connected) {
      helperText = 'Your connection is encrypted and private.';
    } else {
      helperText = 'Tap the button below to connect securely.';
    }

    final Color stateColor;
    if (_isBusy) {
      stateColor = const Color(0xFF6366F1);
    } else if (connected) {
      stateColor = const Color(0xFF10B981);
    } else {
      stateColor = const Color(0xFF64748B);
    }

    return Directionality(
      textDirection: direction,
      child: Column(
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 280),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeOutCubic,
            transitionBuilder: (child, animation) {
              return FadeTransition(
                opacity: animation,
                child: ScaleTransition(scale: animation, child: child),
              );
            },
            child: Text(
              stateText,
              key: ValueKey<String>(stateText),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: stateColor,
                letterSpacing: -0.3,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            helperText,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: theme.typography.body?.color,
            ),
          ),
          const SizedBox(height: 22),
          _ConnectionBlob(
            connected: connected,
            connecting: _isBusy,
            onPressed: _handleConnectionToggle,
          ),
          const SizedBox(height: 14),
          Text(
            connected
                ? 'Tap again to disconnect'
                : 'One tap is all you need',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: theme.typography.caption?.color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServerCard(BuildContext context, V2RayConfig config) {
    final theme = FluentTheme.of(context);
    final brightness = theme.brightness;

    final Color secondaryText = brightness == Brightness.dark
        ? const Color(0xFF94A3B8)
        : const Color(0xFF64748B);

    return _GlassCard(
      child: Directionality(
        textDirection: Directionality.of(context),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF6366F1), Color(0xFFA78BFA)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF6366F1).withValues(alpha: 0.30),
                    blurRadius: 14,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: const Icon(
                m.Symbols.dns_rounded,
                color: Color(0xFFFFFFFF),
                size: 26,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Active server',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: secondaryText,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    config.remark.isEmpty ? 'VPN Server' : config.remark,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: theme.typography.bodyStrong?.color,
                    ),
                  ),
                  const SizedBox(height: 4),
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
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withValues(alpha: 0.12),
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
      ),
    );
  }

  Widget _buildNoServerCard(BuildContext context) {
    final theme = FluentTheme.of(context);
    final direction = Directionality.of(context);

    return _GlassCard(
      child: Directionality(
        textDirection: direction,
        child: Column(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: const Color(0xFF6366F1).withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                m.Symbols.cloud_off_rounded,
                color: Color(0xFF6366F1),
                size: 28,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'No server selected',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: theme.typography.bodyStrong?.color,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              'Add a server or subscription first, then connect in one tap.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: theme.typography.body?.color,
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              height: 44,
              child: FilledButton(
                onPressed: _handleConnectionToggle,
                style: ButtonStyle(
                  backgroundColor: WidgetStateProperty.all(
                    const Color(0xFF6366F1),
                  ),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(m.Symbols.dns_rounded, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Choose Server',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  Widget _buildStatsSection(
    BuildContext context, {
    required V2RayStatus? status,
    required bool connected,
  }) {
    final V2RayStatus current = status ?? V2RayStatus();

    return Directionality(
      textDirection: Directionality.of(context),
      child: Row(
        children: [
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
              icon: m.Symbols.arrow_upward_rounded,
              label: 'Upload',
              value: connected ? _formatSpeed(current.uploadSpeed) : '--',
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
      ),
    );
  }

  Widget _buildConnectionButton(
    BuildContext context, {
    required bool connected,
  }) {
    final String label;
    final IconData icon;
    final Color background;
    if (_isBusy) {
      label = 'Please wait...';
      icon = m.Symbols.progress_activity_rounded;
      background = const Color(0xFF94A3B8);
    } else if (connected) {
      label = 'Disconnect';
      icon = m.Symbols.power_settings_new_rounded;
      background = const Color(0xFFEF4444);
    } else {
      label = 'Connect';
      icon = m.Symbols.bolt_rounded;
      background = const Color(0xFF6366F1);
    }

    return Semantics(
      button: true,
      label: label,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
        height: 56,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: background.withValues(alpha: 0.35),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: SizedBox(
          height: 56,
          child: FilledButton(
            onPressed: _isBusy ? null : _handleConnectionToggle,
            style: ButtonStyle(
              padding: WidgetStateProperty.all(
                const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              ),
              backgroundColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.disabled)) {
                  return const Color(0xFF94A3B8);
                }
                return background;
              }),
              shape: WidgetStateProperty.all(
                RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
            ),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeOutCubic,
              transitionBuilder: (child, animation) {
                return FadeTransition(
                  opacity: animation,
                  child: ScaleTransition(scale: animation, child: child),
                );
              },
              child: Row(
                key: ValueKey<String>(label),
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 22),
                  const SizedBox(width: 10),
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
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
    with TickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final AnimationController _morphController;
  late final AnimationController _pressController;
  late final Animation<double> _pressScale;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat();
    _morphController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 5200),
    )..repeat();
    _pressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 160),
      lowerBound: 0.0,
      upperBound: 0.06,
    );
    _pressScale = Tween<double>(begin: 1.0, end: 0.94).animate(
      CurvedAnimation(parent: _pressController, curve: Curves.easeOutCubic),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _morphController.dispose();
    _pressController.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    if (!widget.connecting) {
      _pressController.forward();
      HapticFeedback.lightImpact().ignore();
    }
  }

  void _handleTapUp() {
    if (_pressController.value > 0) {
      _pressController.reverse();
    }
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
            : m.Symbols.power_settings_new_rounded;

    final String semanticsLabel = widget.connecting
        ? 'Connecting'
        : widget.connected
            ? 'Connected. Tap to disconnect'
            : 'Not connected. Tap to connect';

    final double pulseStrength =
        widget.connecting ? 0.05 : widget.connected ? 0.03 : 0.075;

    return Semantics(
      button: true,
      enabled: !widget.connecting,
      label: semanticsLabel,
      child: GestureDetector(
        onTap: widget.connecting ? null : widget.onPressed,
        onTapDown: _handleTapDown,
        onTapUp: (_) => _handleTapUp(),
        onTapCancel: _handleTapUp,
        behavior: HitTestBehavior.opaque,
        child: ScaleTransition(
          scale: _pressScale,
          child: SizedBox(
            width: 208,
            height: 208,
            child: AnimatedBuilder(
              animation:
                  Listenable.merge([_pulseController, _morphController]),
              builder: (context, child) {
                final double pulse =
                    1.0 + (_pulseController.value * pulseStrength);
                final double morph = _morphController.value * 6.283185307;
                return Transform.scale(
                  scale: pulse,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: 208,
                        height: 208,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: primary.withValues(
                                alpha: widget.connected ? 0.16 : 0.30,
                              ),
                              blurRadius: widget.connected ? 34 : 48,
                              spreadRadius: widget.connected ? 6 : 12,
                            ),
                          ],
                        ),
                      ),
                      _PulseRing(
                        progress: _pulseController.value,
                        color: primary,
                        maxAlpha: widget.connected ? 0.16 : 0.30,
                      ),
                      _PulseRing(
                        progress: (_pulseController.value + 0.5) % 1.0,
                        color: primary,
                        maxAlpha: widget.connected ? 0.10 : 0.20,
                      ),
                      CustomPaint(
                        size: const Size(196, 196),
                        painter: _BlobHaloPainter(
                          progress: morph,
                          color: secondary.withValues(alpha: 0.35),
                        ),
                      ),
                      _WavyBlob(
                        progress: morph,
                        size: 168,
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [primary, secondary],
                        ),
                        glowColor: primary.withValues(alpha: 0.45),
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          switchInCurve: Curves.easeOutCubic,
                          switchOutCurve: Curves.easeOutCubic,
                          transitionBuilder: (child, animation) {
                            return FadeTransition(
                              opacity: animation,
                              child: ScaleTransition(
                                scale: animation,
                                child: child,
                              ),
                            );
                          },
                          child: widget.connecting
                              ? const SizedBox(
                                  key: ValueKey<String>('connecting'),
                                  width: 44,
                                  height: 44,
                                  child: ProgressRing(),
                                )
                              : Icon(
                                  centerIcon,
                                  key: ValueKey<IconData>(centerIcon),
                                  size: 64,
                                  color: const Color(0xFFFFFFFF),
                                ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

/// Expanding soft ring for the idle pulse around the blob.
class _PulseRing extends StatelessWidget {
  const _PulseRing({
    required this.progress,
    required this.color,
    required this.maxAlpha,
  });

  final double progress;
  final Color color;
  final double maxAlpha;

  @override
  Widget build(BuildContext context) {
    final double size = 168 + (progress * 44);
    final double alpha = maxAlpha * (1.0 - progress);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: color.withValues(alpha: alpha),
          width: 2.5,
        ),
      ),
    );
  }
}

class _WavyBlob extends StatelessWidget {
  const _WavyBlob({
    required this.progress,
    required this.size,
    required this.gradient,
    required this.glowColor,
    required this.child,
  });

  final double progress;
  final double size;
  final Gradient gradient;
  final Color glowColor;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: glowColor,
            blurRadius: 30,
            spreadRadius: 2,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipPath(
        clipper: _BlobClipper(progress: progress),
        child: Container(
          decoration: BoxDecoration(gradient: gradient),
          child: Center(child: child),
        ),
      ),
    );
  }
}

class _BlobClipper extends CustomClipper<Path> {
  _BlobClipper({required this.progress});

  final double progress;

  @override
  Path getClip(Size size) {
    final Path path = Path();
    const int steps = 120;
    final double cx = size.width / 2;
    final double cy = size.height / 2;
    final double base = size.width / 2;
    for (int i = 0; i <= steps; i++) {
      final double angle = (i / steps) * math.pi * 2;
      final double wave = 1 +
          0.055 * math.sin(angle * 3 + progress) +
          0.035 * math.sin(angle * 5 - progress * 1.4);
      final double r = base * wave;
      final double x = cx + r * math.cos(angle);
      final double y = cy + r * math.sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant _BlobClipper oldClipper) => true;
}

class _BlobHaloPainter extends CustomPainter {
  _BlobHaloPainter({required this.progress, required this.color});

  final double progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;
    final Path path = Path();
    const int steps = 120;
    final double cx = size.width / 2;
    final double cy = size.height / 2;
    final double base = size.width / 2 - 4;
    for (int i = 0; i <= steps; i++) {
      final double angle = (i / steps) * math.pi * 2;
      final double wave = 1 + 0.07 * math.sin(angle * 3 - progress * 0.8);
      final double r = base * wave;
      final double x = cx + r * math.cos(angle);
      final double y = cy + r * math.sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _BlobHaloPainter oldDelegate) => true;
}

