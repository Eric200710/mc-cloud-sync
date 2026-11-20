@echo off
title Minecraft Cloud Sync - Setup
cd /d "%~dp0"

REM Check if init_setup.ps1 exists locally; if not, download from GitHub
if not exist "%~dp0init_setup.ps1" (
    echo [Info] init_setup.ps1 not found locally. Downloading from GitHub...
    powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; (New-Object System.Net.WebClient).DownloadFile('https://raw.githubusercontent.com/Eric200710/mc-cloud-sync/main/init_setup.ps1', '%~dp0init_setup.ps1')"
    if not exist "%~dp0init_setup.ps1" (
        echo [Error] Failed to download init_setup.ps1 from GitHub.
        echo Please check your internet connection and try again.
        pause
        exit /b 1
    )
    echo [OK] init_setup.ps1 downloaded successfully.
    echo.
)

REM Execute PowerShell setup script
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0init_setup.ps1"

echo.
pause
