@echo off
echo ========================================
echo DMX512 Art-Net Controller - ANDROID
echo ========================================
echo.
echo Bagli Android cihazlar kontrol ediliyor...
echo.
C:\flutter\bin\flutter.bat devices
echo.
echo ========================================
echo.
echo Android cihazda baslatiliyor...
echo (Ilk calisma 2-5 dakika surebilir)
echo.

C:\flutter\bin\flutter.bat run

pause
