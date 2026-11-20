<#
.SYNOPSIS
    【檔案 2】World 存檔同步腳本 (啟動後提問上傳或下載)
#>

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$Host.UI.RawUI.WindowTitle = "Minecraft World 雲端存檔同步工具"

# 載入 config.json
$currentDir = $PSScriptRoot
$configFile = Join-Path $currentDir "config.json"

if (-not (Test-Path $configFile)) {
    Write-Host "[錯誤] 找不到 config.json 設定檔！" -ForegroundColor Red
    Write-Host "請先運行【init_setup.bat】進行初始化設定！" -ForegroundColor Yellow
    pause
    exit
}

try {
    $cfg = Get-Content $configFile -Raw | ConvertFrom-Json
    $MinecraftPath  = $cfg.minecraft_path
    $CloudDrivePath = $cfg.cloud_drive_path
    $WorldName      = $cfg.world_name
} catch {
    Write-Host "[錯誤] 讀取 config.json 失敗！請重新執行 init_setup.bat" -ForegroundColor Red
    pause
    exit
}

$LocalWorldDir = Join-Path (Join-Path $MinecraftPath "saves") $WorldName
$CloudWorldDir = Join-Path $CloudDrivePath "world"
$LockFile      = Join-Path $CloudWorldDir "WORLD_IN_USE.lock"
$CloudZip      = Join-Path $CloudWorldDir "world_latest.zip"
$PlayerName    = $env:USERNAME

Function Show-Status {
    Clear-Host
    Write-Host "==========================================================" -ForegroundColor Cyan
    Write-Host "             Minecraft World 雲端存檔同步工具              " -ForegroundColor Yellow
    Write-Host "==========================================================" -ForegroundColor Cyan
    Write-Host "本地遊戲路徑: $MinecraftPath" -ForegroundColor Gray
    Write-Host "目標世界存檔: $WorldName" -ForegroundColor Gray
    Write-Host "雲端同步路徑: $CloudDrivePath" -ForegroundColor Gray
    Write-Host "----------------------------------------------------------"
    if (Test-Path $LockFile) {
        $lockMsg = Get-Content $LockFile | Select-Object -First 1
        Write-Host "【雲端狀態】: [有人在遊玩] - $lockMsg" -ForegroundColor Red
    } else {
        Write-Host "【雲端狀態】: [目前閒置] - 可以安全下載/上傳" -ForegroundColor Green
    }
    Write-Host "==========================================================" -ForegroundColor Cyan
}

Function Ensure-CloudPath {
    if (-not (Test-Path $CloudDrivePath)) {
        Write-Host "`n[錯誤] 找不到 Google Drive 路徑: $CloudDrivePath" -ForegroundColor Red
        Write-Host "請確認已開啟【Google 雲端硬碟電腦版】！" -ForegroundColor Yellow
        [void][System.Console]::ReadKey()
        return $false
    }
    if (-not (Test-Path $CloudWorldDir)) {
        New-Item -ItemType Directory -Path $CloudWorldDir -Force | Out-Null
    }
    return $true
}

# 下載存檔
Function Download-World {
    Show-Status
    if (-not (Ensure-CloudPath)) { return }

    if (Test-Path $LockFile) {
        $lockInfo = Get-Content $LockFile -Raw -ErrorAction SilentlyContinue
        Write-Host "`n[無法下載] 警告！目前有其他人正在遊玩中！" -ForegroundColor Red
        Write-Host $lockInfo -ForegroundColor Yellow
        Write-Host "`n強制覆蓋會導致他人進度丟失，請等待對方遊玩完畢退出。" -ForegroundColor Yellow
        [void][System.Console]::ReadKey()
        return
    }

    if (-not (Test-Path $CloudZip)) {
        Write-Host "`n[提示] 雲端目前沒有存檔 ($CloudZip)。" -ForegroundColor Yellow
        Write-Host "若您是第一次建檔者，請先選擇 [2] 上傳您的存檔！" -ForegroundColor Cyan
        [void][System.Console]::ReadKey()
        return
    }

    Write-Host "`n[1/3] 正在備份本地舊有存檔 (防止意外)..." -ForegroundColor Cyan
    if (Test-Path $LocalWorldDir) {
        $backupDir = Join-Path (Join-Path $MinecraftPath "saves") "_backup_$($WorldName)_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
        Move-Item $LocalWorldDir $backupDir -Force
        Write-Host "本地原存檔已安全移至備份: $backupDir" -ForegroundColor DarkGray
    }

    Write-Host "[2/3] 正在自 Google 雲端解壓最新世界存檔..." -ForegroundColor Green
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    [System.IO.Compression.ZipFile]::ExtractToDirectory($CloudZip, $LocalWorldDir)

    Write-Host "[3/3] 正在雲端登記世界鎖定 (Lock)..." -ForegroundColor Cyan
    "玩家: $PlayerName `n時間: $(Get-Date -Format 'yyyy/MM/dd HH:mm:ss') `n狀態: 遊玩中" | Set-Content $LockFile -Encoding UTF8

    Write-Host "`n==========================================================" -ForegroundColor Green
    Write-Host "★ 下載並解壓完成！雲端已標記為【遊玩中】。" -ForegroundColor Yellow
    Write-Host "您現在可以啟動 Minecraft 開心遊玩了！" -ForegroundColor White
    Write-Host "★ 玩完關閉遊戲後，請再次打開本程式選擇【2. 上傳檔案】解鎖！" -ForegroundColor Magenta
    Write-Host "==========================================================" -ForegroundColor Green
    [void][System.Console]::ReadKey()
}

