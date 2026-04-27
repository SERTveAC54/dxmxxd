# DMX512 Art-Net Controller

Profesyonel sahne ışıklandırması için Flutter tabanlı mobil DMX kontrol uygulaması.

## 🎯 Özellikler

### 🎛️ Temel Özellikler
- **Art-Net DMX512 Protokolü**: UDP üzerinden standart Art-Net paket gönderimi (Port 6454)
- **40Hz Throttling**: Ağ tıkanıklığını önleyen akıllı paket gönderim sistemi (25ms)
- **512 Kanal Kontrolü**: Tam universe desteği
- **Gerçek Zamanlı Kontrol**: Anlık tepki veren dokunmatik arayüz

### 🎨 Kontrol Arayüzü
- **XY Pad**: Moving Head'ler için hassas Pan/Tilt kontrolü
- **Color Picker**: RGB/RGBW LED'ler için renk paleti
- **DMX Sliders**: Dimmer, Zoom, Focus, Strobe, Gobo, Prism kontrolü
- **Dinamik Kanal Algılama**: Cihaza göre otomatik kontrol arayüzü

### 📚 Fikstür Yönetimi
- **JSON Tabanlı Kütüphane**: Open Fixture Library uyumlu
- **7 Profesyonel Cihaz**: Clay Paky, Martin, Robe, Chauvet, ADJ, Elation
- **Kolay Yamalama**: Drag & drop patching sistemi
- **Adres Çakışma Kontrolü**: Otomatik çakışma tespiti
- **Çoklu Fikstür Desteği**: Sınırsız cihaz kontrolü

### 🎯 Profesyonel Tasarım
- **Dark Mode**: Karanlık sahne ortamı için optimize
- **Neon Renkler**: Yüksek kontrastlı Cyan/Orange vurgular
- **Hızlı Tepki**: Dokunmatik geri bildirim
- **Landscape Optimizasyonu**: Yatay ekran desteği

## 📦 Kurulum

### Gereksinimler
- Flutter SDK (3.0+)
- Dart SDK
- Windows / Android / iOS

### Bağımlılıklar
```bash
flutter pub get
```

### Çalıştırma
```bash
# Windows
flutter run -d windows

# Web (UDP desteği yok)
flutter run -d chrome

# Android
flutter run
```

## 🏗️ Mimari

### Core Services
- **DMXEngine**: 512 kanallık DMX universe yönetimi ve throttling
- **ArtNetService**: UDP soket yönetimi ve Art-Net paket oluşturma
- **FixtureManager**: JSON kütüphane yönetimi ve yamalama
- **OFLParser**: Open Fixture Library JSON parser

### UI Components
- **XYPad**: Pan/Tilt joystick kontrolü
- **DMXColorPicker**: RGB renk seçici
- **DMXSlider**: Dikey kanal slider'ları

### Screens
- **ControlScreen**: Ana kontrol arayüzü (dinamik)
- **PatchScreen**: Fikstür yamalama ekranı
- **SettingsScreen**: Ağ ayarları (IP, Universe)

## 📁 Fikstür Kütüphanesi

### Mevcut Cihazlar
1. **Clay Paky Sharpy** - 16 kanal beam
2. **Martin MAC Aura** - 18 kanal RGBW wash
3. **Robe Robin 600 LEDWash** - 20 kanal profesyonel wash
4. **Chauvet Rogue R2 Spot** - 17 kanal spot
5. **ADJ Vizi Beam 5RX** - 14 kanal beam
6. **Generic LED PAR 64 RGBW** - 8 kanal basit par
7. **Elation Platinum Spot 5R** - 16 kanal spot

### Yeni Cihaz Ekleme
1. `assets/` klasörüne JSON dosyası ekleyin
2. `default_library.json` içindeki `fixtures` dizisine ekleyin
3. Uygulamayı yeniden başlatın

Detaylı bilgi için: [README_FIXTURES.md](README_FIXTURES.md)

## 🌐 Art-Net Protokolü

- **Port**: 6454 (UDP)
- **Paket Formatı**: ArtDmx
- **Protocol Version**: 14
- **Max Refresh Rate**: 40Hz (25ms)
- **Universe**: 0-15 (ayarlanabilir)

## 🚀 Kullanım

1. **Ayarlar**: Hedef IP adresini (ESP32 Art-Net Node) ve Universe numarasını ayarlayın
2. **Patch**: Fikstür kütüphanesinden cihaz seçip DMX adresine yamalayın
3. **Control**: Yamalı fikstürleri seçip XY Pad, Color Picker ve Slider'larla kontrol edin

## 🔧 Geliştirme

### Proje Yapısı
```
lib/
├── main.dart
├── models/
│   └── fixture.dart
├── services/
│   ├── artnet_service.dart
│   ├── dmx_engine.dart
│   ├── fixture_manager.dart
│   └── ofl_parser.dart
├── screens/
│   ├── home_screen.dart
│   ├── control_screen.dart
│   ├── patch_screen.dart
│   └── settings_screen.dart
└── widgets/
    ├── xy_pad.dart
    ├── color_picker.dart
    └── dmx_slider.dart

assets/
├── default_library.json
├── clay_paky_sharpy.json
└── martin_mac_aura.json
```

## 📝 Lisans

Bu proje eğitim ve profesyonel kullanım için geliştirilmiştir.

## 🔗 Kaynaklar

- [Open Fixture Library](https://open-fixture-library.org/)
- [Art-Net Protocol](https://art-net.org.uk/)
- [Flutter Documentation](https://docs.flutter.dev/)

---

**Geliştirici**: DMX Art-Net Controller Team  
**Versiyon**: 1.0.0  
**GitHub**: https://github.com/SERTveAC54/dxmxxd

