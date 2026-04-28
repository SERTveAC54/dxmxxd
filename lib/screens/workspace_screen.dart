import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/fixture_manager.dart';
import '../services/dmx_engine.dart';
import '../models/fixture.dart';
import '../widgets/xy_pad.dart';

// --- GRUP VERİ MODELİMİZ ---
class FixtureGroup {
  final String name;
  final Set<String> fixtureIds;

  FixtureGroup({required this.name, required this.fixtureIds});
}

class WorkspaceScreen extends StatefulWidget {
  const WorkspaceScreen({super.key});

  @override
  State<WorkspaceScreen> createState() => _WorkspaceScreenState();
}

class _WorkspaceScreenState extends State<WorkspaceScreen> {
  final Set<String> _selectedFixtureIds = {};
  String _activeGroupName = "Manuel Seçim";
  bool _isSidebarOpen = false; 
  
  // KAYDIRMA İÇİN SCROLL KONTROLCÜSÜ EKLENDİ
  final ScrollController _scrollController = ScrollController();

  final List<FixtureGroup> _userGroups = [];

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _updateGroupChannel(FixtureManager manager, DMXEngine dmx, ChannelType type, int value) {
    for (var id in _selectedFixtureIds) {
      final fix = manager.patchedFixtures.firstWhere((f) => f.id == id);
      final ch = fix.channels.where((c) => c.type == type).firstOrNull;
      if (ch != null && fix.startAddress != null) {
        dmx.setChannel(fix.startAddress! + ch.offset, value);
      }
    }
  }

  void _toggleSidebar() {
    setState(() {
      _isSidebarOpen = !_isSidebarOpen;
    });
  }

  void _showCreateGroupDialog() {
    if (_selectedFixtureIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Önce gruba eklenecek robotları seçmelisin!"), backgroundColor: Colors.redAccent),
      );
      return;
    }

