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
  
  void _showPatchDialog(BuildContext context, Fixture fixture) {
    final controller = TextEditingController(text: '1');
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1F3A),
        title: Text('Patch ${fixture.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Manufacturer: ${fixture.manufacturer}'),
            Text('Channels: ${fixture.channelCount}'),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Start Address (1-512)',
                labelStyle: TextStyle(color: Colors.white70),
                border: OutlineInputBorder(),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.white24),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFF00D9FF)),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00D9FF),
              foregroundColor: Colors.black,
            ),
            onPressed: () {
              final address = int.tryParse(controller.text);
              if (address != null && address >= 1 && address <= 512) {
                try {
                  context.read<FixtureManager>().patchFixture(fixture, address);
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${fixture.name} patched to Ch $address'),
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
            child: const Text('Patch'),
          ),
        ],
      ),
    );
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
