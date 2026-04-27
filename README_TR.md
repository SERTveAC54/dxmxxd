# 🎭 DMX512 Art-Net Controller

Profesyonel sahne aydınlatma kontrolü için Flutter tabanlı DMX512 Art-Net controller uygulaması.

![Flutter](https://img.shields.io/badge/Flutter-3.0+-blue.svg)
![Platform](https://img.shields.io/badge/Platform-Web%20%7C%20Windows-green.svg)
![Fixtures](https://img.shields.io/badge/Fixtures-2219-orange.svg)

---

## ✨ Özellikler

### 🎮 Workspace (Canlı Kontrol)
- **Canlı DMX Görselleştirme** - Gerçek zamanlı renk ve yoğunluk gösterimi
- **Multi-Select** - Birden fazla fixture'ı aynı anda kontrol edin
- **XY Pad** - Pan/Tilt kontrolü için joystick
- **Master Fader** - Grup dimmer kontrolü
- **Attribute Sliders** - Gobo, Prism, Color Wheel, Focus, vb.
- **Manufacturer Filtreleme** - Markaya göre fixture filtreleme

### 📋 Patch Screen (Fixture Yönetimi)
- **2219 Fixture Kütüphanesi** (510 JSON + 1710 QXF)
- **Gerçek Zamanlı Arama** - Fixture adı veya marka ile arama
- **DMX Kanal Tablosu** - 512 kanalın interaktif haritası
- **Otomatik Adres Bulma** - Boş adresleri otomatik tespit
- **Çakışma Önleme** - Adres çakışmalarını engeller
- **Manufacturer Filtreleme** - 200+ marka desteği

### ⚙️ Settings
- **Art-Net Konfigürasyonu** - IP ve Universe ayarları
- **DMX Engine** - 40Hz throttling ile optimize edilmiş
- **Tema Ayarları** - Dark mode, neon cyan/orange aksanlar

---

## 🚀 Hızlı Başlangıç

### 1. Çift Tıklama ile Başlat
```
run.bat dosyasına çift tıklayın
```

### 2. Manuel Başlatma
```powershell
C:\flutter\bin\flutter.bat run -d chrome
```

Detaylı talimatlar için: **[NASIL_CALISTIRILIR.md](NASIL_CALISTIRILIR.md)**

---

## 📊 DMX Kanal Tablosu Kullanımı

### Yeni Özellik: Akıllı Patch Sistemi

1. **Patch** sekmesine gidin
2. Fixture seçin ve **+** butonuna tıklayın
3. **DMX Kanal Tablosu** açılır:
   - 🟢 **Yeşil** = Boş kanallar
   - 🔴 **Kırmızı** = Kullanımda
   - 🔵 **Mavi** = Seçili aralık
4. **Otomatik adres** için ⚡ butonuna tıklayın
5. Veya tabloda boş kanala tıklayarak manuel seçin
6. **PATCH** butonuna basın

### Örnek Senaryo:
```
Robot #1: Ch 1-18   (18 kanal) ✅
Robot #2: Ch 19-36  (18 kanal) ✅ Otomatik önerilir
LED Par:  Ch 37-43  (7 kanal)  ✅ Çakışma yok!
```

---

## 🎨 Desteklenen Fixture Markaları

200+ marka, 2219 fixture:

- **Martin** - MAC Aura, MAC Viper, vb.
- **Robe** - Robin, Pointe, vb.
- **Chauvet** - Rogue, Maverick, vb.
- **Clay Paky** - Sharpy, Alpha, vb.
- **Elation** - Platinum, Artiste, vb.
- **American DJ** - Vizi, Inno, vb.
- **Showtec** - Phantom, Spectral, vb.
- **Stairville** - LED Par, Moving Head, vb.
- Ve 190+ marka daha...

---

## 🛠️ Teknoloji Stack

- **Flutter 3.0+** - Cross-platform UI framework
- **Provider** - State management
- **Art-Net** - DMX over UDP protocol
- **Shared Preferences** - Local storage
- **QLC+ Format** - QXF fixture library support

---

## 📁 Proje Yapısı

```
dmx_artnet_controller/
├── lib/
│   ├── main.dart                    # Ana uygulama
│   ├── models/
│   │   └── fixture.dart             # Fixture model
│   ├── services/
│   │   ├── dmx_engine.dart          # DMX 512 engine
│   │   ├── artnet_service.dart      # Art-Net UDP
│   │   └── fixture_manager.dart     # Fixture yönetimi
│   ├── screens/
│   │   ├── workspace_screen.dart    # Canlı kontrol
│   │   ├── patch_screen.dart        # Fixture patch
│   │   └── settings_screen.dart     # Ayarlar
│   └── widgets/
│       ├── xy_pad.dart              # Pan/Tilt joystick
│       ├── dmx_slider.dart          # Vertical fader
│       └── color_picker.dart        # RGB picker
├── assets/
│   └── fixtures/
│       ├── library_full.json        # 2219 fixture
│       └── [200+ marka klasörü]/
├── run.bat                          # Hızlı başlatma
├── NASIL_CALISTIRILIR.md           # Detaylı talimatlar
└── pubspec.yaml                     # Bağımlılıklar
```

---

## 🎯 Kullanım Senaryoları

### 1. Sahne Aydınlatma
- Tiyatro gösterileri
- Konser aydınlatması
- Canlı performanslar

### 2. Etkinlik Aydınlatması
- Düğünler
- Kurumsal etkinlikler
- DJ setleri

### 3. Mimari Aydınlatma
- Bina cephe aydınlatması
- Peyzaj aydınlatması
- Sanat enstalasyonları

### 4. Test ve Geliştirme
- Fixture test
- DMX protokol geliştirme
- Aydınlatma tasarımı

---

## 🔌 Art-Net Bağlantısı

### Web Platformu (Chrome)
⚠️ **Not:** Web tarayıcıları UDP desteklemez. Art-Net sadece görsel amaçlıdır.

### Windows Desktop
✅ **Tam destek:** Gerçek DMX cihazlarla çalışır.

```powershell
# Windows için derle
flutter build windows

# Çalıştır
flutter run -d windows
```

---

## 📈 Performans

- **DMX Engine:** 40Hz güncelleme hızı
- **512 Kanal:** Tam DMX universe desteği
- **2219 Fixture:** Anında arama ve filtreleme
- **Smooth UI:** 60 FPS animasyonlar

---

## 🤝 Katkıda Bulunma

Katkılarınızı bekliyoruz! Lütfen:

1. Fork yapın
2. Feature branch oluşturun (`git checkout -b feature/amazing-feature`)
3. Commit yapın (`git commit -m 'Add amazing feature'`)
4. Push edin (`git push origin feature/amazing-feature`)
5. Pull Request açın

---

## 📝 Lisans

Bu proje açık kaynaklıdır.

---

## 🙏 Teşekkürler

- **QLC+** - Fixture library
- **Open Fixture Library** - Fixture definitions
- **Flutter Team** - Harika framework

---

## 📞 İletişim

Sorularınız için:
- GitHub Issues
- Pull Requests

---

## 🎊 Özellikler Yol Haritası

- [ ] Scene kaydetme/yükleme
- [ ] Preset sistemı
- [ ] Timeline/Cue list
- [ ] MIDI controller desteği
- [ ] OSC protokol desteği
- [ ] Multi-universe (Art-Net)
- [ ] Fixture gruplaması
- [ ] Efekt jeneratörü
- [ ] Mobil uygulama (iOS/Android)

---

**Yapım:** 2026 | **Versiyon:** 1.0.0 | **Platform:** Flutter Web & Windows

🎭 **Profesyonel DMX kontrolünün tadını çıkarın!**
