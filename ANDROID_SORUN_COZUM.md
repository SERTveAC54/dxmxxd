# ⚠️ Android APK Sorunu ve Çözümler

## 🔴 Sorun
Android SDK tam kurulu değil. `cmdline-tools` eksik.

---

## ✅ ÇÖZÜM 1: Android Studio Kur (ÖNERİLEN)

### Adımlar:
1. **Android Studio'yu indir**: https://developer.android.com/studio
2. **Kur ve aç**
3. **SDK Manager** → **SDK Tools** sekmesi
4. Şunları işaretle:
   - ✅ Android SDK Command-line Tools
   - ✅ Android SDK Build-Tools
   - ✅ Android SDK Platform-Tools
5. **Apply** → İndir ve kur
6. **Bilgisayarı yeniden başlat**
7. `build_apk.bat` çalıştır

---

## ✅ ÇÖZÜM 2: Web Versiyonu Kullan (EN KOLAY)

APK yerine web versiyonunu kullan:

```powershell
# Chrome'da çalıştır
run.bat
```

### Avantajları:
- ✅ Hemen çalışır
- ✅ Kurulum gerektirmez
- ✅ Hızlı test
- ✅ Hot reload

### Dezavantajları:
- ❌ Art-Net çalışmaz (UDP yok)
- ❌ Telefonda çalışmaz

---

## ✅ ÇÖZÜM 3: Manuel cmdline-tools Kurulumu

### 1. cmdline-tools İndir:
https://developer.android.com/studio#command-line-tools-only

### 2. Çıkart:
```
C:\Users\Sertac\AppData\Local\Android\sdk\cmdline-tools\latest\
```

### 3. Ortam Değişkeni Ekle:
```
ANDROID_HOME = C:\Users\Sertac\AppData\Local\Android\sdk
```

### 4. Lisansları Kabul Et:
```powershell
C:\flutter\bin\flutter.bat doctor --android-licenses
```

### 5. APK Oluştur:
```powershell
build_apk.bat
```

---

## ✅ ÇÖZÜM 4: Başka Bilgisayarda Dene

Eğer başka bir bilgisayarda Android Studio kuruluysa:

1. **Projeyi kopyala** (USB, GitHub, vb.)
2. **O bilgisayarda build et**:
   ```powershell
   flutter build apk --release
   ```
3. **APK'yı geri getir**

---

## 🎯 Hızlı Test İçin

Şimdilik **Chrome versiyonunu** kullan:

```powershell
run.bat
```

Tüm özellikler çalışır (Art-Net hariç):
- ✅ 2219 Fixture kütüphanesi
- ✅ DMX Kanal tablosu
- ✅ Workspace kontrolü
- ✅ Patch sistemi
- ✅ Arama ve filtreleme

---

## 📊 Durum Özeti

| Özellik | Chrome | Android | Windows |
|---------|--------|---------|---------|
| **Çalışıyor** | ✅ | ❌ (SDK eksik) | ✅ |
| **Art-Net** | ❌ | ✅ | ✅ |
| **Kurulum** | Yok | Android Studio | Yok |
| **Hız** | ⚡ Hızlı | 🐢 Yavaş | ⚡ Hızlı |

---

## 💡 Öneri

1. **Şimdi**: `run.bat` ile Chrome'da test et
2. **Sonra**: Android Studio kur
3. **En son**: APK oluştur

---

## 📞 Yardım

### Flutter Doctor Çalıştır:
```powershell
C:\flutter\bin\flutter.bat doctor -v
```

### Android SDK Kontrol:
```
C:\Users\Sertac\AppData\Local\Android\sdk
```

---

**🎊 Chrome versiyonu şimdilik yeterli! Android Studio kurunca APK oluşturursun.**
