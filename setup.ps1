#Requires -Version 5.1
# 1. Tự động kiểm tra và nâng quyền Administrator (Hỗ trợ cả khi chạy từ file lẫn irm | iex)
$currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
if (-not $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    if ($PSCommandPath) {
        Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    } else {
        Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -Command `"irm https://get.eclypse.shop | iex`"" -Verb RunAs
    }
    exit
}

$ErrorActionPreference = 'SilentlyContinue'
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
Clear-Host

# ============================================================================
# MENU LỰA CHỌN CHẾ ĐỘ: GAMING HOẶC OFFICE
# ============================================================================
Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "         ECLYPSE CYBER GAME & WORKSTATION OPTIMIZER       " -ForegroundColor Yellow
Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "  [1] GAMING MODE  (Chạy .\Apps\Gaming + Tối ưu Max FPS)" -ForegroundColor Green
Write-Host "  [2] OFFICE MODE  (Chạy .\Apps\Office + Tối ưu Đa nhiệm)" -ForegroundColor Magenta
Write-Host "  [3] ALL APPS     (Chạy cả Gaming & Office)" -ForegroundColor White
Write-Host "==========================================================" -ForegroundColor Cyan
$choice = Read-Host "Nhập lựa chọn của bạn (1, 2 hoặc 3 - Mặc định là 1)"
if ([string]::IsNullOrWhiteSpace($choice)) {$choice = "1" }

switch ($choice) {
    "2" { $TargetAppFolders = @("Office"); $ModeName = "OFFICE" }
    "3" { $TargetAppFolders = @("Gaming", "Office"); $ModeName = "ALL (GAMING + OFFICE)" }
    Default { $TargetAppFolders = @("Gaming"); $ModeName = "GAMING" }
}
Write-Host "`n[!] Đã chọn chế độ: $ModeName`n" -ForegroundColor Green

# Xác định thư mục gốc (Hỗ trợ cả chạy trực tiếp trên máy lẫn chạy qua irm | iex)
if ($PSScriptRoot) {
    $ScriptDir =$PSScriptRoot
} else {
    $ScriptDir = "$env:TEMP\EclypseSetup"
    if (-not (Test-Path "$ScriptDir\Cursors")) {
        Write-Host "[*] Đang tải gói tài nguyên (Cursors & Apps) từ get.eclypse.shop..." -ForegroundColor Yellow
        New-Item -ItemType Directory -Path $ScriptDir -Force | Out-Null
        # Nếu bạn đóng gói thư mục Cursors và Apps thành Setup.zip trên host:
        Invoke-WebRequest -Uri "https://get.eclypse.shop/Setup.zip" -OutFile "$ScriptDir\Setup.zip" -UseBasicParsing
        if (Test-Path "$ScriptDir\Setup.zip") {
            Expand-Archive -Path "$ScriptDir\Setup.zip" -DestinationPath $ScriptDir -Force
        }
    }
}

function Set-RegKey {
    param([string]$Path, [string]$Name, $Value, [string]$Type = "DWord")
    if (-not (Test-Path $Path)) { New-Item -Path$Path -Force | Out-Null }
    Set-ItemProperty -Path $Path -Name$Name -Value $Value -Type$Type -Force | Out-Null
}

# ============================================================================
# 1. KÍCH HOẠT WINDOWS NGẦM (KMS)
# ============================================================================
Write-Host "[1/8] Kích hoạt Windows ngầm..." -ForegroundColor Cyan
Start-Process "cmd.exe" -ArgumentList "/c cscript //nologo $env:windir\system32\slmgr.vbs /ipk W269N-WFGWX-YVC9B-4J6C9-T83GX & cscript //nologo $env:windir\system32\slmgr.vbs /skms kms.msguides.com & cscript //nologo$env:windir\system32\slmgr.vbs /ato" -WindowStyle Hidden

# ============================================================================
# 2. XÓA POLICY RÁC & DEBLOAT CHROME
# ============================================================================
Write-Host "[2/8] Debloat Google Chrome..." -ForegroundColor Cyan
Stop-Process -Name "chrome" -Force
if (-not (Get-CimInstance -ClassName Win32_ComputerSystem).PartOfDomain) {
    Remove-Item "$env:WINDIR\System32\GroupPolicy" -Recurse -Force
    Remove-Item "$env:WINDIR\System32\GroupPolicyUsers" -Recurse -Force
}
Remove-Item "${env:ProgramFiles(x86)}\Google\Policies" -Recurse -Force
Remove-Item "$env:ProgramFiles\Google\Policies" -Recurse -Force

