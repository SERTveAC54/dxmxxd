import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/fixture_manager.dart';
import '../services/dmx_engine.dart';
import '../models/fixture.dart';
import '../widgets/xy_pad.dart';
import '../widgets/dmx_slider.dart';
import '../widgets/color_picker.dart';

class WorkspaceScreen extends StatefulWidget {
  const WorkspaceScreen({super.key});

  @override
  State<WorkspaceScreen> createState() => _WorkspaceScreenState();
}

class _WorkspaceScreenState extends State<WorkspaceScreen> {
  final Set<String> _selectedFixtureIds = {};
  String _activeFilter = 'All';

  // Seçili tüm cihazların aynı kanal tipini (Örn: Pan) aynı anda güncelleyen motor
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
    
    final filteredFixtures = _activeFilter == 'All' 
        ? fixtureManager.patchedFixtures 
        : fixtureManager.patchedFixtures.where((f) => f.manufacturer == _activeFilter).toList();

    return Scaffold(
      backgroundColor: const Color(0xFF05070A),
      appBar: _buildAppBar(),
      body: Column(
        children: [
          // 1. ÜST KISIM: GRID VE MASTER SIDER
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      _buildGroupBar(fixtureManager),
                      Expanded(
                        child: GridView.builder(
                          padding: const EdgeInsets.all(20),
                          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                            maxCrossAxisExtent: 140,
                            crossAxisSpacing: 15,
                            mainAxisSpacing: 15,
                            childAspectRatio: 0.9,
                          ),
                          itemCount: filteredFixtures.length,
                          itemBuilder: (context, index) {
                            return _buildFixtureCell(filteredFixtures[index], dmxEngine);
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                if (_selectedFixtureIds.isNotEmpty) _buildSideMaster(dmxEngine, fixtureManager),
              ],
            ),
          ),
          
          // 2. ALT KISIM: KONTROL PANELİ (Sadece seçim yapılınca alttan çıkar)
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            height: _selectedFixtureIds.isNotEmpty ? 220 : 0,
            decoration: const BoxDecoration(
              color: Color(0xFF10141D),
              border: Border(top: BorderSide(color: Colors.white12, width: 2)),
            ),
            child: SingleChildScrollView(
              physics: const NeverScrollableScrollPhysics(),
              child: _selectedFixtureIds.isNotEmpty 
                  ? _buildBottomControlPanel(fixtureManager, dmxEngine) 
                  : const SizedBox.shrink(),
            ),
          ),
        ],
      ),
    );
  }

  // --- ALT KONTROL PANELİ (XY PAD VE SLIDERLAR) ---
  Widget _buildBottomControlPanel(FixtureManager manager, DMXEngine dmx) {
    // Arayüzü çizmek için seçili ilk cihazı referans alıyoruz
    final refFixture = manager.patchedFixtures.firstWhere((f) => f.id == _selectedFixtureIds.first);
    
    final hasPan = refFixture.channels.any((c) => c.type == ChannelType.pan);
    final hasRgb = refFixture.channels.any((c) => c.type == ChannelType.red);

    // Pan, Tilt ve RGB dışındaki tüm kanalları Slider olarak listele
    final sliderChannels = refFixture.channels.where((c) => 
       c.type != ChannelType.pan && c.type != ChannelType.tilt && 
       c.type != ChannelType.panFine && c.type != ChannelType.tiltFine && 
       c.type != ChannelType.red && c.type != ChannelType.green && c.type != ChannelType.blue
    ).toList();

    return Container(
      height: 220,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // XY PAD (Moving Head'ler için)
          if (hasPan) ...[
            SizedBox(
              width: 200,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('PAN / TILT', style: TextStyle(color: Color(0xFF00D9FF), fontWeight: FontWeight.bold, fontSize: 12)),
                  const SizedBox(height: 10),
                  Expanded(
                    child: XYPad(
                      onChanged: (x, y) {
                        _updateGroupChannel(manager, dmx, ChannelType.pan, (x * 255).round());
                        _updateGroupChannel(manager, dmx, ChannelType.tilt, (y * 255).round());
                      },
                    ),
                  ),
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: VerticalDivider(color: Colors.white12, width: 1),
            ),
          ],

          // SLIDER BÖLÜMÜ (Gobo, Prism, Color Wheel, Frost vb.)
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('ATTRIBUTES', style: TextStyle(color: Color(0xFF00D9FF), fontWeight: FontWeight.bold, fontSize: 12)),
                const SizedBox(height: 10),
                Expanded(
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: sliderChannels.length,
                    itemBuilder: (context, index) {
                      final ch = sliderChannels[index];
                      final currentVal = dmx.getChannel(refFixture.startAddress! + ch.offset) / 255.0;
                      
                      return SizedBox(
                        width: 80,
                        child: DMXSlider(
                          label: ch.name,
                          value: currentVal,
                          onChanged: (val) {
                            _updateGroupChannel(manager, dmx, ch.type, (val * 255).round());
                          },
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- DİĞER UI BİLEŞENLERİ ---

  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: const Color(0xFF10141D),
      elevation: 0,
      title: const Text('WORKSPACE', style: TextStyle(letterSpacing: 1.2, fontSize: 16, fontWeight: FontWeight.w900)),
      actions: [
        if (_selectedFixtureIds.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Center(
              child: Text(
                '${_selectedFixtureIds.length} SELECTED',
                style: const TextStyle(color: Color(0xFFFF6B35), fontWeight: FontWeight.bold),
              ),
            ),
          ),
        TextButton(
          onPressed: () => setState(() => _selectedFixtureIds.clear()),
          child: const Text('CLEAR', style: TextStyle(color: Colors.white54)),
        ),
      ],
    );
  }

  Widget _buildGroupBar(FixtureManager manager) {
    final manufacturers = ['All', ...manager.patchedFixtures.map((f) => f.manufacturer).toSet()];
    return Container(
      height: 60,
      color: const Color(0xFF10141D),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        children: manufacturers.map((m) => Padding(
          padding: const EdgeInsets.all(8.0),
          child: ChoiceChip(
            label: Text(m),
            selected: _activeFilter == m,
            onSelected: (val) => setState(() => _activeFilter = m),
            selectedColor: const Color(0xFF00D9FF),
            backgroundColor: const Color(0xFF1C222D),
          ),
        )).toList(),
      ),
    );
  }

  Widget _buildFixtureCell(Fixture fixture, DMXEngine dmx) {
    final bool isSelected = _selectedFixtureIds.contains(fixture.id);
    final double intensity = _getFixtureIntensity(fixture, dmx);

    return GestureDetector(
      onTap: () {
        setState(() {
          if (isSelected) _selectedFixtureIds.remove(fixture.id);
          else _selectedFixtureIds.add(fixture.id);
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        decoration: BoxDecoration(
          color: const Color(0xFF1C222D),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: isSelected ? const Color(0xFF00D9FF) : Colors.transparent,
            width: 2,
          ),
          boxShadow: [
            if (isSelected)
              BoxShadow(
                color: const Color(0xFF00D9FF).withOpacity(0.3),
                blurRadius: 15,
                spreadRadius: 2,
              )
          ],
        ),
        child: Stack(
          children: [
            Align(
              alignment: Alignment.bottomCenter,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                height: 100 * intensity, 
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.white.withOpacity(0.4), Colors.white.withOpacity(0.05)],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(fixture.name, maxLines: 2, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                  const Spacer(),
                  Text('CH: ${fixture.startAddress}', style: const TextStyle(fontSize: 10, color: Colors.white54)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSideMaster(DMXEngine dmx, FixtureManager manager) {
    // Seçili cihazların ortak Dimmer kanal değerini göster/ayarla
    final refFixture = manager.patchedFixtures.firstWhere((f) => f.id == _selectedFixtureIds.first);
    final dimCh = refFixture.channels.where((c) => c.type == ChannelType.dimmer).firstOrNull;
    final currentDim = dimCh != null ? dmx.getChannel(refFixture.startAddress! + dimCh.offset) / 255.0 : 0.0;

    return Container(
      width: 80,
      color: const Color(0xFF10141D),
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Column(
        children: [
          const Text('DIM', style: TextStyle(fontSize: 12, color: Color(0xFF00D9FF), fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          Expanded(
            child: RotatedBox(
              quarterTurns: 3,
              child: Slider(
                value: currentDim, 
                onChanged: (val) {
                  _updateGroupChannel(manager, dmx, ChannelType.dimmer, (val * 255).round());
                }
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text('${(currentDim * 100).round()}%', style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  double _getFixtureIntensity(Fixture f, DMXEngine dmx) {
    final dimCh = f.channels.where((c) => c.type == ChannelType.dimmer).firstOrNull;
    if (dimCh == null) return 0.1;
    return (dmx.getChannel(f.startAddress! + dimCh.offset) / 255.0).clamp(0.1, 1.0);
  }
}