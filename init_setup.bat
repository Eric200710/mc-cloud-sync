@echo off
chcp 65001 >nul
cd /d "%~dp0"

echo ==========================================================
echo        Minecraft 雲端接力系統 - 正在自 GitHub 下載必要組件...
echo ==========================================================

set "REPO=https://raw.githubusercontent.com/Eric200710/mc-cloud-sync/main"

:: 透過 PowerShell 下載三個檔案，加入詳細下載進度與錯誤重試
powershell.exe -NoProfile -Command ^
    "[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12;" ^
    "$files = @('init_setup.ps1', 'sync_world.bat', 'sync_world.ps1');" ^
    "foreach ($f in $files) {" ^
    "    Write-Host \" -> 正在下載 $f ...\" -ForegroundColor Cyan;" ^
    "    try {" ^
    "        Invoke-WebRequest -Uri '%REPO%/'$f -OutFile $f -UseBasicParsing;" ^
    "        Write-Host \"    [成功] $f 下載完成！\" -ForegroundColor Green;" ^
    "    } catch {" ^
    "        Write-Host \"    [錯誤] 下載 $f 失敗: $($_.Exception.Message)\" -ForegroundColor Red;" ^
    "    }" ^
    "}"

if not exist "init_setup.ps1" (
    echo.
    echo ==========================================================
    echo [錯誤] 未能成功下載 init_setup.ps1！
    echo 請確認您的網路連線是否正常，或稍後再試。
    echo ==========================================================
    pause
    exit /b 1
)

echo.
echo [完成] 所有必要組件已下載就緒！正在啟動安裝精靈...
echo.

powershell.exe -NoProfile -ExecutionPolicy Bypass -File ".\init_setup.ps1"
pause
