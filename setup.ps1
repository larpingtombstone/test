#Requires -Version 5.1

# 1. Auto-Elevate to Administrator
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
# MENU LUA CHON CHE DO: GAMING HOAC OFFICE
# ============================================================================
Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "         ECLYPSE CYBER GAME & WORKSTATION OPTIMIZER       " -ForegroundColor Yellow
Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "  [1] GAMING MODE  (Chay .\Apps\Gaming + Toi uu Max FPS)" -ForegroundColor Green
Write-Host "  [2] OFFICE MODE  (Chay .\Apps\Office + Toi uu Da nhiem)" -ForegroundColor Magenta
Write-Host "  [3] ALL APPS     (Chay ca Gaming & Office)" -ForegroundColor White
Write-Host "==========================================================" -ForegroundColor Cyan
$choice = Read-Host "Nhap lua chon cua ban (1, 2 hoac 3 - Mac dinh la 1)"
if ([string]::IsNullOrWhiteSpace($choice)) {$choice = "1"
}

switch ($choice) {
    "2" {
        $TargetAppFolders = @("Office")
        $ModeName = "OFFICE"
    }
    "3" {
        $TargetAppFolders = @("Gaming", "Office")
        $ModeName = "ALL (GAMING + OFFICE)"
    }
    Default {
        $TargetAppFolders = @("Gaming")
        $ModeName = "GAMING"
    }
}
Write-Host "`n[!] Da chon che do: $ModeName`n" -ForegroundColor Green

# Xac dinh thu muc goc (Ho tro chay offline va chay qua irm | iex)
if ($PSScriptRoot) {
    $ScriptDir =$PSScriptRoot
} else {
    $ScriptDir = Join-Path$env:TEMP "EclypseSetup"
    $cursorCheck = Join-Path$ScriptDir "Cursors"
    if (-not (Test-Path -Path $cursorCheck)) {
        New-Item -ItemType Directory -Path $ScriptDir -Force | Out-Null
        $zipFile = Join-Path$ScriptDir "Setup.zip"
        Invoke-WebRequest -Uri "https://get.eclypse.shop/Setup.zip" -OutFile $zipFile -UseBasicParsing
        if (Test-Path -Path $zipFile) {
            Expand-Archive -Path $zipFile -DestinationPath$ScriptDir -Force
        }
    }
}

function Set-RegKey {
    param(
        [string]$Path,
        [string]$Name,$Value,
        [string]$Type = "DWord"
    )
    if (-not (Test-Path -Path $Path)) {
        New-Item -Path $Path -Force | Out-Null
    }
    Set-ItemProperty -Path $Path -Name$Name -Value $Value -Type$Type -Force | Out-Null
}

# ============================================================================
# 1. KICH HOAT WINDOWS NGAM (KMS)
# ============================================================================
Write-Host "[1/8] Kich hoat Windows ngam..." -ForegroundColor Cyan
$kmsCmd = "/c cscript //nologo $env:windir\system32\slmgr.vbs /ipk W269N-WFGWX-YVC9B-4J6C9-T83GX & cscript //nologo $env:windir\system32\slmgr.vbs /skms kms.msguides.com & cscript //nologo$env:windir\system32\slmgr.vbs /ato"
Start-Process -FilePath "cmd.exe" -ArgumentList $kmsCmd -WindowStyle Hidden

# ============================================================================
# 2. XOA POLICY RAC & DEBLOAT CHROME
# ============================================================================
Write-Host "[2/8] Debloat Google Chrome..." -ForegroundColor Cyan
Stop-Process -Name "chrome" -Force
if (-not (Get-CimInstance -ClassName Win32_ComputerSystem).PartOfDomain) {
    Remove-Item -Path "$env:WINDIR\System32\GroupPolicy" -Recurse -Force
    Remove-Item -Path "$env:WINDIR\System32\GroupPolicyUsers" -Recurse -Force
}
Remove-Item -Path "${env:ProgramFiles(x86)}\Google\Policies" -Recurse -Force
Remove-Item -Path "$env:ProgramFiles\Google\Policies" -Recurse -Force

$chromeRegPaths = @(
    "HKLM:\Software\Policies\Google\Chrome",
    "HKCU:\Software\Policies\Google\Chrome",
    "HKLM:\Software\Policies\Chromium",
    "HKCU:\Software\Policies\Chromium"
)
$chromeRegPaths | ForEach-Object {
    Remove-Item -Path $_ -Recurse -Force
}

