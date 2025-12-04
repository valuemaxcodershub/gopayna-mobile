@echo off
setlocal enabledelayedexpansion
cd /d "C:\xampp\htdocs\gopayna\mobile\gopayna\android"
set JAVA_HOME=C:\Program Files\Android\Android Studio1\jbr
set PATH=%JAVA_HOME%\bin;%PATH%

echo Building Android APK using Gradle directly:
echo.

set CLASSPATH=%CD%\gradle\wrapper\gradle-wrapper.jar
"!JAVA_HOME!\bin\java.exe" -classpath "!CLASSPATH!" org.gradle.wrapper.GradleWrapperMain assembleDebug

echo.
echo Build completed. Exit code: !errorlevel!
echo.

if exist "app\build\outputs\apk\debug\app-debug.apk" (
    echo SUCCESS: APK found at app\build\outputs\apk\debug\app-debug.apk
    echo File size:
    dir "app\build\outputs\apk\debug\app-debug.apk"
) else (
    echo APK not found in expected location
    echo Checking other possible locations...
    dir /s *.apk 2>nul
)

pause