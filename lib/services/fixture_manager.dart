import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/fixture.dart';

/// Fikstür kütüphanesi ve yamalama yönetimi
class FixtureManager extends ChangeNotifier {
  final List<Fixture> _fixtureLibrary = [];
  final List<Fixture> _patchedFixtures = [];
  
  List<Fixture> get fixtureLibrary => List.unmodifiable(_fixtureLibrary);
  List<Fixture> get patchedFixtures => List.unmodifiable(_patchedFixtures);
  
  FixtureManager() {
    _loadFixtureLibrary();
    _loadPatchedFixtures();
  }
  
  /// Fikstür kütüphanesini yükle (assets'ten veya local'den)
  Future<void> _loadFixtureLibrary() async {
    try {
      // Örnek fikstürleri yükle
      _fixtureLibrary.addAll(_getDefaultFixtures());
      notifyListeners();
    } catch (e) {
      debugPrint('Fikstür kütüphanesi yükleme hatası: $e');
    }
  }
  
  /// Yamalanmış fikstürleri yükle
  Future<void> _loadPatchedFixtures() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final patchedJson = prefs.getString('patched_fixtures');
      
      if (patchedJson != null) {
        final List<dynamic> decoded = jsonDecode(patchedJson);
        _patchedFixtures.clear();
        _patchedFixtures.addAll(
          decoded.map((json) => Fixture.fromJson(json)).toList(),
        );
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Yamalı fikstür yükleme hatası: $e');
    }
  }
  
  /// Fikstür yamala (patch)
  Future<void> patchFixture(Fixture fixture, int startAddress) async {
    if (startAddress < 1 || startAddress > 512) return;
    if (startAddress + fixture.channelCount - 1 > 512) return;
    
    // Adres çakışması kontrolü
    if (_hasAddressConflict(startAddress, fixture.channelCount)) {
      throw Exception('Adres çakışması! Bu adres aralığı kullanımda.');
    }
    
    final patchedFixture = Fixture(
      id: '${fixture.id}_${DateTime.now().millisecondsSinceEpoch}',
      name: fixture.name,
      manufacturer: fixture.manufacturer,
      channelCount: fixture.channelCount,
      channels: fixture.channels,
      startAddress: startAddress,
    );
    
    _patchedFixtures.add(patchedFixture);
    await _savePatchedFixtures();
    notifyListeners();
  }
  
  /// Yamalı fikstürü kaldır
  Future<void> unpatchFixture(String fixtureId) async {
    _patchedFixtures.removeWhere((f) => f.id == fixtureId);
    await _savePatchedFixtures();
    notifyListeners();
  }
  
  /// Adres çakışması kontrolü
  bool _hasAddressConflict(int startAddress, int channelCount) {
    final endAddress = startAddress + channelCount - 1;
    
    for (var fixture in _patchedFixtures) {
      if (fixture.startAddress == null) continue;
      
      final fixtureEnd = fixture.startAddress! + fixture.channelCount - 1;
      
      if ((startAddress >= fixture.startAddress! && startAddress <= fixtureEnd) ||
          (endAddress >= fixture.startAddress! && endAddress <= fixtureEnd)) {
        return true;
      }
    }
    return false;
  }
  
  /// Yamalı fikstürleri kaydet
  Future<void> _savePatchedFixtures() async {
    final prefs = await SharedPreferences.getInstance();
    final json = jsonEncode(_patchedFixtures.map((f) => f.toJson()).toList());
    await prefs.setString('patched_fixtures', json);
  }
  
  /// Varsayılan fikstür örnekleri
  List<Fixture> _getDefaultFixtures() {
    return [
      // Moving Head Beam
      Fixture(
        id: 'beam_230w',
        name: 'Beam 230W Moving Head',
        manufacturer: 'Generic',
        channelCount: 16,
        channels: [
          FixtureChannel(offset: 0, name: 'Pan', type: ChannelType.pan, fineOffset: 1),
          FixtureChannel(offset: 1, name: 'Pan Fine', type: ChannelType.panFine),
          FixtureChannel(offset: 2, name: 'Tilt', type: ChannelType.tilt, fineOffset: 3),
          FixtureChannel(offset: 3, name: 'Tilt Fine', type: ChannelType.tiltFine),
          FixtureChannel(offset: 4, name: 'Dimmer', type: ChannelType.dimmer),
          FixtureChannel(offset: 5, name: 'Strobe', type: ChannelType.strobe),
          FixtureChannel(offset: 6, name: 'Color Wheel', type: ChannelType.colorWheel, presets: [
            ChannelPreset(name: 'Open', value: 0),
            ChannelPreset(name: 'Red', value: 18),
            ChannelPreset(name: 'Blue', value: 37),
            ChannelPreset(name: 'Green', value: 56),
            ChannelPreset(name: 'Yellow', value: 75),
            ChannelPreset(name: 'Magenta', value: 94),
            ChannelPreset(name: 'Cyan', value: 113),
          ]),
          FixtureChannel(offset: 7, name: 'Gobo', type: ChannelType.gobo, presets: [
            ChannelPreset(name: 'Open', value: 0),
            ChannelPreset(name: 'Gobo 1 (Dots)', value: 10),
            ChannelPreset(name: 'Gobo 2 (Star)', value: 20),
            ChannelPreset(name: 'Gobo 3 (Spiral)', value: 30),
            ChannelPreset(name: 'Gobo 4 (Tunnel)', value: 40),
          ]),
          FixtureChannel(offset: 8, name: 'Gobo Rotation', type: ChannelType.goboRotation),
          FixtureChannel(offset: 9, name: 'Prism', type: ChannelType.prism, presets: [
            ChannelPreset(name: 'Open', value: 0),
            ChannelPreset(name: '3-Facet', value: 64),
            ChannelPreset(name: '8-Facet', value: 128),
          ]),
          FixtureChannel(offset: 10, name: 'Prism Rotation', type: ChannelType.prismRotation),
          FixtureChannel(offset: 11, name: 'Focus', type: ChannelType.focus),
          FixtureChannel(offset: 12, name: 'Zoom', type: ChannelType.zoom),
          FixtureChannel(offset: 13, name: 'Frost', type: ChannelType.frost),
          FixtureChannel(offset: 14, name: 'Speed', type: ChannelType.speed),
          FixtureChannel(offset: 15, name: 'Function', type: ChannelType.function),
        ],
      ),
      
      // LED PAR RGBW
      Fixture(
        id: 'led_par_rgbw',
        name: 'LED PAR RGBW',
        manufacturer: 'Generic',
        channelCount: 7,
        channels: [
          FixtureChannel(offset: 0, name: 'Dimmer', type: ChannelType.dimmer),
          FixtureChannel(offset: 1, name: 'Red', type: ChannelType.red),
          FixtureChannel(offset: 2, name: 'Green', type: ChannelType.green),
          FixtureChannel(offset: 3, name: 'Blue', type: ChannelType.blue),
          FixtureChannel(offset: 4, name: 'White', type: ChannelType.white),
          FixtureChannel(offset: 5, name: 'Strobe', type: ChannelType.strobe),
          FixtureChannel(offset: 6, name: 'Macro', type: ChannelType.macro),
        ],
      ),
      
      // LED Bar RGBWA+UV
      Fixture(
        id: 'led_bar_rgbwauv',
        name: 'LED Bar RGBWA+UV',
        manufacturer: 'Generic',
        channelCount: 8,
        channels: [
          FixtureChannel(offset: 0, name: 'Dimmer', type: ChannelType.dimmer),
          FixtureChannel(offset: 1, name: 'Red', type: ChannelType.red),
          FixtureChannel(offset: 2, name: 'Green', type: ChannelType.green),
          FixtureChannel(offset: 3, name: 'Blue', type: ChannelType.blue),
          FixtureChannel(offset: 4, name: 'White', type: ChannelType.white),
          FixtureChannel(offset: 5, name: 'Amber', type: ChannelType.amber),
          FixtureChannel(offset: 6, name: 'UV', type: ChannelType.uv),
          FixtureChannel(offset: 7, name: 'Strobe', type: ChannelType.strobe),
        ],
      ),
      
      // Moving Head Spot
      Fixture(
        id: 'spot_150w',
        name: 'Spot 150W Moving Head',
        manufacturer: 'Generic',
        channelCount: 14,
        channels: [
          FixtureChannel(offset: 0, name: 'Pan', type: ChannelType.pan, fineOffset: 1),
          FixtureChannel(offset: 1, name: 'Pan Fine', type: ChannelType.panFine),
          FixtureChannel(offset: 2, name: 'Tilt', type: ChannelType.tilt, fineOffset: 3),
          FixtureChannel(offset: 3, name: 'Tilt Fine', type: ChannelType.tiltFine),
          FixtureChannel(offset: 4, name: 'Dimmer', type: ChannelType.dimmer),
          FixtureChannel(offset: 5, name: 'Shutter', type: ChannelType.shutter),
          FixtureChannel(offset: 6, name: 'Color Wheel', type: ChannelType.colorWheel),
          FixtureChannel(offset: 7, name: 'Gobo', type: ChannelType.gobo),
          FixtureChannel(offset: 8, name: 'Gobo Rotation', type: ChannelType.goboRotation),
          FixtureChannel(offset: 9, name: 'Focus', type: ChannelType.focus),
          FixtureChannel(offset: 10, name: 'Zoom', type: ChannelType.zoom),
          FixtureChannel(offset: 11, name: 'Iris', type: ChannelType.iris),
          FixtureChannel(offset: 12, name: 'Prism', type: ChannelType.prism),
          FixtureChannel(offset: 13, name: 'Reset', type: ChannelType.reset),
        ],
      ),
    ];
  }
}
