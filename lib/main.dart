import 'package:fluent_ui/fluent_ui.dart';
import 'package:provider/provider.dart';
import 'package:sm_vpn/services/v2ray_service.dart';
import 'package:sm_vpn/theme/app_theme.dart';
import 'package:sm_vpn/screens/home_screen.dart';
import 'package:sm_vpn/screens/servers_screen.dart';
import 'package:sm_vpn/screens/subscriptions_screen.dart';
import 'package:sm_vpn/screens/settings_screen.dart';
import 'package:sm_vpn/screens/onboarding_screen.dart';
import 'package:sm_vpn/widgets/floating_bottom_nav.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => V2RayService(),
      child: FluentApp(
        title: 'S-M VPN',
        themeMode: ThemeMode.light,
        theme: AppTheme.lightTheme(),
        darkTheme: AppTheme.darkTheme(),
        home: const MainNavigation(),
        debugShowCheckedModeBanner: false,
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

  final List<FloatingNavItem> _navItems = defaultFloatingNavItems();

  @override
  void initState() {
    super.initState();
    _initializeApp();
    _checkOnboarding();
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

  Future<void> _initializeApp() async {
    final service = Provider.of<V2RayService>(context, listen: false);
    await service.initialize();
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
                gradient: const LinearGradient(
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
                items: _navItems,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
