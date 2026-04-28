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
  String _searchQuery = '';
  String? _selectedManufacturer;
  
  @override
  Widget build(BuildContext context) {
    final fixtureManager = context.watch<FixtureManager>();
    
    // Tüm üreticileri al
    final manufacturers = fixtureManager.fixtureLibrary
        .map((f) => f.manufacturer)
        .toSet()
        .toList()
      ..sort();
    
    // Filtrelenmiş fixture listesi
    final filteredFixtures = fixtureManager.fixtureLibrary.where((fixture) {
      final matchesSearch = _searchQuery.isEmpty ||
          fixture.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          fixture.manufacturer.toLowerCase().contains(_searchQuery.toLowerCase());
      
      final matchesManufacturer = _selectedManufacturer == null ||
          fixture.manufacturer == _selectedManufacturer;
      
      return matchesSearch && matchesManufacturer;
    }).toList();
    
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1F3A),
        title: const Text('Fixture Patch'),
      ),
      body: Row(
        children: [
          // Sol panel - Fikstür kütüphanesi
          Expanded(
            flex: 2,
            child: Container(
              color: const Color(0xFF0A0E27),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Başlık ve istatistik
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Fixture Library',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF00D9FF),
                          ),
                        ),
                        Row(
                          children: [
                            // Manuel Fixture Ekle Butonu
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFFF6B35),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              icon: const Icon(Icons.build, size: 18),
                              label: const Text('MANUEL EKLE', style: TextStyle(fontWeight: FontWeight.bold)),
                              onPressed: () => _showManualFixtureDialog(context),
                            ),
                            const SizedBox(width: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: const Color(0xFF00D9FF).withOpacity(0.2),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                '${filteredFixtures.length} / ${fixtureManager.fixtureLibrary.length}',
                                style: const TextStyle(
                                  color: Color(0xFF00D9FF),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  
                  // Arama kutusu
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: TextField(
                      onChanged: (value) => setState(() => _searchQuery = value),
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Search fixtures...',
                        hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                        prefixIcon: const Icon(Icons.search, color: Color(0xFF00D9FF)),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, color: Colors.white54),
                                onPressed: () => setState(() => _searchQuery = ''),
                              )
                            : null,
                        filled: true,
                        fillColor: const Color(0xFF1A1F3A),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Üretici filtreleme
                  SizedBox(
                    height: 50,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      children: [
                        _ManufacturerChip(
                          label: 'All (${fixtureManager.fixtureLibrary.length})',
                          isSelected: _selectedManufacturer == null,
                          onTap: () => setState(() => _selectedManufacturer = null),
                        ),
                        ...manufacturers.map((manufacturer) {
                          final count = fixtureManager.fixtureLibrary
                              .where((f) => f.manufacturer == manufacturer)
                              .length;
                          return _ManufacturerChip(
                            label: '$manufacturer ($count)',
                            isSelected: _selectedManufacturer == manufacturer,
                            onTap: () => setState(() => _selectedManufacturer = manufacturer),
                          );
                        }),
                      ],
                    ),
                  ),
                  
                  const Divider(color: Colors.white12),
                  
                  // Fixture listesi
                  Expanded(
                    child: filteredFixtures.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.search_off,
                                  size: 64,
                                  color: Colors.white.withOpacity(0.3),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No fixtures found',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.5),
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            itemCount: filteredFixtures.length,
                            itemBuilder: (context, index) {
                              final fixture = filteredFixtures[index];
                              return _FixtureLibraryCard(
                                fixture: fixture,
                                onPatch: () => _showPatchDialog(context, fixture),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          ),
          
          // Sağ panel - Yamalı fikstürler
          Expanded(
            child: Container(
              color: const Color(0xFF1A1F3A),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Patched Fixtures',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFFF6B35),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFF6B35).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '${fixtureManager.patchedFixtures.length}',
                            style: const TextStyle(
                              color: Color(0xFFFF6B35),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(color: Colors.white12),
                  Expanded(
                    child: fixtureManager.patchedFixtures.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.lightbulb_outline,
                                  size: 64,
                                  color: Colors.white.withOpacity(0.3),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No patched fixtures',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.5),
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Click + to patch a fixture',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.3),
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            itemCount: fixtureManager.patchedFixtures.length,
                            itemBuilder: (context, index) {
                              final fixture = fixtureManager.patchedFixtures[index];
                              return _PatchedFixtureCard(
                                fixture: fixture,
                                onUnpatch: () {
                                  fixtureManager.unpatchFixture(fixture.id);
                                },
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  // Manuel Fixture Oluşturma Dialog'u
  void _showManualFixtureDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const _ManualFixtureDialog(),
    );
  }
  
  void _showPatchDialog(BuildContext context, Fixture fixture) {
    final fixtureManager = context.read<FixtureManager>();
    final nextFreeAddress = _findNextFreeAddress(fixtureManager, fixture.channelCount);
    final controller = TextEditingController(text: nextFreeAddress.toString());
    
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: const Color(0xFF1A1F3A),
        child: Container(
          width: 700,
          height: 600,
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Başlık
              Row(
                children: [
                  const Icon(Icons.lightbulb, color: Color(0xFF00D9FF), size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          fixture.name,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          '${fixture.manufacturer} • ${fixture.channelCount} channels',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.white54,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white54),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(color: Colors.white12, height: 30),
              
              // DMX Kanal Tablosu
              const Text(
                'DMX CHANNEL MAP (1-512)',
                style: TextStyle(
                  color: Color(0xFF00D9FF),
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 12),
              
              Expanded(
                child: _buildChannelMap(fixtureManager, fixture.channelCount, controller),
              ),
              
              const SizedBox(height: 16),
              
              // Adres girişi ve patch butonu
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: controller,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                      decoration: InputDecoration(
                        labelText: 'Start Address',
                        labelStyle: const TextStyle(color: Colors.white70),
                        hintText: 'Enter 1-512',
                        hintStyle: const TextStyle(color: Colors.white24),
                        prefixIcon: const Icon(Icons.pin_drop, color: Color(0xFF00D9FF)),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.auto_fix_high, color: Color(0xFFFF6B35)),
                          tooltip: 'Auto-find next free address',
                          onPressed: () {
                            controller.text = _findNextFreeAddress(fixtureManager, fixture.channelCount).toString();
                          },
                        ),
                        filled: true,
                        fillColor: const Color(0xFF0A0E27),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Colors.white24),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFF00D9FF), width: 2),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00D9FF),
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.add_circle),
                    label: const Text('PATCH', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    onPressed: () {
                      final address = int.tryParse(controller.text);
                      if (address != null && address >= 1 && address <= 512) {
                        try {
                          fixtureManager.patchFixture(fixture, address);
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('✓ ${fixture.name} patched to Ch $address-${address + fixture.channelCount - 1}'),
                              backgroundColor: const Color(0xFF00D9FF),
                            ),
                          );
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(e.toString()),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
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
  
  // DMX Kanal haritası widget'ı
  Widget _buildChannelMap(FixtureManager manager, int fixtureChannelCount, TextEditingController controller) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0A0E27),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        children: [
          // Tablo başlığı
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            decoration: const BoxDecoration(
              color: Color(0xFF10141D),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                const Expanded(
                  flex: 2,
                  child: Text('CHANNEL', style: TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.bold)),
                ),
                const Expanded(
                  flex: 3,
                  child: Text('FIXTURE', style: TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.bold)),
                ),
                const Expanded(
                  flex: 2,
                  child: Text('MANUFACTURER', style: TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.bold)),
                ),
                Expanded(
                  flex: 1,
                  child: Container(),
                ),
              ],
            ),
          ),
          
          // Kanal listesi
          Expanded(
            child: ListView.builder(
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
                
                return InkWell(
                  onTap: isFree ? () {
                    controller.text = channel.toString();
                  } : null,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                    decoration: BoxDecoration(
                      color: isInSelectedRange 
                          ? const Color(0xFF00D9FF).withOpacity(0.2)
                          : (isOccupied 
                              ? Colors.red.withOpacity(0.1) 
                              : Colors.transparent),
                      border: Border(
                        bottom: BorderSide(color: Colors.white.withOpacity(0.05)),
                      ),
                    ),
                    child: Row(
                      children: [
                        // Kanal numarası
                        Expanded(
                          flex: 2,
                          child: Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isInSelectedRange 
                                      ? const Color(0xFF00D9FF)
                                      : (isOccupied ? Colors.red : Colors.green),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                channel.toString().padLeft(3, '0'),
                                style: TextStyle(
                                  color: isInSelectedRange 
                                      ? const Color(0xFF00D9FF)
                                      : (isOccupied ? Colors.red.shade300 : Colors.green.shade300),
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'monospace',
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        // Fixture adı
                        Expanded(
                          flex: 3,
                          child: Text(
                            isOccupied ? occupyingFixture.name : '—',
                            style: TextStyle(
                              color: isOccupied ? Colors.white : Colors.white24,
                              fontSize: 12,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        
                        // Manufacturer
                        Expanded(
                          flex: 2,
                          child: Text(
                            isOccupied ? occupyingFixture.manufacturer : 'FREE',
                            style: TextStyle(
                              color: isOccupied ? Colors.white54 : Colors.green.shade300,
                              fontSize: 11,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        
                        // Aksiyon
                        Expanded(
                          flex: 1,
                          child: isFree
                              ? IconButton(
                                  icon: const Icon(Icons.add_circle_outline, size: 18),
                                  color: const Color(0xFF00D9FF),
                                  onPressed: () {
                                    controller.text = channel.toString();
                                  },
                                  tooltip: 'Use this address',
                                )
                              : const SizedBox.shrink(),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
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
}

class _ManufacturerChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  
  const _ManufacturerChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });
  
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ActionChip(
        label: Text(label),
        backgroundColor: isSelected
            ? const Color(0xFF00D9FF)
            : const Color(0xFF1A1F3A),
        labelStyle: TextStyle(
          color: isSelected ? Colors.black : Colors.white70,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
        side: BorderSide(
          color: isSelected ? Colors.transparent : Colors.white12,
        ),
        onPressed: onTap,
      ),
    );
  }
}

class _FixtureLibraryCard extends StatelessWidget {
  final Fixture fixture;
  final VoidCallback onPatch;
  
  const _FixtureLibraryCard({
    required this.fixture,
    required this.onPatch,
  });
  
  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      color: const Color(0xFF1A1F3A),
      child: ListTile(
        leading: const Icon(Icons.lightbulb_outline, color: Color(0xFF00D9FF)),
        title: Text(
          fixture.name,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Text(
          '${fixture.manufacturer} • ${fixture.channelCount} ch',
          style: TextStyle(color: Colors.white.withOpacity(0.6)),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.add_circle, color: Color(0xFF00D9FF)),
          onPressed: onPatch,
          tooltip: 'Patch fixture',
        ),
      ),
    );
  }
}

class _PatchedFixtureCard extends StatelessWidget {
  final Fixture fixture;
  final VoidCallback onUnpatch;
  
  const _PatchedFixtureCard({
    required this.fixture,
    required this.onUnpatch,
  });
  
  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      color: const Color(0xFF0A0E27),
      child: ListTile(
        leading: const Icon(Icons.lightbulb, color: Color(0xFFFF6B35)),
        title: Text(
          fixture.name,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Text(
          'Ch ${fixture.startAddress} - ${fixture.startAddress! + fixture.channelCount - 1}',
          style: TextStyle(color: Colors.white.withOpacity(0.6)),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.remove_circle, color: Colors.red),
          onPressed: onUnpatch,
          tooltip: 'Unpatch fixture',
        ),
      ),
    );
  }
}


// Manuel Fixture Oluşturma Dialog Widget'ı
class _ManualFixtureDialog extends StatefulWidget {
  const _ManualFixtureDialog();

  @override
  State<_ManualFixtureDialog> createState() => _ManualFixtureDialogState();
}

class _ManualFixtureDialogState extends State<_ManualFixtureDialog> {
  final TextEditingController _nameController = TextEditingController(text: "Yeni Cihaz");
  final TextEditingController _manufacturerController = TextEditingController(text: "Manuel");
  String? _selectedTemplate;
  
  // Hızlı şablonlar
  final Map<String, List<Map<String, String>>> _templates = {
    "RGB Par (3ch)": [
      {"name": "Red", "type": "red"},
      {"name": "Green", "type": "green"},
      {"name": "Blue", "type": "blue"},
    ],
    "RGBW Par (4ch)": [
      {"name": "Red", "type": "red"},
      {"name": "Green", "type": "green"},
      {"name": "Blue", "type": "blue"},
      {"name": "White", "type": "white"},
    ],
    "RGBWA Par (5ch)": [
      {"name": "Red", "type": "red"},
      {"name": "Green", "type": "green"},
      {"name": "Blue", "type": "blue"},
      {"name": "White", "type": "white"},
      {"name": "Amber", "type": "amber"},
    ],
    "RGBWAU Par (6ch)": [
      {"name": "Red", "type": "red"},
      {"name": "Green", "type": "green"},
      {"name": "Blue", "type": "blue"},
      {"name": "White", "type": "white"},
      {"name": "Amber", "type": "amber"},
      {"name": "UV", "type": "uv"},
    ],
    "Moving Head Basic (8ch)": [
      {"name": "Pan", "type": "pan"},
      {"name": "Tilt", "type": "tilt"},
      {"name": "Dimmer", "type": "dimmer"},
      {"name": "Strobe", "type": "strobe"},
      {"name": "Red", "type": "red"},
      {"name": "Green", "type": "green"},
      {"name": "Blue", "type": "blue"},
      {"name": "White", "type": "white"},
    ],
    "Moving Head Pro (16ch)": [
      {"name": "Pan", "type": "pan"},
      {"name": "Pan Fine", "type": "panFine"},
      {"name": "Tilt", "type": "tilt"},
      {"name": "Tilt Fine", "type": "tiltFine"},
      {"name": "Dimmer", "type": "dimmer"},
      {"name": "Strobe", "type": "strobe"},
      {"name": "Red", "type": "red"},
      {"name": "Green", "type": "green"},
      {"name": "Blue", "type": "blue"},
      {"name": "White", "type": "white"},
      {"name": "Color Wheel", "type": "colorWheel"},
      {"name": "Gobo", "type": "gobo"},
      {"name": "Focus", "type": "focus"},
      {"name": "Zoom", "type": "zoom"},
      {"name": "Speed", "type": "speed"},
      {"name": "Reset", "type": "reset"},
    ],
    "Dimmer (1ch)": [
      {"name": "Dimmer", "type": "dimmer"},
    ],
    "Strobe (2ch)": [
      {"name": "Dimmer", "type": "dimmer"},
      {"name": "Strobe", "type": "strobe"},
    ],
  };

  List<FixtureChannel> _channels = [];

  @override
  void dispose() {
    _nameController.dispose();
    _manufacturerController.dispose();
    super.dispose();
  }

  void _applyTemplate(String templateName) {
    final template = _templates[templateName];
    if (template == null) return;

    setState(() {
      _channels = template.asMap().entries.map((entry) {
        final index = entry.key;
        final ch = entry.value;
        return FixtureChannel(
          offset: index,
          name: ch['name']!,
          type: _stringToChannelType(ch['type']!),
        );
      }).toList();
    });
  }

  ChannelType _stringToChannelType(String typeStr) {
    try {
      return ChannelType.values.firstWhere(
        (e) => e.name.toLowerCase() == typeStr.toLowerCase(),
        orElse: () => ChannelType.generic,
      );
    } catch (e) {
      return ChannelType.generic;
    }
  }

  void _saveFixture() {
    if (_channels.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lütfen bir şablon seçin!'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final fixtureManager = context.read<FixtureManager>();
    
    final newFixture = Fixture(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: _nameController.text.isEmpty ? "İsimsiz Cihaz" : _nameController.text,
      manufacturer: _manufacturerController.text.isEmpty ? "Manuel" : _manufacturerController.text,
      channelCount: _channels.length,
      channels: _channels,
    );

    // Fixture'ı kütüphaneye ekle
    fixtureManager.fixtureLibrary.add(newFixture);
    
    Navigator.pop(context);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('✓ ${newFixture.name} kütüphaneye eklendi!'),
        backgroundColor: const Color(0xFF00D9FF),
        action: SnackBarAction(
          label: 'PATCH ET',
          textColor: Colors.black,
          onPressed: () {
            // Patch dialog'unu aç
            _showPatchDialogForNewFixture(context, newFixture);
          },
        ),
      ),
    );
  }

  void _showPatchDialogForNewFixture(BuildContext context, Fixture fixture) {
    // Parent widget'ın _showPatchDialog metodunu çağırmak için
    // Burada basit bir çözüm: fixture'ı ekledikten sonra kullanıcı manuel olarak patch edebilir
    // Veya daha gelişmiş bir callback sistemi kurulabilir
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF1A1F3A),
      child: Container(
        width: 600,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Başlık
            Row(
              children: [
                const Icon(Icons.build, color: Color(0xFFFF6B35), size: 28),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Manuel Fixture Oluştur',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white54),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Hızlı şablon seçerek fixture oluşturun',
              style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 14),
            ),
            const Divider(color: Colors.white12, height: 32),
            
            // Cihaz Adı
            TextField(
              controller: _nameController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Cihaz Adı',
                labelStyle: const TextStyle(color: Colors.white70),
                hintText: 'Örn: LED Par 64',
                hintStyle: const TextStyle(color: Colors.white24),
                prefixIcon: const Icon(Icons.lightbulb, color: Color(0xFF00D9FF)),
                filled: true,
                fillColor: const Color(0xFF0A0E27),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.white24),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF00D9FF), width: 2),
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Üretici Adı
            TextField(
              controller: _manufacturerController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Üretici / Marka',
                labelStyle: const TextStyle(color: Colors.white70),
                hintText: 'Örn: Generic, Chauvet, vb.',
                hintStyle: const TextStyle(color: Colors.white24),
                prefixIcon: const Icon(Icons.business, color: Color(0xFFFF6B35)),
                filled: true,
                fillColor: const Color(0xFF0A0E27),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.white24),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFFF6B35), width: 2),
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Şablon Seçimi
            const Text(
              'ŞABLON SEÇİN',
              style: TextStyle(
                color: Color(0xFF00D9FF),
                fontWeight: FontWeight.bold,
                fontSize: 12,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 12),
            
            Container(
              constraints: const BoxConstraints(maxHeight: 300),
              child: GridView.builder(
                shrinkWrap: true,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 3,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemCount: _templates.length,
                itemBuilder: (context, index) {
                  final templateName = _templates.keys.elementAt(index);
                  final isSelected = _selectedTemplate == templateName;
                  
                  return InkWell(
                    onTap: () {
                      setState(() {
                        _selectedTemplate = templateName;
                        _applyTemplate(templateName);
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isSelected 
                            ? const Color(0xFF00D9FF).withOpacity(0.2)
                            : const Color(0xFF0A0E27),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isSelected 
                              ? const Color(0xFF00D9FF)
                              : Colors.white12,
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            templateName,
                            style: TextStyle(
                              color: isSelected ? const Color(0xFF00D9FF) : Colors.white,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              fontSize: 13,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          if (isSelected) ...[
                            const SizedBox(height: 4),
                            const Icon(
                              Icons.check_circle,
                              color: Color(0xFF00D9FF),
                              size: 16,
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Seçili Şablon Bilgisi
            if (_channels.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF0A0E27),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF00D9FF).withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.info_outline, color: Color(0xFF00D9FF), size: 18),
                        const SizedBox(width: 8),
                        Text(
                          '${_channels.length} Kanal',
                          style: const TextStyle(
                            color: Color(0xFF00D9FF),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: _channels.map((ch) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'Ch${ch.offset + 1}: ${ch.name}',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 11,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
            
            // Kaydet Butonu
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00D9FF),
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.save),
                label: const Text(
                  'KÜTÜPHANEYE EKLE',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    letterSpacing: 1,
                  ),
                ),
                onPressed: _saveFixture,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
