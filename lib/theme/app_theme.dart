import 'package:fluent_ui/fluent_ui.dart';

class AppTheme {
  // ---- Brand palette (light green) ----
  static const Color primary = Color(0xFF34D399); // emerald
  static const Color secondary = Color(0xFF6EE7B7); // mint
  static const Color accent = Color(0xFFA7F3D0); // light green

  // ---- Dark mode ----
  static const Color darkBackground = Color(0xFF0F172A); // blue-black
  static const Color darkSurface = Color(0xFF1E293B);
  static const Color textPrimary = Color(0xFFF1F5F9);
  static const Color textSecondary = Color(0xFF94A3B8);

  // ---- Light mode ----
  static const Color lightBackground = Color(0xFFF8FAFC);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightTextPrimary = Color(0xFF0F172A);
  static const Color lightTextSecondary = Color(0xFF475569);

  /// Emerald accent swatch for the FluentUI theme (buttons, toggles, sliders).
  static final AccentColor emerald = AccentColor.swatch(const <String, Color>{
    'darkest': Color(0xFF059669),
    'darker': Color(0xFF0FA373),
    'dark': Color(0xFF10B981),
    'normal': Color(0xFF34D399),
    'light': Color(0xFF6EE7B7),
    'lighter': Color(0xFF86EFAC),
    'lightest': Color(0xFFA7F3D0),
  });

  // ---- Legacy aliases used across the app ----
  static const Color glassBackground = Color(0x30FFFFFF);
  static const Color glassBorder = Color(0x50FFFFFF);
  static const Color primaryGradientStart = Color(0xFF34D399);
  static const Color primaryGradientEnd = Color(0xFF6EE7B7);
  static const Color connectedGreen = Color(0xFF34D399);
  static const Color disconnectedRed = Color(0xFFE53935);
  static const Color warningOrange = Color(0xFFFF9800);

  static FluentThemeData darkTheme() {
    return FluentThemeData(
      brightness: Brightness.dark,
      accentColor: emerald,
      scaffoldBackgroundColor: darkBackground,
      navigationPaneTheme: const NavigationPaneThemeData(
        backgroundColor: darkSurface,
      ),
    );
  }

  static FluentThemeData lightTheme() {
    return FluentThemeData(
      brightness: Brightness.light,
      accentColor: emerald,
      scaffoldBackgroundColor: lightBackground,
      navigationPaneTheme: const NavigationPaneThemeData(
        backgroundColor: lightSurface,
      ),
    );
  }

  static BoxDecoration glassDecoration({
    double borderRadius = 16,
    double opacity = 0.1,
  }) {
    return BoxDecoration(
      borderRadius: BorderRadius.circular(borderRadius),
      color: Colors.white.withOpacity(opacity),
      border: Border.all(
        color: Colors.white.withOpacity(0.2),
        width: 1.5,
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.3),
          blurRadius: 20,
          spreadRadius: 5,
        ),
      ],
    );
  }

  static BoxDecoration glassDecorationLight({
    double borderRadius = 16,
    double opacity = 0.06,
  }) {
    return BoxDecoration(
      borderRadius: BorderRadius.circular(borderRadius),
      color: Colors.black.withOpacity(opacity),
      border: Border.all(
        color: Colors.black.withOpacity(0.08),
        width: 1.5,
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.08),
          blurRadius: 16,
          spreadRadius: 2,
        ),
      ],
    );
  }

  static BoxDecoration gradientButtonDecoration({
    double borderRadius = 12,
    bool isActive = false,
  }) {
    return BoxDecoration(
      borderRadius: BorderRadius.circular(borderRadius),
      gradient: LinearGradient(
        colors: isActive
            ? [connectedGreen, connectedGreen.withOpacity(0.7)]
            : [primaryGradientStart, primaryGradientEnd],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      boxShadow: [
        BoxShadow(
          color: (isActive ? connectedGreen : primaryGradientStart).withOpacity(0.4),
          blurRadius: 15,
          spreadRadius: 2,
        ),
      ],
    );
  }

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
