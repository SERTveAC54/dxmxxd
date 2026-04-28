# 🔧 Android SDK Kurulum Adımları

## ⚠️ Şu Anda Eksik: cmdline-tools

---

## 📋 ADIM ADIM KURULUM

### 1. Android Studio'yu Aç
```
Başlat → Android Studio
```

### 2. SDK Manager'ı Aç
```
Üst menü → Tools → SDK Manager
```
Veya
```
Welcome Screen → More Actions → SDK Manager
```

### 3. SDK Tools Sekmesine Geç
```
SDK Manager → SDK Tools (üstteki sekme)
```

### 4. Şunları İşaretle (✅):
- ✅ **Android SDK Command-line Tools (latest)**
- ✅ **Android SDK Build-Tools** (en son versiyon)
- ✅ **Android SDK Platform-Tools**
- ✅ **Android Emulator** (opsiyonel)
- ✅ **Google Play services** (opsiyonel)

### 5. Apply Butonuna Bas
```
Sağ alttaki "Apply" veya "OK" butonuna tıkla
```

### 6. İndirmeyi Bekle
```
İndirme ve kurulum 5-10 dakika sürebilir
```

### 7. Android Studio'yu Kapat ve Aç
```
Tamamen kapat ve yeniden aç
```

---

## ✅ KURULUM SONRASI TEST

### PowerShell'de Çalıştır:
```powershell
C:\flutter\bin\flutter.bat doctor -v
```

### Görmek İstediğimiz:
```
[√] Android toolchain - develop for Android devices (Android SDK version 34.0.0)
    • Android SDK at C:\Users\Sertac\AppData\Local\Android\sdk
    • Platform android-34, build-tools 34.0.0
    • Java binary at: ...
    • All Android licenses accepted.
```

---

## 🔑 Lisansları Kabul Et

SDK kurulduktan sonra:

```powershell
C:\flutter\bin\flutter.bat doctor --android-licenses
```

Tüm sorulara **"y"** (yes) cevabı ver.

---

## 🚀 APK OLUŞTUR

Her şey tamam olduktan sonra:

```powershell
build_apk.bat
```

Veya manuel:

```powershell
C:\flutter\bin\flutter.bat build apk --release
```

---

## 📍 APK Nerede Olacak?

```
build\app\outputs\flutter-apk\app-release.apk
```

---

## 🎯 Hızlı Kontrol Listesi

- [ ] Android Studio açıldı
- [ ] SDK Manager açıldı
- [ ] SDK Tools sekmesine geçildi
- [ ] Command-line Tools işaretlendi
- [ ] Build-Tools işaretlendi
- [ ] Platform-Tools işaretlendi
- [ ] Apply'a basıldı
- [ ] İndirme tamamlandı
- [ ] Android Studio yeniden başlatıldı
- [ ] `flutter doctor` çalıştırıldı
- [ ] Lisanslar kabul edildi
- [ ] APK build edildi

---

## 💡 İpuçları

1. **İnternet bağlantısı** gerekli (SDK indirilecek)
2. **5-10 dakika** sürebilir
3. **Yönetici yetkisi** gerekebilir
4. **Antivirus** kapatılabilir (hızlandırır)

---

## 🔧 Alternatif: Manuel Kurulum

Eğer SDK Manager çalışmazsa:

### 1. cmdline-tools İndir:
https://developer.android.com/studio#command-line-tools-only

### 2. Çıkart:
```
C:\Users\Sertac\AppData\Local\Android\sdk\cmdline-tools\latest\
```

### 3. Ortam Değişkeni:
```
ANDROID_HOME = C:\Users\Sertac\AppData\Local\Android\sdk
PATH += %ANDROID_HOME%\cmdline-tools\latest\bin
PATH += %ANDROID_HOME%\platform-tools
```

---

**🎊 SDK kurulunca APK oluşturmaya hazırız!**
