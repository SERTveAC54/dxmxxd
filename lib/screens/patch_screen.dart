import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/fixture_manager.dart';
import '../models/fixture.dart';

class PatchScreen extends StatefulWidget {
  const PatchScreen({super.key});

  @override
  State<PatchScreen> createState() => _PatchScreenState();
}

class _PatchScreenState extends State<PatchScreen> {
  
  // 1. MANUEL FİKSTÜR PENCERESİNİ AÇAR
  void _showManualFixtureBuilder(BuildContext context) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: "Manuel Fikstür",
      pageBuilder: (context, animation, secondaryAnimation) {
        return const Scaffold(
          backgroundColor: Colors.transparent,
          body: Center(
            child: ManualFixtureDialog(),
          ),
        );
      },
    ).then((_) {
      // Diyalog kapandığında listeyi güncellemek için setState tetikliyoruz
      setState(() {});
    });
  }

  // 2. KÜTÜPHANE SAYFASINI AÇAR
  void _openLibraryScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const LibraryScreen()),
    ).then((_) {
      // Kütüphaneden dönüldüğünde ekranı yenile
      setState(() {});
    });
  }

  // 3. DMX ADRESİNİ DEĞİŞTİRME DİYALOĞU (DMX GRID İLE)
  void _showEditAddressDialog(BuildContext context, Fixture fixture, FixtureManager manager) {
    final addressController = TextEditingController(text: fixture.startAddress.toString());
    
    showDialog(
      context: context,
      builder: (ctx) {
        return Dialog(
          backgroundColor: const Color(0xFF1A1F3A),
          child: StatefulBuilder(
            builder: (context, setState) {
              final currentAddress = int.tryParse(addressController.text) ?? fixture.startAddress!;
              
              return Container(
                width: 900,
                height: 700,
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // BAŞLIK
                    Row(
                      children: [
                        const Icon(Icons.edit, color: Color(0xFF00E5FF), size: 28),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "DMX Adresini Değiştir",
                                style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                fixture.name,
                                style: const TextStyle(color: Color(0xFF00E5FF), fontSize: 16),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.white54),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                    const Divider(color: Colors.white24, height: 32),
                    
                    // ADRES GİRİŞİ
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: addressController,
                            keyboardType: TextInputType.number,
                            style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                            decoration: InputDecoration(
                              labelText: 'Yeni DMX Adresi',
                              labelStyle: const TextStyle(color: Colors.white70),
                              hintText: '1-512',
                              hintStyle: const TextStyle(color: Colors.white30),
                              filled: true,
                              fillColor: Colors.black26,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(color: Color(0xFF00E5FF)),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(color: Colors.white24),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(color: Color(0xFF00E5FF), width: 2),
                              ),
                            ),
                            onChanged: (value) {
                              setState(() {}); // Grid'i güncelle
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.black26,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.white24),
                          ),
                          child: Text(
                            "${fixture.channelCount} Kanal\n($currentAddress - ${currentAddress + fixture.channelCount - 1})",
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.white70, fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // DMX GRID
                    const Text(
                      "DMX Kanal Haritası (512 Kanal)",
                      style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black26,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.white24),
                        ),
                        padding: const EdgeInsets.all(12),
                        child: GridView.builder(
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 32,
                            childAspectRatio: 1,
                            crossAxisSpacing: 2,
                            mainAxisSpacing: 2,
                          ),
                          itemCount: 512,
                          itemBuilder: (context, index) {
                            final channel = index + 1;
                            
                            // Bu kanalı kullanan fixture'ı bul (kendisi hariç)
                            Fixture? occupyingFixture;
                            for (var f in manager.patchedFixtures) {
                              if (f.id == fixture.id) continue;
                              if (f.startAddress == null) continue;
                              
                              final start = f.startAddress!;
                              final end = start + f.channelCount - 1;
                              
                              if (channel >= start && channel <= end) {
                                occupyingFixture = f;
                                break;
                              }
                            }
                            
                            // Yeni seçilen adres aralığında mı?
                            final isInNewRange = channel >= currentAddress && 
                                                 channel < currentAddress + fixture.channelCount;
                            
                            // Renk belirle
                            Color boxColor;
                            if (isInNewRange) {
                              boxColor = const Color(0xFF00E5FF); // Mavi - Yeni seçim
                            } else if (occupyingFixture != null) {
                              boxColor = const Color(0xFFEF4444); // Kırmızı - Dolu
                            } else {
                              boxColor = const Color(0xFF4ADE80); // Yeşil - Boş
                            }
                            
                            return Tooltip(
                              message: occupyingFixture != null 
                                  ? "${occupyingFixture.name}\n${occupyingFixture.startAddress}-${occupyingFixture.startAddress! + occupyingFixture.channelCount - 1}"
                                  : isInNewRange
                                      ? "${fixture.name} (Yeni)\n$currentAddress-${currentAddress + fixture.channelCount - 1}"
                                      : "Kanal $channel\nBoş",
                              child: Container(
                                decoration: BoxDecoration(
                                  color: boxColor.withOpacity(0.3),
                                  border: Border.all(color: boxColor, width: 0.5),
                                  borderRadius: BorderRadius.circular(2),
                                ),
                                child: Center(
                                  child: Text(
                                    '$channel',
                                    style: TextStyle(
                                      color: isInNewRange || occupyingFixture != null
                                          ? Colors.white
                                          : Colors.white70,
                                      fontSize: 8,
                                      fontWeight: isInNewRange 
                                          ? FontWeight.bold 
                                          : FontWeight.normal,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // LEGEND
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildLegendItem(const Color(0xFF4ADE80), "Boş"),
                        const SizedBox(width: 24),
                        _buildLegendItem(const Color(0xFFEF4444), "Dolu"),
                        const SizedBox(width: 24),
                        _buildLegendItem(const Color(0xFF00E5FF), "Yeni Seçim"),
                      ],
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // BUTONLAR
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text("İPTAL", style: TextStyle(color: Colors.white54)),
                        ),
                        const SizedBox(width: 16),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF00E5FF),
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                          ),
                          onPressed: () async {
                            final newAddress = int.tryParse(addressController.text) ?? fixture.startAddress!;
                            
                            if (newAddress < 1 || newAddress > 512) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text("❌ Adres 1-512 arasında olmalı!"),
                                  backgroundColor: Colors.red,
                                ),
                              );
                              return;
                            }
                            
                            if (newAddress + fixture.channelCount - 1 > 512) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text("❌ Bu adres için yeterli kanal yok! (${fixture.channelCount} kanal gerekli)"),
                                  backgroundColor: Colors.red,
                                ),
                              );
                              return;
                            }
                            
                            // Adres çakışması kontrolü (kendisi hariç)
                            bool hasConflict = false;
                            for (var other in manager.patchedFixtures) {
                              if (other.id == fixture.id) continue;
                              
                              final otherStart = other.startAddress!;
                              final otherEnd = otherStart + other.channelCount - 1;
                              final newEnd = newAddress + fixture.channelCount - 1;
                              
                              if ((newAddress >= otherStart && newAddress <= otherEnd) ||
                                  (newEnd >= otherStart && newEnd <= otherEnd)) {
                                hasConflict = true;
                                break;
                              }
                            }
                            
                            if (hasConflict) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text("❌ Adres çakışması! Bu adres aralığı kullanımda."),
                                  backgroundColor: Colors.red,
                                ),
                              );
                              return;
                            }
                            
                            // Adresi güncelle
                            await manager.updateFixtureAddress(fixture.id, newAddress);
                            
                            Navigator.pop(ctx);
                            
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text("✓ ${fixture.name} adresi ${newAddress} olarak güncellendi!"),
                                backgroundColor: const Color(0xFF00E5FF),
                              ),
                            );
                          },
                          child: const Text("KAYDET", style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }
  
  // Legend item widget
  Widget _buildLegendItem(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color.withOpacity(0.3),
            border: Border.all(color: color, width: 1),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final manager = context.watch<FixtureManager>();

    return Scaffold(
      backgroundColor: const Color(0xFF090A0F),
      body: SafeArea(
        child: Column(
          children: [
            // --- ÜST BAŞLIK VE BUTONLAR ---
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
                  Row(
                    children: [
                      // KÜTÜPHANEDEN EKLE BUTONU
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: Colors.white24),
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                        ),
                        icon: const Icon(Icons.library_books, size: 20),
                        label: const Text("KÜTÜPHANEDEN", style: TextStyle(fontWeight: FontWeight.bold)),
                        onPressed: _openLibraryScreen,
                      ),
                      const SizedBox(width: 16),
                      // MANUEL EKLE BUTONU
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF00E5FF),
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        icon: const Icon(Icons.build, size: 20),
                        label: const Text("MANUEL OLUŞTUR", style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1)),
                        onPressed: () => _showManualFixtureBuilder(context),
                      ),
                    ],
                  )
                ],
              ),
            ),
            
            // --- EKLENMİŞ CİHAZLARIN LİSTESİ ---
            Expanded(
              child: manager.patchedFixtures.isEmpty 
              ? const Center(
                  child: Text("Sahneye henüz cihaz eklenmedi.\nKütüphaneden seçin veya manuel oluşturun.", 
                  textAlign: TextAlign.center, 
                  style: TextStyle(color: Colors.white38, fontSize: 16, height: 1.5)))
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
                        subtitle: Text("Marka: ${fixture.manufacturer}  •  ${fixture.channelCount} Kanal", style: const TextStyle(color: Colors.white54)),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
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
                            const SizedBox(width: 8),
                            // DÜZENLEME BUTONU
                            IconButton(
                              icon: const Icon(Icons.edit_outlined, color: Color(0xFF00E5FF)),
                              tooltip: "DMX Adresini Değiştir",
                              onPressed: () {
                                _showEditAddressDialog(context, fixture, manager);
                              },
                            ),
                            // SİLME BUTONU
                            IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                              tooltip: "Sahneden Kaldır",
                              onPressed: () async {
                                // FixtureManager'ın unpatchFixture metodunu kullan
                                await manager.unpatchFixture(fixture.id);
                              },
                            )
                          ],
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


