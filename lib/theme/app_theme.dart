import 'package:fluent_ui/fluent_ui.dart';

class AppTheme {
  // ---- Brand palette (indigo / light purple) ----
  static const Color primary = Color(0xFF6366F1); // indigo
  static const Color primaryLight = Color(0xFF818CF8);
  static const Color primaryDark = Color(0xFF4F46E5);
  static const Color secondary = Color(0xFFA78BFA); // light purple
  static const Color accent = Color(0xFFC7D2FE);

  // ---- Light mode ----
  static const Color lightBackground = Color(0xFFF8FAFC);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightTextPrimary = Color(0xFF0F172A);
  static const Color lightTextSecondary = Color(0xFF64748B);
  static const Color lightBorder = Color(0xFFE2E8F0);

  // ---- Dark mode ----
  static const Color darkBackground = Color(0xFF0F172A);
  static const Color darkSurface = Color(0xFF1E293B);
  static const Color textPrimary = Color(0xFFF1F5F9);
  static const Color textSecondary = Color(0xFF94A3B8);
  static const Color darkBorder = Color(0xFF334155);

  /// Indigo accent swatch for the FluentUI theme (buttons, toggles, sliders).
  static final AccentColor indigo = AccentColor.swatch(const <String, Color>{
    'darkest': Color(0xFF4338CA),
    'darker': Color(0xFF4F46E5),
    'dark': Color(0xFF6366F1),
    'normal': Color(0xFF6366F1),
    'light': Color(0xFF818CF8),
    'lighter': Color(0xFFA78BFA),
    'lightest': Color(0xFFC7D2FE),
  });

  // ---- Legacy aliases used across the app ----
  static const Color primaryGradientStart = primary;
  static const Color primaryGradientEnd = primaryLight;
  static const Color connectedGreen = Color(0xFF22C55E);
  static const Color disconnectedRed = Color(0xFFEF4444);
  static const Color warningOrange = Color(0xFFF59E0B);

  static FluentThemeData lightTheme() {
    return FluentThemeData(
      brightness: Brightness.light,
      accentColor: indigo,
      scaffoldBackgroundColor: lightBackground,
      navigationPaneTheme: const NavigationPaneThemeData(
        backgroundColor: lightSurface,
      ),
    );
  }

  static FluentThemeData darkTheme() {
    return FluentThemeData(
      brightness: Brightness.dark,
      accentColor: indigo,
      scaffoldBackgroundColor: darkBackground,
      navigationPaneTheme: const NavigationPaneThemeData(
        backgroundColor: darkSurface,
      ),
    );
  }

  /// Neo-glass card: rounded surface with a soft, diffuse shadow.
  /// [margin] and [padding] follow the neo-glass spec (16h/8v and 20).
  static BoxDecoration neoCardDecoration({
    double borderRadius = 24,
    Brightness brightness = Brightness.light,
    Color? color,
    double opacity = 1.0,
    double blurRadius = 20,
  }) {
    final isLight = brightness == Brightness.light;
    return BoxDecoration(
      borderRadius: BorderRadius.circular(borderRadius),
      color: color ??
          (isLight
              ? lightSurface.withValues(alpha: opacity)
              : darkSurface.withValues(alpha: opacity)),
      border: Border.all(
        color: isLight ? lightBorder : darkBorder,
        width: 1,
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.04),
          blurRadius: blurRadius,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }

  /// Standard neo-glass card margin.
  static const EdgeInsets cardMargin = EdgeInsets.symmetric(
    horizontal: 16,
    vertical: 8,
  );

  /// Standard neo-glass card padding.
  static const EdgeInsets cardPadding = EdgeInsets.all(20);

  /// Bottom padding used by scrollable screens so content is never
  /// hidden behind the floating navigation bar.
  static const double bottomNavHeight = 96.0;

  static Color getPingColor(int? ping) {
    if (ping == null || ping < 0) return Colors.grey;
    if (ping < 100) return connectedGreen;
    if (ping < 300) return warningOrange;
    return disconnectedRed;
  }

  static String formatSpeed(int bytesPerSecond) {
    if (bytesPerSecond < 1024) {
      return '$bytesPerSecond B/s';
    } else if (bytesPerSecond < 1024 * 1024) {
      return '${(bytesPerSecond / 1024).toStringAsFixed(1)} KB/s';
    } else {
      return '${(bytesPerSecond / (1024 * 1024)).toStringAsFixed(1)} MB/s';
    }
  }

  static String formatBytes(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    } else if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    } else {
      return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
    }
  }
}
