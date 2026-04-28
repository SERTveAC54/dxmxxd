import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/fixture_manager.dart';
import 'services/dmx_engine.dart';
import 'screens/home_screen.dart';
import 'screens/workspace_screen.dart';
import 'screens/patch_screen.dart';
import 'screens/settings_screen.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => FixtureManager()),
        ChangeNotifierProvider(create: (_) => DMXEngine()),
      ],
      child: const DMXControllerApp(),
    ),
  );
}

class DMXControllerApp extends StatelessWidget {
  const DMXControllerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pro DMX Control',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF090A0F),
        primaryColor: const Color(0xFF00E5FF),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF00E5FF),
          secondary: Color(0xFF4A90E2),
          surface: Color(0xFF151822),
        ),
        fontFamily: 'Roboto', // Modern ve okunaklı bir font
      ),
      home: const MainLayout(),
    );
  }
}

// Tüm Sayfaları Yönetecek Profesyonel Ana Layout (Sol Menülü)
class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const HomeScreen(),
    const WorkspaceScreen(), // Seninle yaptığımız o efsane ekran
    const PatchScreen(),
    const SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // TABLETLER İÇİN PROFESYONEL SOL İKON MENÜSÜ (Navigation Rail)
          NavigationRail(
            backgroundColor: const Color(0xFF10121A),
            selectedIndex: _selectedIndex,
            onDestinationSelected: (int index) {
              setState(() {
                _selectedIndex = index;
              });
            },
            selectedIconTheme: const IconThemeData(color: Color(0xFF00E5FF), size: 32),
            unselectedIconTheme: const IconThemeData(color: Colors.white38, size: 28),
            selectedLabelTextStyle: const TextStyle(color: Color(0xFF00E5FF), fontSize: 11, fontWeight: FontWeight.bold),
            unselectedLabelTextStyle: const TextStyle(color: Colors.white38, fontSize: 10),
            labelType: NavigationRailLabelType.all,
            destinations: const [
              NavigationRailDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard), label: Text('ANA SAYFA')),
              NavigationRailDestination(icon: Icon(Icons.tune_outlined), selectedIcon: Icon(Icons.tune), label: Text('KONTROL')),
              NavigationRailDestination(icon: Icon(Icons.grid_on_outlined), selectedIcon: Icon(Icons.grid_on), label: Text('PATCH')),
              NavigationRailDestination(icon: Icon(Icons.settings_outlined), selectedIcon: Icon(Icons.settings), label: Text('AYARLAR')),
            ],
          ),
          // Seçili Ekranı Göster
          Expanded(child: _screens[_selectedIndex]),
        ],
      ),
    );
  }
}