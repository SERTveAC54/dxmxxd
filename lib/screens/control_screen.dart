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
          const Divider(height: 32),
          
          // Kontrol alanı
          Expanded(
            child: Row(
              children: [
                // XY Pad (Pan/Tilt)
                if (hasMovement) ...[
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Pan / Tilt',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Expanded(
                          child: XYPad(
                            onChanged: (x, y) {
                              _updatePanTilt(fixture, dmxEngine, x, y);
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                ],
                
                // Color Picker (RGB)
                if (hasColor) ...[
                  Expanded(
                    flex: 1,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Color',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Expanded(
                          child: DMXColorPicker(
                            onColorChanged: (color) {
                              _updateColor(fixture, dmxEngine, color);
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                ],
                
                // Sliders (Dimmer, Zoom, vb.)
                SizedBox(
                  width: 300,
                  child: _buildSliders(fixture, dmxEngine),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildSliders(Fixture fixture, DMXEngine dmxEngine) {
    final sliderChannels = fixture.channels.where((ch) =>
        ch.type == ChannelType.dimmer ||
        ch.type == ChannelType.zoom ||
        ch.type == ChannelType.focus ||
        ch.type == ChannelType.strobe).toList();
    
    if (sliderChannels.isEmpty) {
      return const Center(child: Text('No sliders available'));
    }
    
    return Row(
      children: sliderChannels.map((channel) {
        final address = fixture.startAddress! + channel.offset;
        final currentValue = dmxEngine.getChannel(address) / 255.0;
        
        return Expanded(
          child: DMXSlider(
            label: channel.name,
            value: currentValue,
            onChanged: (value) {
              dmxEngine.setChannel(address, (value * 255).round());
            },
          ),
        );
      }).toList(),
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