$chromeRegPaths = @(
    "HKLM:\Software\Policies\Google\Chrome",
    "HKCU:\Software\Policies\Google\Chrome",
    "HKLM:\Software\Policies\Chromium",
    "HKCU:\Software\Policies\Chromium"
)
foreach ($p in $chromeRegPaths) { Remove-Item -Path$p -Recurse -Force }

$chromePolicies = @{
    "BackgroundModeEnabled"               = 0
    "MetricsReportingEnabled"             = 0
    "ChromeCleanupEnabled"                = 0
    "ChromeCleanupReportingEnabled"       = 0
    "BuiltInDnsClientEnabled"             = 0
    "HighEfficiencyModeEnabled"           = 1
    "PromotionalTabsEnabled"              = 0
    "PrivacySandboxPromptEnabled"         = 0
    "PrivacySandboxAdMeasurementEnabled"  = 0
    "PrivacySandboxAdTopicsEnabled"       = 0
    "AutofillAddressEnabled"              = 0
    "AutofillCreditCardEnabled"           = 0
    "HardwareAccelerationModeEnabled"     = 1
}
foreach ($kvp in$chromePolicies.GetEnumerator()) {
    Set-RegKey -Path "HKLM:\SOFTWARE\Policies\Google\Chrome" -Name $kvp.Key -Value$kvp.Value -Type DWord
}

# ============================================================================
# 3. TỐI ƯU HỆ THỐNG DISKLESS BOOTROM GCAFE & RTX 2080 (144Hz/240Hz)
# ============================================================================
Write-Host "[3/8] Tối ưu mạng LAN Bootrom, RAM Cache và GPU RTX 2080..." -ForegroundColor Cyan
Set-RegKey "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" "NetworkThrottlingIndex" 0xFFFFFFFF "DWord"
Set-RegKey "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" "SystemResponsiveness" 0 "DWord"

$gamesTaskPath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games"
Set-RegKey $gamesTaskPath "GPU Priority" 8 "DWord"
Set-RegKey $gamesTaskPath "Priority" 6 "DWord"
Set-RegKey $gamesTaskPath "Scheduling Category" "High" "String"
Set-RegKey $gamesTaskPath "SFIO Priority" "High" "String"

$memPath = "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management"
Set-RegKey $memPath "LargeSystemCache" 0 "DWord"
Set-RegKey $memPath "DisablePagingExecutive" 1 "DWord"

Set-RegKey "HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers" "HwSchMode" 2 "DWord"
Set-RegKey "HKLM:\SOFTWARE\Microsoft\Windows\Dwm" "OverlayTestMode" 5 "DWord"

powercfg -duplicatescheme e9a42b02-d5df-448d-aa00-03f14749eb61 | Out-Null
$ultimatePlan = (powercfg -list | Select-String -Pattern "Ultimate").Line.Split()[3]
if ($ultimatePlan) {
    powercfg /setactive $ultimatePlan
} else {
    powercfg /setactive 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c
}
powercfg /change monitor-timeout-ac 0
powercfg /change disk-timeout-ac 0
powercfg /change standby-timeout-ac 0

Set-RegKey "HKCU:\SystemConfigStore" "GameDVR_Enabled" 0 "DWord"
Set-RegKey "HKCU:\Software\Microsoft\Windows\CurrentVersion\GameDVR" "AppCaptureEnabled" 0 "DWord"
Set-RegKey "HKLM:\SOFTWARE\Policies\Microsoft\Windows\GameDVR" "AllowGameDVR" 0 "DWord"
Set-RegKey "HKCU:\Software\Microsoft\GameBar" "AllowAutoGameMode" 1 "DWord"
Set-RegKey "HKCU:\Software\Microsoft\GameBar" "AutoGameModeEnabled" 1 "DWord"
Set-RegKey "HKCU:\Control Panel\Mouse" "MouseSpeed" "0" "String"
Set-RegKey "HKCU:\Control Panel\Mouse" "MouseThreshold1" "0" "String"
Set-RegKey "HKCU:\Control Panel\Mouse" "MouseThreshold2" "0" "String"
Set-RegKey "HKCU:\Software\Microsoft\Windows\CurrentVersion\BackgroundAccessApplications" "GlobalUserDisabled" 1 "DWord"

