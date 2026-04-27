import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/artnet_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late TextEditingController _ipController;
  late TextEditingController _universeController;
  
  @override
  void initState() {
    super.initState();
    final artnet = context.read<ArtNetService>();
    _ipController = TextEditingController(text: artnet.targetIP);
    _universeController = TextEditingController(text: artnet.universe.toString());
  }
  
  @override
  void dispose() {
    _ipController.dispose();
    _universeController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    final artnet = context.watch<ArtNetService>();
    
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1F3A),
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Art-Net Ayarları
          _SectionHeader(
            icon: Icons.network_wifi,
            title: 'Art-Net Configuration',
            color: const Color(0xFF00D9FF),
          ),
          const SizedBox(height: 16),
          
          // Bağlantı durumu
          _StatusCard(
            label: 'Connection Status',
            value: artnet.isConnected ? 'Connected' : 'Disconnected',
            color: artnet.isConnected ? Colors.green : Colors.red,
          ),
          
          const SizedBox(height: 16),
          
          // IP Adresi
          TextField(
            controller: _ipController,
            decoration: InputDecoration(
              labelText: 'Target IP Address',
              hintText: '192.168.1.100',
              prefixIcon: const Icon(Icons.computer),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Universe
          TextField(
            controller: _universeController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Universe',
              hintText: '0',
              prefixIcon: const Icon(Icons.hub),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Kaydet butonu
          ElevatedButton.icon(
            onPressed: () async {
              final ip = _ipController.text;
              final universe = int.tryParse(_universeController.text) ?? 0;
              
              await artnet.setTargetIP(ip);
              await artnet.setUniverse(universe);
              
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Settings saved')),
                );
              }
            },
            icon: const Icon(Icons.save),
            label: const Text('Save Settings'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00D9FF),
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
          
          const SizedBox(height: 32),
          
          // Uygulama Bilgisi
          _SectionHeader(
            icon: Icons.info,
            title: 'About',
            color: const Color(0xFFFF6B35),
          ),
          const SizedBox(height: 16),
          
          const _InfoCard(
            label: 'Version',
            value: '1.0.0',
          ),
          const _InfoCard(
            label: 'Protocol',
            value: 'Art-Net DMX512',
          ),
          const _InfoCard(
            label: 'Max Refresh Rate',
            value: '40 Hz (25ms)',
          ),
          const _InfoCard(
            label: 'Universe Size',
            value: '512 Channels',
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;
  
  const _SectionHeader({
    required this.icon,
    required this.title,
    required this.color,
  });
  
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: color),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}

class _StatusCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  
  const _StatusCard({
    required this.label,
    required this.value,
    required this.color,
  });
  
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1F3A),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 16)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: color),
            ),
            child: Text(
              value,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String label;
  final String value;
  
  const _InfoCard({
    required this.label,
    required this.value,
  });
  
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
