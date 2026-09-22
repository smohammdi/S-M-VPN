import 'package:fluent_ui/fluent_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A selectable brand palette: primary seed plus derived tones.
/// The 3 preview dots of a palette are [primary, secondary, dark].
class AppPalette {
  const AppPalette({
    required this.id,
    required this.nameEn,
    required this.nameFa,
    required this.primary,
    required this.light,
    required this.dark,
    required this.secondary,
    required this.accent,
  });

  final String id;
  final String nameEn;
  final String nameFa;
  final Color primary;
  final Color light;
  final Color dark;
  final Color secondary;
  final Color accent;

  String name(String langCode) => langCode == 'fa' ? nameFa : nameEn;

  List<Color> get dots => [primary, secondary, dark];

  /// FluentUI accent swatch derived from the primary seed.
  AccentColor get swatch => AccentColor.swatch(<String, Color>{
        'darkest': _mix(primary, const Color(0xFF000000), 0.45),
        'darker': _mix(primary, const Color(0xFF000000), 0.30),
        'dark': _mix(primary, const Color(0xFF000000), 0.12),
        'normal': primary,
        'light': _mix(primary, const Color(0xFFFFFFFF), 0.25),
        'lighter': _mix(primary, const Color(0xFFFFFFFF), 0.45),
        'lightest': _mix(primary, const Color(0xFFFFFFFF), 0.65),
      });

  static Color _mix(Color a, Color b, double t) => Color.lerp(a, b, t)!;
}

/// The 8 built-in palettes. Aurora (indigo #6366F1) is the default.
class AppPalettes {
  static const AppPalette aurora = AppPalette(
    id: 'aurora',
    nameEn: 'Aurora',
    nameFa: 'آرورا',
    primary: Color(0xFF6366F1),
    light: Color(0xFF818CF8),
    dark: Color(0xFF4F46E5),
    secondary: Color(0xFFA78BFA),
    accent: Color(0xFFC7D2FE),
  );
  static const AppPalette ember = AppPalette(
    id: 'ember',
    nameEn: 'Ember',
    nameFa: 'امبر',
    primary: Color(0xFFF97316),
    light: Color(0xFFFB923C),
    dark: Color(0xFFEA580C),
    secondary: Color(0xFFFDBA74),
    accent: Color(0xFFFED7AA),
  );
  static const AppPalette midnight = AppPalette(
    id: 'midnight',
    nameEn: 'Midnight',
    nameFa: 'میدنایت',
    primary: Color(0xFF2563EB),
    light: Color(0xFF60A5FA),
    dark: Color(0xFF1D4ED8),
    secondary: Color(0xFF93C5FD),
    accent: Color(0xFFBFDBFE),
  );
  static const AppPalette sakura = AppPalette(
    id: 'sakura',
    nameEn: 'Sakura',
    nameFa: 'ساکورا',
    primary: Color(0xFFEC4899),
    light: Color(0xFFF472B6),
    dark: Color(0xFFDB2777),
    secondary: Color(0xFFF9A8D4),
    accent: Color(0xFFFBCFE8),
  );
  static const AppPalette citrus = AppPalette(
    id: 'citrus',
    nameEn: 'Citrus',
    nameFa: 'سیتروس',
    primary: Color(0xFFF59E0B),
    light: Color(0xFFFBBF24),
    dark: Color(0xFFD97706),
    secondary: Color(0xFFFDE68A),
    accent: Color(0xFFFEF3C7),
  );
  static const AppPalette mono = AppPalette(
    id: 'mono',
    nameEn: 'Mono',
    nameFa: 'مونو',
    primary: Color(0xFF64748B),
    light: Color(0xFF94A3B8),
    dark: Color(0xFF334155),
    secondary: Color(0xFFCBD5E1),
    accent: Color(0xFFE2E8F0),
  );
  static const AppPalette neonLime = AppPalette(
    id: 'neon_lime',
    nameEn: 'Neon Lime',
    nameFa: 'لایم نئونی',
    primary: Color(0xFF65A30D),
    light: Color(0xFF84CC16),
    dark: Color(0xFF3F6212),
    secondary: Color(0xFFA3E635),
    accent: Color(0xFFD9F99D),
  );
  static const AppPalette tokyo = AppPalette(
    id: 'tokyo',
    nameEn: 'Tokyo',
    nameFa: 'توکیو',
    primary: Color(0xFF06B6D4),
    light: Color(0xFF22D3EE),
    dark: Color(0xFF0E7490),
    secondary: Color(0xFF67E8F9),
    accent: Color(0xFFA5F3FC),
  );

