import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'services/dmx_engine.dart';
import 'services/artnet_service.dart';
import 'services/fixture_manager.dart';
import 'screens/home_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Ekranı landscape modda kilitle (opsiyonel)
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  
  runApp(const DMXControllerApp());
}

class DMXControllerApp extends StatelessWidget {
  const DMXControllerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => DMXEngine()),
        ChangeNotifierProvider(create: (_) => ArtNetService()),
        ChangeNotifierProvider(create: (_) => FixtureManager()),
      ],
      child: MaterialApp(
        title: 'DMX Art-Net Controller',
        debugShowCheckedModeBanner: false,
        theme: ThemeData.dark().copyWith(
          scaffoldBackgroundColor: const Color(0xFF0A0E27),
          primaryColor: const Color(0xFF00D9FF),
          colorScheme: const ColorScheme.dark(
            primary: Color(0xFF00D9FF),
            secondary: Color(0xFFFF6B35),
            surface: Color(0xFF1A1F3A),
            background: Color(0xFF0A0E27),
          ),
          sliderTheme: SliderThemeData(
            activeTrackColor: const Color(0xFF00D9FF),
            thumbColor: const Color(0xFF00D9FF),
            overlayColor: const Color(0xFF00D9FF).withOpacity(0.2),
          ),
        ),
        home: const HomeScreen(),
      ),
    );
  }
}
