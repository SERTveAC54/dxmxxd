import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/fixture_manager.dart';
import '../services/artnet_service.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final fixtureManager = context.watch<FixtureManager>();
    final artnet = context.watch<ArtNetService>();
    
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // BAŞLIK
              Row(
                children: [
                  Container(
                    width: 4,
                    height: 40,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF00D9FF), Color(0xFFFF6B35)],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "DMX CONTROLLER",
                        style: Theme.of(context).textTheme.displayMedium?.copyWith(
                          letterSpacing: 2,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Professional Lighting Control System",
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: const Color(0xFF00D9FF),
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              
              const SizedBox(height: 32),
              
              // DURUM KARTLARI
              Row(
                children: [
                  Expanded(
                    child: _buildStatusCard(
                      context,
                      "ART-NET",
                      artnet.isConnected ? "Connected" : "Disconnected",
                      artnet.isConnected ? artnet.targetIP : "Not Connected",
                      Icons.wifi,
                      artnet.isConnected ? const Color(0xFF4ADE80) : const Color(0xFFEF4444),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildStatusCard(
                      context,
                      "FIXTURES",
                      "${fixtureManager.patchedFixtures.length}",
                      "Patched Devices",
                      Icons.lightbulb,
                      const Color(0xFF00D9FF),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildStatusCard(
                      context,
                      "UNIVERSE",
                      "${artnet.universe}",
                      "Active Universe",
                      Icons.hub,
                      const Color(0xFFFF6B35),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 32),
              
              // KÜTÜPHANE İSTATİSTİKLERİ
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1F3A),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withOpacity(0.1)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.library_books, color: Color(0xFF00D9FF), size: 32),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Fixture Library",
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "${fixtureManager.fixtureLibrary.length} fixtures available",
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF00D9FF).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFF00D9FF)),
                      ),
                      child: Text(
                        "${fixtureManager.fixtureLibrary.length}",
                        style: const TextStyle(
                          color: Color(0xFF00D9FF),
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              
              // HIZLI BİLGİ
              Text(
                "QUICK INFO",
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.white54,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 12),
              
              _buildInfoRow(context, "Connection", artnet.isConnected ? "Active" : "Inactive"),
              _buildInfoRow(context, "Target IP", artnet.targetIP),
              _buildInfoRow(context, "Port", "6454 (Art-Net)"),
              _buildInfoRow(context, "Protocol", "Art-Net DMX512"),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusCard(
    BuildContext context,
    String title,
    String value,
    String subtitle,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1F3A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.white70,
                    fontSize: 12,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.white38,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.white54,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: const Color(0xFF00D9FF),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}