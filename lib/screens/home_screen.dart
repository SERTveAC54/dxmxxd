import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/dmx_engine.dart';
import '../services/artnet_service.dart';
import '../services/fixture_manager.dart';
import 'workspace_screen.dart'; // <--- YENİ WORKSPACE EKRANI
import 'patch_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  
  @override
  void initState() {
    super.initState();
    _initializeServices();
  }
  
  Future<void> _initializeServices() async {
    final artnet = context.read<ArtNetService>();
    final dmxEngine = context.read<DMXEngine>();
    
    // Art-Net bağlantısını başlat
    await artnet.connect();
    
    // DMX Engine'den Art-Net'e veri akışını bağla
    dmxEngine.onDataChanged = (data) {
      artnet.sendDMX(data);
    };
  }
  
  @override
  Widget build(BuildContext context) {
    // SADECE 3 SAYFA: Workspace, Patch, Settings
    final pages = [
      const WorkspaceScreen(), // <--- YENİ WORKSPACE EKRANI
      const PatchScreen(),
      const SettingsScreen(),
    ];
    
    return Scaffold(
      body: pages[_selectedIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1A1F3A),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _NavButton(
                  icon: Icons.dashboard, // <--- Workspace ikonu
                  label: 'Workspace',
                  isSelected: _selectedIndex == 0,
                  onTap: () => setState(() => _selectedIndex = 0),
                ),
                _NavButton(
                  icon: Icons.grid_on,
                  label: 'Patch',
                  isSelected: _selectedIndex == 1,
                  onTap: () => setState(() => _selectedIndex = 1),
                ),
                _NavButton(
                  icon: Icons.settings,
                  label: 'Settings',
                  isSelected: _selectedIndex == 2,
                  onTap: () => setState(() => _selectedIndex = 2),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  
  const _NavButton({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });
  
  @override
  Widget build(BuildContext context) {
    final color = isSelected ? const Color(0xFF00D9FF) : Colors.white54;
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected 
              ? const Color(0xFF00D9FF).withOpacity(0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
