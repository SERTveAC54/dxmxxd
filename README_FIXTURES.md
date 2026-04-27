# Fikstür Kütüphanesi Kullanım Kılavuzu

## 📁 Klasör Yapısı

```
assets/
├── default_library.json      # Ana kütüphane (7 profesyonel cihaz)
├── clay_paky_sharpy.json     # Clay Paky Sharpy
├── martin_mac_aura.json      # Martin MAC Aura
└── [diğer cihazlar...]
```

## 🎭 Mevcut Cihazlar

### 1. Clay Paky Sharpy (16 Kanal)
- Profesyonel beam moving head
- Color wheel, gobo, prism
- 16-bit Pan/Tilt

### 2. Martin MAC Aura (18 Kanal)
- RGBW LED wash
- 16-bit renk kontrolü
- Zoom özelliği

### 3. Robe Robin 600 LEDWash (20 Kanal)
- Profesyonel LED wash
- RGBW + CTC
- Virtual color wheel

### 4. Chauvet Rogue R2 Spot (17 Kanal)
- Moving head spot
- Çift gobo tekerleği
- Prism ve frost

### 5. ADJ Vizi Beam 5RX (14 Kanal)
- Kompakt beam
- Gobo ve prism
- Hızlı Pan/Tilt

### 6. Generic LED PAR 64 RGBW (8 Kanal)
- Basit LED par
- RGBW renk karışımı
- Strobe ve macro

### 7. Elation Platinum Spot 5R (16 Kanal)
- 5R discharge lamp
- Çift gobo + prism
- Iris ve frost

## 📝 JSON Format

```json
{
  "id": "unique_id",
  "name": "Cihaz Adı",
  "manufacturer": "Üretici",
  "channelCount": 16,
  "channels": [
    {
      "offset": 0,
      "name": "Kanal Adı",
      "type": "channelType"
    }
  ]
}
```

## 🔧 Kanal Tipleri

- `pan`, `panFine` - Yatay hareket
- `tilt`, `tiltFine` - Dikey hareket
- `dimmer` - Parlaklık
- `strobe`, `shutter` - Strobe efekti
- `red`, `green`, `blue`, `white` - Renk kanalları
- `amber`, `uv`, `cyan`, `magenta`, `yellow` - Ek renkler
- `colorWheel` - Renk tekerleği
- `gobo`, `goboRotation` - Gobo tekerleği
- `prism`, `prismRotation` - Prizma
- `focus`, `zoom`, `iris`, `frost` - Optik
- `speed`, `macro`, `function`, `reset` - Kontrol

## ➕ Yeni Cihaz Ekleme

1. `assets/` klasörüne yeni JSON dosyası ekleyin
2. Yukarıdaki formatı kullanın
3. `default_library.json` içindeki `fixtures` dizisine ekleyin
4. Uygulamayı yeniden başlatın

## 🌐 Open Fixture Library

Binlerce profesyonel cihaz profili:
https://open-fixture-library.org/

İndirdiğiniz JSON dosyalarını `assets/` klasörüne atın!

## 💡 İpuçları

- Kanal offset'leri 0'dan başlar
- Fine kanallar 16-bit hassasiyet için kullanılır
- Manufacturer alanı opsiyoneldir
- ID benzersiz olmalıdır