// =================================================================
// KÜTÜPHANE SEÇİM EKRANI (YENİ EKLENDİ)
// =================================================================
class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  String _searchQuery = "";

  // Cihaz seçildiğinde DMX adresini sorar ve sahneye yollar
  void _promptAddressAndPatch(BuildContext context, Fixture template) {
    final manager = context.read<FixtureManager>();
    final nextFreeAddress = _findNextFreeAddress(manager, template.channelCount);
    final addressController = TextEditingController(text: nextFreeAddress.toString());
    final quantityController = TextEditingController(text: '1');
    
    // Her fixture için ayrı adres kontrolcüleri
    List<TextEditingController> fixtureAddressControllers = [];
    
    showDialog(
      context: context,
      builder: (ctx) {
        return Dialog(
          backgroundColor: const Color(0xFF1A1F3A),
          child: StatefulBuilder(
            builder: (context, setState) {
              final quantity = int.tryParse(quantityController.text) ?? 1;
              
              // Fixture adres kontrolcülerini güncelle
              while (fixtureAddressControllers.length < quantity) {
                final lastAddress = fixtureAddressControllers.isEmpty 
                    ? int.tryParse(addressController.text) ?? nextFreeAddress
                    : (int.tryParse(fixtureAddressControllers.last.text) ?? 1) + template.channelCount;
                fixtureAddressControllers.add(TextEditingController(text: lastAddress.toString()));
              }
              while (fixtureAddressControllers.length > quantity) {
                fixtureAddressControllers.removeLast();
              }
              
              return Container(
                width: 1000,
                height: 750,
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // BAŞLIK
                    Row(
                      children: [
                        const Icon(Icons.lightbulb, color: Color(0xFF00D9FF), size: 28),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                template.name,
                                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                              ),
                              Text(
                                '${template.manufacturer} • ${template.channelCount} kanal',
                                style: const TextStyle(fontSize: 14, color: Colors.white54),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.white54),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                    const Divider(color: Colors.white12, height: 30),
                    
                    // ADET SEÇİCİ
                    Row(
                      children: [
                        const Text('Adet:', style: TextStyle(color: Colors.white70, fontSize: 14)),
                        const SizedBox(width: 12),
                        Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFF0A0E27),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.white24),
                          ),
                          child: Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.remove, color: Color(0xFFFF6B35)),
                                onPressed: () {
                                  setState(() {
                                    int current = int.tryParse(quantityController.text) ?? 1;
                                    if (current > 1) {
                                      quantityController.text = (current - 1).toString();
                                    }
                                  });
                                },
                              ),
                              SizedBox(
                                width: 40,
                                child: Text(
                                  quantityController.text,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.add, color: Color(0xFFFF6B35)),
                                onPressed: () {
                                  setState(() {
                                    int current = int.tryParse(quantityController.text) ?? 1;
                                    if (current < 50) {
                                      quantityController.text = (current + 1).toString();
                                    }
                                  });
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // FİXTURE LİSTESİ VE ADRESLER
                    Expanded(
                      child: Row(
                        children: [
                          // SOL: Fixture Listesi
                          Expanded(
                            flex: 2,
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.black26,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.white24),
                              ),
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'EKLENECEK CİHAZLAR',
                                    style: TextStyle(color: Color(0xFF00D9FF), fontWeight: FontWeight.bold, fontSize: 12),
                                  ),
                                  const SizedBox(height: 12),
                                  Expanded(
                                    child: ListView.builder(
                                      itemCount: quantity,
                                      itemBuilder: (context, index) {
                                        final controller = fixtureAddressControllers[index];
                                        final address = int.tryParse(controller.text) ?? 1;
                                        
                                        return Container(
                                          margin: const EdgeInsets.only(bottom: 8),
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF0A0E27),
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(color: const Color(0xFF00D9FF).withOpacity(0.3)),
                                          ),
                                          child: Row(
                                            children: [
                                              Container(
                                                width: 32,
                                                height: 32,
                                                decoration: BoxDecoration(
                                                  color: const Color(0xFF00D9FF).withOpacity(0.2),
                                                  borderRadius: BorderRadius.circular(6),
                                                ),
                                                child: Center(
                                                  child: Text(
                                                    '${index + 1}',
                                                    style: const TextStyle(color: Color(0xFF00D9FF), fontWeight: FontWeight.bold),
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      '${template.name} #${index + 1}',
                                                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                                                    ),
                                                    Text(
                                                      '$address - ${address + template.channelCount - 1}',
                                                      style: const TextStyle(color: Colors.white54, fontSize: 12),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              SizedBox(
                                                width: 80,
                                                child: TextField(
                                                  controller: controller,
                                                  keyboardType: TextInputType.number,
                                                  textAlign: TextAlign.center,
                                                  style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                                                  decoration: InputDecoration(
                                                    contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                                    filled: true,
                                                    fillColor: Colors.black26,
                                                    border: OutlineInputBorder(
                                                      borderRadius: BorderRadius.circular(6),
                                                      borderSide: BorderSide.none,
                                                    ),
                                                    enabledBorder: OutlineInputBorder(
                                                      borderRadius: BorderRadius.circular(6),
                                                      borderSide: const BorderSide(color: Colors.white24),
                                                    ),
                                                    focusedBorder: OutlineInputBorder(
                                                      borderRadius: BorderRadius.circular(6),
                                                      borderSide: const BorderSide(color: Color(0xFF00D9FF), width: 2),
                                                    ),
                                                  ),
                                                  onChanged: (value) {
                                                    setState(() {}); // Grid'i güncelle
                                                  },
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          
                          const SizedBox(width: 16),
                          
                          // SAĞ: DMX Grid
                          Expanded(
                            flex: 3,
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.black26,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.white24),
                              ),
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'DMX KANAL HARİTASI (512 KANAL)',
                                    style: TextStyle(color: Color(0xFF00D9FF), fontWeight: FontWeight.bold, fontSize: 12),
                                  ),
                                  const SizedBox(height: 12),
                                  Expanded(
                                    child: GridView.builder(
                                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                        crossAxisCount: 32,
                                        childAspectRatio: 1,
                                        crossAxisSpacing: 2,
                                        mainAxisSpacing: 2,
                                      ),
                                      itemCount: 512,
                                      itemBuilder: (context, index) {
                                        final channel = index + 1;
                                        
                                        // Mevcut fixture'ları kontrol et
                                        Fixture? occupyingFixture;
                                        for (var f in manager.patchedFixtures) {
                                          if (f.startAddress == null) continue;
                                          final start = f.startAddress!;
                                          final end = start + f.channelCount - 1;
                                          if (channel >= start && channel <= end) {
                                            occupyingFixture = f;
                                            break;
                                          }
                                        }
                                        
                                        // Yeni eklenecek fixture'ları kontrol et
                                        int? newFixtureIndex;
                                        for (int i = 0; i < fixtureAddressControllers.length; i++) {
                                          final addr = int.tryParse(fixtureAddressControllers[i].text) ?? 0;
                                          if (channel >= addr && channel < addr + template.channelCount) {
                                            newFixtureIndex = i;
                                            break;
                                          }
                                        }
                                        
                                        // Renk belirle
                                        Color boxColor;
                                        if (newFixtureIndex != null) {
                                          // Yeni fixture'lardan biri
                                          final colors = [
                                            const Color(0xFF00E5FF),
                                            const Color(0xFF00D9FF),
                                            const Color(0xFF00C5FF),
                                            const Color(0xFF00B1FF),
                                            const Color(0xFF009DFF),
                                          ];
                                          boxColor = colors[newFixtureIndex % colors.length];
                                        } else if (occupyingFixture != null) {
                                          boxColor = const Color(0xFFEF4444); // Kırmızı - Dolu
                                        } else {
                                          boxColor = const Color(0xFF4ADE80); // Yeşil - Boş
                                        }
                                        
                                        return Tooltip(
                                          message: newFixtureIndex != null
                                              ? "${template.name} #${newFixtureIndex + 1}\n${int.tryParse(fixtureAddressControllers[newFixtureIndex].text)}-${(int.tryParse(fixtureAddressControllers[newFixtureIndex].text) ?? 0) + template.channelCount - 1}"
                                              : occupyingFixture != null
                                                  ? "${occupyingFixture.name}\n${occupyingFixture.startAddress}-${occupyingFixture.startAddress! + occupyingFixture.channelCount - 1}"
                                                  : "Kanal $channel\nBoş",
                                          child: Container(
                                            decoration: BoxDecoration(
                                              color: boxColor.withOpacity(0.3),
                                              border: Border.all(color: boxColor, width: 0.5),
                                              borderRadius: BorderRadius.circular(2),
                                            ),
                                            child: Center(
                                              child: Text(
                                                '$channel',
                                                style: TextStyle(
                                                  color: newFixtureIndex != null || occupyingFixture != null
                                                      ? Colors.white
                                                      : Colors.white70,
                                                  fontSize: 8,
                                                  fontWeight: newFixtureIndex != null 
                                                      ? FontWeight.bold 
                                                      : FontWeight.normal,
                                                ),
                                              ),
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  // Legend
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      _buildLegendItem(const Color(0xFF4ADE80), "Boş"),
                                      const SizedBox(width: 16),
                                      _buildLegendItem(const Color(0xFFEF4444), "Dolu"),
                                      const SizedBox(width: 16),
                                      _buildLegendItem(const Color(0xFF00E5FF), "Yeni"),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // BUTONLAR
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text("İPTAL", style: TextStyle(color: Colors.white54)),
                        ),
                        const SizedBox(width: 16),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF00E5FF),
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                          ),
                          icon: const Icon(Icons.add),
                          label: Text('${quantity} CİHAZ EKLE', style: const TextStyle(fontWeight: FontWeight.bold)),
                          onPressed: () async {
                            final navigator = Navigator.of(ctx);
                            final parentNavigator = Navigator.of(context);
                            final messenger = ScaffoldMessenger.of(context);

                            try {
                              int successCount = 0;
                              List<String> errors = [];
                              
                              // Her fixture için ayrı ayrı ekle
                              for (int i = 0; i < fixtureAddressControllers.length; i++) {
                                final address = int.tryParse(fixtureAddressControllers[i].text) ?? 1;
                                
                                // Adres kontrolü
                                if (address < 1 || address > 512) {
                                  errors.add("Cihaz #${i + 1}: Adres 1-512 arasında olmalı");
                                  continue;
                                }
                                
                                if (address + template.channelCount - 1 > 512) {
                                  errors.add("Cihaz #${i + 1}: Yeterli kanal yok");
                                  continue;
                                }
                                
                                // Çakışma kontrolü (önceki eklenenler dahil)
                                bool hasConflict = false;
                                
                                // Mevcut fixture'larla çakışma
                                for (var f in manager.patchedFixtures) {
                                  if (f.startAddress == null) continue;
                                  final start = f.startAddress!;
                                  final end = start + f.channelCount - 1;
                                  final newEnd = address + template.channelCount - 1;
                                  
                                  if ((address >= start && address <= end) ||
                                      (newEnd >= start && newEnd <= end)) {
                                    hasConflict = true;
                                    break;
                                  }
                                }
                                
                                // Önceki eklenenlerle çakışma
                                if (!hasConflict) {
                                  for (int j = 0; j < i; j++) {
                                    final otherAddr = int.tryParse(fixtureAddressControllers[j].text) ?? 0;
                                    final otherEnd = otherAddr + template.channelCount - 1;
                                    final newEnd = address + template.channelCount - 1;
                                    
                                    if ((address >= otherAddr && address <= otherEnd) ||
                                        (newEnd >= otherAddr && newEnd <= otherEnd)) {
                                      hasConflict = true;
                                      break;
                                    }
                                  }
                                }
                                
                                if (hasConflict) {
                                  errors.add("Cihaz #${i + 1}: Adres çakışması");
                                  continue;
                                }
                                
                                // Ekle
                                await manager.patchFixture(template, address);
                                successCount++;
                              }
                              
                              navigator.pop(); // Diyaloğu kapat
                              parentNavigator.pop(); // Kütüphane sayfasını kapat
                              
                              // Sonuç mesajı
                              if (errors.isEmpty) {
                                messenger.showSnackBar(
                                  SnackBar(
                                    content: Text("✓ ${template.name} x$successCount başarıyla eklendi!"),
                                    backgroundColor: const Color(0xFF00D9FF),
                                    duration: const Duration(seconds: 2),
                                  ),
                                );
                              } else {
                                messenger.showSnackBar(
                                  SnackBar(
                                    content: Text("⚠️ $successCount/${quantity} cihaz eklendi\n${errors.join('\n')}"),
                                    backgroundColor: Colors.orange,
                                    duration: const Duration(seconds: 4),
                                  ),
                                );
                              }
                            } catch (e) {
                              messenger.showSnackBar(
                                SnackBar(
                                  content: Text(e.toString()),
                                  backgroundColor: Colors.red,
                                  duration: const Duration(seconds: 3),
                                ),
                              );
                            }
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }
  
  // Boş adres bulma fonksiyonu
  int _findNextFreeAddress(FixtureManager manager, int channelCount) {
    if (manager.patchedFixtures.isEmpty) return 1;
    
    // Tüm kullanılan adresleri işaretle
    final usedChannels = List<bool>.filled(512, false);
    for (var fixture in manager.patchedFixtures) {
      if (fixture.startAddress != null) {
        for (int i = 0; i < fixture.channelCount; i++) {
          final ch = fixture.startAddress! + i - 1;
          if (ch >= 0 && ch < 512) {
            usedChannels[ch] = true;
          }
        }
      }
    }
    
    // İlk boş aralığı bul
    for (int start = 0; start <= 512 - channelCount; start++) {
      bool canFit = true;
      for (int i = 0; i < channelCount; i++) {
        if (usedChannels[start + i]) {
          canFit = false;
          break;
        }
      }
      if (canFit) return start + 1; // DMX 1-indexed
    }
    
    return 1; // Fallback
  }
  
  // DMX Kanal haritası widget'ı - GRID GÖRÜNÜMÜ
  Widget _buildChannelMap(FixtureManager manager, int fixtureChannelCount, TextEditingController controller, StateSetter setState) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0A0E27),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        children: [
          // Bilgi paneli
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              color: Color(0xFF10141D),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildLegendItem(Colors.green, 'BOŞ'),
                _buildLegendItem(Colors.red, 'DOLU'),
                _buildLegendItem(const Color(0xFF00D9FF), 'SEÇİLİ'),
              ],
            ),
          ),
          
          // Grid - 512 kanal
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 32, // 32 sütun = 16 satır (512/32)
                  crossAxisSpacing: 2,
                  mainAxisSpacing: 2,
                  childAspectRatio: 1,
                ),
                itemCount: 512,
                itemBuilder: (context, index) {
                  final channel = index + 1;
                  final occupyingFixture = _getFixtureAtChannel(manager, channel);
                  final isOccupied = occupyingFixture != null;
                  final isFree = !isOccupied;
                  
                  // Seçili adres aralığını hesapla
                  final selectedAddress = int.tryParse(controller.text) ?? 0;
                  final isInSelectedRange = selectedAddress > 0 && 
                      channel >= selectedAddress && 
                      channel < selectedAddress + fixtureChannelCount;
                  
                  Color boxColor;
                  if (isInSelectedRange) {
                    boxColor = const Color(0xFF00D9FF);
                  } else if (isOccupied) {
                    boxColor = Colors.red.shade700;
                  } else {
                    boxColor = Colors.green.shade700;
                  }
                  
                  return Tooltip(
                    message: isOccupied 
                        ? 'Ch $channel: ${occupyingFixture.name}\n${occupyingFixture.manufacturer}'
                        : 'Ch $channel: BOŞ',
                    child: InkWell(
                      onTap: isFree ? () {
                        controller.text = channel.toString();
                        setState(() {});
                      } : null,
                      child: Container(
                        decoration: BoxDecoration(
                          color: boxColor,
                          borderRadius: BorderRadius.circular(2),
                          border: Border.all(
                            color: isInSelectedRange 
                                ? Colors.white 
                                : Colors.black26,
                            width: isInSelectedRange ? 1.5 : 0.5,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            channel.toString(),
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 8,
                              fontWeight: isInSelectedRange ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          
          // Seçili fixture bilgisi
          if (int.tryParse(controller.text) != null && int.parse(controller.text) > 0)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(
                color: Color(0xFF10141D),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(12),
                  bottomRight: Radius.circular(12),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.info_outline, color: Color(0xFF00D9FF), size: 16),
                  const SizedBox(width: 8),
                  Text(
                    'Seçili: Ch ${controller.text} - ${int.parse(controller.text) + fixtureChannelCount - 1} ($fixtureChannelCount kanal)',
                    style: const TextStyle(
                      color: Color(0xFF00D9FF),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
  
  // Legend item helper
  Widget _buildLegendItem(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
            border: Border.all(color: Colors.white24),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
  
  // Belirli bir kanalda fixture var mı kontrol et
  Fixture? _getFixtureAtChannel(FixtureManager manager, int channel) {
    for (var fixture in manager.patchedFixtures) {
      if (fixture.startAddress != null) {
        final start = fixture.startAddress!;
        final end = start + fixture.channelCount - 1;
        if (channel >= start && channel <= end) {
          return fixture;
        }
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final manager = context.watch<FixtureManager>();
    
    // DEBUG: Kütüphane durumunu kontrol et
    debugPrint('🔍 Arama: "$_searchQuery"');
    debugPrint('📚 Toplam fixture: ${manager.fixtureLibrary.length}');
    
    // Arama Çubuğuna Göre Listeyi Filtrele (İsim, Marka VE Kanal Sayısı)
    final library = _searchQuery.isEmpty 
        ? manager.fixtureLibrary // Arama boşsa tümünü göster
        : manager.fixtureLibrary.where((f) {
            final query = _searchQuery.toLowerCase();
            return f.name.toLowerCase().contains(query) || 
                   f.manufacturer.toLowerCase().contains(query) ||
                   f.channelCount.toString().contains(query);
          }).toList();
    
    debugPrint('📊 Filtrelenmiş sonuç: ${library.length} fixture');
    
    // DEBUG: İlk 5 sonucu göster
    if (library.isNotEmpty) {
      debugPrint('🎯 İlk sonuçlar:');
      for (int i = 0; i < (library.length < 5 ? library.length : 5); i++) {
        debugPrint('  ${i+1}. ${library[i].name} (${library[i].manufacturer}) - ${library[i].channelCount} CH');
      }
    }

    return Scaffold(
      backgroundColor: const Color(0xFF090A0F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF10121A),
        iconTheme: const IconThemeData(color: Color(0xFF00E5FF)),
        title: TextField(
          style: const TextStyle(color: Colors.white),
          cursorColor: const Color(0xFF00E5FF),
          decoration: const InputDecoration(
            hintText: "Marka, Model veya Kanal Sayısı Ara (örn: 16)...",
            hintStyle: TextStyle(color: Colors.white38),
            border: InputBorder.none,
            prefixIcon: Icon(Icons.search, color: Color(0xFF00E5FF)),
          ),
          onChanged: (val) {
            setState(() {
              _searchQuery = val;
            });
          },
        ),
      ),
      body: library.isEmpty
          ? const Center(child: Text("Kütüphanede cihaz bulunamadı.", style: TextStyle(color: Colors.white54, fontSize: 16)))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: library.length,
              itemBuilder: (context, index) {
                final fixture = library[index];
                return Card(
                  color: const Color(0xFF151822),
                  margin: const EdgeInsets.only(bottom: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  child: ListTile(
                    leading: const Icon(Icons.archive, color: Colors.white38),
                    title: Text(fixture.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    subtitle: Text(fixture.manufacturer, style: const TextStyle(color: Colors.white54)),
                    trailing: Text("${fixture.channelCount} CH", style: const TextStyle(color: Color(0xFF00E5FF), fontWeight: FontWeight.bold)),
                    onTap: () => _promptAddressAndPatch(context, fixture),
                  ),
                );
              },
            ),
    );
  }
}


// =================================================================
// MANUEL CİHAZ OLUŞTURMA DİYALOĞU (HATALAR GİDERİLDİ)
// =================================================================
class ManualFixtureDialog extends StatefulWidget {
  const ManualFixtureDialog({super.key});

  @override
  State<ManualFixtureDialog> createState() => _ManualFixtureDialogState();
}

class _ManualFixtureDialogState extends State<ManualFixtureDialog> {
  final TextEditingController _nameController = TextEditingController(text: "Yeni Robot");
  final TextEditingController _addressController = TextEditingController(text: "1");
  final TextEditingController _channelCountController = TextEditingController(text: "4");

  List<ChannelData> _channels = [];
  
  // Genişletilmiş kanal tipleri listesi
  final List<String> _commonTypes = [
    "Dimmer", "Strobe", "Shutter",
    "Red", "Green", "Blue", "White", "Amber", "UV",
    "Cyan", "Magenta", "Yellow",
    "Pan", "Tilt", "PanFine", "TiltFine",
    "ColorWheel", "Gobo", "GoboRotation",
    "Prism", "PrismRotation",
    "Focus", "Zoom", "Iris", "Frost",
    "Speed", "Macro", "Reset", "Function",
    "Rotation", "Generic"
  ];

  @override
  void initState() {
    super.initState();
    _generateChannels(4); 
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _channelCountController.dispose();
    super.dispose();
  }

  void _generateChannels(int count) {
    if (count <= 0 || count > 512) return;
    List<ChannelData> newChannels = [];
    for (int i = 0; i < count; i++) {
      if (i < _channels.length) {
        newChannels.add(_channels[i]);
      } else {
        newChannels.add(ChannelData(name: "Kanal ${i + 1}", typeName: "Generic"));
      }
    }
    setState(() {
      _channels = newChannels;
    });
  }

  // Tipleri projendeki "ChannelType" Enum'una çökmeden çevirir
  ChannelType _getSafeEnum(String typeStr) {
    final searchStr = typeStr.toLowerCase();
    for (var val in ChannelType.values) {
      if (val.toString().split('.').last.toLowerCase() == searchStr) {
        return val;
      }
    }
    return ChannelType.values.first; // Eşleşmezse varsayılan
  }

  void _saveFixture() async {
    int startAddress = int.tryParse(_addressController.text) ?? 1;
    if (startAddress < 1 || startAddress > 512) startAddress = 1;

    // Kanalları "FixtureChannel" objesi olarak haritalıyoruz
    List<FixtureChannel> mappedChannels = [];
    for (int i = 0; i < _channels.length; i++) {
      mappedChannels.add(
        FixtureChannel(
          offset: i, 
          name: _channels[i].name.isEmpty ? "Kanal ${i + 1}" : _channels[i].name,
          type: _getSafeEnum(_channels[i].typeName),
        )
      );
    }

    // Yeni fixture oluştur
    final newFixture = Fixture(
      id: 'manual_${DateTime.now().millisecondsSinceEpoch}', 
      name: _nameController.text.isEmpty ? "İsimsiz Cihaz" : _nameController.text,
      manufacturer: "Manuel",
      channelCount: _channels.length, 
      channels: mappedChannels,
    );

    final manager = context.read<FixtureManager>();
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    
    try {
      // FixtureManager'ın patchFixture metodunu kullan
      await manager.patchFixture(newFixture, startAddress);
      
      navigator.pop(); // Pencereyi Kapat
      
      // Başarı mesajı
      messenger.showSnackBar(
        SnackBar(
          content: Text("✓ ${newFixture.name} Ch $startAddress adresine eklendi!"),
          backgroundColor: const Color(0xFF00E5FF),
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      // Hata mesajı
      messenger.showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 700,
      height: 600,
      decoration: BoxDecoration(
        color: const Color(0xFF151822),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF00E5FF).withOpacity(0.3), width: 2),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.8), blurRadius: 30, spreadRadius: 10)],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: Color(0xFF10121A),
              borderRadius: BorderRadius.only(topLeft: Radius.circular(14), topRight: Radius.circular(14)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("MANUEL FİKSTÜR OLUŞTUR", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 1)),
                IconButton(icon: const Icon(Icons.close, color: Colors.white54), onPressed: () => Navigator.pop(context)),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: _buildTextField("Cihaz Adı", _nameController, TextInputType.text),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 1,
                  child: _buildTextField("DMX Adres", _addressController, TextInputType.number),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 1,
                  child: _buildTextField(
                    "Kanal Sayısı", 
                    _channelCountController, 
                    TextInputType.number,
                    onChanged: (val) {
                      int? count = int.tryParse(val);
                      if (count != null) _generateChannels(count);
                    }
                  ),
                ),
              ],
            ),
          ),

          const Divider(color: Colors.white10, height: 1),

          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              itemCount: _channels.length,
              itemBuilder: (context, index) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF11131A),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        alignment: Alignment.center,
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: Colors.black45, borderRadius: BorderRadius.circular(6)),
                        child: Text("CH\n${index + 1}", style: const TextStyle(color: Color(0xFF00E5FF), fontSize: 10, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                      ),
                      const SizedBox(width: 16),
                      
                      Expanded(
                        flex: 1,
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            dropdownColor: const Color(0xFF151822),
                            value: _channels[index].typeName,
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                            items: _commonTypes.map((type) {
                              return DropdownMenuItem(value: type, child: Text(type.toUpperCase()));
                            }).toList(),
                            onChanged: (newType) {
                              if (newType != null) {
                                setState(() { _channels[index].typeName = newType; });
                              }
                            },
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),

                      Expanded(
                        flex: 2,
                        child: TextField(
                          style: const TextStyle(color: Colors.white70, fontSize: 14),
                          decoration: InputDecoration(
                            hintText: "Örn: Master Dimmer",
                            hintStyle: const TextStyle(color: Colors.white24),
                            filled: true,
                            fillColor: Colors.black26,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: BorderSide.none),
                          ),
                          onChanged: (val) => _channels[index].name = val,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: Color(0xFF10121A),
              borderRadius: BorderRadius.only(bottomLeft: Radius.circular(14), bottomRight: Radius.circular(14)),
            ),
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00E5FF),
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: _saveFixture,
                child: const Text("CİHAZI SAHNEYE EKLE (PATCH)", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 1)),
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, TextInputType type, {Function(String)? onChanged}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: type,
          style: const TextStyle(color: Colors.white, fontSize: 16),
          onChanged: onChanged,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.black26,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Colors.white10)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF00E5FF))),
          ),
        ),
      ],
    );
  }
}

class ChannelData {
  String name;
  String typeName;
  ChannelData({required this.name, required this.typeName});
}