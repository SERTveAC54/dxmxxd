import 'dart:async';
import 'package:flutter/foundation.dart';

/// WiFi tarama ve DMX Tester cihazını bulma servisi
class WiFiScanner extends ChangeNotifier {
  List<DMXDevice> _devices = [];
  bool _isScanning = false;
  String? _connectedSSID;
  
  List<DMXDevice> get devices => _devices;
  bool get isScanning => _isScanning;
  String? get connectedSSID => _connectedSSID;
  
  /// DMX Tester cihazlarını tara
  Future<void> scanForDevices() async {
    _isScanning = true;
    notifyListeners();
    
    try {
      // TODO: Platform-specific WiFi scanning
      // Android: wifi_scan paketi kullanılabilir
      // iOS: network_info_plus paketi kullanılabilir
      
      // Şimdilik manuel IP girişi için placeholder
      _devices = [
        DMXDevice(
          ssid: 'DMX_Tester_MANUAL',
          ip: '192.168.4.1', // ESP32 AP default IP
          signalStrength: -50,
        ),
      ];
      
      debugPrint('WiFi tarama tamamlandı: ${_devices.length} cihaz bulundu');
    } catch (e) {
      debugPrint('WiFi tarama hatası: $e');
    } finally {
      _isScanning = false;
      notifyListeners();
    }
  }
  
  /// Cihaza bağlan
  Future<bool> connectToDevice(DMXDevice device) async {
    try {
      // TODO: Platform-specific WiFi connection
      // Android/iOS: wifi_iot paketi kullanılabilir
      
      _connectedSSID = device.ssid;
      notifyListeners();
      
      debugPrint('Cihaza bağlanıldı: ${device.ssid}');
      return true;
    } catch (e) {
      debugPrint('Bağlantı hatası: $e');
      return false;
    }
  }
  
  /// Bağlantıyı kes
  void disconnect() {
    _connectedSSID = null;
    notifyListeners();
  }
}

/// DMX Tester cihaz modeli
class DMXDevice {
  final String ssid;
  final String ip;
  final int signalStrength;
  
  DMXDevice({
    required this.ssid,
    required this.ip,
    required this.signalStrength,
  });
  
  bool get isDMXTester => ssid.startsWith('DMX_Tester_');
}