$chromePolicyPath = "HKLM:\SOFTWARE\Policies\Google\Chrome"
Set-RegKey -Path $chromePolicyPath -Name "BackgroundModeEnabled" -Value 0 -Type "DWord"
Set-RegKey -Path $chromePolicyPath -Name "MetricsReportingEnabled" -Value 0 -Type "DWord"
Set-RegKey -Path $chromePolicyPath -Name "ChromeCleanupEnabled" -Value 0 -Type "DWord"
Set-RegKey -Path $chromePolicyPath -Name "ChromeCleanupReportingEnabled" -Value 0 -Type "DWord"
Set-RegKey -Path $chromePolicyPath -Name "BuiltInDnsClientEnabled" -Value 0 -Type "DWord"
Set-RegKey -Path $chromePolicyPath -Name "HighEfficiencyModeEnabled" -Value 1 -Type "DWord"
Set-RegKey -Path $chromePolicyPath -Name "PromotionalTabsEnabled" -Value 0 -Type "DWord"
Set-RegKey -Path $chromePolicyPath -Name "PrivacySandboxPromptEnabled" -Value 0 -Type "DWord"
Set-RegKey -Path $chromePolicyPath -Name "PrivacySandboxAdMeasurementEnabled" -Value 0 -Type "DWord"
Set-RegKey -Path $chromePolicyPath -Name "PrivacySandboxAdTopicsEnabled" -Value 0 -Type "DWord"
Set-RegKey -Path $chromePolicyPath -Name "AutofillAddressEnabled" -Value 0 -Type "DWord"
Set-RegKey -Path $chromePolicyPath -Name "AutofillCreditCardEnabled" -Value 0 -Type "DWord"
Set-RegKey -Path $chromePolicyPath -Name "HardwareAccelerationModeEnabled" -Value 1 -Type "DWord"

# ============================================================================
# 3. TOI UU HE THONG DISKLESS BOOTROM GCAFE & RTX 2080 (144Hz/240Hz)
# ============================================================================
Write-Host "[3/8] Toi uu mang LAN Bootrom, RAM Cache va GPU RTX 2080..." -ForegroundColor Cyan
$mmProfilePath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile"
Set-RegKey -Path $mmProfilePath -Name "NetworkThrottlingIndex" -Value 0xFFFFFFFF -Type "DWord"
Set-RegKey -Path $mmProfilePath -Name "SystemResponsiveness" -Value 0 -Type "DWord"

$gamesTaskPath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games"
Set-RegKey -Path $gamesTaskPath -Name "GPU Priority" -Value 8 -Type "DWord"
Set-RegKey -Path $gamesTaskPath -Name "Priority" -Value 6 -Type "DWord"
Set-RegKey -Path $gamesTaskPath -Name "Scheduling Category" -Value "High" -Type "String"
Set-RegKey -Path $gamesTaskPath -Name "SFIO Priority" -Value "High" -Type "String"

$memPath = "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management"
Set-RegKey -Path $memPath -Name "LargeSystemCache" -Value 0 -Type "DWord"
Set-RegKey -Path $memPath -Name "DisablePagingExecutive" -Value 1 -Type "DWord"

Set-RegKey -Path "HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers" -Name "HwSchMode" -Value 2 -Type "DWord"
Set-RegKey -Path "HKLM:\SOFTWARE\Microsoft\Windows\Dwm" -Name "OverlayTestMode" -Value 5 -Type "DWord"

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

Set-RegKey -Path "HKCU:\SystemConfigStore" -Name "GameDVR_Enabled" -Value 0 -Type "DWord"
Set-RegKey -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\GameDVR" -Name "AppCaptureEnabled" -Value 0 -Type "DWord"
Set-RegKey -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\GameDVR" -Name "AllowGameDVR" -Value 0 -Type "DWord"
Set-RegKey -Path "HKCU:\Software\Microsoft\GameBar" -Name "AllowAutoGameMode" -Value 1 -Type "DWord"
Set-RegKey -Path "HKCU:\Software\Microsoft\GameBar" -Name "AutoGameModeEnabled" -Value 1 -Type "DWord"
Set-RegKey -Path "HKCU:\Control Panel\Mouse" -Name "MouseSpeed" -Value "0" -Type "String"
Set-RegKey -Path "HKCU:\Control Panel\Mouse" -Name "MouseThreshold1" -Value "0" -Type "String"
Set-RegKey -Path "HKCU:\Control Panel\Mouse" -Name "MouseThreshold2" -Value "0" -Type "String"
Set-RegKey -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\BackgroundAccessApplications" -Name "GlobalUserDisabled" -Value 1 -Type "DWord"

