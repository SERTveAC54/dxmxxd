import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/fixture_manager.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final fixtureManager = context.watch<FixtureManager>();
    
    return Scaffold(
      backgroundColor: const Color(0xFF090A0F),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Hoş Geldiniz", style: TextStyle(color: Colors.white54, fontSize: 18)),
              const SizedBox(height: 8),
              const Text("STUDIO 1 KONTROL", style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold, letterSpacing: 2)),
              const SizedBox(height: 40),
              
              // DURUM KARTLARI (DMX / ARTNET)
              Row(
                children: [
                  _buildStatusCard("ART-NET AĞI", "Bağlı (192.168.1.15)", Icons.wifi, Colors.greenAccent),
                  const SizedBox(width: 20),
                  _buildStatusCard("TOPLAM CİHAZ", "${fixtureManager.patchedFixtures.length} Robot", Icons.lightbulb, const Color(0xFF00E5FF)),
                  const SizedBox(width: 20),
                  _buildStatusCard("UNIVERSE", "Universe 1", Icons.hub, Colors.purpleAccent),
                ],
              ),
              
              const SizedBox(height: 40),
              const Text("HIZLI ERİŞİM", style: TextStyle(color: Colors.white54, fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 1)),
              const SizedBox(height: 16),
              
              // HIZLI KISAYOLLAR
              Row(
                children: [
                  _buildQuickAction(context, "Sahne\nKontrolü", Icons.tune, const Color(0xFF4A90E2)),
                  const SizedBox(width: 20),
                  _buildQuickAction(context, "Cihaz\nEkle/Sil", Icons.grid_on, Colors.orangeAccent),
                  const SizedBox(width: 20),
                  _buildQuickAction(context, "Ağ\nAyarları", Icons.settings, Colors.grey),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusCard(String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFF151822),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3), width: 1),
          boxShadow: [BoxShadow(color: color.withOpacity(0.05), blurRadius: 20, spreadRadius: 5)],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 24),
                const SizedBox(width: 12),
                Text(title, style: const TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 16),
            Text(value, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickAction(BuildContext context, String title, IconData icon, Color color) {
    return Expanded(
      child: InkWell(
        onTap: () {
          // Navigasyonu _selectedIndex üzerinden yapıyoruz, burası sadece UI örneği
        },
        child: Container(
          height: 140,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF11131A),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white10),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 40),
              const SizedBox(height: 16),
              Text(title, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }
}