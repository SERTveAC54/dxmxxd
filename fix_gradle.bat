@echo off
echo Gradle wrapper duzeltiliyor...

cd android

echo Gradle wrapper siliniyor...
rmdir /s /q gradle 2>nul
del /f /q gradlew 2>nul
del /f /q gradlew.bat 2>nul

echo Gradle wrapper yeniden olusturuluyor...
C:\flutter\bin\flutter.bat create --platforms=android ..

cd ..

echo Tamam! Simdi build_apk.bat calistirin.
pause
