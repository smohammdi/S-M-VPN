import 'package:fluent_ui/fluent_ui.dart';
import 'package:material_symbols_icons/symbols.dart' as m;
import 'package:provider/provider.dart';
import 'package:sm_vpn/services/v2ray_service.dart';
import 'package:sm_vpn/theme/app_theme.dart';
import 'package:sm_vpn/l10n/app_strings.dart';
import 'package:sm_vpn/screens/home_screen.dart';
import 'package:sm_vpn/screens/servers_screen.dart';
import 'package:sm_vpn/screens/settings_screen.dart';
import 'package:sm_vpn/screens/onboarding_screen.dart';
import 'package:sm_vpn/widgets/floating_bottom_nav.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final paletteIndex = await ThemeProvider.loadIndex();
  final languageCode = await LanguageProvider.loadCode();
  runApp(MyApp(
    initialPaletteIndex: paletteIndex,
    initialLanguageCode: languageCode,
  ));
}

class MyApp extends StatelessWidget {
  const MyApp({
    super.key,
    required this.initialPaletteIndex,
    required this.initialLanguageCode,
  });

  final int initialPaletteIndex;
  final String initialLanguageCode;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => V2RayService()),
        ChangeNotifierProvider(
          create: (_) => ThemeProvider(initialIndex: initialPaletteIndex),
        ),
        ChangeNotifierProvider(
          create: (_) => LanguageProvider(initialCode: initialLanguageCode),
        ),
      ],
      child: Builder(
        builder: (context) {
          context.watch<ThemeProvider>();
          final language = context.watch<LanguageProvider>();
          return FluentApp(
            title: 'S-M VPN',
            themeMode: ThemeMode.light,
            theme: AppTheme.lightTheme(),
            darkTheme: AppTheme.darkTheme(),
            locale: language.locale,
            supportedLocales: const [Locale('en'), Locale('fa')],
            home: const MainNavigation(),
            debugShowCheckedModeBanner: false,
          );
        },
      ),
    );
  }
}

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _selectedIndex = 0;
  bool? _showOnboarding;

  final List<Widget> _screens = const [
    HomeScreen(),
    ServersScreen(),
    SettingsScreen(),
  ];

  List<FloatingNavItem> _navItems(BuildContext context) {
    return [
      FloatingNavItem(
        icon: m.Symbols.home_rounded,
        activeIcon: m.Symbols.home_filled_rounded,
        label: S.of(context, 'nav_home'),
      ),
      FloatingNavItem(
        icon: m.Symbols.dns_rounded,
        activeIcon: m.Symbols.dns_rounded,
        label: S.of(context, 'nav_servers'),
      ),
      FloatingNavItem(
        icon: m.Symbols.settings_rounded,
        activeIcon: m.Symbols.settings_rounded,
        label: S.of(context, 'nav_settings'),
      ),
    ];
  }

  @override
  void initState() {
    super.initState();
    _initializeApp();
    _checkOnboarding();
  }

  Future<void> _initializeApp() async {
    final service = Provider.of<V2RayService>(context, listen: false);
    await service.initialize();
  }

  Future<void> _checkOnboarding() async {
    final seen = await isOnboardingSeen();
    if (!mounted) return;
    setState(() {
      _showOnboarding = !seen;
    });
  }

  Future<void> _finishOnboarding() async {
    await setOnboardingSeen();
    if (!mounted) return;
    setState(() {
      _showOnboarding = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_showOnboarding == null) {
      return const SizedBox.shrink();
    }
    if (_showOnboarding!) {
      return OnboardingScreen(onFinished: _finishOnboarding);
    }
    return NavigationView(
      appBar: NavigationAppBar(
        automaticallyImplyLeading: false,
        title: const Row(
          children: [
            Text(
              'S-M',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
      content: Stack(
        children: [
          _TabTransitionStack(
            index: _selectedIndex,
            children: _screens,
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SafeArea(
              top: false,
              child: FloatingBottomNav(
                selectedIndex: _selectedIndex,
                onSelected: (index) {
                  setState(() {
                    _selectedIndex = index;
                  });
                },
                items: _navItems(context),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Animated replacement for [IndexedStack] used by the bottom navigation:
/// all tabs stay mounted (state is preserved exactly like IndexedStack),
/// while the newly selected tab fades + slides in over 300ms.
/// The slide direction follows the tab order and mirrors automatically
/// in RTL locales.
class _TabTransitionStack extends StatefulWidget {
  const _TabTransitionStack({
    required this.index,
    required this.children,
  });

  final int index;
  final List<Widget> children;

  @override
  State<_TabTransitionStack> createState() => _TabTransitionStackState();
}

class _TabTransitionStackState extends State<_TabTransitionStack>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  final Tween<Offset> _slideTween =
      Tween<Offset>(begin: Offset.zero, end: Offset.zero);
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    )..value = 1.0;
    final curved = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOutCubic,
    );
    _fade = curved;
    _slide = _slideTween.animate(curved);
  }

  @override
  void didUpdateWidget(covariant _TabTransitionStack oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.index != oldWidget.index) {
      final bool forward = widget.index > oldWidget.index;
      final bool rtl =
          Directionality.of(context) == TextDirection.rtl;
      final double dx = (forward ? 0.06 : -0.06) * (rtl ? -1.0 : 1.0);
      _slideTween.begin = Offset(dx, 0);
      _controller.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        for (int i = 0; i < widget.children.length; i++)
          Offstage(
            offstage: i != widget.index,
            child: i == widget.index
                ? FadeTransition(
                    opacity: _fade,
                    child: SlideTransition(
                      position: _slide,
                      child: widget.children[i],
                    ),
                  )
                : widget.children[i],
          ),
      ],
    );
  }
}
