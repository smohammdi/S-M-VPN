import 'package:fluent_ui/fluent_ui.dart';
import 'package:provider/provider.dart';
import 'package:sm_vpn/services/v2ray_service.dart';
import 'package:sm_vpn/theme/app_theme.dart';
import 'package:sm_vpn/screens/home_screen.dart';
import 'package:sm_vpn/screens/servers_screen.dart';
import 'package:sm_vpn/screens/subscriptions_screen.dart';
import 'package:sm_vpn/screens/settings_screen.dart';

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
        themeMode: ThemeMode.dark,
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

  final List<NavigationPaneItem> _items = [
    PaneItem(
      icon: const Icon(FluentIcons.home),
      title: const Text('Home'),
      body: const HomeScreen(),
    ),
    PaneItem(
      icon: const Icon(FluentIcons.server),
      title: const Text('Servers'),
      body: const ServersScreen(),
    ),
    PaneItem(
      icon: const Icon(FluentIcons.cloud),
      title: const Text('Subscriptions'),
      body: const SubscriptionsScreen(),
    ),
  ];

  final List<NavigationPaneItem> _footerItems = [
    PaneItem(
      icon: const Icon(FluentIcons.settings),
      title: const Text('Settings'),
      body: const SettingsScreen(),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    final service = Provider.of<V2RayService>(context, listen: false);
    await service.initialize();
  }

  @override
  Widget build(BuildContext context) {
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
                  colors: [AppTheme.primaryGradientStart, AppTheme.primaryGradientEnd],
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
      pane: NavigationPane(
        selected: _selectedIndex,
        onChanged: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        displayMode: PaneDisplayMode.compact,
        items: _items,
        footerItems: _footerItems,
      ),
    );
  }
}
