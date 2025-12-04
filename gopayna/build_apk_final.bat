@echo off
setlocal enabledelayedexpansion
cd /d "C:\xampp\htdocs\gopayna\mobile\gopayna\android"
set JAVA_HOME=C:\Program Files\Android\Android Studio1\jbr
set PATH=%JAVA_HOME%\bin;%PATH%

echo Building APK...
echo.

gradlew.bat assembleDebug

echo.
echo Build completed. Exit code: !errorlevel!
echo.

if !errorlevel! equ 0 (
    echo SUCCESS! Looking for APK files:
    echo.
    dir /s *.apk
) else (
    echo BUILD FAILED
)

pause