# ============================================================================
# 4. GIAO DIEN LIGHT MODE, TASKBAR TOP + CAN GIUA KIEU WINDOWS 11 & NEN DEN
# ============================================================================
Write-Host "[4/8] Tinh chinh Taskbar (Vi tri Top + Can giua kieu Win 11) & Light Mode..." -ForegroundColor Cyan
Set-RegKey -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" -Name "SystemUsesLightTheme" -Value 1 -Type "DWord"
Set-RegKey -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" -Name "AppsUseLightTheme" -Value 1 -Type "DWord"
Set-RegKey -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer" -Name "EnableAutoTray" -Value 1 -Type "DWord"
Set-RegKey -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Search" -Name "SearchboxTaskbarMode" -Value 0 -Type "DWord"
Set-RegKey -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "ShowTaskViewButton" -Value 0 -Type "DWord"
Set-RegKey -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "ShowCortanaButton" -Value 0 -Type "DWord"
Set-RegKey -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced\People" -Name "PeopleBand" -Value 0 -Type "DWord"
Set-RegKey -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Feeds" -Name "ShellFeedsTaskbarViewMode" -Value 2 -Type "DWord"
Set-RegKey -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer" -Name "HideSCAMeetNow" -Value 1 -Type "DWord"
Set-RegKey -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" -Name "SystemPaneSuggestionsEnabled" -Value 0 -Type "DWord"
Set-RegKey -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "Start_TrackProgs" -Value 0 -Type "DWord"

# Can giua Taskbar (TaskbarAl = 1)
Set-RegKey -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "TaskbarAl" -Value 1 -Type "DWord"

# Dua vi tri Taskbar len TREN CUNG (Top = 01 o byte thu 12 trong StuckRects3)
Stop-Process -Name "explorer" -Force
Start-Sleep -Seconds 1
$stuckRectsPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\StuckRects3"
if (Test-Path -Path $stuckRectsPath) {
    $settings = (Get-ItemProperty -Path$stuckRectsPath -Name "Settings").Settings
    if ($settings.Length -ge 13) {$settings[12] = 1
        Set-ItemProperty -Path $stuckRectsPath -Name "Settings" -Value $settings -Force
    }
}

# Go Bloatware Apps
$bloatApps = @(
    "*3DViewer*", "*BingWeather*", "*Camera*", "*CommunicationsApps*", "*FeedbackHub*",
    "*GetHelp*", "*Getstarted*", "*MicrosoftOfficeHub*", "*MicrosoftSolitaireCollection*",
    "*MixedReality*", "*Office.OneNote*", "*People*", "*SkypeApp*", "*Todos*", "*Wallet*",
    "*ZuneMusic*", "*ZuneVideo*", "*LinkedIn*"
)
$bloatApps | ForEach-Object {
    Get-AppxPackage -Name $_ | Remove-AppxPackage
}

# Ap dung Layout chi ghim Chrome & Settings
$layoutPath = Join-Path$env:LOCALAPPDATA "LayoutModification.xml"
$layoutXml = '<?xml version="1.0" encoding="utf-8"?><LayoutModificationTemplate Version="1" xmlns="http://schemas.microsoft.com/Start/2014/LayoutModification" xmlns:defaultlayout="http://schemas.microsoft.com/Start/2014/FullDefaultLayout" xmlns:start="http://schemas.microsoft.com/Start/2014/StartLayout" xmlns:taskbar="http://schemas.microsoft.com/Start/2014/TaskbarLayout"><LayoutOptions StartTileGroupCellWidth="6"/><DefaultLayoutOverride><StartLayoutCollection><defaultlayout:StartLayout GroupCellWidth="6" /></StartLayoutCollection></DefaultLayoutOverride><CustomTaskbarLayoutCollection PinListPlacement="Replace"><defaultlayout:TaskbarLayout><taskbar:TaskbarPinList><taskbar:DesktopApp DesktopApplicationID="Chrome" /><taskbar:UWA AppUserModelID="windows.immersivecontrolpanel_cw5n1h2txyewy!microsoft.windows.immersivecontrolpanel" /></taskbar:TaskbarPinList></defaultlayout:TaskbarLayout></CustomTaskbarLayoutCollection></LayoutModificationTemplate>'
Set-Content -Path $layoutPath -Value$layoutXml -Encoding UTF8 -Force
Import-StartLayout -LayoutPath $layoutPath -MountPath "$env:SystemDrive\"

