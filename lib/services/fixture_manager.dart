import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/fixture.dart';

/// Fikstür kütüphanesi ve yamalama yönetimi
class FixtureManager extends ChangeNotifier {
  final List<Fixture> _fixtureLibrary = [];
  final List<Fixture> _patchedFixtures = [];
  
  List<Fixture> get fixtureLibrary => _fixtureLibrary;
  List<Fixture> get patchedFixtures => _patchedFixtures;
  
  FixtureManager() {
    // Uygulama açılır açılmaz gömülü kütüphaneyi RAM'e al!
    _loadBuiltInLibrary();
    _loadPatchedFixtures();
  }
  
  /// Gömülü JSON kütüphanesini yükle (basit format)
  Future<void> _loadBuiltInLibrary() async {
    try {
      debugPrint('📦 Kütüphane yükleniyor...');
      
      // 1. Assets içindeki json dosyasını oku
      final String jsonString = await rootBundle.loadString('assets/library.json');
      
      // 2. JSON'u Listeye çevir
      final List<dynamic> devices = jsonDecode(jsonString);
      
      // 3. Her bir cihazı kendi Fixture modelimize dönüştür
      for (int i = 0; i < devices.length; i++) {
        final device = devices[i];
        final String name = device['name'] ?? 'Bilinmeyen Cihaz';
        final List<dynamic> channelNames = device['channels'] ?? [];
        
        List<FixtureChannel> parsedChannels = [];
        for (int c = 0; c < channelNames.length; c++) {
          final chName = channelNames[c].toString();
          parsedChannels.add(
            FixtureChannel(
              name: chName,
              offset: c,
              type: _guessChannelType(chName),
            ),
          );
        }
        
        _fixtureLibrary.add(
          Fixture(
            id: 'builtin_$i',
            name: name,
            manufacturer: 'Generic',
            channelCount: parsedChannels.length,
            channels: parsedChannels,
          ),
        );
      }
      
      // 4. Arayüzü güncelle
      notifyListeners();
      debugPrint("✅ Kütüphane Yüklendi: ${_fixtureLibrary.length} cihaz hazır.");
      
    } catch (e) {
      debugPrint("❌ Gömülü kütüphane yüklenemedi: $e");
      // Fallback: Varsayılan cihazları yükle
      _fixtureLibrary.addAll(_getDefaultFixtures());
      notifyListeners();
    }
  }
  