# 上傳存檔
Function Upload-World {
    Show-Status
    if (-not (Ensure-CloudPath)) { return }

    # 檢查遊戲是否仍在運行
    $mc = Get-Process -Name "javaw", "java" -ErrorAction SilentlyContinue | Where-Object { $_.MainWindowTitle -match "Minecraft" }
    if ($mc) {
        Write-Host "`n[警告] 偵測到 Minecraft 仍在運行！" -ForegroundColor Red
        Write-Host "請先在遊戲中儲存世界並【完全關閉 Minecraft】，以免存檔被鎖定或損壞！" -ForegroundColor Yellow
        [void][System.Console]::ReadKey()
        return
    }

    if (-not (Test-Path $LocalWorldDir)) {
        Write-Host "`n[錯誤] 找不到本地世界資料夾: $LocalWorldDir" -ForegroundColor Red
        [void][System.Console]::ReadKey()
        return
    }

    Write-Host "`n[1/3] 正在打包本地存檔為 ZIP..." -ForegroundColor Cyan
    $tempZip = Join-Path $env:TEMP "upload_world_temp.zip"
    if (Test-Path $tempZip) { Remove-Item $tempZip -Force }

    Add-Type -AssemblyName System.IO.Compression.FileSystem
    [System.IO.Compression.ZipFile]::CreateFromDirectory($LocalWorldDir, $tempZip)

    Write-Host "[2/3] 正在上傳至 Google Drive..." -ForegroundColor Cyan
    if (Test-Path $CloudZip) {
        # 保留雲端上一版備份
        Move-Item $CloudZip (Join-Path $CloudWorldDir "world_previous_backup.zip") -Force -ErrorAction SilentlyContinue
    }
    Copy-Item $tempZip $CloudZip -Force
    Remove-Item $tempZip -Force
    Write-Host "世界存檔已成功上傳覆蓋！" -ForegroundColor Green

    Write-Host "[3/3] 解除雲端世界鎖定 (Unlock)..." -ForegroundColor Cyan
    if (Test-Path $LockFile) {
        Remove-Item $LockFile -Force
    }

    Write-Host "`n==========================================================" -ForegroundColor Green
    Write-Host "★ 上傳完成！雲端存檔已更新，鎖定已解除！" -ForegroundColor Yellow
    Write-Host "其他小夥伴現在可以接力下載遊玩了！" -ForegroundColor White
    Write-Host "==========================================================" -ForegroundColor Green
    [void][System.Console]::ReadKey()
}

# 強制解鎖
Function Force-Unlock {
    Show-Status
    if (Test-Path $LockFile) {
        Write-Host "`n目前鎖定資訊:`n$(Get-Content $LockFile -Raw)" -ForegroundColor Yellow
        $ans = Read-Host "確定要強制解除鎖定嗎？請確認當事人已經沒有在遊玩！(Y/N)"
        if ($ans -eq 'Y' -or $ans -eq 'y') {
            Remove-Item $LockFile -Force
            Write-Host "已清除鎖定狀態！" -ForegroundColor Green
        }
    } else {
        Write-Host "`n目前沒有人鎖定，狀態正常！" -ForegroundColor Green
    }
    [void][System.Console]::ReadKey()
}

# 主選單循環
while ($true) {
    Show-Status
    Write-Host " 請選擇要執行的操作:" -ForegroundColor White
    Write-Host " [1] 下載檔案 (開玩前：從雲端下載最新世界存檔 + 標記鎖定)" -ForegroundColor Cyan
    Write-Host " [2] 上傳檔案 (玩完後：將最新世界存檔打包上傳 + 解除鎖定)" -ForegroundColor Green
    Write-Host " [3] 強制解鎖 (若遊戲異常閃退導致卡在遊玩中狀態)" -ForegroundColor Yellow
    Write-Host " [4] 離開" -ForegroundColor Gray
    Write-Host "----------------------------------------------------------"
    
    $inputChoice = Read-Host "請輸入選項 (1 / 2 / 3 / 4)"
    switch ($inputChoice) {
        "1" { Download-World }
        "2" { Upload-World }
        "3" { Force-Unlock }
        "4" { exit }
    }
}
