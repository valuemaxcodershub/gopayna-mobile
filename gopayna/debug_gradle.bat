@echo off
setlocal enabledelayedexpansion
cd /d "C:\xampp\htdocs\gopayna\mobile\gopayna\android"
set JAVA_HOME=C:\Program Files\Android\Android Studio1\jbr
set PATH=%JAVA_HOME%\bin;%PATH%

echo Testing individual commands:
echo.

echo 1. Testing java:
java -version
if !errorlevel! neq 0 (
    echo Java FAILED
    exit /b 1
)
echo Java OK
echo.

echo 2. Testing current directory:
echo Current dir: %CD%
dir gradlew.bat
if !errorlevel! neq 0 (
    echo gradlew.bat not found
    exit /b 1
)
echo gradlew.bat found
echo.

echo 3. Testing gradlew.bat execution:
echo Running: gradlew.bat --version
gradlew.bat --version
echo Exit code: !errorlevel!

pause