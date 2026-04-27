/// Fikstür (Sahne Işığı Cihazı) modeli
class Fixture {
  final String id;
  final String name;
  final String manufacturer;
  final int channelCount;
  final List<FixtureChannel> channels;
  
  // Yamalama bilgisi
  int? startAddress;
  
  Fixture({
    required this.id,
    required this.name,
    required this.manufacturer,
    required this.channelCount,
    required this.channels,
    this.startAddress,
  });
  
  factory Fixture.fromJson(Map<String, dynamic> json) {
    return Fixture(
      id: json['id'] as String,
      name: json['name'] as String,
      manufacturer: json['manufacturer'] as String? ?? 'Generic',
      channelCount: json['channelCount'] as int,
      channels: (json['channels'] as List)
          .map((ch) => FixtureChannel.fromJson(ch))
          .toList(),
      startAddress: json['startAddress'] as int?,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'manufacturer': manufacturer,
      'channelCount': channelCount,
      'channels': channels.map((ch) => ch.toJson()).toList(),
      'startAddress': startAddress,
    };
  }
  
  bool get isPatched => startAddress != null;
}

/// Fikstür kanalı
class FixtureChannel {
  final int offset; // 0-based (0 = ilk kanal)
  final String name;
  final ChannelType type;
  final int? fineOffset; // 16-bit için fine kanal (opsiyonel)
  final List<ChannelPreset>? presets; // Gobo, renk tekerleği vb. için
  
  FixtureChannel({
    required this.offset,
    required this.name,
    required this.type,
    this.fineOffset,
    this.presets,
  });
  
  factory FixtureChannel.fromJson(Map<String, dynamic> json) {
    return FixtureChannel(
      offset: json['offset'] as int,
      name: json['name'] as String,
      type: ChannelType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => ChannelType.generic,
      ),
      fineOffset: json['fineOffset'] as int?,
      presets: json['presets'] != null
          ? (json['presets'] as List)
              .map((p) => ChannelPreset.fromJson(p))
              .toList()
          : null,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'offset': offset,
      'name': name,
      'type': type.name,
      if (fineOffset != null) 'fineOffset': fineOffset,
      if (presets != null) 'presets': presets!.map((p) => p.toJson()).toList(),
    };
  }
}

/// Kanal tipleri
enum ChannelType {
  pan,
  tilt,
  dimmer,
  red,
  green,
  blue,
  white,
  amber,
  colorWheel,
  gobo,
  goboRotation,
  prism,
  zoom,
  focus,
  iris,
  frost,
  strobe,
  shutter,
  generic,
}

/// Preset değerler (Gobo, Renk Tekerleği vb.)
class ChannelPreset {
  final String name;
  final int value;
  final int? valueEnd; // Aralık için (örn: 10-20)
  
  ChannelPreset({
    required this.name,
    required this.value,
    this.valueEnd,
  });
  
  factory ChannelPreset.fromJson(Map<String, dynamic> json) {
    return ChannelPreset(
      name: json['name'] as String,
      value: json['value'] as int,
      valueEnd: json['valueEnd'] as int?,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'value': value,
      if (valueEnd != null) 'valueEnd': valueEnd,
    };
  }
}
