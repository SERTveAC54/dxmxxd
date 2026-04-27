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
      Fixture(
        id: 'beam_230w',
        name: 'Beam 230W Moving Head',
        manufacturer: 'Generic',
        channelCount: 16,
        channels: [
          FixtureChannel(offset: 0, name: 'Pan', type: ChannelType.pan, fineOffset: 1),
          FixtureChannel(offset: 1, name: 'Pan Fine', type: ChannelType.pan),
          FixtureChannel(offset: 2, name: 'Tilt', type: ChannelType.tilt, fineOffset: 3),
          FixtureChannel(offset: 3, name: 'Tilt Fine', type: ChannelType.tilt),
          FixtureChannel(offset: 4, name: 'Dimmer', type: ChannelType.dimmer),
          FixtureChannel(offset: 5, name: 'Strobe', type: ChannelType.strobe),
          FixtureChannel(offset: 6, name: 'Color Wheel', type: ChannelType.colorWheel, presets: [
            ChannelPreset(name: 'Open', value: 0),
            ChannelPreset(name: 'Red', value: 18),
            ChannelPreset(name: 'Blue', value: 37),
            ChannelPreset(name: 'Green', value: 56),
            ChannelPreset(name: 'Yellow', value: 75),
          ]),
          FixtureChannel(offset: 7, name: 'Gobo', type: ChannelType.gobo, presets: [
            ChannelPreset(name: 'Open', value: 0),
            ChannelPreset(name: 'Gobo 1', value: 10),
            ChannelPreset(name: 'Gobo 2', value: 20),
            ChannelPreset(name: 'Gobo 3', value: 30),
          ]),
          FixtureChannel(offset: 8, name: 'Gobo Rotation', type: ChannelType.goboRotation),
          FixtureChannel(offset: 9, name: 'Prism', type: ChannelType.prism),
          FixtureChannel(offset: 10, name: 'Focus', type: ChannelType.focus),
          FixtureChannel(offset: 11, name: 'Zoom', type: ChannelType.zoom),
        ],
      ),
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
        ],
      ),
    ];
  }
}
