@echo off
echo ===================================================
echo   Building Meeting Room Booking System WAR
echo ===================================================

powershell -ExecutionPolicy Bypass -File "%~dp0build.ps1"

if %ERRORLEVEL% EQU 0 (
    echo [SUCCESS] target\meetingroom.war generated successfully.
) else (
    echo [ERROR] Build failed.
)