# ============================================================================
# 4. GIAO DIỆN LIGHT MODE, TASKBAR TOP + CĂN GIỮA KIỂU WINDOWS 11 & NỀN ĐEN
# ============================================================================
Write-Host "[4/8] Tinh chỉnh Taskbar (Vị trí Top + Căn giữa kiểu Win 11) & Light Mode..." -ForegroundColor Cyan
Set-RegKey "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" "SystemUsesLightTheme" 1 "DWord"
Set-RegKey "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" "AppsUseLightTheme" 1 "DWord"
Set-RegKey "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer" "EnableAutoTray" 1 "DWord"
Set-RegKey "HKCU:\Software\Microsoft\Windows\CurrentVersion\Search" "SearchboxTaskbarMode" 0 "DWord"
Set-RegKey "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" "ShowTaskViewButton" 0 "DWord"
Set-RegKey "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" "ShowCortanaButton" 0 "DWord"
Set-RegKey "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced\People" "PeopleBand" 0 "DWord"
Set-RegKey "HKCU:\Software\Microsoft\Windows\CurrentVersion\Feeds" "ShellFeedsTaskbarViewMode" 2 "DWord"
Set-RegKey "HKCU:\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer" "HideSCAMeetNow" 1 "DWord"
Set-RegKey "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" "SystemPaneSuggestionsEnabled" 0 "DWord"
Set-RegKey "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" "Start_TrackProgs" 0 "DWord"

# Căn giữa Taskbar (TaskbarAl = 1 cho Windows 11 / ExplorerPatcher)
Set-RegKey "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" "TaskbarAl" 1 "DWord"

# Đưa vị trí Taskbar lên TRÊN CÙNG (Top = 01 ở byte thứ 12 trong StuckRects3)
Stop-Process -Name "explorer" -Force
Start-Sleep -Seconds 1
$stuckRectsPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\StuckRects3"
if (Test-Path $stuckRectsPath) {
    $settings = (Get-ItemProperty -Path$stuckRectsPath -Name "Settings").Settings
    if ($settings.Length -ge 13) {$settings[12] = 1 # 0 = Left, 1 = Top, 2 = Right, 3 = Bottom
        Set-ItemProperty -Path $stuckRectsPath -Name "Settings" -Value $settings -Force
    }
}

# Gỡ Bloatware Apps
$bloatApps = @(
    "*3DViewer*", "*BingWeather*", "*Camera*", "*CommunicationsApps*", "*FeedbackHub*",
    "*GetHelp*", "*Getstarted*", "*MicrosoftOfficeHub*", "*MicrosoftSolitaireCollection*",
    "*MixedReality*", "*Office.OneNote*", "*People*", "*SkypeApp*", "*Todos*", "*Wallet*",
    "*ZuneMusic*", "*ZuneVideo*", "*LinkedIn*"
)
foreach ($app in$bloatApps) {
    Get-AppxPackage -Name $app | Remove-AppxPackage
}

# Áp dụng Layout chỉ ghim Chrome & Settings
$layoutPath = "$env:LOCALAPPDATA\LayoutModification.xml"
$layoutXml = @"
<?xml version="1.0" encoding="utf-8"?>
<LayoutModificationTemplate Version="1" xmlns="http://schemas.microsoft.com/Start/2014/LayoutModification" xmlns:defaultlayout="http://schemas.microsoft.com/Start/2014/FullDefaultLayout" xmlns:start="http://schemas.microsoft.com/Start/2014/StartLayout" xmlns:taskbar="http://schemas.microsoft.com/Start/2014/TaskbarLayout">
  <LayoutOptions StartTileGroupCellWidth="6"/>
  <DefaultLayoutOverride>
    <StartLayoutCollection>
      <defaultlayout:StartLayout GroupCellWidth="6" />
    </StartLayoutCollection>
  </DefaultLayoutOverride>
  <CustomTaskbarLayoutCollection PinListPlacement="Replace">
    <defaultlayout:TaskbarLayout>
      <taskbar:TaskbarPinList>
        <taskbar:DesktopApp DesktopApplicationID="Chrome" />
        <taskbar:UWA AppUserModelID="windows.immersivecontrolpanel_cw5n1h2txyewy!microsoft.windows.immersivecontrolpanel" />
      </taskbar:TaskbarPinList>
    </defaultlayout:TaskbarLayout>
  </CustomTaskbarLayoutCollection>
</LayoutModificationTemplate>
"@
$layoutXml \vert{} Out-File -FilePath$layoutPath -Encoding utf8 -Force
Import-StartLayout -LayoutPath $layoutPath -MountPath "$env:SystemDrive\"

