@echo off
setlocal EnableDelayedExpansion

title ZTN Verification

REM =========================================================
REM CONFIG
REM =========================================================

set "API=https://ztn-verify-production.up.railway.app"

set "CURRENT_VERSION=1.0"
set "VERSION_URL=https://raw.githubusercontent.com/vrozuvisdiscordtiktoo-jpg/ZTN-UPDATES/main/version.txt"
set "UPDATE_URL=https://raw.githubusercontent.com/vrozuvisdiscordtiktoo-jpg/ZTN-UPDATES/main/Loader.bat"

set "UPDATE_FILE=%TEMP%\ZTN-Loader-Update.bat"
set "VERSION_FILE=%TEMP%\ZTN-Version.txt"

REM =========================================================
REM CHECK FOR UPDATE
REM =========================================================

cls
echo.
echo ==========================================
echo             ZTN Verification 1.0.1
echo ==========================================
echo.
echo Checking for updates...
echo.

powershell -NoProfile -Command ^
"try { Invoke-WebRequest -Uri '%VERSION_URL%' -OutFile '%VERSION_FILE%' -UseBasicParsing; exit 0 } catch { exit 1 }"

if errorlevel 1 (
    echo Could not check for updates.
    echo Continuing with version %CURRENT_VERSION%...
    timeout /t 2 /nobreak >nul
    goto START
)

set /p LATEST_VERSION=<"%VERSION_FILE%"
del "%VERSION_FILE%" >nul 2>&1

if "!LATEST_VERSION!"=="" (
    echo Could not read latest version.
    echo Continuing with version %CURRENT_VERSION%...
    timeout /t 2 /nobreak >nul
    goto START
)

echo Current version: %CURRENT_VERSION%
echo Latest version:  !LATEST_VERSION!
echo.

if "%CURRENT_VERSION%"=="!LATEST_VERSION!" (
    echo You are up to date!
    timeout /t 2 /nobreak >nul
    goto START
)

echo A new version is available!
echo.
echo Updating ZTN Verification...
echo.

REM =========================================================
REM DOWNLOAD NEW LOADER
REM =========================================================

powershell -NoProfile -Command ^
"try { Invoke-WebRequest -Uri '%UPDATE_URL%' -OutFile '%UPDATE_FILE%' -UseBasicParsing; exit 0 } catch { exit 1 }"

if errorlevel 1 (
    echo.
    echo [ERROR] Failed to download the update.
    echo.
    echo Continuing with current version...
    timeout /t 3 /nobreak >nul
    goto START
)

REM =========================================================
REM VERIFY UPDATE FILE
REM =========================================================

if not exist "%UPDATE_FILE%" (
    echo.
    echo [ERROR] Update file was not downloaded.
    echo.
    timeout /t 3 /nobreak >nul
    goto START
)

echo Update downloaded successfully.
echo Installing update...
echo.

REM =========================================================
REM CREATE UPDATE HELPER
REM =========================================================

set "UPDATE_HELPER=%TEMP%\ZTN-Update-Helper.bat"

(
    echo @echo off
    echo timeout /t 1 /nobreak ^>nul
    echo copy /y "%UPDATE_FILE%" "%~f0" ^>nul
    echo del "%UPDATE_FILE%" ^>nul 2^>^&1
    echo start "" "%~f0"
    echo del "%%~f0"
) > "%UPDATE_HELPER%"

REM =========================================================
REM RUN UPDATE
REM =========================================================

start "" "%UPDATE_HELPER%"

exit /b

REM =========================================================
REM START
REM =========================================================

:START

cls
echo.
echo ==========================================
echo             ZTN Verification
echo             Version %CURRENT_VERSION%
echo ==========================================
echo.
echo Connecting to verification server...
echo.

REM =========================================================
REM CREATE VERIFICATION ID
REM =========================================================

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

REM =========================================================
REM SHOW VERIFICATION ID
REM =========================================================

cls
echo.
echo ==========================================
echo             ZTN Verification
echo             Version %CURRENT_VERSION%
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

REM =========================================================
REM CHECK VERIFICATION
REM =========================================================

:CHECK

timeout /t 3 /nobreak >nul

powershell -NoProfile -Command ^
"$r = Invoke-RestMethod -Uri '%API%/status/!ID!'; if ($r.verified -eq $true) { exit 0 } else { exit 1 }"

if !errorlevel! EQU 0 goto VERIFIED

goto CHECK

REM =========================================================
REM VERIFIED
REM =========================================================

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
