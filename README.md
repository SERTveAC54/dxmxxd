# DMX512 Art-Net Controller

Profesyonel sahne ışıklandırması için Flutter tabanlı mobil DMX kontrol uygulaması.

## Özellikler

### 🎛️ Temel Özellikler
- **Art-Net DMX512 Protokolü**: UDP üzerinden standart Art-Net paket gönderimi
- **40Hz Throttling**: Ağ tıkanıklığını önleyen akıllı paket gönderim sistemi (25ms)
- **512 Kanal Kontrolü**: Tam universe desteği
- **Gerçek Zamanlı Kontrol**: Anlık tepki veren dokunmatik arayüz

### 🎨 Kontrol Arayüzü
- **XY Pad**: Moving Head'ler için hassas Pan/Tilt kontrolü
- **Color Picker**: RGB/RGBW LED'ler için renk paleti
- **DMX Sliders**: Dimmer, Zoom, Focus, Strobe kontrolü
- **Preset Butonlar**: Gobo ve renk tekerleği seçimi

### 📚 Fikstür Yönetimi
- JSON tabanlı fikstür kütüphanesi
- Kolay yamalama (patching) sistemi
- Adres çakışma kontrolü
- Çoklu fikstür desteği

### 🎯 Profesyonel Tasarım
- Dark mode (karanlık sahne ortamı için)
- Yüksek kontrastlı neon renkler (Cyan/Orange)
- Hızlı tepki veren UI
- Landscape optimizasyonu

## Kurulum

### Gereksinimler
- Flutter SDK (3.0+)
- Dart SDK
- Android Studio / Xcode (mobil geliştirme için)

### Bağımlılıklar
```bash
flutter pub get
```

### Çalıştırma
```bash
flutter run
```

## Mimari

### Core Services
- **DMXEngine**: 512 kanallık DMX universe yönetimi ve throttling
- **ArtNetService**: UDP soket yönetimi ve Art-Net paket oluşturma
- **FixtureManager**: Fikstür kütüphanesi ve yamalama yönetimi

### UI Components
- **XYPad**: Pan/Tilt joystick kontrolü
- **DMXColorPicker**: RGB renk seçici
- **DMXSlider**: Dikey kanal slider'ları

### Screens
- **ControlScreen**: Ana kontrol arayüzü
- **PatchScreen**: Fikstür yamalama ekranı
- **SettingsScreen**: Ağ ayarları

## Art-Net Protokolü

Uygulama standart Art-Net DMX512 protokolünü kullanır:
- Port: 6454 (UDP)
- Paket Formatı: ArtDmx
- Protocol Version: 14
- Max Refresh Rate: 40Hz (25ms)

## Kullanım

1. **Ayarlar**: Hedef IP adresini ve Universe numarasını ayarlayın
2. **Patch**: Fikstür kütüphanesinden cihaz seçip DMX adresine yamalayın
3. **Control**: Yamalı fikstürleri seçip XY Pad, Color Picker ve Slider'larla kontrol edin

## Örnek Fikstürler

Uygulama 2 örnek fikstür profili ile gelir:
- **Beam 230W Moving Head**: 16 kanal (Pan/Tilt, Gobo, Color Wheel)
- **LED PAR RGBW**: 7 kanal (RGBW renk karışımı)

## Lisans

Bu proje eğitim ve profesyonel kullanım için geliştirilmiştir.