Remove-Item "$env:APPDATA\Microsoft\Internet Explorer\Quick Launch\User Pinned\TaskBar\*" -Force
Remove-Item "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Taskband" -Recurse -Force
Set-RegKey "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Explorer" "StartLayoutFile" $layoutPath "String"
Set-RegKey "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Explorer" "LockedStartLayout" 1 "DWord"

# Đổi hình nền Đen tuyền
Set-RegKey "HKCU:\Control Panel\Colors" "Background" "0 0 0" "String"
Set-RegKey "HKCU:\Control Panel\Desktop" "Wallpaper" "" "String"
$win32Api = @"
using System;
using System.Runtime.InteropServices;
public class PInvoke {
    [DllImport("user32.dll", CharSet=CharSet.Auto)]
    public static extern int SystemParametersInfo(int uAction, int uParam, string lpvParam, int fuWinIni);
    [DllImport("user32.dll")]
    public static extern bool SetSysColors(int cElements, int[] lpaElements, uint[] lpaRgbValues);
}
"@
Add-Type -TypeDefinition $win32Api
[PInvoke]::SystemParametersInfo(20, 0, '', 3) | Out-Null
[PInvoke]::SetSysColors(1, @(1), @(0)) | Out-Null

# ============================================================================
# 5. KHỞI ĐỘNG LẠI EXPLORER & KÍCH HOẠT CĂN GIỮA TASKBAR (CHO WINDOWS 10)
# ============================================================================
Write-Host "[5/8] Khởi động lại Windows Explorer..." -ForegroundColor Cyan
Start-Process "explorer.exe"
Start-Sleep -Seconds 3
Remove-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Explorer" -Name "LockedStartLayout" -Force
Remove-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Explorer" -Name "StartLayoutFile" -Force

# Nếu bạn dùng Windows 10 và muốn cả nút Start lẫn Icon nằm chính giữa hệt Windows 11,
# script sẽ tự chạy TaskbarX nếu có sẵn trong thư mục Setup\TaskbarX\TaskbarX.exe
$taskbarXPath = Join-Path$ScriptDir "TaskbarX\TaskbarX.exe"
if (Test-Path $taskbarXPath) {
    Start-Process -FilePath $taskbarXPath -ArgumentList "-tbs=0 -c=1"
}

# ============================================================================
# 6. CÀI ĐẶT CON TRỎ CHUỘT DÙNG ĐƯỜNG DẪN TƯƠNG ĐỐI ($ScriptDir)
# ============================================================================
Write-Host "[6/8] Cài đặt bộ con trỏ chuột..." -ForegroundColor Cyan
$cursorPaths = @(
    (Join-Path $ScriptDir "Cursors\Install.inf"),
    (Join-Path $ScriptDir "Mr v5 Cursors\Mr v5 MegaPack\Install.inf")
)
foreach ($inf in$cursorPaths) {
    if (Test-Path $inf) {
        Push-Location (Split-Path $inf -Parent)
        Start-Process "rundll32.exe" -ArgumentList "advpack.dll,LaunchINFSection Install.inf,DefaultInstall" -Wait
        Pop-Location
        break
    }
}

# ============================================================================
# 7. CHẠY CÁC ỨNG DỤNG THEO LỰA CHỌN (GAMING HOẶC OFFICE)
# ============================================================================
Write-Host "[7/8] Đang khởi chạy các ứng dụng thuộc chế độ $ModeName..." -ForegroundColor Cyan
foreach ($folder in$TargetAppFolders) {
    $targetPath = Join-Path$ScriptDir "Apps\$folder"
    if (Test-Path $targetPath) {
        Get-ChildItem -Path $targetPath -Filter "*.exe" -Recurse -File | ForEach-Object {
            Write-Host " -> Đang chạy: [$folder] $($_.Name)" -ForegroundColor Green
            Start-Process -FilePath $_.FullName -WorkingDirectory$_.DirectoryName
        }
    } else {
        Write-Host " [!] Không tìm thấy thư mục: $targetPath" -ForegroundColor Yellow
    }
}

# ============================================================================
# 8. MỞ BẢNG CHỌN CHUỘT & CHROME
# ============================================================================
Write-Host "[8/8] Hoàn tất! Đang mở Mouse Properties và Google Chrome..." -ForegroundColor Cyan
Start-Process "control.exe" -ArgumentList "main.cpl,,1"
Start-Process "chrome.exe" -ArgumentList "--disable-background-networking --disable-component-update --disable-default-apps --no-default-browser-check --no-first-run"
