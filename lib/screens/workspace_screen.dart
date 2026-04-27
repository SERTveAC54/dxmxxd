import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/fixture_manager.dart';
import '../services/dmx_engine.dart';
import '../models/fixture.dart';

class WorkspaceScreen extends StatefulWidget {
  const WorkspaceScreen({super.key});

  @override
  State<WorkspaceScreen> createState() => _WorkspaceScreenState();
}

class _WorkspaceScreenState extends State<WorkspaceScreen> {
  final Set<String> _selectedFixtureIds = {};
  String _activeFilter = 'All';

  @override
  Widget build(BuildContext context) {
    final fixtureManager = context.watch<FixtureManager>();
    final dmxEngine = context.watch<DMXEngine>();

    // Filtreye göre cihazları listele
    final filteredFixtures = _activeFilter == 'All'
        ? fixtureManager.patchedFixtures
        : fixtureManager.patchedFixtures
            .where((f) => f.manufacturer == _activeFilter)
            .toList();

    return Scaffold(
      backgroundColor: const Color(0xFF05070A), // Saf siyah yakın arka plan
      appBar: _buildAppBar(),
      body: Row(
        children: [
          // 1. ANA ÇALIŞMA ALANI (GRID)
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
                      final fixture = filteredFixtures[index];
                      return _buildFixtureCell(fixture, dmxEngine);
                    },
                  ),
                ),
              ],
            ),
          ),

          // 2. SAĞ MASTER ŞERİDİ (Sadece seçim varsa)
          if (_selectedFixtureIds.isNotEmpty)
            _buildSideMaster(dmxEngine, fixtureManager),
        ],
      ),
    );
  }

  // --- UI BİLEŞENLERİ ---

  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: const Color(0xFF10141D),
      elevation: 0,
      title: const Text(
        'PROJECT WORKSPACE',
        style: TextStyle(
          letterSpacing: 1.2,
          fontSize: 16,
          fontWeight: FontWeight.w900,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => setState(() => _selectedFixtureIds.clear()),
          child: const Text(
            'DESELECT ALL',
            style: TextStyle(color: Colors.white54),
          ),
        ),
      ],
    );
  }

  Widget _buildGroupBar(FixtureManager manager) {
    final manufacturers = [
      'All',
      ...manager.fixtureLibrary.map((f) => f.manufacturer).toSet()
    ];

    return Container(
      height: 60,
      color: const Color(0xFF10141D),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        children: manufacturers
            .map((m) => Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: ChoiceChip(
                    label: Text(m),
                    selected: _activeFilter == m,
                    onSelected: (val) => setState(() => _activeFilter = m),
                    selectedColor: const Color(0xFF00D9FF),
                    backgroundColor: const Color(0xFF1C222D),
                  ),
                ))
            .toList(),
      ),
    );
  }

  Widget _buildFixtureCell(Fixture fixture, DMXEngine dmx) {
    final bool isSelected = _selectedFixtureIds.contains(fixture.id);

    // Cihazın rengini ve parlaklığını motor üzerinden anlık al
    final Color liveColor = _getFixtureLiveColor(fixture, dmx);
    final double intensity = _getFixtureIntensity(fixture, dmx);

    return GestureDetector(
      onTap: () {
        setState(() {
          if (isSelected) {
            _selectedFixtureIds.remove(fixture.id);
          } else {
            _selectedFixtureIds.add(fixture.id);
          }
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
            // Cihazın ışığına göre dışa parlama (Glow)
            BoxShadow(
              color: liveColor.withOpacity(intensity * 0.4),
              blurRadius: isSelected ? 15 : 5,
              spreadRadius: isSelected ? 2 : 0,
            )
          ],
        ),
        child: Stack(
          children: [
            // PARLAKLIK DOLGUSU (Luminair tarzı hücre içi dolgu)
            Align(
              alignment: Alignment.bottomCenter,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                height: 100 * intensity, // Parlaklık kadar yükselen bar
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      liveColor.withOpacity(0.6),
                      liveColor.withOpacity(0.1)
                    ],
                  ),
                ),
              ),
            ),

            // CİHAZ BİLGİLERİ
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    fixture.name,
                    maxLines: 1,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'CH: ${fixture.startAddress}',
                    style: const TextStyle(
                      fontSize: 9,
                      color: Colors.white38,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSideMaster(DMXEngine dmx, FixtureManager manager) {
    return Container(
      width: 80,
      color: const Color(0xFF10141D),
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Column(
        children: [
          const Text(
            'MASTER',
            style: TextStyle(fontSize: 10, color: Colors.white38),
          ),
          const Expanded(
            child: RotatedBox(
              quarterTurns: 3,
              child: Slider(
                value: 0.5,
                onChanged: null,
              ), // Buraya toplu kontrol eklenecek
            ),
          ),
          IconButton(
            icon: const Icon(Icons.tune, color: Color(0xFF00D9FF)),
            onPressed: () {},
          ),
        ],
      ),
    );
  }

  // --- MOTOR YARDIMCI FONKSİYONLARI ---

  Color _getFixtureLiveColor(Fixture f, DMXEngine dmx) {
    // RGB kanallarını bul ve DMX değerlerini al
    final rCh = f.channels.where((c) => c.type == ChannelType.red).firstOrNull;
    final gCh = f.channels.where((c) => c.type == ChannelType.green).firstOrNull;
    final bCh = f.channels.where((c) => c.type == ChannelType.blue).firstOrNull;

    if (rCh == null) return Colors.white; // RGB değilse beyaz göster

    return Color.fromARGB(
      255,
      dmx.getChannel(f.startAddress! + rCh.offset),
      dmx.getChannel(f.startAddress! + gCh.offset),
      dmx.getChannel(f.startAddress! + bCh.offset),
    );
  }

  double _getFixtureIntensity(Fixture f, DMXEngine dmx) {
    final dimCh = f.channels.where((c) => c.type == ChannelType.dimmer).firstOrNull;
    if (dimCh == null) return 1.0;
    return dmx.getChannel(f.startAddress! + dimCh.offset) / 255.0;
  }
}
