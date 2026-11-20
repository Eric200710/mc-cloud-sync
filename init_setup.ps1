<#
.SYNOPSIS
    【檔案 1】新手初始化安裝腳本
    1. 檢查並引導安裝 Google 雲端硬碟電腦版
    2. 自動搜尋或讓使用者設定正確的 Minecraft 安裝路徑
    3. 自動生成/更新 config.json 設定檔
    4. 自動從 GitHub 下載/更新最新版的 sync_world 腳本與說明檔
#>

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$Host.UI.RawUI.WindowTitle = "Minecraft 雲端接力系統 - 初始化安裝嚮導"

Clear-Host
Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "       Minecraft 雲端存檔接力系統 - 初始化安裝精靈         " -ForegroundColor Yellow
Write-Host "==========================================================" -ForegroundColor Cyan

$currentDir = $PSScriptRoot

# ----------------- 步驟 1: 從 GitHub 下載/更新最新腳本 -----------------
Write-Host "`n[步驟 1/4] 正在從 GitHub 下載最新版本腳本..." -ForegroundColor Cyan
$repoRawUrl = "https://raw.githubusercontent.com/Eric200710/mc-cloud-sync/main"
$filesToDownload = @(
    "sync_world.bat",
    "sync_world.ps1",
    "README.md"
)

foreach ($file in $filesToDownload) {
    try {
        $targetPath = Join-Path $currentDir $file
        $downloadUrl = "$repoRawUrl/$file"
        Write-Host " -> 正在更新 $file ..." -ForegroundColor Gray
        Invoke-WebRequest -Uri $downloadUrl -OutFile $targetPath -UseBasicParsing
        Write-Host "    [成功] $file 已更新至最新版！" -ForegroundColor Green
    } catch {
        Write-Host "    [提示] 無法從 GitHub 下載 $file，使用本地現有版本。" -ForegroundColor DarkYellow
    }
}

# ----------------- 步驟 2: 檢查 Google 雲端硬碟電腦版 -----------------
Write-Host "`n[步驟 2/4] 檢查 Google 雲端硬碟電腦版 (Google Drive for Desktop)..." -ForegroundColor Cyan
$gdriveInstalled = $false
$possibleGPaths = @(
    "C:\Program Files\Google\Drive File Stream",
    "C:\Program Files\Google\Drive",
    "C:\Program Files (x86)\Google\Drive"
)
foreach ($p in $possibleGPaths) {
    if (Test-Path $p) { $gdriveInstalled = $true; break }
}

if ($gdriveInstalled -or (Test-Path "G:\")) {
    Write-Host " -> 已檢測到 Google 雲端硬碟環境！" -ForegroundColor Green
} else {
    Write-Host " -> 未檢測到 Google 雲端硬碟電腦版！" -ForegroundColor Yellow
    $install = Read-Host "是否立即為您下載並開啟官方安裝程式？(Y/N)"
    if ($install -eq 'Y' -or $install -eq 'y') {
        $installerUrl = "https://dl.google.com/drive-file-stream/GoogleDriveSetup.exe"
        $installerPath = Join-Path $env:TEMP "GoogleDriveSetup.exe"
        Write-Host "正在下載 Google Drive 安裝程式..." -ForegroundColor Cyan
        Invoke-WebRequest -Uri $installerUrl -OutFile $installerPath -UseBasicParsing
        Write-Host "正在啟動安裝程式，請依照畫面完成安裝並登入帳號..." -ForegroundColor Yellow
        Start-Process -FilePath $installerPath -Wait
        Write-Host "安裝完成！" -ForegroundColor Green
    }
}

# ----------------- 步驟 3: 設定 Minecraft 安裝目錄 -----------------
Write-Host "`n[步驟 3/4] 配置 Minecraft 遊戲目錄..." -ForegroundColor Cyan
$configFile = Join-Path $currentDir "config.json"

# 載入現有設定
$config = @{
    "minecraft_path" = ""
    "cloud_drive_path" = "G:\我的雲端硬碟\MC_Shared_Server"
    "world_name" = "新的世界 (2)"
}
if (Test-Path $configFile) {
    try {
        $loaded = Get-Content $configFile -Raw | ConvertFrom-Json
        if ($loaded.minecraft_path) { $config.minecraft_path = $loaded.minecraft_path }
        if ($loaded.cloud_drive_path) { $config.cloud_drive_path = $loaded.cloud_drive_path }
        if ($loaded.world_name) { $config.world_name = $loaded.world_name }
    } catch {}
}

# 自動探測常見路徑
$defaultPaths = @(
    $currentDir,
    (Join-Path $currentDir ".."),
    "D:\custom mc i\1201iron and tinker fight",
    "$env:APPDATA\.minecraft"
)

$detectedPath = ""
foreach ($p in $defaultPaths) {
    if (Test-Path (Join-Path $p "saves") -or Test-Path (Join-Path $p "mods")) {
        $detectedPath = (Resolve-Path $p).Path
        break
    }
}

if ($config.minecraft_path -and (Test-Path $config.minecraft_path)) {
    Write-Host "目前已記錄的 Minecraft 路徑: $($config.minecraft_path)" -ForegroundColor Green
    $change = Read-Host "是否需要重新指定路徑？(Y/N，預設 N)"
    if ($change -eq 'Y' -or $change -eq 'y') {
        $userPath = Read-Host "請輸入 Minecraft 實例的完整路徑 (包含 mods/saves 的資料夾)"
        if (Test-Path $userPath) { $config.minecraft_path = $userPath }
    }
} elseif ($detectedPath) {
    Write-Host "自動偵測到 Minecraft 路徑: $detectedPath" -ForegroundColor Green
    $confirm = Read-Host "是否直接使用此路徑？(Y/N，預設 Y)"
    if ($confirm -eq 'N' -or $confirm -eq 'n') {
        $userPath = Read-Host "請手動輸入 Minecraft 路徑"
        $config.minecraft_path = $userPath
    } else {
        $config.minecraft_path = $detectedPath
    }
} else {
    $userPath = Read-Host "請輸入 Minecraft 實例完整路徑 (包含 mods、saves 的資料夾)"
    $config.minecraft_path = $userPath
}

# 設定 Google Drive 共享路徑
Write-Host "`n目前設定的雲端共享路徑: $($config.cloud_drive_path)" -ForegroundColor Gray
$changeCloud = Read-Host "若你的 Google Drive 不是 G 槽，是否變更雲端路徑？(Y/N，預設 N)"
if ($changeCloud -eq 'Y' -or $changeCloud -eq 'y') {
    $config.cloud_drive_path = Read-Host "請輸入 Google Drive 共享資料夾路徑 (例如 G:\Shared drives\MC)"
}

# ----------------- 步驟 4: 儲存設定檔並就緒 -----------------
Write-Host "`n[步驟 4/4] 保存設定檔..." -ForegroundColor Cyan
$config | ConvertTo-Json -Depth 4 | Set-Content $configFile -Encoding UTF8
Write-Host " -> config.json 設定檔已儲存完畢！" -ForegroundColor Green

Write-Host "`n==========================================================" -ForegroundColor Cyan
Write-Host "★ 初始化設定全部完成！" -ForegroundColor Green
Write-Host "日後每次要玩遊戲或同步存檔時，請直接點擊運行：" -ForegroundColor Yellow
Write-Host "👉 【sync_world.bat】" -ForegroundColor Magenta
Write-Host "==========================================================" -ForegroundColor Cyan
pause
