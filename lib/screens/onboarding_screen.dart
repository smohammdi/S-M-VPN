import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/services.dart';
import 'package:material_symbols_icons/symbols.dart' as m;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sm_vpn/theme/app_theme.dart';

/// Storage key marking onboarding as seen. Same SharedPreferences pattern
/// the app already uses for its settings.
const String onboardingSeenKey = 'onboarding_seen';

/// Beginner-friendly 5-slide onboarding: welcome, adding servers,
/// one-tap connect, managing lists, and settings.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key, required this.onFinished});

  final VoidCallback onFinished;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingSlide {
  const _OnboardingSlide({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  static const List<_OnboardingSlide> _slides = [
    _OnboardingSlide(
      icon: m.Symbols.waving_hand_rounded,
      title: 'Welcome to S-M VPN',
      subtitle: 'Fast, private and secure internet in one tap.',
    ),
    _OnboardingSlide(
      icon: m.Symbols.qr_code_scanner_rounded,
      title: 'Add your first server',
      subtitle: 'Paste a config link, scan a QR code, or import a subscription list.',
    ),
    _OnboardingSlide(
      icon: m.Symbols.touch_app_rounded,
      title: 'One tap to connect',
      subtitle: 'Tap the big button. Purple means off, green means you are protected.',
    ),
    _OnboardingSlide(
      icon: m.Symbols.dns_rounded,
      title: 'Manage servers with ease',
      subtitle: 'Find all your servers and subscriptions in one clean list.',
    ),
    _OnboardingSlide(
      icon: m.Symbols.settings_rounded,
      title: 'Make it yours',
      subtitle: 'Auto-connect on start, dark mode and more live in Settings.',
    ),
  ];

  final PageController _pageController = PageController();
  int _index = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _goNext() {
    HapticFeedback.lightImpact().ignore();
    if (_index < _slides.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOutCubic,
      );
    } else {
      widget.onFinished();
    }
  }

  void _skip() {
    HapticFeedback.lightImpact().ignore();
    widget.onFinished();
  }

  Color _secondaryText(BuildContext context) {
    return FluentTheme.of(context).brightness == Brightness.dark
        ? const Color(0xFF94A3B8)
        : const Color(0xFF64748B);
  }

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);
    final bool isLast = _index == _slides.length - 1;

    return Container(
      color: theme.scaffoldBackgroundColor,
      child: SafeArea(
        child: Directionality(
          textDirection: Directionality.of(context),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Row(
                        children: List.generate(_slides.length, (i) {
                          final bool active = i <= _index;
                          return Expanded(
                            child: Container(
                              margin: EdgeInsets.only(
                                right: i == _slides.length - 1 ? 0 : 6,
                              ),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOutCubic,
                                height: 6,
                                decoration: BoxDecoration(
                                  color: active
                                      ? AppTheme.primary
                                      : (theme.brightness == Brightness.dark
                                          ? const Color(0xFF334155)
                                          : const Color(0xFFE2E8F0)),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                              ),
                            ),
                          );
                        }),
                      ),
                    ),
                    const SizedBox(width: 12),
                    HyperlinkButton(
                      onPressed: _skip,
                      child: const Text('Skip'),
                    ),
                  ],
                ),
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: _slides.length,
                    onPageChanged: (i) => setState(() => _index = i),
                    itemBuilder: (context, i) {
                      final slide = _slides[i];
                      return Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 300),
                            switchInCurve: Curves.easeInOutCubic,
                            switchOutCurve: Curves.easeInOutCubic,
                            transitionBuilder: (child, animation) {
                              return FadeTransition(
                                opacity: animation,
                                child: ScaleTransition(
                                  scale: animation,
                                  child: child,
                                ),
                              );
                            },
                            child: Container(
                              key: ValueKey<int>(i),
                              width: 120,
                              height: 120,
                              decoration: BoxDecoration(
                                color: const Color(0xFF6366F1)
                                    .withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(36),
                              ),
                              child: Center(
                                child: Icon(
                                  slide.icon,
                                  size: 56,
                                  color: const Color(0xFF6366F1),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 28),
                          Text(
                            slide.title,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                              color: theme.typography.bodyStrong?.color,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            slide.subtitle,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 15,
                              color: _secondaryText(context),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: FilledButton(
                    onPressed: _goNext,
                    style: ButtonStyle(
                      backgroundColor: WidgetStateProperty.all(
                        const Color(0xFF6366F1),
                      ),
                      shape: WidgetStateProperty.all(
                        RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                    child: Text(
                      isLast ? 'Get Started' : 'Next',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Reads the onboarding-seen flag using the same SharedPreferences
/// approach as the app settings. Returns true when onboarding was seen.
Future<bool> isOnboardingSeen() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getBool(onboardingSeenKey) ?? false;
}

/// Persists the onboarding-seen flag.
Future<void> setOnboardingSeen() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool(onboardingSeenKey, true);
}
