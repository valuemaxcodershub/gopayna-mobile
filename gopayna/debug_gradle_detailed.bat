@echo off
setlocal enabledelayedexpansion
cd /d "C:\xampp\htdocs\gopayna\mobile\gopayna\android"
set JAVA_HOME=C:\Program Files\Android\Android Studio1\jbr
set PATH=%JAVA_HOME%\bin;%PATH%

echo Debugging Gradle wrapper execution:
echo.

echo JAVA_HOME=%JAVA_HOME%
echo.

echo Contents of JAVA_HOME\bin:
dir "%JAVA_HOME%\bin\java*"
echo.

echo Testing Java executable:
set JAVA_EXE=%JAVA_HOME%\bin\java.exe
echo JAVA_EXE=!JAVA_EXE!
"!JAVA_EXE!" -version
if !errorlevel! neq 0 (
    echo Java executable test FAILED
    pause
    exit /b 1
)
echo Java executable OK
echo.

echo Testing Gradle wrapper JAR:
if exist "gradle\wrapper\gradle-wrapper.jar" (
    echo gradle-wrapper.jar exists
) else (
    echo gradle-wrapper.jar NOT FOUND
    pause
    exit /b 1
)
echo.

echo Testing manual Gradle command:
set CLASSPATH=%CD%\gradle\wrapper\gradle-wrapper.jar
echo CLASSPATH=!CLASSPATH!
echo.
echo Running Java with Gradle wrapper:
"!JAVA_EXE!" -classpath "!CLASSPATH!" org.gradle.wrapper.GradleWrapperMain --version
echo Exit code: !errorlevel!

pause