@echo off
chcp 65001 >nul
cd /d "%~dp0"

echo ==========================================================
echo        Minecraft 雲端接力系統 - 正在自 GitHub 下載必要組件...
echo ==========================================================

:: 1. 直接用 PowerShell 下載最新版的 init_setup.ps1
set "RAW_URL=https://raw.githubusercontent.com/Eric200710/mc-cloud-sync/main"
echo [1/3] 正在下載核心安裝邏輯 (init_setup.ps1)...
powershell.exe -NoProfile -Command "[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; (New-Object Net.WebClient).DownloadFile('%RAW_URL%/init_setup.ps1', 'init_setup.ps1')"

:: 2. 下載 sync_world.bat
echo [2/3] 正在下載同步啟動檔 (sync_world.bat)...
powershell.exe -NoProfile -Command "[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; (New-Object Net.WebClient).DownloadFile('%RAW_URL%/sync_world.bat', 'sync_world.bat')"

:: 3. 下載 sync_world.ps1
echo [3/3] 正在下載同步邏輯核心 (sync_world.ps1)...
powershell.exe -NoProfile -Command "[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; (New-Object Net.WebClient).DownloadFile('%RAW_URL%/sync_world.ps1', 'sync_world.ps1')"

echo [完成] 所有必要腳本已下載就緒！正在啟動安裝精靈...
echo.

:: 4. 執行下載下來的 init_setup.ps1
powershell.exe -NoProfile -ExecutionPolicy Bypass -File ".\init_setup.ps1"
pause