  /// Akıllı Kanal Tipi Algılayıcı (Gelen isme göre Pan, Tilt, Color ayırır)
  ChannelType _guessChannelType(String name) {
    final lower = name.toLowerCase();
    
    if (lower.contains('pan fine')) return ChannelType.panFine;
    if (lower.contains('tilt fine')) return ChannelType.tiltFine;
    if (lower.contains('pan')) return ChannelType.pan;
    if (lower.contains('tilt')) return ChannelType.tilt;
    if (lower.contains('dimmer') || lower.contains('intensity')) return ChannelType.dimmer;
    if (lower.contains('strobe') || lower.contains('shutter')) return ChannelType.strobe;
    if (lower.contains('red')) return ChannelType.red;
    if (lower.contains('green')) return ChannelType.green;
    if (lower.contains('blue')) return ChannelType.blue;
    if (lower.contains('white')) return ChannelType.white;
    if (lower.contains('amber')) return ChannelType.amber;
    if (lower.contains('uv')) return ChannelType.uv;
    if (lower.contains('color') || lower.contains('colour')) return ChannelType.colorWheel;
    if (lower.contains('gobo rotation')) return ChannelType.goboRotation;
    if (lower.contains('gobo')) return ChannelType.gobo;
    if (lower.contains('prism rotation')) return ChannelType.prismRotation;
    if (lower.contains('prism')) return ChannelType.prism;
    if (lower.contains('focus')) return ChannelType.focus;
    if (lower.contains('zoom')) return ChannelType.zoom;
    if (lower.contains('iris')) return ChannelType.iris;
    if (lower.contains('frost')) return ChannelType.frost;
    if (lower.contains('speed')) return ChannelType.speed;
    if (lower.contains('macro')) return ChannelType.macro;
    if (lower.contains('reset')) return ChannelType.reset;
    
    return ChannelType.function;
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
    
    _patchedFixtures.add(fixture.copyWith(startAddress: startAddress));
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
  
  /// Dışarıdan özel dosya eklemek istersen kullanılacak fonksiyon
  void addCustomFixture(Fixture customFixture) {
    _fixtureLibrary.add(customFixture);
    notifyListeners();
    debugPrint('✅ Özel fikstür eklendi: ${customFixture.name}');
  }
  
  /// Kütüphaneden fikstür sil
  void removeFixtureFromLibrary(String fixtureId) {
    _fixtureLibrary.removeWhere((f) => f.id == fixtureId);
    notifyListeners();
    debugPrint('🗑️ Fikstür silindi: $fixtureId');
  }
  
  /// Varsayılan fikstür örnekleri (Sektör standartları)
  List<Fixture> _getDefaultFixtures() {
    return [
      // 7R Beam (Profesyonel)
      Fixture(
        id: '7r_beam',
        name: 'Beam 7R (16Ch)',
        manufacturer: 'Generic',
        channelCount: 16,
        channels: [
          FixtureChannel(offset: 0, name: 'Color Wheel', type: ChannelType.colorWheel),
          FixtureChannel(offset: 1, name: 'Strobe', type: ChannelType.strobe),
          FixtureChannel(offset: 2, name: 'Dimmer', type: ChannelType.dimmer),
          FixtureChannel(offset: 3, name: 'Gobo Wheel', type: ChannelType.gobo),
          FixtureChannel(offset: 4, name: 'Prism Insertion', type: ChannelType.prism),
          FixtureChannel(offset: 5, name: 'Prism Rotation', type: ChannelType.rotation),
          FixtureChannel(offset: 6, name: 'Effects', type: ChannelType.function),
          FixtureChannel(offset: 7, name: 'Frost', type: ChannelType.frost),
          FixtureChannel(offset: 8, name: 'Focus', type: ChannelType.focus),
          FixtureChannel(offset: 9, name: 'Pan', type: ChannelType.pan),
          FixtureChannel(offset: 10, name: 'Pan Fine', type: ChannelType.panFine),
          FixtureChannel(offset: 11, name: 'Tilt', type: ChannelType.tilt),
          FixtureChannel(offset: 12, name: 'Tilt Fine', type: ChannelType.tiltFine),
          FixtureChannel(offset: 13, name: 'Function', type: ChannelType.function),
          FixtureChannel(offset: 14, name: 'Reset', type: ChannelType.reset),
          FixtureChannel(offset: 15, name: 'Lamp Control', type: ChannelType.function),
        ],
      ),
      
      // LED Wash 36x10W
      Fixture(
        id: 'wash_led_36',
        name: 'LED Wash 36x10W',
        manufacturer: 'Generic',
        channelCount: 10,
        channels: [
          FixtureChannel(offset: 0, name: 'Pan', type: ChannelType.pan),
          FixtureChannel(offset: 1, name: 'Tilt', type: ChannelType.tilt),
          FixtureChannel(offset: 2, name: 'Dimmer', type: ChannelType.dimmer),
          FixtureChannel(offset: 3, name: 'Strobe', type: ChannelType.strobe),
          FixtureChannel(offset: 4, name: 'Red', type: ChannelType.red),
          FixtureChannel(offset: 5, name: 'Green', type: ChannelType.green),
          FixtureChannel(offset: 6, name: 'Blue', type: ChannelType.blue),
          FixtureChannel(offset: 7, name: 'White', type: ChannelType.white),
          FixtureChannel(offset: 8, name: 'Speed', type: ChannelType.speed),
          FixtureChannel(offset: 9, name: 'Macro', type: ChannelType.macro),
        ],
      ),
      
      // LED PAR RGBW (Basit)
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
      
      // Moving Head Spot 150W
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
