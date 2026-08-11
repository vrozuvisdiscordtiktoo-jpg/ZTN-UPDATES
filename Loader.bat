@echo off
setlocal EnableDelayedExpansion

title ZTN Loader

REM ============================================================
REM CONFIG
REM ============================================================

set "API=https://ztn-verify-production.up.railway.app"
set "VERSION=1.1"

REM ============================================================
REM UPDATE CHECK
REM ============================================================

cls

echo.
echo ==========================================
echo              ZTN Loader
echo ==========================================
echo.
echo Current version: %VERSION%
echo Checking for updates...
echo.

set "LATEST_VERSION="

powershell -NoProfile -Command ^
    "$r = Invoke-RestMethod -Uri '%API%/version'; $r.version" > "%TEMP%\ztn_version.txt"

if errorlevel 1 (
    echo.
    echo [WARNING] Could not check for updates.
    echo Continuing with current version...
    timeout /t 2 /nobreak >nul
    goto CREATE_ID
)

set /p LATEST_VERSION=<"%TEMP%\ztn_version.txt"

del "%TEMP%\ztn_version.txt" >nul 2>&1

if "!LATEST_VERSION!"=="" (
    echo.
    echo [WARNING] Server did not return a version.
    echo Continuing with current version...
    timeout /t 2 /nobreak >nul
    goto CREATE_ID
)

echo Latest version: !LATEST_VERSION!
echo.

REM ============================================================
REM CHECK IF UPDATE IS NEEDED
REM ============================================================

if "%VERSION%"=="!LATEST_VERSION!" (
    echo You are using the latest version.
    timeout /t 2 /nobreak >nul
    goto CREATE_ID
)

echo.
echo ==========================================
echo             Update Available
echo ==========================================
echo.
echo Current version: %VERSION%
echo New version:     !LATEST_VERSION!
echo.
echo Downloading update...
echo.

REM ============================================================
REM DOWNLOAD UPDATE
REM ============================================================

set "UPDATE_FILE=%TEMP%\ZTN_Loader_New.bat"

powershell -NoProfile -Command ^
    "try { Invoke-WebRequest -Uri '%API%/update' -OutFile '%UPDATE_FILE%' -UseBasicParsing; exit 0 } catch { exit 1 }"

if errorlevel 1 (
    echo.
    echo [WARNING] Failed to download update.
    echo Continuing with current version...
    timeout /t 3 /nobreak >nul
    goto CREATE_ID
)

if not exist "%UPDATE_FILE%" (
    echo.
    echo [WARNING] Update file was not downloaded.
    echo Continuing with current version...
    timeout /t 3 /nobreak >nul
    goto CREATE_ID
)

REM ============================================================
REM CREATE SELF-UPDATE HELPER
REM ============================================================

set "UPDATE_HELPER=%TEMP%\ZTN_Update_Helper.bat"

(
    echo @echo off
    echo timeout /t 2 /nobreak ^>nul
    echo copy /Y "%UPDATE_FILE%" "%~f0" ^>nul
    echo start "" "%~f0"
    echo del "%%~f0" ^>nul 2^>^&1
) > "%UPDATE_HELPER%"

echo.
echo Update downloaded successfully.
echo Restarting...
echo.

start "" "%UPDATE_HELPER%"

exit /b


REM ============================================================
REM CREATE VERIFICATION ID
REM ============================================================

:CREATE_ID

cls

echo.
echo ==========================================
echo              ZTN Loader
echo ==========================================
echo.
echo Connecting to verification server...
echo.

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

REM ============================================================
REM SHOW VERIFICATION ID
REM ============================================================

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

REM ============================================================
REM CHECK VERIFICATION
REM ============================================================

:CHECK

timeout /t 3 /nobreak >nul

powershell -NoProfile -Command ^
    "$r = Invoke-RestMethod -Uri '%API%/status/!ID!'; if ($r.verified -eq $true) { exit 0 } else { exit 1 }"

if !errorlevel! EQU 0 goto VERIFIED

goto CHECK


REM ============================================================
REM VERIFIED
REM ============================================================

:VERIFIED

cls

echo.
echo ==========================================
echo          Verification Successful!
echo ==========================================
echo.
echo Your ID has been verified: !ID!
echo.
echo ==========================================
echo.

pause
exit /b
