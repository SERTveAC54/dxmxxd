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
    _loadPixilabLibrary(); // Artık manuel listeyi değil, klasördeki JSON'ları yüklüyoruz
    _loadPatchedFixtures(); // Senin yazdığın hafızadan geri yükleme fonksiyonu
  }
  
  /// Pixilab JSON Fikstür kütüphanesini assets'ten yükle
  Future<void> _loadPixilabLibrary() async {
    try {
      debugPrint('📦 Kütüphane yükleniyor...');
      
      // Önce library_full.json'u dene (tüm fixture'lar burada)
      try {
        final String jsonStr = await rootBundle.loadString('assets/fixtures/library_full.json');
        final dynamic data = jsonDecode(jsonStr);
        
        if (data is List) {
          for (var deviceData in data) {
            _parseAndAddFixture(deviceData, 'assets/fixtures/library_full.json');
          }
          
          _fixtureLibrary.sort((a, b) => a.name.compareTo(b.name));
          notifyListeners();
          debugPrint("✅ Kütüphane Yüklendi: ${_fixtureLibrary.length} Cihaz Hazır!");
          return;
        }
      } catch (e) {
        debugPrint('⚠️ library_full.json yüklenemedi, library.json deneniyor...');
      }
      
      // Fallback: library.json
      try {
        final String jsonStr = await rootBundle.loadString('assets/fixtures/library.json');
        final dynamic data = jsonDecode(jsonStr);
        
        if (data is List) {
          for (var deviceData in data) {
            _parseAndAddFixture(deviceData, 'assets/fixtures/library.json');
          }
          
          _fixtureLibrary.sort((a, b) => a.name.compareTo(b.name));
          notifyListeners();
          debugPrint("✅ Kütüphane Yüklendi: ${_fixtureLibrary.length} Cihaz Hazır!");
          return;
        }
      } catch (e) {
        debugPrint('⚠️ library.json yüklenemedi, AssetManifest deneniyor...');
      }
      
      // AssetManifest ile tüm dosyaları tara (Native platformlar için)
      final manifestContent = await rootBundle.loadString('AssetManifest.json');
      final Map<String, dynamic> manifestMap = jsonDecode(manifestContent);
      
      // Sadece assets/fixtures/ içindeki .json dosyalarını filtrele
      final fixturePaths = manifestMap.keys
          .where((String key) => key.startsWith('assets/fixtures/') && key.endsWith('.json'))
          .toList();
      
      for (String path in fixturePaths) {
        try {
          final String jsonStr = await rootBundle.loadString(path);
          final dynamic data = jsonDecode(jsonStr);
          
          // Eğer array ise (library.json gibi)
          if (data is List) {
            for (var deviceData in data) {
              _parseAndAddFixture(deviceData, path);
            }
          }
          // Eğer tek bir obje ise
          else if (data is Map<String, dynamic>) {
            _parseAndAddFixture(data, path);
          }
          
        } catch (e) {
          debugPrint('⚠️ Dosya parse hatası ($path): $e');
          continue; // Hatalı dosya varsa çökme, diğerine geç
        }
      }
      
      // Marka ve modele göre alfabetik sırala
      _fixtureLibrary.sort((a, b) => a.name.compareTo(b.name));
      notifyListeners();
      debugPrint("✅ Kütüphane Yüklendi: ${_fixtureLibrary.length} Cihaz Hazır!");
      
    } catch (e) {
      debugPrint('❌ Fikstür kütüphanesi yükleme hatası: $e');
    }
  }
  
  /// Tek bir fixture objesini parse edip listeye ekle
  void _parseAndAddFixture(Map<String, dynamic> data, String path) {
    try {
      // Eğer fixture'ın kendi manufacturer bilgisi varsa onu kullan
      String brandName = data['manufacturer'] ?? data['brand'] ?? 'Generic';
      
      // Eğer yoksa dosya yolundan çıkarmaya çalış
      if (brandName == 'Generic' && !path.contains('library_full.json')) {
        final pathSegments = path.split('/');
        if (pathSegments.length > 2) {
          brandName = pathSegments[pathSegments.length - 2];
        }
      }
      
      final pathSegments = path.split('/');
      final fileName = pathSegments.last.replaceAll('.json', '');
      
      final String deviceName = data['name'] ?? fileName;
      final List<dynamic> channels = data['channels'] ?? [];
      
      List<FixtureChannel> parsedChannels = [];
      int currentOffset = 0;
      
      for (var ch in channels) {
        // Eğer kanal string ise (basit format)
        if (ch is String) {
          parsedChannels.add(
            FixtureChannel(
              offset: currentOffset,
              name: ch,
              type: _guessChannelType(ch),
            ),
          );
          currentOffset++;
        }
        // Eğer kanal obje ise (detaylı format)
        else if (ch is Map<String, dynamic>) {
          final String chName = ch['name'] ?? 'Bilinmeyen';
          final String chType = ch['type'] ?? 'Analog_8';
          
          parsedChannels.add(
            FixtureChannel(
              offset: currentOffset,
              name: chName,
              type: _guessChannelType(chName),
            ),
          );
          
          // 16-bit (Fine) kanal tespiti
          currentOffset += (chType == 'Analog_16' || chType == 'Analog_24') ? 2 : 1;
        }
      }
      
      _fixtureLibrary.add(
        Fixture(
          id: 'px_${brandName}_$fileName'.replaceAll(' ', '_').toLowerCase(),
          name: deviceName,
          manufacturer: brandName,
          channelCount: currentOffset,
          channels: parsedChannels,
        ),
      );
      
    } catch (e) {
      debugPrint('⚠️ Fixture parse hatası: $e');
    }
  }
  
  /// Kanal isimlerinden türü anlayan fonksiyon
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
}
