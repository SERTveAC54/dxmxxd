import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Art-Net UDP paket gönderimi
class ArtNetService extends ChangeNotifier {
  RawDatagramSocket? _socket;
  
  String _targetIP = '192.168.4.1'; // ESP32 AP default IP
  int _universe = 0;
  int _port = 6454;
  
  bool _isConnected = false;
  
  ArtNetService() {
    _loadSettings();
  }
  
  String get targetIP => _targetIP;
  int get universe => _universe;
  bool get isConnected => _isConnected;
  
  /// Ayarları yükle
  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _targetIP = prefs.getString('artnet_ip') ?? '192.168.4.1'; // ESP32 AP default
    _universe = prefs.getInt('artnet_universe') ?? 0;
    notifyListeners();
  }
  
  /// Hedef IP'yi güncelle
  Future<void> setTargetIP(String ip) async {
    _targetIP = ip;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('artnet_ip', ip);
    notifyListeners();
  }
  
  /// Universe numarasını güncelle
  Future<void> setUniverse(int universe) async {
    _universe = universe;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('artnet_universe', universe);
    notifyListeners();
  }
  
  /// UDP soketini başlat
  Future<void> connect() async {
    try {
      _socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
      _isConnected = true;
      notifyListeners();
    } catch (e) {
      debugPrint('Art-Net bağlantı hatası: $e');
      _isConnected = false;
    }
  }
  
  /// Art-Net DMX paketi gönder
  void sendDMX(List<int> dmxData) {
    if (_socket == null || !_isConnected) return;
    
    final packet = _buildArtDmxPacket(dmxData);
    
    try {
      final address = InternetAddress(_targetIP);
      _socket!.send(packet, address, _port);
    } catch (e) {
      debugPrint('Art-Net gönderim hatası: $e');
    }
  }
  
  /// Art-Net ArtDmx paketi oluştur (standart protokol)
  Uint8List _buildArtDmxPacket(List<int> dmxData) {
    final packet = BytesBuilder();
    
    // Header: "Art-Net\0" (8 byte)
    packet.add([0x41, 0x72, 0x74, 0x2D, 0x4E, 0x65, 0x74, 0x00]);
    
    // OpCode: ArtDmx = 0x5000 (little-endian)
    packet.add([0x00, 0x50]);
    
    // Protocol Version: 14 (big-endian)
    packet.add([0x00, 0x0E]);
    
    // Sequence: 0 (paket sırası, genelde 0)
    packet.addByte(0);
    
    // Physical: 0 (fiziksel port)
    packet.addByte(0);
    
    // Universe: Low byte, High byte (little-endian)
    packet.addByte(_universe & 0xFF);
    packet.addByte((_universe >> 8) & 0xFF);
    
    // Length: DMX veri uzunluğu (512) - big-endian
    packet.addByte(0x02); // 512 = 0x0200
    packet.addByte(0x00);
    
    // DMX Data: 512 byte
    packet.add(dmxData);
    
    return packet.toBytes();
  }
  
  @override
  void dispose() {
    _socket?.close();
    super.dispose();
  }
}
