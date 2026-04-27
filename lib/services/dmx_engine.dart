import 'dart:async';
import 'package:flutter/foundation.dart';

/// DMX Universe yönetimi ve throttling mekanizması
class DMXEngine extends ChangeNotifier {
  // 512 kanallık DMX universe (0-255 değerler)
  final List<int> _dmxData = List.filled(512, 0);
  
  // Throttling için
  Timer? _sendTimer;
  bool _hasChanges = false;
  static const int _maxFps = 40; // 40Hz = 25ms
  static const Duration _throttleDuration = Duration(milliseconds: 25);
  
  // Callback: Veri değiştiğinde Art-Net servisine bildirim
  Function(List<int>)? onDataChanged;
  
  DMXEngine() {
    _startThrottleTimer();
  }
  
  /// DMX kanalına değer yaz (1-512 arası adres, 0-255 arası değer)
  void setChannel(int address, int value) {
    if (address < 1 || address > 512) return;
    if (value < 0 || value > 255) return;
    
    final index = address - 1;
    if (_dmxData[index] != value) {
      _dmxData[index] = value;
      _hasChanges = true;
    }
  }
  
  /// Birden fazla kanalı toplu güncelle
  void setChannels(Map<int, int> channels) {
    for (var entry in channels.entries) {
      setChannel(entry.key, entry.value);
    }
  }
  
  /// Belirli bir aralıktaki kanalları güncelle
  void setChannelRange(int startAddress, List<int> values) {
    for (int i = 0; i < values.length; i++) {
      setChannel(startAddress + i, values[i]);
    }
  }
  
  /// DMX kanalını oku
  int getChannel(int address) {
    if (address < 1 || address > 512) return 0;
    return _dmxData[address - 1];
  }
  
  /// Tüm DMX verisini al (kopyasını döndür)
  List<int> getDMXData() {
    return List.from(_dmxData);
  }
  
  /// Throttling timer - 40Hz (25ms) ile veri gönderimi
  void _startThrottleTimer() {
    _sendTimer = Timer.periodic(_throttleDuration, (timer) {
      if (_hasChanges) {
        onDataChanged?.call(getDMXData());
        _hasChanges = false;
      }
    });
  }
  
  /// Tüm kanalları sıfırla (Blackout)
  void blackout() {
    for (int i = 0; i < 512; i++) {
      _dmxData[i] = 0;
    }
    _hasChanges = true;
    notifyListeners();
  }
  
  @override
  void dispose() {
    _sendTimer?.cancel();
    super.dispose();
  }
}