Remove-Item -Path "$env:APPDATA\Microsoft\Internet Explorer\Quick Launch\User Pinned\TaskBar\*" -Force
Remove-Item -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Taskband" -Recurse -Force
Set-RegKey -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Explorer" -Name "StartLayoutFile" -Value $layoutPath -Type "String"
Set-RegKey -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Explorer" -Name "LockedStartLayout" -Value 1 -Type "DWord"

# Doi hinh nen Den tuyen
Set-RegKey -Path "HKCU:\Control Panel\Colors" -Name "Background" -Value "0 0 0" -Type "String"
Set-RegKey -Path "HKCU:\Control Panel\Desktop" -Name "Wallpaper" -Value "" -Type "String"
$win32Api = 'using System; using System.Runtime.InteropServices; public class PInvoke { [DllImport("user32.dll", CharSet=CharSet.Auto)] public static extern int SystemParametersInfo(int uAction, int uParam, string lpvParam, int fuWinIni); [DllImport("user32.dll")] public static extern bool SetSysColors(int cElements, int[] lpaElements, uint[] lpaRgbValues); }'
Add-Type -TypeDefinition $win32Api
[PInvoke]::SystemParametersInfo(20, 0, '', 3) | Out-Null
[PInvoke]::SetSysColors(1, @(1), @(0)) | Out-Null

# ============================================================================
# 5. KHOI DONG LAI EXPLORER & KICH HOAT CAN GIUA TASKBAR
# ============================================================================
Write-Host "[5/8] Khoi dong lai Windows Explorer..." -ForegroundColor Cyan
Start-Process -FilePath "explorer.exe"
Start-Sleep -Seconds 3
Remove-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Explorer" -Name "LockedStartLayout" -Force
Remove-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Explorer" -Name "StartLayoutFile" -Force

$taskbarXPath = Join-Path$ScriptDir "TaskbarX\TaskbarX.exe"
if (Test-Path -Path $taskbarXPath) {
    Start-Process -FilePath $taskbarXPath -ArgumentList "-tbs=0 -c=1"
}

# ============================================================================
# 6. CAI DAT CON TRO CHUOT
# ============================================================================
Write-Host "[6/8] Cai dat bo con tro chuot..." -ForegroundColor Cyan
$cursorPaths = @(
    (Join-Path $ScriptDir "Cursors\Install.inf"),
    (Join-Path $ScriptDir "Mr v5 Cursors\Mr v5 MegaPack\Install.inf"),
    "C:\Users\Administrator\Downloads\Setup\Cursors\Install.inf"
)
$cursorPaths | ForEach-Object {
    if (Test-Path -Path $_) {
        Push-Location -Path (Split-Path -Path $_ -Parent)
        Start-Process -FilePath "rundll32.exe" -ArgumentList "advpack.dll,LaunchINFSection Install.inf,DefaultInstall" -Wait
        Pop-Location
    }
}

# ============================================================================
# 7. CHAY CAC UNG DUNG THEO LUA CHON (GAMING HOAC OFFICE)
# ============================================================================
Write-Host "[7/8] Dang khoi chay cac ung dung thuoc che do $ModeName..." -ForegroundColor Cyan
$TargetAppFolders \vert{} ForEach-Object {$folderName = $_$possibleDirs = @(
        (Join-Path $ScriptDir "Apps\$folderName"),
        "C:\Users\Administrator\Downloads\Setup\Apps\$folderName"
    )
    $possibleDirs | ForEach-Object {
        if (Test-Path -Path $_) {
            Get-ChildItem -Path $_ -Filter "*.exe" -Recurse -File | ForEach-Object {
                Write-Host " -> Dang chay: [$folderName] $($_.Name)" -ForegroundColor Green
                Start-Process -FilePath $_.FullName -WorkingDirectory$_.DirectoryName
            }
        }
    }
}

# ============================================================================
# 8. MO BANG CHON CHUOT & CHROME
# ============================================================================
Write-Host "[8/8] Hoan tat! Dang mo Mouse Properties va Google Chrome..." -ForegroundColor Cyan
Start-Process -FilePath "control.exe" -ArgumentList "main.cpl,,1"
Start-Process -FilePath "chrome.exe" -ArgumentList "--disable-background-networking --disable-component-update --disable-default-apps --no-default-browser-check --no-first-run"
