import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xml/xml.dart';
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
      
      int successCount = 0;
      int failCount = 0;
      Map<String, int> manufacturerCount = {};
      
      // Fixture manifest'i yükle
      try {
        final manifestStr = await rootBundle.loadString('assets/fixtures/fixture_manifest.json');
        final manifestData = jsonDecode(manifestStr);
        final List<String> fixturePaths = List<String>.from(manifestData['fixtures']);
        
        debugPrint('📂 ${fixturePaths.length} fixture dosyası bulundu');
        
        // Her dosyayı yükle
        for (String path in fixturePaths) {
          try {
            // Marka ismini path'ten çıkar
            final pathParts = path.split('/');
            if (pathParts.length < 3) continue; // Geçersiz path
            
            final manufacturer = pathParts[pathParts.length - 2];
            
            if (path.endsWith('.qxf')) {
              // QXF (XML) dosyasını parse et
              final String xmlStr = await rootBundle.loadString(path);
              if (_parseAndAddQxfFixture(xmlStr, path)) {
                successCount++;
                manufacturerCount[manufacturer] = (manufacturerCount[manufacturer] ?? 0) + 1;
              } else {
                failCount++;
              }
            } else if (path.endsWith('.json') && !path.contains('fixture_manifest.json')) {
              // JSON dosyasını parse et
              final String jsonStr = await rootBundle.loadString(path);
              final dynamic data = jsonDecode(jsonStr);
              
              if (data is List) {
                for (var deviceData in data) {
                  if (_parseAndAddFixture(deviceData, path)) {
                    successCount++;
                    manufacturerCount[manufacturer] = (manufacturerCount[manufacturer] ?? 0) + 1;
                  } else {
                    failCount++;
                  }
                }
              } else if (data is Map<String, dynamic>) {
                if (_parseAndAddFixture(data, path)) {
                  successCount++;
                  manufacturerCount[manufacturer] = (manufacturerCount[manufacturer] ?? 0) + 1;
                } else {
                  failCount++;
                }
              }
            }
          } catch (e) {
            // Dosya parse hatası - sessizce devam et
            failCount++;
          }
        }
        
        // Marka ve modele göre alfabetik sırala
        _fixtureLibrary.sort((a, b) => a.name.compareTo(b.name));
        notifyListeners();
        
        debugPrint("✅ Kütüphane Yüklendi: ${_fixtureLibrary.length} Cihaz Hazır!");
        debugPrint("📊 Başarılı: $successCount, Başarısız: $failCount");
        debugPrint("🏭 ${manufacturerCount.length} farklı marka");
        
        // En çok fixture'a sahip ilk 5 markayı göster
        final topManufacturers = manufacturerCount.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));
        debugPrint("🔝 En çok fixture:");
        for (var i = 0; i < (topManufacturers.length < 5 ? topManufacturers.length : 5); i++) {
          debugPrint("   ${topManufacturers[i].key}: ${topManufacturers[i].value}");
        }
        
      } catch (e) {
        debugPrint('❌ Fixture manifest yüklenemedi: $e');
        debugPrint('⚠️ Lütfen generate_fixture_manifest.ps1 çalıştırın');
      }
      
    } catch (e) {
      debugPrint('❌ Fikstür kütüphanesi yükleme hatası: $e');
    }
  }
  
  /// Tek bir fixture objesini parse edip listeye ekle
  /// Returns true if successful, false if failed
  bool _parseAndAddFixture(Map<String, dynamic> data, String path) {
    try {
      // Eğer fixture'ın kendi manufacturer bilgisi varsa onu kullan
      String brandName = data['manufacturer'] ?? data['brand'] ?? 'Generic';
      
      // Eğer yoksa dosya yolundan çıkarmaya çalış
      if (brandName == 'Generic' && !path.contains('library_full.json') && !path.contains('library.json')) {
        final pathSegments = path.split('/');
        if (pathSegments.length > 2) {
          // Son segment dosya adı, ondan önceki manufacturer
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
        // Eğer kanal obje ise (QLC+ detaylı format)
        else if (ch is Map<String, dynamic>) {
          final String chName = ch['name'] ?? 'Bilinmeyen';
          final String chType = ch['type'] ?? 'Analog_8';
          
          // QLC+ format: Analog_8, Analog_16, Ranges
          if (chType == 'Analog_16' || chType == 'Analog_24') {
            // 16-bit kanal (Pan, Tilt gibi hassas kanallar)
            // Coarse (MSB) kanal
            parsedChannels.add(
              FixtureChannel(
                offset: currentOffset,
                name: chName,
                type: _guessChannelType(chName),
              ),
            );
            currentOffset++;
            
            // Fine (LSB) kanal
            parsedChannels.add(
              FixtureChannel(
                offset: currentOffset,
                name: '$chName Fine',
                type: _guessChannelType('$chName Fine'),
              ),
            );
            currentOffset++;
          } 
          else if (chType == 'Ranges') {
            // Range-based kanal (Gobo, Color Wheel, Shutter, vb.)
            parsedChannels.add(
              FixtureChannel(
                offset: currentOffset,
                name: chName,
                type: _guessChannelType(chName),
              ),
            );
            currentOffset++;
          }
          else {
            // Analog_8 veya diğer standart kanallar
            parsedChannels.add(
              FixtureChannel(
                offset: currentOffset,
                name: chName,
                type: _guessChannelType(chName),
              ),
            );
            currentOffset++;
          }
        }
      }
      
      // Eğer hiç kanal yoksa bu fixture'ı ekleme
      if (parsedChannels.isEmpty) {
        debugPrint('⚠️ Fixture kanal yok: $deviceName ($path)');
        return false;
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
      
      return true;
      
    } catch (e) {
      debugPrint('⚠️ Fixture parse hatası ($path): $e');
      return false;
    }
  }
  
  /// QXF (XML) dosyasını parse edip listeye ekle
  /// Returns true if successful, false if failed
  bool _parseAndAddQxfFixture(String xmlContent, String path) {
    try {
      final document = XmlDocument.parse(xmlContent);
      final root = document.findElements('FixtureDefinition').first;
      
      // Manufacturer ve Model bilgilerini al
      final manufacturer = root.findElements('Manufacturer').first.innerText;
      final model = root.findElements('Model').first.innerText;
      
      // İlk Mode'u al (genellikle "Standard" veya en basit mod)
      final modes = root.findElements('Mode').toList();
      if (modes.isEmpty) {
        debugPrint('⚠️ QXF Mode yok: $model ($path)');
        return false;
      }
      
      // İlk modu kullan
      final mode = modes.first;
      final modeName = mode.getAttribute('Name') ?? 'Standard';
      
      // Mode içindeki Channel referanslarını al
      final modeChannels = mode.findElements('Channel').toList();
      
      List<FixtureChannel> parsedChannels = [];
      int maxOffset = -1;
      
      for (var modeChannel in modeChannels) {
        // QLC+ Number attribute'ü 0-indexed
        final channelNumber = int.parse(modeChannel.getAttribute('Number') ?? '0');
        final channelName = modeChannel.innerText;
        
        // Channel tanımını bul
        final channelDef = root.findElements('Channel')
            .where((ch) => ch.getAttribute('Name') == channelName)
            .firstOrNull;
        
        if (channelDef != null) {
          // Preset kontrolü (Pan, Tilt, Dimmer gibi standart kanallar)
          final preset = channelDef.getAttribute('Preset');
          String finalName = channelName;
          
          // Preset varsa kullan
          if (preset != null) {
            if (preset.contains('Pan') && !preset.contains('Fine')) {
              finalName = 'Pan';
            } else if (preset.contains('PanFine')) {
              finalName = 'Pan Fine';
            } else if (preset.contains('Tilt') && !preset.contains('Fine')) {
              finalName = 'Tilt';
            } else if (preset.contains('TiltFine')) {
              finalName = 'Tilt Fine';
            } else if (preset.contains('Dimmer')) {
              finalName = 'Dimmer';
            } else if (preset.contains('Focus')) {
              finalName = 'Focus';
            } else if (preset.contains('Shutter')) {
              finalName = 'Shutter';
            } else if (preset.contains('Strobe')) {
              finalName = 'Strobe';
            } else if (preset.contains('ColorWheel')) {
              finalName = 'Color Wheel';
            } else if (preset.contains('GoboWheel')) {
              finalName = 'Gobo';
            }
          }
          
          parsedChannels.add(
            FixtureChannel(
              offset: channelNumber,
              name: finalName,
              type: _guessChannelType(finalName),
            ),
          );
          
          if (channelNumber > maxOffset) {
            maxOffset = channelNumber;
          }
        } else {
          // Channel tanımı bulunamadıysa, sadece ismi kullan
          parsedChannels.add(
            FixtureChannel(
              offset: channelNumber,
              name: channelName,
              type: _guessChannelType(channelName),
            ),
          );
          
          if (channelNumber > maxOffset) {
            maxOffset = channelNumber;
          }
        }
      }
      
      // Eğer hiç kanal yoksa bu fixture'ı ekleme
      if (parsedChannels.isEmpty) {
        debugPrint('⚠️ QXF kanal yok: $model ($path)');
        return false;
      }
      
      // Kanal sayısını hesapla (maxOffset 0-indexed olduğu için +1)
      final channelCount = maxOffset + 1;
      
      final pathSegments = path.split('/');
      final fileName = pathSegments.last.replaceAll('.qxf', '');
      
      _fixtureLibrary.add(
        Fixture(
          id: 'qxf_${manufacturer}_$fileName'.replaceAll(' ', '_').toLowerCase(),
          name: '$model ($modeName)',
          manufacturer: manufacturer,
          channelCount: channelCount,
          channels: parsedChannels,
        ),
      );
      
      return true;
      
    } catch (e) {
      debugPrint('⚠️ QXF parse hatası ($path): $e');
      return false;
    }
  }
  
  /// Kanal isimlerinden türü anlayan fonksiyon
  ChannelType _guessChannelType(String name) {
    final lower = name.toLowerCase();
    
    // Fine kanallar önce kontrol edilmeli
    if (lower.contains('pan fine') || lower.contains('pan_fine')) return ChannelType.panFine;
    if (lower.contains('tilt fine') || lower.contains('tilt_fine')) return ChannelType.tiltFine;
    
    // Hareket kanalları
    if (lower.contains('pan')) return ChannelType.pan;
    if (lower.contains('tilt')) return ChannelType.tilt;
    
    // Işık kontrolü
    if (lower.contains('dimmer') || lower.contains('intensity') || lower.contains('master')) return ChannelType.dimmer;
    if (lower.contains('strobe')) return ChannelType.strobe;
    if (lower.contains('shutter')) return ChannelType.shutter;
    
    // Renk kanalları
    if (lower.contains('red')) return ChannelType.red;
    if (lower.contains('green')) return ChannelType.green;
    if (lower.contains('blue')) return ChannelType.blue;
    if (lower.contains('white')) return ChannelType.white;
    if (lower.contains('amber')) return ChannelType.amber;
    if (lower.contains('uv')) return ChannelType.uv;
    if (lower.contains('cyan')) return ChannelType.cyan;
    if (lower.contains('magenta')) return ChannelType.magenta;
    if (lower.contains('yellow')) return ChannelType.yellow;
    
    // Tekerlek ve efektler (rotation önce kontrol edilmeli)
    if (lower.contains('gobo rotation') || lower.contains('gobo rot')) return ChannelType.goboRotation;
    if (lower.contains('gobo')) return ChannelType.gobo;
    if (lower.contains('prism rotation') || lower.contains('prism rot')) return ChannelType.prismRotation;
    if (lower.contains('prism')) return ChannelType.prism;
    if (lower.contains('color wheel') || lower.contains('colour wheel') || lower.contains('colorwheel')) return ChannelType.colorWheel;
    if (lower.contains('color') || lower.contains('colour')) return ChannelType.colorWheel;
    
    // Optik
    if (lower.contains('focus')) return ChannelType.focus;
    if (lower.contains('zoom')) return ChannelType.zoom;
    if (lower.contains('iris')) return ChannelType.iris;
    if (lower.contains('frost')) return ChannelType.frost;
    
    // Diğer
    if (lower.contains('rotation') || lower.contains('rotate')) return ChannelType.rotation;
    if (lower.contains('speed')) return ChannelType.speed;
    if (lower.contains('macro')) return ChannelType.macro;
    if (lower.contains('reset')) return ChannelType.reset;
    if (lower.contains('function') || lower.contains('control')) return ChannelType.function;
    
    return ChannelType.generic;
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
  
  /// Yamalı fikstürün DMX adresini güncelle
  Future<void> updateFixtureAddress(String fixtureId, int newAddress) async {
    final index = _patchedFixtures.indexWhere((f) => f.id == fixtureId);
    if (index == -1) return;
    
    final oldFixture = _patchedFixtures[index];
    final updatedFixture = Fixture(
      id: oldFixture.id,
      name: oldFixture.name,
      manufacturer: oldFixture.manufacturer,
      channelCount: oldFixture.channelCount,
      channels: oldFixture.channels,
      startAddress: newAddress,
    );
    
    _patchedFixtures[index] = updatedFixture;
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
