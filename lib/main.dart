import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'services/fixture_manager.dart';
import 'services/dmx_engine.dart';
import 'services/artnet_service.dart';
import 'services/wifi_scanner.dart';
import 'screens/home_screen.dart';
import 'screens/workspace_screen.dart';
import 'screens/patch_screen.dart';
import 'screens/settings_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  
  // SADECE YATAY MOD - DİKEY MODU KİLİTLE
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  
  // Sistem UI'yi gizle (Tam ekran mod)
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => FixtureManager()),
        ChangeNotifierProvider(create: (_) => DMXEngine()),
        ChangeNotifierProvider(create: (_) => ArtNetService()),
        ChangeNotifierProvider(create: (_) => WiFiScanner()),
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
      title: 'DMX Pro Controller',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0A0E27),
        primaryColor: const Color(0xFF00D9FF),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF00D9FF),
          secondary: Color(0xFFFF6B35),
          surface: Color(0xFF1A1F3A),
        ),
        // Modern ve okunaklı fontlar
        textTheme: const TextTheme(
          displayLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
          displayMedium: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
          displaySmall: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: Colors.white),
          headlineMedium: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white),
          titleLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white),
          titleMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.white),
          bodyLarge: TextStyle(fontSize: 14, color: Colors.white70),
          bodyMedium: TextStyle(fontSize: 13, color: Colors.white60),
          labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        // Card tema
        cardTheme: CardThemeData(
          color: const Color(0xFF1A1F3A),
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        // AppBar tema
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1A1F3A),
          elevation: 0,
          centerTitle: false,
          titleTextStyle: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF00D9FF),
          ),
        ),
        // Button tema
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF00D9FF),
            foregroundColor: Colors.black,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFF00D9FF),
            side: const BorderSide(color: Color(0xFF00D9FF), width: 2),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
        ),
        // Input tema
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF1A1F3A),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFF2A3F5A)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFF2A3F5A)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFF00D9FF), width: 2),
          ),
          labelStyle: const TextStyle(color: Colors.white70),
          hintStyle: const TextStyle(color: Colors.white38),
        ),
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
          // PROFESYONEL SOL MENÜ (Navigation Rail)
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF1A1F3A),
              border: Border(
                right: BorderSide(color: Colors.white.withOpacity(0.1), width: 1),
              ),
            ),
            child: NavigationRail(
              backgroundColor: Colors.transparent,
              selectedIndex: _selectedIndex,
              onDestinationSelected: (int index) {
                setState(() {
                  _selectedIndex = index;
                });
              },
              selectedIconTheme: const IconThemeData(
                color: Color(0xFF00D9FF),
                size: 28,
              ),
              unselectedIconTheme: IconThemeData(
                color: Colors.white.withOpacity(0.4),
                size: 24,
              ),
              selectedLabelTextStyle: const TextStyle(
                color: Color(0xFF00D9FF),
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
              unselectedLabelTextStyle: TextStyle(
                color: Colors.white.withOpacity(0.4),
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
              labelType: NavigationRailLabelType.all,
              leading: Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Column(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF00D9FF), Color(0xFFFF6B35)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.lightbulb,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'DMX',
                      style: TextStyle(
                        color: Color(0xFF00D9FF),
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                    const Text(
                      'PRO',
                      style: TextStyle(
                        color: Color(0xFFFF6B35),
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ),
              destinations: const [
                NavigationRailDestination(
                  icon: Icon(Icons.dashboard_outlined),
                  selectedIcon: Icon(Icons.dashboard),
                  label: Text('DASHBOARD'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.tune_outlined),
                  selectedIcon: Icon(Icons.tune),
                  label: Text('CONTROL'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.grid_on_outlined),
                  selectedIcon: Icon(Icons.grid_on),
                  label: Text('PATCH'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.settings_outlined),
                  selectedIcon: Icon(Icons.settings),
                  label: Text('SETTINGS'),
                ),
              ],
            ),
          ),
          // Seçili Ekranı Göster
          Expanded(child: _screens[_selectedIndex]),
        ],
      ),
    );
  }
}