@echo off
setlocal EnableDelayedExpansion

title ZTN Verification

REM ==========================================
REM CONFIGURATION
REM ==========================================
set "CURRENT_VERSION=1.0.1"
set "API=https://ztn-verify-production.up.railway.app"

REM Replace these with your actual RAW GitHub URLs:
set "VERSION_URL=https://raw.githubusercontent.com/YourUsername/YourRepo/main/version.txt"
set "SCRIPT_URL=https://raw.githubusercontent.com/YourUsername/YourRepo/main/Loader.bat"

REM ==========================================
REM CHECK FOR UPDATES
REM ==========================================
echo Checking for updates...

REM Fetch remote version from GitHub
powershell -NoProfile -Command ^
    "try { (Invoke-RestMethod -Uri '%VERSION_URL%').Trim() } catch { 'ERROR' }" > "%TEMP%\ztn_remote_ver.txt"

set /p REMOTE_VERSION=<"%TEMP%\ztn_remote_ver.txt"
del "%TEMP%\ztn_remote_ver.txt" >nul 2>&1

REM Skip update check if offline or error
if "%REMOTE_VERSION%"=="ERROR" (
    echo Unable to check for updates. Continuing...
    timeout /t 2 >nul
    goto START_MAIN
)

REM Compare versions
if not "%REMOTE_VERSION%"=="%CURRENT_VERSION%" (
    echo.
    echo New version found: v%REMOTE_VERSION% ^(Current: v%CURRENT_VERSION%^)
    echo Downloading update...
    
    REM Download the new script to a temporary file
    powershell -NoProfile -Command ^
        "Invoke-WebRequest -Uri '%SCRIPT_URL%' -OutFile '%TEMP%\Loader_new.bat'"
    
    if exist "%TEMP%\Loader_new.bat" (
        echo Applying update...
        
        REM Spawn a background command process to replace the running file and restart it
        start /b "" cmd /c "timeout /t 1 /nobreak >nul & move /y ""%TEMP%\Loader_new.bat"" ""%~f0"" >nul & start "" ""%~f0"" & exit"
        exit /b
    ) else (
        echo Update download failed. Continuing with current version...
        timeout /t 2 >nul
    )
)

:START_MAIN
cls

echo.
echo ==========================================
echo             ZTN Verification 1.0.1
echo ==========================================
echo.
echo Connecting to verification server...
echo.

REM ==========================================
REM CREATE VERIFICATION ID
REM ==========================================

powershell -NoProfile -Command ^
    "$r = Invoke-RestMethod -Method Post -Uri '%API%/create'; $r.id" > "%TEMP%\ztn_id.txt"

if errorlevel 1 (
    echo.
    echo [ERROR] Could not connect to verification server.
    echo.
    pause
    exit /b
)

set /p ID=<"%TEMP%\ztn_id.txt"

del "%TEMP%\ztn_id.txt" >nul 2>&1

if "!ID!"=="" (
    echo.
    echo [ERROR] Server did not return a verification ID.
    echo.
    pause
    exit /b
)

REM ==========================================
REM SHOW VERIFICATION ID
REM ==========================================

cls

echo.
echo ==========================================
echo             ZTN Verification
echo ==========================================
echo.
echo Your verification ID is:
echo.
echo                 !ID!
echo.
echo ==========================================
echo.
echo Go to Discord and run:
echo.
echo                 /verify !ID!
echo.
echo ==========================================
echo.
echo Waiting for verification...
echo.

REM ==========================================
REM CHECK VERIFICATION
REM ==========================================

:CHECK

timeout /t 3 /nobreak >nul

powershell -NoProfile -Command ^
    "$r = Invoke-RestMethod -Uri '%API%/status/!ID!'; if ($r.verified -eq $true) { exit 0 } else { exit 1 }"

if !errorlevel! EQU 0 goto VERIFIED

goto CHECK

REM ==========================================
REM VERIFIED
REM ==========================================

:VERIFIED

cls

echo.
echo ==========================================
echo          Verification Successful!
echo ==========================================
echo.
echo your ID have been verified: !ID!
echo.
echo ==========================================
echo.

pause
exit /b
