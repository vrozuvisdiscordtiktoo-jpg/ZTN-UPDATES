@echo off
setlocal EnableDelayedExpansion

title ZTN Verification

set "API=https://ztn-verify-production.up.railway.app"

cls

echo.
echo ==========================================
echo             ZTN Verification
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
