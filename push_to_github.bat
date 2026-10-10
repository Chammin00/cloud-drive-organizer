@echo off
title Push DriveFlow to GitHub
echo ========================================================
echo   Pushing DriveFlow to GitHub (Chammin00)...
echo ========================================================

set GIT_EXE="C:\Users\chase\AppData\Local\GitHubDesktop\app-3.6.3\resources\app\git\cmd\git.exe"

%GIT_EXE% add -A
%GIT_EXE% commit -m "feat: complete DriveFlow 1-click organizer with web/mobile UI and cron scheduler"
%GIT_EXE% branch -M main

echo Attempting push to origin main...
%GIT_EXE% push -u origin main

if %errorlevel% neq 0 (
    echo.
    echo --------------------------------------------------------
    echo If GitHub prompts for authentication:
    echo 1. You can open GitHub Desktop and click 'Publish repository'.
    echo 2. Or run 'gh auth login' in terminal and re-run this script.
    echo --------------------------------------------------------
) else (
    echo.
    echo Successfully pushed to GitHub!
)
pause
