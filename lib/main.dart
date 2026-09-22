import 'package:fluent_ui/fluent_ui.dart';
import 'package:material_symbols_icons/symbols.dart' as m;
import 'package:provider/provider.dart';
import 'package:sm_vpn/services/v2ray_service.dart';
import 'package:sm_vpn/theme/app_theme.dart';
import 'package:sm_vpn/l10n/app_strings.dart';
import 'package:sm_vpn/screens/home_screen.dart';
import 'package:sm_vpn/screens/servers_screen.dart';
import 'package:sm_vpn/screens/subscriptions_screen.dart';
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
    SubscriptionsScreen(),
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
        icon: m.Symbols.subscriptions_rounded,
        activeIcon: m.Symbols.subscriptions_rounded,
        label: S.of(context, 'nav_subscriptions'),
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
        title: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppTheme.primary, AppTheme.primaryLight],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Center(
                child: Icon(FluentIcons.shield_solid, color: Colors.white, size: 18),
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'S-M',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
      content: Stack(
        children: [
          IndexedStack(
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
