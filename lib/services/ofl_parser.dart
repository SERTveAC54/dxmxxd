import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../models/fixture.dart';

/// Open Fixture Library JSON Parser
class OFLParser {
  /// JSON string'i Fixture objesine çevirir
  static Fixture? parse(String jsonString) {
    try {
      final Map<String, dynamic> json = jsonDecode(jsonString);
      
      // ID kontrolü
      if (!json.containsKey('id') || !json.containsKey('name')) {
        debugPrint('⚠️ JSON\'da id veya name eksik');
        return null;
      }
      
      // Kanalları parse et
      final List<FixtureChannel> channels = [];
      if (json.containsKey('channels') && json['channels'] is List) {
        for (var channelJson in json['channels']) {
          try {
            final channel = _parseChannel(channelJson);
            if (channel != null) {
              channels.add(channel);
            }
          } catch (e) {
            debugPrint('⚠️ Kanal parse hatası: $e');
          }
        }
      }
      
      // Fixture oluştur
      return Fixture(
        id: json['id'] as String,
        name: json['name'] as String,
        manufacturer: json['manufacturer'] as String? ?? 'Generic',
        channelCount: json['channelCount'] as int? ?? channels.length,
        channels: channels,
      );
      
    } catch (e) {
      debugPrint('❌ Fixture parse hatası: $e');
      return null;
    }
  }
  
  /// Kanal JSON'unu FixtureChannel'a çevirir
  static FixtureChannel? _parseChannel(Map<String, dynamic> json) {
    try {
      final String name = json['name'] as String;
      final int offset = json['offset'] as int;
      final String typeStr = json['type'] as String;
      
      // String'i ChannelType enum'a çevir
      final ChannelType type = _parseChannelType(typeStr);
      
      // Fine offset varsa al
      final int? fineOffset = json['fineOffset'] as int?;
      
      // Presets varsa parse et
      List<ChannelPreset>? presets;
      if (json.containsKey('presets') && json['presets'] is List) {
        presets = (json['presets'] as List)
            .map((p) => _parsePreset(p))
            .whereType<ChannelPreset>()
            .toList();
      }
      
      return FixtureChannel(
        offset: offset,
        name: name,
        type: type,
        fineOffset: fineOffset,
        presets: presets,
      );
      
    } catch (e) {
      debugPrint('⚠️ Kanal parse hatası: $e');
      return null;
    }
  }
  
  /// String'i ChannelType enum'a çevirir
  static ChannelType _parseChannelType(String typeStr) {
    try {
      return ChannelType.values.firstWhere(
        (e) => e.name.toLowerCase() == typeStr.toLowerCase(),
        orElse: () => ChannelType.generic,
      );
    } catch (e) {
      return ChannelType.generic;
    }
  }
  
  /// Preset JSON'unu ChannelPreset'e çevirir
  static ChannelPreset? _parsePreset(Map<String, dynamic> json) {
    try {
      return ChannelPreset(
        name: json['name'] as String,
        value: json['value'] as int,
        valueEnd: json['valueEnd'] as int?,
      );
    } catch (e) {
      return null;
    }
  }
  
  /// Birden fazla fixture içeren JSON array'i parse eder
  static List<Fixture> parseMultiple(String jsonString) {
    try {
      final dynamic decoded = jsonDecode(jsonString);
      final List<Fixture> fixtures = [];
      
      // Eğer root'ta "fixtures" key'i varsa
      if (decoded is Map && decoded.containsKey('fixtures')) {
        final List<dynamic> fixtureList = decoded['fixtures'] as List;
        for (var fixtureJson in fixtureList) {
          final fixture = parse(jsonEncode(fixtureJson));
          if (fixture != null) {
            fixtures.add(fixture);
          }
        }
      }
      // Eğer direkt array ise
      else if (decoded is List) {
        for (var fixtureJson in decoded) {
          final fixture = parse(jsonEncode(fixtureJson));
          if (fixture != null) {
            fixtures.add(fixture);
          }
        }
      }
      
      return fixtures;
      
    } catch (e) {
      debugPrint('❌ Multiple fixture parse hatası: $e');
      return [];
    }
  }
}
