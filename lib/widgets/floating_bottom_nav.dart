import 'dart:ui';

import 'package:fluent_ui/fluent_ui.dart';
import 'package:material_symbols_icons/symbols.dart' as m;
import 'package:sm_vpn/theme/app_theme.dart';

/// A single destination of the [FloatingBottomNav].
class FloatingNavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;

  const FloatingNavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}

/// Floating neo-glass bottom navigation bar, improved for beginners.
///
/// Glass container floats 16px from left/right/bottom edges, 76px tall
/// with 24px radius. Active item is a #6366F1 pill with white icon and
/// label below; inactive items are outline grey icons with grey labels.
/// Layout is direction-aware so it works in both LTR and RTL locales.
class FloatingBottomNav extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final List<FloatingNavItem> items;

  const FloatingBottomNav({
    super.key,
    required this.selectedIndex,
    required this.onSelected,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);
    final bool isLight = theme.brightness == Brightness.light;

    final Color glassBackground = isLight
        ? const Color(0xFFFFFFFF).withValues(alpha: 0.80)
        : const Color(0xFF0B1220).withValues(alpha: 0.80);
    final Color glassBorder = isLight
        ? const Color(0xFFFFFFFF).withValues(alpha: 0.65)
        : const Color(0xFFFFFFFF).withValues(alpha: 0.10);
    final Color inactiveColor = isLight
        ? AppTheme.lightTextSecondary
        : AppTheme.textSecondary;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      height: 76,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              color: glassBackground,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: glassBorder, width: 1),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF000000).withValues(alpha: 0.10),
                  blurRadius: 20,
                  spreadRadius: 0,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              children: List.generate(items.length, (index) {
                final FloatingNavItem item = items[index];
                final bool selected = index == selectedIndex;
                return Expanded(
                  child: _FloatingNavButton(
                    icon: selected ? item.activeIcon : item.icon,
                    label: item.label,
                    selected: selected,
                    inactiveColor: inactiveColor,
                    onTap: () => onSelected(index),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}

/// Single tappable destination with animated pill and scale pop.
///
/// Minimum 48px touch target and semantic label keep the bar
/// beginner-friendly. Text uses Directionality so Persian labels
/// render correctly when the app switches to RTL.
class _FloatingNavButton extends StatefulWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final Color inactiveColor;
  final VoidCallback onTap;

  const _FloatingNavButton({
    required this.icon,
    required this.label,
    required this.selected,
    required this.inactiveColor,
    required this.onTap,
  });

  @override
  State<_FloatingNavButton> createState() => _FloatingNavButtonState();
}

class _FloatingNavButtonState extends State<_FloatingNavButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _scaleController;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.06).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeInOutCubic),
    );
    if (widget.selected) {
      _scaleController.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(covariant _FloatingNavButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selected && !oldWidget.selected) {
      _scaleController.forward();
    } else if (!widget.selected && oldWidget.selected) {
      _scaleController.reverse();
    }
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Color foreground =
        widget.selected ? Colors.white : widget.inactiveColor;
    final TextDirection direction = Directionality.of(context);
    return Semantics(
      button: true,
      selected: widget.selected,
      label: widget.label,
      child: GestureDetector(
        onTap: widget.onTap,
        behavior: HitTestBehavior.opaque,
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeInOutCubic,
            constraints: const BoxConstraints(minHeight: 56, minWidth: 56),
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: widget.selected
                  ? AppTheme.primary
                  : const Color(0x00000000),
              borderRadius: BorderRadius.circular(100),
              boxShadow: widget.selected
                  ? [
                      BoxShadow(
                        color: AppTheme.primary.withValues(alpha: 0.35),
                        blurRadius: 12,
                        spreadRadius: 0,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : null,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 280),
                  switchInCurve: Curves.easeInOutCubic,
                  switchOutCurve: Curves.easeInOutCubic,
                  transitionBuilder: (child, animation) {
                    return ScaleTransition(scale: animation, child: child);
                  },
                  child: Icon(
                    widget.icon,
                    key: ValueKey<IconData>(widget.icon),
                    size: 26,
                    color: foreground,
                  ),
                ),
                const SizedBox(height: 3),
                Flexible(
                  child: Directionality(
                    textDirection: direction,
                    child: Text(
                      widget.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: foreground,
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

/// Default destinations with material-symbols icons.
///
/// Labels stay English for now; the bar itself is RTL-ready so Persian
/// labels can replace these strings later without layout changes.
List<FloatingNavItem> defaultFloatingNavItems() {
  return const [
    FloatingNavItem(
      icon: m.Symbols.home_rounded,
      activeIcon: m.Symbols.home_filled_rounded,
      label: 'Home',
    ),
    FloatingNavItem(
      icon: m.Symbols.dns_rounded,
      activeIcon: m.Symbols.dns_rounded,
      label: 'Servers',
    ),
    FloatingNavItem(
      icon: m.Symbols.subscriptions_rounded,
      activeIcon: m.Symbols.subscriptions_rounded,
      label: 'Subscriptions',
    ),
    FloatingNavItem(
      icon: m.Symbols.settings_rounded,
      activeIcon: m.Symbols.settings_rounded,
      label: 'Settings',
    ),
  ];
}