  static const List<AppPalette> all = [
    aurora,
    ember,
    midnight,
    sakura,
    citrus,
    mono,
    neonLime,
    tokyo,
  ];

  static int indexOfId(String id) {
    final i = all.indexWhere((p) => p.id == id);
    return i < 0 ? 0 : i;
  }
}

class AppTheme {
  static AppPalette _palette = AppPalettes.aurora;

  /// Currently active palette. Updated by [ThemeProvider].
  static AppPalette get palette => _palette;
  static void setPalette(AppPalette palette) {
    _palette = palette;
  }

  // ---- Brand colors (follow the active palette) ----
  static Color get primary => _palette.primary;
  static Color get primaryLight => _palette.light;
  static Color get primaryDark => _palette.dark;
  static Color get secondary => _palette.secondary;
  static Color get accent => _palette.accent;

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

  /// Accent swatch for the FluentUI theme (buttons, toggles, sliders).
  /// Follows the active palette.
  static AccentColor get accentSwatch => _palette.swatch;

  // ---- Legacy aliases used across the app ----
  static Color get primaryGradientStart => primary;
  static Color get primaryGradientEnd => primaryLight;
  static const Color connectedGreen = Color(0xFF22C55E);
  static const Color disconnectedRed = Color(0xFFEF4444);
  static const Color warningOrange = Color(0xFFF59E0B);

  static FluentThemeData lightTheme() {
    return FluentThemeData(
      brightness: Brightness.light,
      accentColor: _palette.swatch,
      scaffoldBackgroundColor: lightBackground,
      navigationPaneTheme: const NavigationPaneThemeData(
        backgroundColor: lightSurface,
      ),
    );
  }

  static FluentThemeData darkTheme() {
    return FluentThemeData(
      brightness: Brightness.dark,
      accentColor: _palette.swatch,
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

/// Rounded shimmer placeholder used for skeleton loading states.
/// Theme-aware: light grey sweep in light mode, slate sweep in dark mode.
/// The animation repeats every 1300ms with an easeInOut curve.
class ShimmerBox extends StatefulWidget {
  const ShimmerBox({
    super.key,
    this.width,
    this.height,
    this.borderRadius = 12,
    this.circle = false,
  });

  final double? width;
  final double? height;
  final double borderRadius;
  final bool circle;

  @override
  State<ShimmerBox> createState() => _ShimmerBoxState();
}

class _ShimmerBoxState extends State<ShimmerBox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1300),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark =
        FluentTheme.of(context).brightness == Brightness.dark;
    final Color base =
        isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0);
    final Color highlight =
        isDark ? const Color(0xFF334155) : const Color(0xFFF8FAFC);

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final double v = _controller.value;
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            shape: widget.circle ? BoxShape.circle : BoxShape.rectangle,
            borderRadius: widget.circle
                ? null
                : BorderRadius.circular(widget.borderRadius),
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [base, highlight, base],
              stops: [
                (v - 0.35).clamp(0.0, 1.0),
                v.clamp(0.0, 1.0),
                (v + 0.35).clamp(0.0, 1.0),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Holds the active color palette, persists it with the same
/// SharedPreferences approach the app uses for settings, and rebuilds
/// the UI on change.
class ThemeProvider extends ChangeNotifier {
  ThemeProvider({int initialIndex = 0}) {
    _index = initialIndex.clamp(0, AppPalettes.all.length - 1);
    AppTheme.setPalette(AppPalettes.all[_index]);
  }

  int _index = 0;

  int get paletteIndex => _index;
  AppPalette get palette => AppPalettes.all[_index];

  Future<void> setPalette(int index) async {
    final safe = index.clamp(0, AppPalettes.all.length - 1);
    if (safe == _index) return;
    _index = safe;
    AppTheme.setPalette(AppPalettes.all[safe]);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('theme_palette', AppPalettes.all[safe].id);
    notifyListeners();
  }

  static Future<int> loadIndex() async {
    final prefs = await SharedPreferences.getInstance();
    return AppPalettes.indexOfId(prefs.getString('theme_palette') ?? 'aurora');
  }
}
