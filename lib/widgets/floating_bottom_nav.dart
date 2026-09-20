import 'package:fluent_ui/fluent_ui.dart';
import 'package:sm_vpn/theme/app_theme.dart';

/// A single destination of the [FloatingBottomNav].
class FloatingNavItem {
  final IconData icon;
  final String label;

  const FloatingNavItem({required this.icon, required this.label});
}

/// Floating, pill-shaped bottom navigation bar (neo-glass style).
///
/// Active item is a rounded purple capsule with white label; inactive items
/// render icon + label in the secondary text color.
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
    final isLight = theme.brightness == Brightness.light;
    final surface = isLight ? Colors.white : AppTheme.darkSurface;
    final muted = isLight ? AppTheme.lightTextSecondary : AppTheme.textSecondary;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: surface.withOpacity(0.95),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: isLight ? AppTheme.lightBorder : AppTheme.darkBorder,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: List.generate(items.length, (index) {
          final item = items[index];
          final selected = index == selectedIndex;
          return Expanded(
            child: GestureDetector(
              onTap: () => onSelected(index),
              behavior: HitTestBehavior.opaque,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOut,
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: selected ? AppTheme.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      item.icon,
                      size: 20,
                      color: selected ? Colors.white : muted,
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        item.label,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight:
                              selected ? FontWeight.w600 : FontWeight.w500,
                          color: selected ? Colors.white : muted,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
