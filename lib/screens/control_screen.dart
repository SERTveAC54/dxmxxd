import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/dmx_engine.dart';
import '../services/fixture_manager.dart';
import '../models/fixture.dart';
import '../widgets/xy_pad.dart';
import '../widgets/color_picker.dart';
import '../widgets/dmx_slider.dart';

class ControlScreen extends StatefulWidget {
  const ControlScreen({super.key});

  @override
  State<ControlScreen> createState() => _ControlScreenState();
}

class _ControlScreenState extends State<ControlScreen> {
  Fixture? _selectedFixture;
  
  @override
  Widget build(BuildContext context) {
    final fixtureManager = context.watch<FixtureManager>();
    final patchedFixtures = fixtureManager.patchedFixtures;
    
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1F3A),
        title: const Text('DMX Control'),
        actions: [
          IconButton(
            icon: const Icon(Icons.power_settings_new),
            onPressed: () {
              context.read<DMXEngine>().blackout();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Blackout!')),
              );
            },
          ),
        ],
      ),
      body: patchedFixtures.isEmpty
          ? _buildEmptyState()
          : Row(
              children: [
                // Sol panel - Fikstür listesi
                Container(
                  width: 200,
                  color: const Color(0xFF1A1F3A),
                  child: _buildFixtureList(patchedFixtures),
                ),
                
                // Sağ panel - Kontrol arayüzü
                Expanded(
                  child: _selectedFixture == null
                      ? _buildSelectPrompt()
                      : _buildControlPanel(_selectedFixture!),
                ),
              ],
            ),
    );
  }
  
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.lightbulb_outline,
            size: 80,
            color: Colors.white.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'Henüz yamalı fikstür yok',
            style: TextStyle(
              color: Colors.white.withOpacity(0.5),
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Patch sekmesinden fikstür ekleyin',
            style: TextStyle(
              color: Colors.white.withOpacity(0.3),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildFixtureList(List<Fixture> fixtures) {
    return ListView.builder(
      itemCount: fixtures.length,
      itemBuilder: (context, index) {
        final fixture = fixtures[index];
        final isSelected = _selectedFixture?.id == fixture.id;
        
        return ListTile(
          selected: isSelected,
          selectedTileColor: const Color(0xFF00D9FF).withOpacity(0.2),
          leading: const Icon(Icons.lightbulb, color: Color(0xFF00D9FF)),
          title: Text(
            fixture.name,
            style: const TextStyle(fontSize: 14),
          ),
          subtitle: Text(
            'Ch ${fixture.startAddress}',
            style: const TextStyle(fontSize: 12),
          ),
          onTap: () {
            setState(() {
              _selectedFixture = fixture;
            });
          },
        );
      },
    );
  }
  
  Widget _buildSelectPrompt() {
    return Center(
      child: Text(
        'Soldan bir fikstür seçin',
        style: TextStyle(
          color: Colors.white.withOpacity(0.5),
          fontSize: 16,
        ),
      ),
    );
  }
  
  Widget _buildControlPanel(Fixture fixture) {
    final dmxEngine = context.read<DMXEngine>();
    
    // Kanal tiplerini grupla
    final hasMovement = fixture.channels.any((ch) => 
        ch.type == ChannelType.pan || ch.type == ChannelType.tilt);
    final hasColor = fixture.channels.any((ch) => 
        ch.type == ChannelType.red || ch.type == ChannelType.green || ch.type == ChannelType.blue);
    
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Başlık
          Text(
            fixture.name,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF00D9FF),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'DMX Address: ${fixture.startAddress}',
            style: const TextStyle(color: Colors.white70),
          ),
          const Divider(height: 32, color: Colors.white24),
          
          // Kontrol alanı
          Expanded(
            child: ListView(
              children: [
                // XY Pad (Pan/Tilt)
                if (hasMovement) ...[
                  const Text(
                    'Movement',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF00D9FF),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 300,
                    child: XYPad(
                      onChanged: (x, y) {
                        _updatePanTilt(fixture, dmxEngine, x, y);
                      },
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
                
                // Color Picker (RGB)
                if (hasColor) ...[
                  const Text(
                    'Color Mixing',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF00D9FF),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 250,
                    child: DMXColorPicker(
                      onColorChanged: (color) {
                        _updateColor(fixture, dmxEngine, color);
                      },
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
                
                // Dynamic Sliders
                const Text(
                  'Channel Faders',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF00D9FF),
                  ),
                ),
                const SizedBox(height: 12),
                _buildDynamicSliders(fixture, dmxEngine),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildDynamicSliders(Fixture fixture, DMXEngine dmxEngine) {
    // Pan/Tilt ve RGB dışındaki tüm önemli kanalları slider olarak göster
    final importantTypes = [
      ChannelType.dimmer,
      ChannelType.strobe,
      ChannelType.focus,
      ChannelType.zoom,
      ChannelType.gobo,
      ChannelType.colorWheel,
      ChannelType.prism,
      ChannelType.rotation,
      ChannelType.goboRotation,
      ChannelType.prismRotation,
      ChannelType.frost,
      ChannelType.iris,
      ChannelType.shutter,
      ChannelType.speed,
      ChannelType.macro,
    ];
    
    final sliderChannels = fixture.channels
        .where((ch) => importantTypes.contains(ch.type))
        .toList();
    
    if (sliderChannels.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Text(
          'No fader channels available',
          style: TextStyle(color: Colors.white54),
        ),
      );
    }
    
    return SizedBox(
      height: 300,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: sliderChannels.length,
        itemBuilder: (context, index) {
          final channel = sliderChannels[index];
          final address = fixture.startAddress! + channel.offset;
          final currentValue = dmxEngine.getChannel(address) / 255.0;
          
          return Container(
            width: 80,
            margin: const EdgeInsets.only(right: 12),
            child: DMXSlider(
              label: channel.name,
              value: currentValue,
              onChanged: (value) {
                dmxEngine.setChannel(address, (value * 255).round());
              },
            ),
          );
        },
      ),
    );
  }
  
  void _updatePanTilt(Fixture fixture, DMXEngine dmxEngine, double x, double y) {
    final panChannel = fixture.channels.firstWhere(
      (ch) => ch.type == ChannelType.pan,
      orElse: () => fixture.channels.first,
    );
    final tiltChannel = fixture.channels.firstWhere(
      (ch) => ch.type == ChannelType.tilt,
      orElse: () => fixture.channels.first,
    );
    
    final panAddress = fixture.startAddress! + panChannel.offset;
    final tiltAddress = fixture.startAddress! + tiltChannel.offset;
    
    dmxEngine.setChannel(panAddress, (x * 255).round());
    dmxEngine.setChannel(tiltAddress, (y * 255).round());
  }
  
  void _updateColor(Fixture fixture, DMXEngine dmxEngine, Color color) {
    final redCh = fixture.channels.where((ch) => ch.type == ChannelType.red).firstOrNull;
    final greenCh = fixture.channels.where((ch) => ch.type == ChannelType.green).firstOrNull;
    final blueCh = fixture.channels.where((ch) => ch.type == ChannelType.blue).firstOrNull;
    
    if (redCh != null) {
      dmxEngine.setChannel(fixture.startAddress! + redCh.offset, color.red);
    }
    if (greenCh != null) {
      dmxEngine.setChannel(fixture.startAddress! + greenCh.offset, color.green);
    }
    if (blueCh != null) {
      dmxEngine.setChannel(fixture.startAddress! + blueCh.offset, color.blue);
    }
  }
}
