@echo off
cls
echo ==========================================
echo   ANDROID CHAT SIMULATION
echo ==========================================

:: 1. Event ID Al
set /p eventId="Event ID Girin: "

if "%eventId%"=="" (
    echo [ERROR] ID girmediniz!
    goto End
)

echo.
echo [INFO] APK derleniyor ve yukleniyor...
echo [INFO] Bu islem ilk seferde biraz surebilir (Gradle Build).
echo.

:: 2. Android'de Çalıştır
:: -d android yerine, mevcut açık emülatörü otomatik bulması için sadece flutter run diyoruz
:: veya spesifik id için "flutter devices" komutuna bakabilirsin.
call flutter run -t lib/message_test_script.dart --dart-define=EVENT_ID="%eventId%"

:End
pause