@echo off
title DriveFlow AutoOrganizer
echo ========================================================
echo   Starting DriveFlow AutoOrganizer...
echo ========================================================

set SCRIPT_DIR=%~dp0

:: Launch background PowerShell server if not already running
netstat -ano | find "8080" >nul 2>&1
if %errorlevel% neq 0 (
    echo [1/2] Launching DriveFlow Local Micro-Server...
    start /min powershell.exe -ExecutionPolicy Bypass -File "%SCRIPT_DIR%server.ps1"
    timeout /t 2 /nobreak >nul
) else (
    echo [1/2] Server already running on port 8080.
)

:: Open web dashboard in default browser
echo [2/2] Opening Web Dashboard...
start http://localhost:8080

echo.
echo DriveFlow is running at http://localhost:8080
echo You can access this dashboard on your mobile device via local network IP!
echo.
pause
