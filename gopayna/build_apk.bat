@echo off
cd /d "C:\xampp\htdocs\gopayna\mobile\gopayna\android"
set JAVA_HOME=C:\Program Files\Android\Android Studio1\jbr
set PATH=%JAVA_HOME%\bin;%PATH%
echo Java version:
java -version
echo.
echo Running Gradle...
gradlew.bat assembleDebug --stacktrace --info
pause