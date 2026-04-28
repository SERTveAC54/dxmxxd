# 🚨 ÖNEMLİ: Proje Taşınmalı!

## ❌ Sorun
Proje yolu Türkçe karakter içeriyor: `D:\Arşiv\dmx uygulama`

Android Gradle Türkçe karakterleri (`ş`, `ı`, vb.) desteklemiyor.

---

## ✅ ÇÖZÜM: Projeyi Taşı

### Adım 1: Yeni Klasör Oluştur
```
D:\Projects\dmx_controller
```

### Adım 2: Projeyi Kopyala
```powershell
# PowerShell'de:
xcopy "D:\Arşiv\dmx uygulama" "D:\Projects\dmx_controller" /E /I /H
```

Veya manuel:
1. `D:\Arşiv\dmx uygulama` klasörünü aç
2. Tüm dosyaları seç (Ctrl+A)
3. Kopyala (Ctrl+C)
4. `D:\Projects\dmx_controller` klasörüne yapıştır (Ctrl+V)

### Adım 3: Yeni Klasörde Aç
```powershell
cd D:\Projects\dmx_controller
```

### Adım 4: APK Oluştur
```powershell
C:\flutter\bin\flutter.bat clean
C:\flutter\bin\flutter.bat build apk --release
```

---

## 🎯 Hızlı Komutlar

```powershell
# 1. Yeni klasör oluştur
New-Item -ItemType Directory -Path "D:\Projects\dmx_controller" -Force

# 2. Kopyala
Copy-Item "D:\Arşiv\dmx uygulama\*" "D:\Projects\dmx_controller" -Recurse -Force

# 3. Geç
cd D:\Projects\dmx_controller

# 4. Build
C:\flutter\bin\flutter.bat build apk --release
```

---

## 📱 APK Nerede Olacak?
```
D:\Projects\dmx_controller\build\app\outputs\flutter-apk\app-release.apk
```

---

## 💡 Neden Taşımalıyız?

Android build araçları (Gradle, NDK) ASCII olmayan karakterleri desteklemiyor:
- ❌ `Arşiv` → `Ar�iv` (bozuluyor)
- ❌ `ş`, `ı`, `ğ`, `ü`, `ö`, `ç`
- ✅ Sadece İngilizce karakterler: `a-z`, `A-Z`, `0-9`, `_`, `-`

---

## 🚀 Alternatif Yollar

### Yol 1: C:\ Sürücüsü
```
C:\dmx_controller
```

### Yol 2: Kullanıcı Klasörü
```
C:\Users\Sertac\dmx_controller
```

### Yol 3: Projects Klasörü (ÖNERİLEN)
```
D:\Projects\dmx_controller
```

---

**🎊 Taşıdıktan sonra APK başarıyla oluşacak!**
