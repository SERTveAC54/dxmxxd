import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/fixture_manager.dart';

class PatchScreen extends StatelessWidget {
  const PatchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final manager = context.watch<FixtureManager>();

    return Scaffold(
      backgroundColor: const Color(0xFF090A0F),
      body: SafeArea(
        child: Column(
          children: [
            // ÜST BAŞLIK ALANI
            Container(
              padding: const EdgeInsets.all(24),
              color: const Color(0xFF10121A),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("PATCH & FİKSTÜRLER", style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text("Toplam ${manager.patchedFixtures.length} cihaz eklendi (Universe 1)", style: const TextStyle(color: Colors.white54, fontSize: 13)),
                    ],
                  ),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00E5FF),
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    icon: const Icon(Icons.add, size: 20),
                    label: const Text("YENİ CİHAZ EKLE (PATCH)", style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1)),
                    onPressed: () {
                      // TODO: Senin kütüphaneden cihaz seçme ekranına yönlendir
                    },
                  ),
                ],
              ),
            ),
            
            // CİHAZ LİSTESİ TABLOSU
            Expanded(
              child: manager.patchedFixtures.isEmpty 
              ? const Center(child: Text("Henüz cihaz eklenmedi.", style: TextStyle(color: Colors.white38)))
              : ListView.builder(
                  padding: const EdgeInsets.all(24),
                  itemCount: manager.patchedFixtures.length,
                  itemBuilder: (context, index) {
                    final fixture = manager.patchedFixtures[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF151822),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white10),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        leading: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(8)),
                          child: const Icon(Icons.lightbulb, color: Color(0xFF00E5FF)),
                        ),
                        title: Text(fixture.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                        subtitle: Text("Mod: ${fixture.channels.length} Kanal", style: const TextStyle(color: Colors.white54)),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF00E5FF).withOpacity(0.1),
                            border: Border.all(color: const Color(0xFF00E5FF).withOpacity(0.5)),
                            borderRadius: BorderRadius.circular(6)
                          ),
                          child: Text(
                            "DMX: ${fixture.startAddress}", 
                            style: const TextStyle(color: Color(0xFF00E5FF), fontWeight: FontWeight.bold, fontSize: 16)
                          ),
                        ),
                      ),
                    );
                  },
                ),
            ),
          ],
        ),
      ),
    );
  }
}