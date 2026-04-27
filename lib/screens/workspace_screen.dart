import 'package:flutter/material.dart';

class WorkspaceScreen extends StatefulWidget {
  const WorkspaceScreen({super.key});

  @override
  State<WorkspaceScreen> createState() => _WorkspaceScreenState();
}

class _WorkspaceScreenState extends State<WorkspaceScreen> {
  // Sahnedeki tüm yamalanmış cihazların (örnek) listesi
  final List<Map<String, dynamic>> _fixtures = [
    {'id': '1', 'name': 'Beam 7R 1', 'type': 'Spot', 'address': 1},
    {'id': '2', 'name': 'Beam 7R 2', 'type': 'Spot', 'address': 17},
    {'id': '3', 'name': 'Wash 36x10 1', 'type': 'Wash', 'address': 33},
    {'id': '4', 'name': 'Wash 36x10 2', 'type': 'Wash', 'address': 45},
    {'id': '5', 'name': 'Front LED 1', 'type': 'Generic', 'address': 100},
  ];

  // Aktif olarak seçili olan cihazların ID'lerini tuttuğumuz set (Multi-select için)
  final Set<String> _selectedFixtureIds = {};

  // Üst menüdeki aktif grup filtresi
  String _activeGroup = 'All';

  // Seçim işlemini yöneten fonksiyon
  void _toggleSelection(String id) {
    setState(() {
      if (_selectedFixtureIds.contains(id)) {
        _selectedFixtureIds.remove(id);
      } else {
        _selectedFixtureIds.add(id);
      }
    });
  }

  // Gruba göre seçim yapma fonksiyonu
  void _selectGroup(String group) {
    setState(() {
      _activeGroup = group;
      _selectedFixtureIds.clear(); // Önceki seçimleri temizle
      
      if (group == 'All') {
        _selectedFixtureIds.addAll(_fixtures.map((f) => f['id'] as String));
      } else {
        _selectedFixtureIds.addAll(
          _fixtures
              .where((f) => f['type'] == group)
              .map((f) => f['id'] as String)
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E27), // Derin karanlık arka plan
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1F3A),
        elevation: 0,
        title: const Text(
          'DMX Workspace',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.clear_all),
            onPressed: () => setState(() => _selectedFixtureIds.clear()),
            tooltip: 'Seçimleri Temizle',
          ),
        ],
      ),
      body: Column(
        children: [
          // 1. ÜST BÖLÜM: GRUPLAMA BUTONLARI (CHIPS)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            color: const Color(0xFF1A1F3A),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildGroupChip('All'),
                  _buildGroupChip('Spot'),
                  _buildGroupChip('Wash'),
                  _buildGroupChip('Generic'),
                ],
              ),
            ),
          ),

          // 2. ORTA BÖLÜM: CİHAZ KARTLARI (GRID)
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3, // Tablette bu sayı artırılabilir
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.1,
              ),
              itemCount: _fixtures.length,
              itemBuilder: (context, index) {
                final fixture = _fixtures[index];
                final isSelected = _selectedFixtureIds.contains(fixture['id']);

                return GestureDetector(
                  onTap: () => _toggleSelection(fixture['id']),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFF00D9FF).withOpacity(0.15)
                          : const Color(0xFF1A1F3A),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFF00D9FF)
                            : Colors.white12,
                        width: isSelected ? 2 : 1,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: const Color(0xFF00D9FF).withOpacity(0.3),
                                blurRadius: 8,
                              )
                            ]
                          : [],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.lightbulb_circle,
                          color: isSelected
                              ? const Color(0xFF00D9FF)
                              : Colors.white54,
                          size: 32,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          fixture['name'],
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.white70,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Ch: ${fixture['address']}',
                          style: const TextStyle(
                            color: Colors.white38,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // 3. ALT BÖLÜM: KONTROL PANELİ (Sadece cihaz seçiliyse görünür)
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            height: _selectedFixtureIds.isNotEmpty ? 80 : 0,
            decoration: const BoxDecoration(
              color: Color(0xFF1A1F3A),
              border: Border(top: BorderSide(color: Colors.white12)),
            ),
            child: SingleChildScrollView(
              physics: const NeverScrollableScrollPhysics(),
              child: SizedBox(
                height: 80,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Text(
                      '${_selectedFixtureIds.length} Cihaz Seçili',
                      style: const TextStyle(
                        color: Color(0xFF00D9FF),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () {
                        // TODO: Renk, XY Pad ve Efekt motorunun olduğu Modal Bottom Sheet açılacak
                        _showControlPanel();
                      },
                      icon: const Icon(Icons.tune, color: Colors.black),
                      label: const Text(
                        'Kontrol Et',
                        style: TextStyle(color: Colors.black),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00D9FF),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Gruplama butonu üreten yardımcı widget
  Widget _buildGroupChip(String label) {
    final isActive = _activeGroup == label;
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: ActionChip(
        label: Text(label),
        backgroundColor: isActive
            ? const Color(0xFFFF6B35)
            : const Color(0xFF0A0E27),
        labelStyle: TextStyle(
          color: isActive ? Colors.white : Colors.white70,
          fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
        ),
        side: BorderSide(
          color: isActive ? Colors.transparent : Colors.white12,
        ),
        onPressed: () => _selectGroup(label),
      ),
    );
  }

  // Kontrol panelini açan fonksiyon
  void _showControlPanel() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1F3A),
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Handle bar
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Text(
                '${_selectedFixtureIds.length} Cihaz Kontrolü',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF00D9FF),
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  children: [
                    const Text(
                      'Kontrol paneli yakında eklenecek...',
                      style: TextStyle(color: Colors.white70),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      '• XY Pad (Pan/Tilt)\n• Color Picker\n• Dimmer Slider\n• Efekt Butonları',
                      style: TextStyle(color: Colors.white54),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
