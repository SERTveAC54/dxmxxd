# 🚀 DMX512 Art-Net Controller - Nasıl Çalıştırılır?

## ⚡ Hızlı Başlatma (En Kolay Yöntem)

### Yöntem 1: Çift Tıklama
1. **`run.bat`** dosyasına çift tıklayın
2. Chrome otomatik açılacak
3. Uygulama yüklenecek (15-20 saniye)

---

## 🖥️ Manuel Başlatma

### PowerShell ile:
```powershell
# Proje klasörüne gidin
cd "D:\Arşiv\dmx uygulama"

# Chrome'da çalıştırın
C:\flutter\bin\flutter.bat run -d chrome
```

### CMD ile:
```cmd
cd "D:\Arşiv\dmx uygulama"
C:\flutter\bin\flutter.bat run -d chrome
```

---

## 🔧 Flutter PATH'e Ekleme (Opsiyonel)

Eğer her seferinde tam yol yazmak istemiyorsanız:

### Windows'ta Flutter'ı PATH'e Ekleyin:
1. **Windows Tuşu + R** → `sysdm.cpl` yazın
2. **Gelişmiş** sekmesi → **Ortam Değişkenleri**
3. **Path** değişkenini seçin → **Düzenle**
4. **Yeni** → `C:\flutter\bin` ekleyin
5. **Tamam** → PowerShell'i yeniden başlatın

Artık şöyle çalıştırabilirsiniz:
```powershell
flutter run -d chrome
```

---

## 📱 Farklı Platformlarda Çalıştırma

### Chrome (Web):
```powershell
flutter run -d chrome
```

### Windows Desktop:
```powershell
flutter run -d windows
```

### Tüm cihazları listele:
```powershell
flutter devices
```

---

## 🛠️ Sorun Giderme

### Problem: "flutter komutu bulunamadı"
**Çözüm:** Tam yolu kullanın:
```powershell
C:\flutter\bin\flutter.bat run -d chrome
```

### Problem: "Chrome bulunamadı"
**Çözüm:** Chrome'un kurulu olduğundan emin olun veya başka tarayıcı seçin:
```powershell
flutter run -d edge
```

### Problem: Uygulama yavaş yükleniyor
**Çözüm:** İlk çalıştırma 20-30 saniye sürebilir. Sonraki çalıştırmalar daha hızlı olacak.

### Problem: Değişiklikler görünmüyor
**Çözüm:** Hot reload yapın:
- Terminal'de **`r`** tuşuna basın
- Veya uygulamayı yeniden başlatın: **`R`** tuşu

---

## ⌨️ Çalışırken Kullanılabilir Komutlar

Uygulama çalışırken terminal'de:

| Tuş | Açıklama |
|-----|----------|
| `r` | Hot reload (hızlı yenileme) |
| `R` | Hot restart (tam yeniden başlatma) |
| `q` | Uygulamayı kapat |
| `c` | Ekranı temizle |
| `h` | Yardım menüsü |

---

## 📊 Başarılı Başlatma Çıktısı

Uygulama başarıyla başladığında şunu görmelisiniz:

```
✅ Kütüphane Yüklendi: 2219 Cihaz Hazır!
Debug service listening on ws://127.0.0.1:xxxxx
```

Chrome'da uygulama açılacak ve 3 sekme göreceksiniz:
- **Workspace** - Canlı DMX kontrolü
- **Patch** - Fixture ekleme/çıkarma
- **Settings** - Ayarlar

---

## 🎯 İlk Kullanım Adımları

1. **Patch** sekmesine gidin
2. Arama kutusuna fixture adı yazın (örn: "Martin")
3. Bir fixture seçin ve **+** butonuna tıklayın
4. **DMX Kanal Tablosu** açılır
5. Otomatik adres önerisini kabul edin veya manuel seçin
6. **PATCH** butonuna basın
7. **Workspace** sekmesine geçin
8. Fixture'ınızı kontrol edin!

---

## 💡 İpuçları

- **İlk çalıştırma** en uzun sürer (bağımlılıklar indirilir)
- **Hot reload (r)** kod değişikliklerini hızlıca test eder
- **DevTools** tarayıcıda F12 ile açılır
- **2219 fixture** kütüphanesi hazır!

---

## 📞 Yardım

Sorun yaşarsanız:
1. `flutter doctor` komutunu çalıştırın
2. Terminal çıktısını kontrol edin
3. Chrome DevTools'u açın (F12)

---

**🎊 Başarılar! Profesyonel DMX kontrolünün tadını çıkarın!**
