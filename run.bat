@echo off
cls
echo ========================================
echo DMX512 Art-Net Controller
echo ========================================
echo.

echo Paketler kontrol ediliyor...
C:\flutter\bin\flutter.bat pub get

echo.
echo Chrome'da baslatiliyor (Port 8081)...
echo.
echo Hot reload: r tusuna basin
echo Cikis: q tusuna basin
echo.

C:\flutter\bin\flutter.bat run -d chrome --web-port=8081

pause
