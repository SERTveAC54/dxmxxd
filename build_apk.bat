@echo off
echo ========================================
echo DMX512 Art-Net Controller
echo APK OLUSTURUCU
echo ========================================
echo.
echo Release APK olusturuluyor...
echo (Bu islem 3-10 dakika surebilir)
echo.

C:\flutter\bin\flutter.bat build apk --release

echo.
echo ========================================
echo TAMAMLANDI!
echo ========================================
echo.
echo APK dosyasi burada:
echo build\app\outputs\flutter-apk\app-release.apk
echo.
echo Bu dosyayi Android telefonunuza kopyalayip yukleyin!
echo.

explorer build\app\outputs\flutter-apk

pause
