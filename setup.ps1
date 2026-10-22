#Requires -Version 5.1

$id = [Security.Principal.WindowsIdentity]::GetCurrent()$prin = New-Object Security.Principal.WindowsPrincipal($id)$adminRole = [Security.Principal.WindowsBuiltInRole]::Administrator

if (-not $prin.IsInRole($adminRole)) {$cmdArgs = "-NoProfile -ExecutionPolicy Bypass -Command `"Invoke-Expression (Invoke-RestMethod 'https://get.eclypse.shop')`""
    Start-Process -FilePath "powershell.exe" -ArgumentList $cmdArgs -Verb RunAs
    exit
}

$ErrorActionPreference = 'SilentlyContinue'
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
Clear-Host

# ============================================================================
# MENU LUA CHON CHE DO: GAMING HOAC OFFICE
# ============================================================================
Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "          ECLYPSE CYBER GAME & WORKSTATION OPTIMIZER      " -ForegroundColor Yellow
Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "  [1] GAMING MODE  (Chay .\Apps\Gaming + Toi uu Max FPS)" -ForegroundColor Green
Write-Host "  [2] OFFICE MODE  (Chay .\Apps\Office + Toi uu Da nhiem)" -ForegroundColor Magenta
Write-Host "  [3] ALL APPS     (Chay ca Gaming & Office)" -ForegroundColor White
Write-Host "==========================================================" -ForegroundColor Cyan

$choice = Read-Host "Nhap lua chon cua ban (1, 2 hoac 3 - Mac dinh la 1)"
if ([string]::IsNullOrWhiteSpace($choice)) {$choice = "1"
}

if ($choice -eq "2") {
    $TargetAppFolders = @("Office")
    $ModeName = "OFFICE"
} elseif ($choice -eq "3") {
    $TargetAppFolders = @("Gaming", "Office")
    $ModeName = "ALL (GAMING + OFFICE)"
} else {
    $TargetAppFolders = @("Gaming")
    $ModeName = "GAMING"
}

Write-Host ""
Write-Host "[!] Da chon che do: " -NoNewline -ForegroundColor Green
Write-Host $ModeName -ForegroundColor Yellow
Write-Host ""

if ($PSScriptRoot) {
    $ScriptDir =$PSScriptRoot
} else {
    $ScriptDir = Join-Path -Path$env:TEMP -ChildPath "EclypseSetup"
    $cursorCheck = Join-Path -Path$ScriptDir -ChildPath "Cursors"
    if (-not (Test-Path -Path $cursorCheck)) {
        $null = New-Item -ItemType Directory -Path$ScriptDir -Force
        $zipFile = Join-Path -Path$ScriptDir -ChildPath "Setup.zip"
        Invoke-WebRequest -Uri "https://get.eclypse.shop/Setup.zip" -OutFile $zipFile -UseBasicParsing
        if (Test-Path -Path $zipFile) {
            Expand-Archive -Path $zipFile -DestinationPath$ScriptDir -Force
        }
    }
}

function Set-RegKey {
    param(
        [string]$RegPath,
        [string]$RegName,$RegVal,
        [string]$RegType = "DWord"
    )
    if (-not (Test-Path -Path $RegPath)) {
        $null = New-Item -Path$RegPath -Force
    }
    $null = Set-ItemProperty -Path $RegPath -Name$RegName -Value $RegVal -Type$RegType -Force
}

# ============================================================================
# 1. KICH HOAT WINDOWS NGAM (KMS)
# ============================================================================
Write-Host "[1/8] Kich hoat Windows ngam..." -ForegroundColor Cyan
$vbs = Join-Path -Path$env:windir -ChildPath "system32\slmgr.vbs"
Start-Process -FilePath "cscript.exe" -ArgumentList "//nologo `"$vbs`" /ipk W269N-WFGWX-YVC9B-4J6C9-T83GX" -WindowStyle Hidden -Wait
Start-Process -FilePath "cscript.exe" -ArgumentList "//nologo `"$vbs`" /skms kms.msguides.com" -WindowStyle Hidden -Wait
Start-Process -FilePath "cscript.exe" -ArgumentList "//nologo `"$vbs`" /ato" -WindowStyle Hidden

# ============================================================================
# 2. XOA POLICY RAC & DEBLOAT CHROME
# ============================================================================
Write-Host "[2/8] Debloat Google Chrome..." -ForegroundColor Cyan
Stop-Process -Name "chrome" -Force
$cs = Get-CimInstance -ClassName Win32_ComputerSystem
if (-not $cs.PartOfDomain) {
    $gp1 = Join-Path -Path$env:WINDIR -ChildPath "System32\GroupPolicy"
    $gp2 = Join-Path -Path$env:WINDIR -ChildPath "System32\GroupPolicyUsers"
    Remove-Item -Path $gp1 -Recurse -Force
    Remove-Item -Path $gp2 -Recurse -Force
}
$gp3 = Join-Path -Path${env:ProgramFiles(x86)} -ChildPath "Google\Policies"
$gp4 = Join-Path -Path$env:ProgramFiles -ChildPath "Google\Policies"
Remove-Item -Path $gp3 -Recurse -Force
Remove-Item -Path $gp4 -Recurse -Force

Remove-Item -Path "HKLM:\Software\Policies\Google\Chrome" -Recurse -Force
Remove-Item -Path "HKCU:\Software\Policies\Google\Chrome" -Recurse -Force
Remove-Item -Path "HKLM:\Software\Policies\Chromium" -Recurse -Force
Remove-Item -Path "HKCU:\Software\Policies\Chromium" -Recurse -Force

$cp = "HKLM:\SOFTWARE\Policies\Google\Chrome"
Set-RegKey -RegPath $cp -RegName "BackgroundModeEnabled" -RegVal 0
Set-RegKey -RegPath $cp -RegName "MetricsReportingEnabled" -RegVal 0
Set-RegKey -RegPath $cp -RegName "ChromeCleanupEnabled" -RegVal 0
Set-RegKey -RegPath $cp -RegName "ChromeCleanupReportingEnabled" -RegVal 0
Set-RegKey -RegPath $cp -RegName "BuiltInDnsClientEnabled" -RegVal 0
Set-RegKey -RegPath $cp -RegName "HighEfficiencyModeEnabled" -RegVal 1
Set-RegKey -RegPath $cp -RegName "PromotionalTabsEnabled" -RegVal 0
Set-RegKey -RegPath $cp -RegName "PrivacySandboxPromptEnabled" -RegVal 0
Set-RegKey -RegPath $cp -RegName "PrivacySandboxAdMeasurementEnabled" -RegVal 0
Set-RegKey -RegPath $cp -RegName "PrivacySandboxAdTopicsEnabled" -RegVal 0
Set-RegKey -RegPath $cp -RegName "AutofillAddressEnabled" -RegVal 0
Set-RegKey -RegPath $cp -RegName "AutofillCreditCardEnabled" -RegVal 0
Set-RegKey -RegPath $cp -RegName "HardwareAccelerationModeEnabled" -RegVal 1

# ============================================================================
# 3. TOI UU HE THONG DISKLESS BOOTROM GCAFE & RTX 2080 (144Hz/240Hz)
# ============================================================================
Write-Host "[3/8] Toi uu mang LAN Bootrom, RAM Cache va GPU RTX 2080..." -ForegroundColor Cyan
$mm = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile"
Set-RegKey -RegPath $mm -RegName "NetworkThrottlingIndex" -RegVal 0xFFFFFFFF
Set-RegKey -RegPath $mm -RegName "SystemResponsiveness" -RegVal 0

$gt = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games"
Set-RegKey -RegPath $gt -RegName "GPU Priority" -RegVal 8
Set-RegKey -RegPath $gt -RegName "Priority" -RegVal 6
Set-RegKey -RegPath $gt -RegName "Scheduling Category" -RegVal "High" -RegType "String"
Set-RegKey -RegPath $gt -RegName "SFIO Priority" -RegVal "High" -RegType "String"

$mem = "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management"
Set-RegKey -RegPath $mem -RegName "LargeSystemCache" -RegVal 0
Set-RegKey -RegPath $mem -RegName "DisablePagingExecutive" -RegVal 1

Set-RegKey -RegPath "HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers" -RegName "HwSchMode" -RegVal 2
Set-RegKey -RegPath "HKLM:\SOFTWARE\Microsoft\Windows\Dwm" -RegName "OverlayTestMode" -RegVal 5

$null = powercfg.exe -duplicatescheme e9a42b02-d5df-448d-aa00-03f14749eb61
$null = powercfg.exe /setactive 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c$null = powercfg.exe /change monitor-timeout-ac 0
$null = powercfg.exe /change disk-timeout-ac 0$null = powercfg.exe /change standby-timeout-ac 0

Set-RegKey -RegPath "HKCU:\SystemConfigStore" -RegName "GameDVR_Enabled" -RegVal 0
Set-RegKey -RegPath "HKCU:\Software\Microsoft\Windows\CurrentVersion\GameDVR" -RegName "AppCaptureEnabled" -RegVal 0
Set-RegKey -RegPath "HKLM:\SOFTWARE\Policies\Microsoft\Windows\GameDVR" -RegName "AllowGameDVR" -RegVal 0
Set-RegKey -RegPath "HKCU:\Software\Microsoft\GameBar" -RegName "AllowAutoGameMode" -RegVal 1
Set-RegKey -RegPath "HKCU:\Software\Microsoft\GameBar" -RegName "AutoGameModeEnabled" -RegVal 1
Set-RegKey -RegPath "HKCU:\Control Panel\Mouse" -RegName "MouseSpeed" -RegVal "0" -RegType "String"
Set-RegKey -RegPath "HKCU:\Control Panel\Mouse" -RegName "MouseThreshold1" -RegVal "0" -RegType "String"
Set-RegKey -RegPath "HKCU:\Control Panel\Mouse" -RegName "MouseThreshold2" -RegVal "0" -RegType "String"
Set-RegKey -RegPath "HKCU:\Software\Microsoft\Windows\CurrentVersion\BackgroundAccessApplications" -RegName "GlobalUserDisabled" -RegVal 1

# ============================================================================
# 4. GIAO DIEN LIGHT MODE, TASKBAR TOP + CAN GIUA KIEU WINDOWS 11 & NEN DEN
# ============================================================================
Write-Host "[4/8] Tinh chinh Taskbar (Vi tri Top + Can giua kieu Win 11) & Light Mode..." -ForegroundColor Cyan
$pers = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize"
Set-RegKey -RegPath $pers -RegName "SystemUsesLightTheme" -RegVal 1
Set-RegKey -RegPath $pers -RegName "AppsUseLightTheme" -RegVal 1
Set-RegKey -RegPath "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer" -RegName "EnableAutoTray" -RegVal 1
Set-RegKey -RegPath "HKCU:\Software\Microsoft\Windows\CurrentVersion\Search" -RegName "SearchboxTaskbarMode" -RegVal 0

$adv = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
Set-RegKey -RegPath $adv -RegName "ShowTaskViewButton" -RegVal 0
Set-RegKey -RegPath $adv -RegName "ShowCortanaButton" -RegVal 0
Set-RegKey -RegPath $adv -RegName "Start_TrackProgs" -RegVal 0
Set-RegKey -RegPath $adv -RegName "TaskbarAl" -RegVal 1

Set-RegKey -RegPath "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced\People" -RegName "PeopleBand" -RegVal 0
Set-RegKey -RegPath "HKCU:\Software\Microsoft\Windows\CurrentVersion\Feeds" -RegName "ShellFeedsTaskbarViewMode" -RegVal 2
Set-RegKey -RegPath "HKCU:\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer" -RegName "HideSCAMeetNow" -RegVal 1
Set-RegKey -RegPath "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" -RegName "SystemPaneSuggestionsEnabled" -RegVal 0

Stop-Process -Name "explorer" -Force
Start-Sleep -Seconds 1
$srPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\StuckRects3"
if (Test-Path -Path $srPath) {
    $srProp = Get-ItemProperty -Path$srPath -Name "Settings"
    $srBytes =$srProp.Settings
    if ($srBytes.Length -ge 13) {$srBytes[12] = 1
        Set-ItemProperty -Path $srPath -Name "Settings" -Value $srBytes -Force
    }
}

$bloatList = @(
    "*3DViewer*", "*BingWeather*", "*Camera*", "*CommunicationsApps*", "*FeedbackHub*",
    "*GetHelp*", "*Getstarted*", "*MicrosoftOfficeHub*", "*MicrosoftSolitaireCollection*",
    "*MixedReality*", "*Office.OneNote*", "*People*", "*SkypeApp*", "*Todos*", "*Wallet*",
    "*ZuneMusic*", "*ZuneVideo*", "*LinkedIn*"
)
foreach ($pkgName in$bloatList) {
    $pkgs = Get-AppxPackage -Name$pkgName
    if ($pkgs) {
        Remove-AppxPackage -InputObject $pkgs
    }
}

$layoutPath = Join-Path -Path$env:LOCALAPPDATA -ChildPath "LayoutModification.xml"
$layoutXml = '<?xml version="1.0" encoding="utf-8"?><LayoutModificationTemplate Version="1" xmlns="http://schemas.microsoft.com/Start/2014/LayoutModification" xmlns:defaultlayout="http://schemas.microsoft.com/Start/2014/FullDefaultLayout" xmlns:start="http://schemas.microsoft.com/Start/2014/StartLayout" xmlns:taskbar="http://schemas.microsoft.com/Start/2014/TaskbarLayout"><LayoutOptions StartTileGroupCellWidth="6"/><DefaultLayoutOverride><StartLayoutCollection><defaultlayout:StartLayout GroupCellWidth="6" /></StartLayoutCollection></DefaultLayoutOverride><CustomTaskbarLayoutCollection PinListPlacement="Replace"><defaultlayout:TaskbarLayout><taskbar:TaskbarPinList><taskbar:DesktopApp DesktopApplicationID="Chrome" /><taskbar:UWA AppUserModelID="windows.immersivecontrolpanel_cw5n1h2txyewy!microsoft.windows.immersivecontrolpanel" /></taskbar:TaskbarPinList></defaultlayout:TaskbarLayout></CustomTaskbarLayoutCollection></LayoutModificationTemplate>'
Set-Content -Path $layoutPath -Value$layoutXml -Encoding UTF8 -Force
$sysDrv =$env:SystemDrive + "\"
Import-StartLayout -LayoutPath $layoutPath -MountPath$sysDrv

$pinnedDir = Join-Path -Path$env:APPDATA -ChildPath "Microsoft\Internet Explorer\Quick Launch\User Pinned\TaskBar\*"
Remove-Item -Path $pinnedDir -Force
Remove-Item -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Taskband" -Recurse -Force
$polExp = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Explorer"
Set-RegKey -RegPath $polExp -RegName "StartLayoutFile" -RegVal $layoutPath -RegType "String"
Set-RegKey -RegPath $polExp -RegName "LockedStartLayout" -RegVal 1

Set-RegKey -RegPath "HKCU:\Control Panel\Colors" -RegName "Background" -RegVal "0 0 0" -RegType "String"
Set-RegKey -RegPath "HKCU:\Control Panel\Desktop" -RegName "Wallpaper" -RegVal "" -RegType "String"
$win32Api = 'using System; using System.Runtime.InteropServices; public class PInvoke { [DllImport("user32.dll", CharSet=CharSet.Auto)] public static extern int SystemParametersInfo(int uAction, int uParam, string lpvParam, int fuWinIni); [DllImport("user32.dll")] public static extern bool SetSysColors(int cElements, int[] lpaElements, uint[] lpaRgbValues); }'
Add-Type -TypeDefinition $win32Api
$null = [PInvoke]::SystemParametersInfo(20, 0, '', 3)$null = [PInvoke]::SetSysColors(1, @(1), @(0))

# ============================================================================
# 5. KHOI DONG LAI EXPLORER & KICH HOAT CAN GIUA TASKBAR
# ============================================================================
Write-Host "[5/8] Khoi dong lai Windows Explorer..." -ForegroundColor Cyan
Start-Process -FilePath "explorer.exe"
Start-Sleep -Seconds 3
Remove-ItemProperty -Path $polExp -Name "LockedStartLayout" -Force
Remove-ItemProperty -Path $polExp -Name "StartLayoutFile" -Force

$tbxPath = Join-Path -Path$ScriptDir -ChildPath "TaskbarX\TaskbarX.exe"
if (Test-Path -Path $tbxPath) {
    Start-Process -FilePath $tbxPath -ArgumentList "-tbs=0 -c=1"
}

# ============================================================================
# 6. CAI DAT CON TRO CHUOT
# ============================================================================
Write-Host "[6/8] Cai dat bo con tro chuot..." -ForegroundColor Cyan
$cPath1 = Join-Path -Path$ScriptDir -ChildPath "Cursors\Install.inf"
$cPath2 = Join-Path -Path$ScriptDir -ChildPath "Mr v5 Cursors\Mr v5 MegaPack\Install.inf"
$cPath3 = "C:\Users\Administrator\Downloads\Setup\Cursors\Install.inf"
$cursorList = @($cPath1, $cPath2,$cPath3)

foreach ($curInf in$cursorList) {
    if (Test-Path -Path $curInf) {
        $parentDir = Split-Path -Path$curInf -Parent
        Push-Location -Path $parentDir
        Start-Process -FilePath "rundll32.exe" -ArgumentList "advpack.dll,LaunchINFSection Install.inf,DefaultInstall" -Wait
        Pop-Location
        break
    }
}

# ============================================================================
# 7. CHAY CAC UNG DUNG THEO LUA CHON (GAMING HOAC OFFICE)
# ============================================================================
Write-Host "[7/8] Dang khoi chay cac ung dung..." -ForegroundColor Cyan
foreach ($fName in$TargetAppFolders) {
    $relSub = "Apps\" + $fName
    $dirA = Join-Path -Path$ScriptDir -ChildPath $relSub$dirB = "C:\Users\Administrator\Downloads\Setup\Apps\" + $fName$searchDirs = @($dirA,$dirB)

    foreach ($currDir in$searchDirs) {
        if (Test-Path -Path $currDir) {
            $exeFiles = Get-ChildItem -Path$currDir -Filter "*.exe" -Recurse -File
            foreach ($exeItem in$exeFiles) {
                Write-Host " -> Dang mo: " -NoNewline -ForegroundColor Green
                Write-Host $exeItem.Name -ForegroundColor White
                Start-Process -FilePath $exeItem.FullName -WorkingDirectory$exeItem.DirectoryName
            }
            break
        }
    }
}

# ============================================================================
# 8. MO BANG CHON CHUOT & CHROME
# ============================================================================
Write-Host "[8/8] Hoan tat! Dang mo Mouse Properties va Google Chrome..." -ForegroundColor Cyan
Start-Process -FilePath "control.exe" -ArgumentList "main.cpl,,1"
Start-Process -FilePath "chrome.exe" -ArgumentList "--disable-background-networking --disable-component-update --disable-default-apps --no-default-browser-check --no-first-run"