    final TextEditingController nameController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF151822),
          title: const Text("Yeni Grup Ekle", style: TextStyle(color: Colors.white)),
          content: TextField(
            controller: nameController,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              hintText: "Örn: Sahne Önü Washlar",
              hintStyle: TextStyle(color: Colors.white38),
              enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF00E5FF))),
              focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF00E5FF))),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("İPTAL", style: TextStyle(color: Colors.white54)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00E5FF)),
              onPressed: () {
                if (nameController.text.isNotEmpty) {
                  setState(() {
                    _userGroups.add(FixtureGroup(
                      name: nameController.text,
                      fixtureIds: Set.from(_selectedFixtureIds), 
                    ));
                    _activeGroupName = nameController.text;
                  });
                  Navigator.pop(context);
                }
              },
              child: const Text("KAYDET", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final fixtureManager = context.watch<FixtureManager>();
    final dmxEngine = context.watch<DMXEngine>();

    return Scaffold(
      backgroundColor: const Color(0xFF090A0F),
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                _buildTopInfoBar(),
                Expanded(
                  child: _selectedFixtureIds.isEmpty
                      ? _buildEmptyState()
                      : _buildControlConsole(fixtureManager, dmxEngine),
                ),
              ],
            ),

            if (_isSidebarOpen)
              GestureDetector(
                onTap: _toggleSidebar,
                child: Container(color: Colors.black.withOpacity(0.5)),
              ),

            AnimatedPositioned(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOutBack,
              left: _isSidebarOpen ? 0 : -320,
              top: 0,
              bottom: 0,
              width: 320,
              child: _buildSidebar(fixtureManager),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopInfoBar() {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF10121A),
        border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.05))),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.menu, color: Color(0xFF00E5FF), size: 28),
            onPressed: _toggleSidebar,
          ),
          const SizedBox(width: 16),
          Text(
            _activeGroupName.toUpperCase(),
            style: const TextStyle(color: Colors.white70, fontSize: 16, letterSpacing: 2, fontWeight: FontWeight.bold),
          ),
          const Spacer(),
          Row(
            children: [
              const Icon(Icons.circle, color: Colors.greenAccent, size: 12),
              const SizedBox(width: 8),
              const Text("DMX AKTİF", style: TextStyle(color: Colors.white54, fontSize: 12)),
              const SizedBox(width: 16),
              IconButton(icon: const Icon(Icons.settings, color: Colors.white54), onPressed: () {}),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildSidebar(FixtureManager manager) {
    Map<String, List<Fixture>> groupedFixtures = {};
    for (var f in manager.patchedFixtures) {
      groupedFixtures.putIfAbsent(f.name, () => []).add(f);
    }

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF151822),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.8), blurRadius: 20, offset: const Offset(5, 0))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            color: const Color(0xFF10121A),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Proje Gezgini", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                IconButton(icon: const Icon(Icons.close, color: Colors.white54), onPressed: _toggleSidebar)
              ],
            ),
          ),

          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 20, 16, 8),
                  child: Text("GRUPLAR", style: TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1)),
                ),
                
                ListTile(
                  leading: const Icon(Icons.add_box, color: Color(0xFF00E5FF)),
                  title: const Text("Yeni Grup Ekle", style: TextStyle(color: Color(0xFF00E5FF), fontWeight: FontWeight.bold)),
                  onTap: _showCreateGroupDialog,
                ),

                ..._userGroups.map((group) {
                  final isSelectedGroup = _activeGroupName == group.name;
                  return ListTile(
                    dense: true,
                    leading: Icon(Icons.folder, color: isSelectedGroup ? const Color(0xFF00E5FF) : Colors.white38, size: 20),
                    title: Text(group.name, style: TextStyle(color: isSelectedGroup ? Colors.white : Colors.white70, fontSize: 14)),
                    trailing: Text("${group.fixtureIds.length} Cihaz", style: const TextStyle(color: Colors.white38, fontSize: 10)),
                    tileColor: isSelectedGroup ? const Color(0xFF00E5FF).withOpacity(0.1) : Colors.transparent,
                    onTap: () {
                      setState(() {
                        _activeGroupName = group.name;
                        _selectedFixtureIds.clear();
                        _selectedFixtureIds.addAll(group.fixtureIds);
                      });
                    },
                  );
                }),

                const Divider(color: Colors.white12, height: 30),

                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 8, 16, 8),
                  child: Text("FİKSTÜRLER", style: TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1)),
                ),

                Theme(
                  data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                  child: Column(
                    children: groupedFixtures.entries.map((entry) {
                      String fixtureTypeName = entry.key; 
                      List<Fixture> fixturesOfType = entry.value;

                      return ExpansionTile(
                        iconColor: const Color(0xFF00E5FF),
                        collapsedIconColor: Colors.white54,
                        leading: const Icon(Icons.category, size: 20),
                        title: Text(
                          "$fixtureTypeName (${fixturesOfType.length})",
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14),
                        ),
                        children: fixturesOfType.map((fixture) {
                          final isSelected = _selectedFixtureIds.contains(fixture.id);
                          return _buildFixtureTile(fixture, isSelected);
                        }).toList(),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFixtureTile(Fixture fixture, bool isSelected) {
    return GestureDetector(
      onTap: () {
        setState(() {
          isSelected ? _selectedFixtureIds.remove(fixture.id) : _selectedFixtureIds.add(fixture.id);
          _activeGroupName = "Manuel Seçim"; 
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF00E5FF).withOpacity(0.15) : Colors.white.withOpacity(0.03),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isSelected ? const Color(0xFF00E5FF) : Colors.transparent, width: 1.5),
        ),
        child: Row(
          children: [
            Icon(Icons.lightbulb_outline, color: isSelected ? const Color(0xFF00E5FF) : Colors.white38, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    fixture.name,
                    style: TextStyle(color: isSelected ? Colors.white : Colors.white70, fontSize: 13, fontWeight: FontWeight.bold)
                  ),
                  const SizedBox(height: 2),
                  Text(
                    "Kanal: ${fixture.startAddress}",
                    style: TextStyle(color: isSelected ? Colors.white70 : Colors.white38, fontSize: 11)
                  ),
                ],
              ),
            ),
            if (isSelected) const Icon(Icons.check_circle, color: Color(0xFF00E5FF), size: 18),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.touch_app, size: 64, color: Colors.white.withOpacity(0.1)),
          const SizedBox(height: 16),
          Text("Kontrol etmek için sol üstteki menüden robot seçin", style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 16)),
        ],
      ),
    );
  }

  Widget _buildControlConsole(FixtureManager manager, DMXEngine dmx) {
    final refFixture = manager.patchedFixtures.firstWhere((f) => f.id == _selectedFixtureIds.first);
    final sliderChannels = refFixture.channels.where((c) => c.type != ChannelType.pan && c.type != ChannelType.tilt).toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch, 
        children: [
          // YATAY KAYDIRMA ÇUBUĞU (SCROLLBAR) VE LİSTE EKLENDİ
          Expanded(
            flex: 4, 
            child: RawScrollbar(
              controller: _scrollController,
              thumbColor: const Color(0xFF00E5FF).withOpacity(0.8), // Neon kaydırma çubuğu
              radius: const Radius.circular(8),
              thickness: 8,
              interactive: true, // Elle tutup çekilebilir
              padding: const EdgeInsets.only(bottom: 2),
              child: ListView.builder(
                controller: _scrollController,
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()), // Daha pürüzsüz kaydırma
                padding: const EdgeInsets.only(bottom: 16), // Alt boşluk Scrollbar'ın görünmesi için
                itemCount: sliderChannels.length,
                itemBuilder: (context, index) {
                  final ch = sliderChannels[index];
                  final value = dmx.getChannel(refFixture.startAddress! + ch.offset) / 255.0;
                  
                  Color faderColor = const Color(0xFF4A90E2);
                  if (ch.type == ChannelType.red) faderColor = Colors.redAccent;
                  if (ch.type == ChannelType.green) faderColor = Colors.greenAccent;
                  if (ch.type == ChannelType.blue) faderColor = Colors.blueAccent;
                  if (ch.name.toLowerCase().contains('dimmer')) faderColor = Colors.white;

                  return ProFader(
                    label: ch.name,
                    value: value,
                    activeColor: faderColor,
                    onChanged: (val) => _updateGroupChannel(manager, dmx, ch.type, (val * 255).round()),
                  );
                },
              ),
            ),
          ),
          
          Container(
            width: 280, 
            margin: const EdgeInsets.only(left: 24),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: const Color(0xFF151822), borderRadius: BorderRadius.circular(20)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("POZİSYON (XY)", style: TextStyle(color: Colors.white54, fontWeight: FontWeight.bold, letterSpacing: 1)),
                const SizedBox(height: 20),
                Expanded(
                  child: Center(
                    child: XYPad(
                      onChanged: (x, y) {
                        _updateGroupChannel(manager, dmx, ChannelType.pan, (x * 255).round());
                        _updateGroupChannel(manager, dmx, ChannelType.tilt, (y * 255).round());
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ProFader extends StatefulWidget {
  final String label;
  final double value; 
  final Color activeColor;
  final ValueChanged<double> onChanged;

  const ProFader({
    super.key,
    required this.label,
    required this.value,
    required this.activeColor,
    required this.onChanged,
  });

  @override
  State<ProFader> createState() => _ProFaderState();
}

class _ProFaderState extends State<ProFader> {
  late double _currentValue;

  @override
  void initState() {
    super.initState();
    _currentValue = widget.value;
  }

  @override
  void didUpdateWidget(covariant ProFader oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _currentValue = widget.value;
    }
  }

  void _handleDrag(double localDy, double trackHeight) {
    double newValue = 1.0 - (localDy / trackHeight);
    newValue = newValue.clamp(0.0, 1.0);
    
    setState(() {
      _currentValue = newValue;
    });
    
    widget.onChanged(newValue);
  }

  @override
  Widget build(BuildContext context) {
    final int dmxValue = (_currentValue * 255).round();
    final int percentValue = (_currentValue * 100).round();
    
    const double thumbHeight = 56.0;

    return Container(
      width: 120, 
      margin: const EdgeInsets.only(right: 20),
      child: Column(
        children: [
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final trackHeight = constraints.maxHeight;

                return GestureDetector(
                  behavior: HitTestBehavior.opaque, 
                  // onTapDown BURADAN KALDIRILDI! ARTIK YANLIŞLIKLA EKRAN KAYDIRIRKEN DEĞER DEĞİŞMEYECEK.
                  onVerticalDragStart: (details) {
                    _handleDrag(details.localPosition.dy, trackHeight);
                  },
                  onVerticalDragUpdate: (details) {
                    _handleDrag(details.localPosition.dy, trackHeight);
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF11131A), 
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 10, offset: const Offset(0, 5))
                      ],
                    ),
                    child: Stack(
                      alignment: Alignment.bottomCenter,
                      children: [
                        FractionallySizedBox(
                          heightFactor: _currentValue, 
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.bottomCenter,
                                end: Alignment.topCenter,
                                colors: [
                                  widget.activeColor.withOpacity(0.3),
                                  widget.activeColor.withOpacity(0.9),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ),
                        
                        Positioned(
                          bottom: _currentValue * (trackHeight - thumbHeight),
                          child: Container(
                            width: constraints.maxWidth, 
                            height: thumbHeight,
                            padding: const EdgeInsets.symmetric(horizontal: 6),
                            decoration: BoxDecoration(
                              color: Colors.white, 
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: widget.activeColor, width: 3.5), 
                              boxShadow: [
                                BoxShadow(color: widget.activeColor.withOpacity(0.6), blurRadius: 12, spreadRadius: 1)
                              ]
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF2A2D3A),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    "$percentValue%", 
                                    style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w900),
                                  ),
                                ),
                                Text(
                                  dmxValue.toString(),
                                  style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 18),
                                ),
                              ],
                            ),
                          ),
                        )
                      ],
                    ),
                  ),
                );
              }
            ),
          ),
          
          const SizedBox(height: 16),
          
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF151822),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.white12, width: 1.5)
            ),
            child: Text(
              widget.label.toUpperCase(),
              style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}