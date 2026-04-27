import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/fixture_manager.dart';
import '../services/dmx_engine.dart';
import '../models/fixture.dart';
import '../widgets/xy_pad.dart';
import '../widgets/dmx_slider.dart';

class WorkspaceScreen extends StatefulWidget {
  const WorkspaceScreen({super.key});

  @override
  State<WorkspaceScreen> createState() => _WorkspaceScreenState();
}

class _WorkspaceScreenState extends State<WorkspaceScreen> {
  final Set<String> _selectedFixtureIds = {};
  String _activeGroupName = "Tüm Robotlar"; // Marka yerine grup ismi

  // Seçili gruba veya tümüne göre toplu kanal güncelleme
  void _updateGroupChannel(FixtureManager manager, DMXEngine dmx, ChannelType type, int value) {
    for (var id in _selectedFixtureIds) {
      final fix = manager.patchedFixtures.firstWhere((f) => f.id == id);
      final ch = fix.channels.where((c) => c.type == type).firstOrNull;
      if (ch != null && fix.startAddress != null) {
        dmx.setChannel(fix.startAddress! + ch.offset, value);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final fixtureManager = context.watch<FixtureManager>();
    final dmxEngine = context.watch<DMXEngine>();

    return Scaffold(
      backgroundColor: const Color(0xFF05070A),
      body: Column(
        children: [
          // 1. ÜST BÖLÜM: ANA ÇALIŞMA ALANI (CIHAZ KUTUCUKLARI)
          Expanded(
            flex: 3,
            child: GridView.builder(
              padding: const EdgeInsets.all(20),
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 130,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1,
              ),
              itemCount: fixtureManager.patchedFixtures.length,
              itemBuilder: (context, index) {
                final fixture = fixtureManager.patchedFixtures[index];
                final isSelected = _selectedFixtureIds.contains(fixture.id);
                return _buildFixtureCell(fixture, isSelected, dmxEngine);
              },
            ),
          ),

          // 2. ORTA BÖLÜM: GENİŞ SLIDER VE GÖREV ALANI (ATTRIBUTES)
          if (_selectedFixtureIds.isNotEmpty)
            Expanded(
              flex: 2,
              child: Container(
                color: const Color(0xFF0F121A),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: _buildLargeControlPanel(fixtureManager, dmxEngine),
              ),
            ),

          // 3. ALT BÖLÜM: BİLGİ VE GRUP BARI (BAR)
          _buildInfoBar(fixtureManager),
        ],
      ),
    );
  }

  // İSTEDİĞİN ÖZEL BAR YAPISI
  Widget _buildInfoBar(FixtureManager manager) {
    return Container(
      height: 55,
      decoration: const BoxDecoration(
        color: Color(0xFF1A1F3A),
        border: Border(top: BorderSide(color: Colors.white12)),
      ),
      child: Row(
        children: [
          // EN SOLDA DEĞİŞTİRİLEBİLİR GRUP KUTUCUĞU
          GestureDetector(
            onTap: () {
              // Burada grup seçimi veya isim verme diyaloğu açılabilir
            },
            child: Container(
              width: 120,
              color: const Color(0xFF00D9FF).withOpacity(0.2),
              alignment: Alignment.center,
              child: Text(
                _activeGroupName.toUpperCase(),
                style: const TextStyle(color: Color(0xFF00D9FF), fontWeight: FontWeight.bold, fontSize: 11),
              ),
            ),
          ),
          
          // İNCE ÇİZGİ
          Container(width: 1, color: Colors.white24, margin: const EdgeInsets.symmetric(vertical: 10)),

          // SEÇİLMİŞ ROBOTLARIN ÖZETİ
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: _selectedFixtureIds.isEmpty 
                ? const Text("LÜTFEN ROBOT SEÇİN", style: TextStyle(color: Colors.white24, fontSize: 10))
                : ListView(
                    scrollDirection: Axis.horizontal,
                    children: _selectedFixtureIds.map((id) {
                      final name = manager.patchedFixtures.firstWhere((f) => f.id == id).name;
                      return Center(
                        child: Container(
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(4)),
                          child: Text(name, style: const TextStyle(color: Colors.white70, fontSize: 10)),
                        ),
                      );
                    }).toList(),
                  ),
            ),
          ),
        ],
      ),
    );
  }

  // DAHA BÜYÜK VE GENİŞ KONTROL PANELİ
  Widget _buildLargeControlPanel(FixtureManager manager, DMXEngine dmx) {
    final refFixture = manager.patchedFixtures.firstWhere((f) => f.id == _selectedFixtureIds.first);
    
    // Pan/Tilt ve RGB dışındaki kanallar
    final sliderChannels = refFixture.channels.where((c) => 
       c.type != ChannelType.pan && c.type != ChannelType.tilt && 
       c.type != ChannelType.red && c.type != ChannelType.green && c.type != ChannelType.blue
    ).toList();

    return Row(
      children: [
        // DAHA BÜYÜK XY PAD
        SizedBox(
          width: 220,
          child: XYPad(
            onChanged: (x, y) {
              _updateGroupChannel(manager, dmx, ChannelType.pan, (x * 255).round());
              _updateGroupChannel(manager, dmx, ChannelType.tilt, (y * 255).round());
            },
          ),
        ),
        const VerticalDivider(color: Colors.white10, indent: 10, endIndent: 10),
        
        // DAHA GENİŞ SLIDERLAR
        Expanded(
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: sliderChannels.length,
            itemBuilder: (context, index) {
              final ch = sliderChannels[index];
              return Container(
                width: 100, // Slider genişliğini artırdım
                margin: const EdgeInsets.symmetric(horizontal: 4),
                child: DMXSlider(
                  label: ch.name.toUpperCase(),
                  value: dmx.getChannel(refFixture.startAddress! + ch.offset) / 255.0,
                  onChanged: (val) => _updateGroupChannel(manager, dmx, ch.type, (val * 255).round()),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFixtureCell(Fixture fixture, bool isSelected, DMXEngine dmx) {
    return GestureDetector(
      onTap: () {
        setState(() {
          if (isSelected) _selectedFixtureIds.remove(fixture.id);
          else _selectedFixtureIds.add(fixture.id);
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF1A1F3A) : const Color(0xFF11141D),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: isSelected ? const Color(0xFF00D9FF) : Colors.white10, width: isSelected ? 2 : 1),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.lightbulb, color: isSelected ? const Color(0xFF00D9FF) : Colors.white24, size: 24),
            const SizedBox(height: 5),
            Text(fixture.name, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
            Text("CH: ${fixture.startAddress}", style: const TextStyle(fontSize: 9, color: Colors.white38)),
          ],
        ),
      ),
    );
  }
}