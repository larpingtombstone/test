#Requires -Version 5.1
<#
.SYNOPSIS
    Eclypse Cyber Game + Workstation Setup
    - Downloads + installs: Discord, Steam, LLaunch, Zalo, Zic
    - Then runs all Eclypse optimizations (steps 1-8)
.NOTES
    Run as Administrator or it will self-elevate.
#>

# ============================================================================
# SELF-ELEVATE
# ============================================================================
$id        = [Security.Principal.WindowsIdentity]::GetCurrent()
$prin      = New-Object Security.Principal.WindowsPrincipal($id)
$adminRole = [Security.Principal.WindowsBuiltInRole]::Administrator

if (-not $prin.IsInRole($adminRole)) {
    $self = $MyInvocation.MyCommand.Path
    if ($self) {
        $cmdArgs = "-NoProfile -ExecutionPolicy Bypass -File `"$self`""
    } else {
        $cmdArgs = "-NoProfile -ExecutionPolicy Bypass -Command `"Invoke-Expression (Invoke-RestMethod 'https://get.eclypse.shop')`""
    }
    Start-Process -FilePath "powershell.exe" -ArgumentList $cmdArgs -Verb RunAs
    exit
}

$ErrorActionPreference = 'SilentlyContinue'
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
Clear-Host

# ============================================================================
# SHARED HELPERS
# ============================================================================
function Write-Banner {
    param([string]$Text, [string]$Color = "Cyan")
    Write-Host ""
    Write-Host ("=" * 62) -ForegroundColor $Color
    Write-Host "  $Text" -ForegroundColor Yellow
    Write-Host ("=" * 62) -ForegroundColor $Color
}

function Write-Step { Write-Host "  >> $($args[0])" -ForegroundColor White }
function Write-OK   { Write-Host "  [OK] $($args[0])" -ForegroundColor Green  }
function Write-Warn { Write-Host "  [!!] $($args[0])" -ForegroundColor Yellow }
function Write-Fail { Write-Host "  [XX] $($args[0])" -ForegroundColor Red    }

function Set-RegKey {
    param(
        [string]$RegPath,
        [string]$RegName,
                $RegVal,
        [string]$RegType = "DWord"
    )
    if (-not (Test-Path -Path $RegPath)) {
        $null = New-Item -Path $RegPath -Force
    }
    $null = Set-ItemProperty -Path $RegPath -Name $RegName -Value $RegVal -Type $RegType -Force
}

# Download file with browser-like user-agent (helps with Cloudflare)
function Get-AppFile {
    param(
        [string]$Uri,
        [string]$OutFile,
        [string]$Label
    )
    Write-Step "Downloading $Label..."
    Write-Host "     $Uri" -ForegroundColor DarkGray
    try {
        # Use a realistic browser user-agent to bypass some Cloudflare checks
        $headers = @{
            "User-Agent" = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"
        }
        Invoke-WebRequest -Uri $Uri -OutFile $OutFile -UseBasicParsing -Headers $headers -ErrorAction Stop
        Write-OK "$Label downloaded"
        return $true
    }
    catch {
        Write-Fail "Download failed for $Label : $_"
        if (Test-Path $OutFile) { Remove-Item $OutFile -Force }
        return $false
    }
}

# Run an installer and wait for it to fully exit
function Start-Installer {
    param(
        [string]$FilePath,
        [string[]]$Arguments = @(),
        [string]$Label,
        [string]$WorkDir     = "",
        [int]$TimeoutSec     = 300
    )
    Write-Step "Installing $Label -- waiting up to ${TimeoutSec}s..."
    try {
        $sArgs = @{
            FilePath    = $FilePath
            PassThru    = $true
            ErrorAction = 'Stop'
        }
        if ($Arguments.Count -gt 0) { $sArgs.ArgumentList    = $Arguments }
        if ($WorkDir -ne "")        { $sArgs.WorkingDirectory = $WorkDir   }

        $proc = Start-Process @sArgs
        $ok   = $proc.WaitForExit($TimeoutSec * 1000)
        if ($ok) {
            Write-OK "$Label finished (exit code $($proc.ExitCode))"
        } else {
            Write-Warn "$Label timed out after ${TimeoutSec}s -- continuing"
        }
    }
    catch {
        Write-Fail "Failed to start $Label installer : $_"
    }
}

# ============================================================================
# MODE SELECTION MENU
# ============================================================================
Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "          ECLYPSE CYBER GAME + WORKSTATION OPTIMIZER      " -ForegroundColor Yellow
Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "  [1] GAMING MODE  (Chay .\Apps\Gaming + Toi uu Max FPS)" -ForegroundColor Green
Write-Host "  [2] OFFICE MODE  (Chay .\Apps\Office + Toi uu Da nhiem)" -ForegroundColor Magenta
Write-Host "  [3] ALL APPS     (Chay ca Gaming va Office)"              -ForegroundColor White
Write-Host "==========================================================" -ForegroundColor Cyan

$choice = Read-Host "Nhap lua chon (1, 2 hoac 3 - mac dinh la 1)"
if ([string]::IsNullOrWhiteSpace($choice)) { $choice = "1" }

if ($choice -eq "2") {
    $TargetAppFolders = @("Office")
    $ModeName         = "OFFICE"
} elseif ($choice -eq "3") {
    $TargetAppFolders = @("Gaming", "Office")
    $ModeName         = "ALL (GAMING + OFFICE)"
} else {
    $TargetAppFolders = @("Gaming")
    $ModeName         = "GAMING"
}

Write-Host ""
Write-Host "[!] Da chon che do: " -NoNewline -ForegroundColor Green
Write-Host $ModeName -ForegroundColor Yellow
Write-Host ""

# ============================================================================
# RESOLVE SCRIPT DIR / DOWNLOAD ECLYPSE SETUP.ZIP IF NEEDED
# ============================================================================
if ($PSScriptRoot) {
    $ScriptDir = $PSScriptRoot
} else {
    $ScriptDir   = Join-Path $env:TEMP "EclypseSetup"
    $cursorCheck = Join-Path $ScriptDir "Cursors"
    if (-not (Test-Path $cursorCheck)) {
        $null    = New-Item -ItemType Directory -Path $ScriptDir -Force
        $zipFile = Join-Path $ScriptDir "Setup.zip"
        Invoke-WebRequest -Uri "https://get.eclypse.shop/Setup.zip" -OutFile $zipFile -UseBasicParsing
        if (Test-Path $zipFile) {
            Expand-Archive -Path $zipFile -DestinationPath $ScriptDir -Force
        }
    }
}

$TempDir = Join-Path $env:TEMP "AppInstalls"
$null = New-Item -ItemType Directory -Path $TempDir -Force

# ============================================================================
# [0/8] DOWNLOAD + INSTALL APPS
# ============================================================================
Write-Banner "[0/8] DOWNLOADING AND INSTALLING APPLICATIONS"

# Discord (always re-download to ensure valid binary)
$discordExe = Join-Path $TempDir "DiscordSetup.exe"
if (Test-Path $discordExe) { Remove-Item $discordExe -Force }
$discordUrl = "https://discord.com/api/downloads/distributions/app/installers/latest?channel=stable&platform=win&arch=x64"
$ok = Get-AppFile -Uri $discordUrl -OutFile $discordExe -Label "Discord"
if ($ok) { Start-Installer -FilePath $discordExe -Arguments @("--silent") -Label "Discord" }

# Steam
$steamExe = Join-Path $TempDir "SteamSetup.exe"
if (Test-Path $steamExe) {
    Write-Warn "Steam already cached -- skipping download"
    $ok = $true
} else {
    $ok = Get-AppFile -Uri "https://cdn.akamai.steamstatic.com/client/installer/SteamSetup.exe" -OutFile $steamExe -Label "Steam"
}
if ($ok) { Start-Installer -FilePath $steamExe -Arguments @("/S") -Label "Steam" }

# LLaunch (may be behind Cloudflare, so skip on failure)
$llExe = Join-Path $TempDir "LLaunchSetup.exe"
if (Test-Path $llExe) {
    Write-Warn "LLaunch already cached -- skipping download"
    $ok = $true
} else {
    Write-Step "Attempting LLaunch download (may fail due to Cloudflare)..."
    $ok = Get-AppFile -Uri "https://dl.llaun.ch/legacy/installer" -OutFile $llExe -Label "LLaunch"
    if (-not $ok) {
        Write-Warn "LLaunch download blocked by Cloudflare -- skipping (install manually from https://llaunch.io)"
    }
}
if ($ok) { Start-Installer -FilePath $llExe -Arguments @("/silent") -Label "LLaunch" }

# Zalo (may redirect; try direct download)
$zaloExe = Join-Path $TempDir "ZaloSetup.exe"
if (Test-Path $zaloExe) {
    Write-Warn "Zalo already cached -- skipping download"
    $ok = $true
} else {
    Write-Step "Attempting Zalo download..."
    $ok = Get-AppFile -Uri "https://zalo.me/download/zalo-pc?utm=90000" -OutFile $zaloExe -Label "Zalo"
    if (-not $ok) {
        Write-Warn "Zalo download failed -- skipping (install manually from https://zalo.me)"
    }
}
if ($ok) { Start-Installer -FilePath $zaloExe -Arguments @("/silent") -Label "Zalo" }

# Zic (ZIP)
$zicZip     = Join-Path $TempDir "Zic-Windows.zip"
$zicExtract = Join-Path $TempDir "Zic"
if (Test-Path $zicZip) {
    Write-Warn "Zic already cached -- skipping download"
    $ok = $true
} else {
    $ok = Get-AppFile -Uri "https://bu0aexszmjfm6qkc.public.blob.vercel-storage.com/Windows/Zic-Windows.zip" -OutFile $zicZip -Label "Zic"
}
if ($ok) {
    Write-Step "Extracting Zic..."
    $null = New-Item -ItemType Directory -Path $zicExtract -Force
    Expand-Archive -LiteralPath $zicZip -DestinationPath $zicExtract -Force
    $zicExe = Get-ChildItem -Path $zicExtract -Filter "*.exe" -Recurse -File | Select-Object -First 1
    if ($zicExe) {
        Start-Installer -FilePath $zicExe.FullName -WorkDir $zicExe.DirectoryName -Label "Zic" -TimeoutSec 120
    } else {
        Write-Warn "No .exe found inside Zic ZIP -- check $zicExtract manually"
    }
}

Write-OK "All app installations complete"

# ============================================================================
# [1/8] KICH HOAT WINDOWS NGAM (KMS)
# ============================================================================
Write-Host "[1/8] Kich hoat Windows ngam..." -ForegroundColor Cyan
$vbs = Join-Path $env:windir "system32\slmgr.vbs"
Start-Process "cscript.exe" -ArgumentList "//nologo `"$vbs`" /ipk W269N-WFGWX-YVC9B-4J6C9-T83GX" -WindowStyle Hidden -Wait
Start-Process "cscript.exe" -ArgumentList "//nologo `"$vbs`" /skms kms.msguides.com"               -WindowStyle Hidden -Wait
Start-Process "cscript.exe" -ArgumentList "//nologo `"$vbs`" /ato"                                 -WindowStyle Hidden

# ============================================================================
# [2/8] XOA POLICY RAC + DEBLOAT CHROME
# ============================================================================
Write-Host "[2/8] Debloat Google Chrome..." -ForegroundColor Cyan
Stop-Process -Name "chrome" -Force
$cs = Get-CimInstance -ClassName Win32_ComputerSystem
if (-not $cs.PartOfDomain) {
    Remove-Item -Path (Join-Path $env:WINDIR "System32\GroupPolicy")      -Recurse -Force
    Remove-Item -Path (Join-Path $env:WINDIR "System32\GroupPolicyUsers") -Recurse -Force
}
Remove-Item -Path (Join-Path ${env:ProgramFiles(x86)} "Google\Policies") -Recurse -Force
Remove-Item -Path (Join-Path $env:ProgramFiles "Google\Policies")         -Recurse -Force
Remove-Item -Path "HKLM:\Software\Policies\Google\Chrome" -Recurse -Force
Remove-Item -Path "HKCU:\Software\Policies\Google\Chrome" -Recurse -Force
Remove-Item -Path "HKLM:\Software\Policies\Chromium"      -Recurse -Force
Remove-Item -Path "HKCU:\Software\Policies\Chromium"      -Recurse -Force

$cp = "HKLM:\SOFTWARE\Policies\Google\Chrome"
Set-RegKey -RegPath $cp -RegName "BackgroundModeEnabled"              -RegVal 0
Set-RegKey -RegPath $cp -RegName "MetricsReportingEnabled"            -RegVal 0
Set-RegKey -RegPath $cp -RegName "ChromeCleanupEnabled"               -RegVal 0
Set-RegKey -RegPath $cp -RegName "ChromeCleanupReportingEnabled"      -RegVal 0
Set-RegKey -RegPath $cp -RegName "BuiltInDnsClientEnabled"            -RegVal 0
Set-RegKey -RegPath $cp -RegName "HighEfficiencyModeEnabled"          -RegVal 1
Set-RegKey -RegPath $cp -RegName "PromotionalTabsEnabled"             -RegVal 0
Set-RegKey -RegPath $cp -RegName "PrivacySandboxPromptEnabled"        -RegVal 0
Set-RegKey -RegPath $cp -RegName "PrivacySandboxAdMeasurementEnabled" -RegVal 0
Set-RegKey -RegPath $cp -RegName "PrivacySandboxAdTopicsEnabled"      -RegVal 0
Set-RegKey -RegPath $cp -RegName "AutofillAddressEnabled"             -RegVal 0
Set-RegKey -RegPath $cp -RegName "AutofillCreditCardEnabled"          -RegVal 0
Set-RegKey -RegPath $cp -RegName "HardwareAccelerationModeEnabled"    -RegVal 1

# ============================================================================
# [3/8] TOI UU HE THONG DISKLESS BOOTROM GCAFE + RTX 2080 (144Hz/240Hz)
# ============================================================================
Write-Host "[3/8] Toi uu mang LAN Bootrom, RAM Cache va GPU RTX 2080..." -ForegroundColor Cyan
$mm = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile"
Set-RegKey -RegPath $mm -RegName "NetworkThrottlingIndex" -RegVal 0xFFFFFFFF
Set-RegKey -RegPath $mm -RegName "SystemResponsiveness"   -RegVal 0

$gt = "$mm\Tasks\Games"
Set-RegKey -RegPath $gt -RegName "GPU Priority"        -RegVal 8
Set-RegKey -RegPath $gt -RegName "Priority"            -RegVal 6
Set-RegKey -RegPath $gt -RegName "Scheduling Category" -RegVal "High" -RegType "String"
Set-RegKey -RegPath $gt -RegName "SFIO Priority"       -RegVal "High" -RegType "String"

$mem = "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management"
Set-RegKey -RegPath $mem -RegName "LargeSystemCache"       -RegVal 0
Set-RegKey -RegPath $mem -RegName "DisablePagingExecutive" -RegVal 1

Set-RegKey -RegPath "HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers" -RegName "HwSchMode"       -RegVal 2
Set-RegKey -RegPath "HKLM:\SOFTWARE\Microsoft\Windows\Dwm"                   -RegName "OverlayTestMode" -RegVal 5

$null = powercfg.exe -duplicatescheme e9a42b02-d5df-448d-aa00-03f14749eb61
$null = powercfg.exe /setactive 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c
$null = powercfg.exe /change monitor-timeout-ac 0
$null = powercfg.exe /change disk-timeout-ac    0
$null = powercfg.exe /change standby-timeout-ac 0

Set-RegKey -RegPath "HKCU:\SystemConfigStore"                                                      -RegName "GameDVR_Enabled"       -RegVal 0
Set-RegKey -RegPath "HKCU:\Software\Microsoft\Windows\CurrentVersion\GameDVR"                     -RegName "AppCaptureEnabled"     -RegVal 0
Set-RegKey -RegPath "HKLM:\SOFTWARE\Policies\Microsoft\Windows\GameDVR"                           -RegName "AllowGameDVR"          -RegVal 0
Set-RegKey -RegPath "HKCU:\Software\Microsoft\GameBar"                                             -RegName "AllowAutoGameMode"     -RegVal 1
Set-RegKey -RegPath "HKCU:\Software\Microsoft\GameBar"                                             -RegName "AutoGameModeEnabled"   -RegVal 1
Set-RegKey -RegPath "HKCU:\Control Panel\Mouse"                                                    -RegName "MouseSpeed"            -RegVal "0" -RegType "String"
Set-RegKey -RegPath "HKCU:\Control Panel\Mouse"                                                    -RegName "MouseThreshold1"       -RegVal "0" -RegType "String"
Set-RegKey -RegPath "HKCU:\Control Panel\Mouse"                                                    -RegName "MouseThreshold2"       -RegVal "0" -RegType "String"
Set-RegKey -RegPath "HKCU:\Software\Microsoft\Windows\CurrentVersion\BackgroundAccessApplications" -RegName "GlobalUserDisabled"    -RegVal 1

# ============================================================================
# [4/8] GIAO DIEN LIGHT MODE, TASKBAR + CAN GIUA KIEU WIN 11 + NEN DEN
# ============================================================================
Write-Host "[4/8] Tinh chinh Taskbar (Vi tri Top + Can giua kieu Win 11) va Light Mode..." -ForegroundColor Cyan
$pers = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize"
Set-RegKey -RegPath $pers -RegName "SystemUsesLightTheme" -RegVal 1
Set-RegKey -RegPath $pers -RegName "AppsUseLightTheme"    -RegVal 1
Set-RegKey -RegPath "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer" -RegName "EnableAutoTray"       -RegVal 1
Set-RegKey -RegPath "HKCU:\Software\Microsoft\Windows\CurrentVersion\Search"   -RegName "SearchboxTaskbarMode" -RegVal 0

$adv = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
Set-RegKey -RegPath $adv -RegName "ShowTaskViewButton" -RegVal 0
Set-RegKey -RegPath $adv -RegName "ShowCortanaButton"  -RegVal 0
Set-RegKey -RegPath $adv -RegName "Start_TrackProgs"   -RegVal 0
Set-RegKey -RegPath $adv -RegName "TaskbarAl"          -RegVal 1

Set-RegKey -RegPath "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced\People"  -RegName "PeopleBand"                   -RegVal 0
Set-RegKey -RegPath "HKCU:\Software\Microsoft\Windows\CurrentVersion\Feeds"                     -RegName "ShellFeedsTaskbarViewMode"    -RegVal 2
Set-RegKey -RegPath "HKCU:\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer"         -RegName "HideSCAMeetNow"               -RegVal 1
Set-RegKey -RegPath "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager"    -RegName "SystemPaneSuggestionsEnabled" -RegVal 0

Stop-Process -Name "explorer" -Force
Start-Sleep -Seconds 1

$srPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\StuckRects3"
if (Test-Path $srPath) {
    $srBytes = (Get-ItemProperty -Path $srPath -Name "Settings").Settings
    if ($srBytes.Length -ge 13) {
        $srBytes[12] = 1
        Set-ItemProperty -Path $srPath -Name "Settings" -Value $srBytes -Force
    }
}

$bloatList = @(
    "*3DViewer*", "*BingWeather*", "*Camera*", "*CommunicationsApps*", "*FeedbackHub*",
    "*GetHelp*", "*Getstarted*", "*MicrosoftOfficeHub*", "*MicrosoftSolitaireCollection*",
    "*MixedReality*", "*Office.OneNote*", "*People*", "*SkypeApp*", "*Todos*", "*Wallet*",
    "*ZuneMusic*", "*ZuneVideo*", "*LinkedIn*"
)
foreach ($pkgName in $bloatList) {
    $pkgs = Get-AppxPackage -Name $pkgName
    if ($pkgs) { Remove-AppxPackage -InputObject $pkgs }
}

$layoutPath = Join-Path $env:LOCALAPPDATA "LayoutModification.xml"
$layoutXml  = '<?xml version="1.0" encoding="utf-8"?>'
$layoutXml += '<LayoutModificationTemplate Version="1"'
$layoutXml += ' xmlns="http://schemas.microsoft.com/Start/2014/LayoutModification"'
$layoutXml += ' xmlns:defaultlayout="http://schemas.microsoft.com/Start/2014/FullDefaultLayout"'
$layoutXml += ' xmlns:start="http://schemas.microsoft.com/Start/2014/StartLayout"'
$layoutXml += ' xmlns:taskbar="http://schemas.microsoft.com/Start/2014/TaskbarLayout">'
$layoutXml += '<LayoutOptions StartTileGroupCellWidth="6"/>'
$layoutXml += '<DefaultLayoutOverride><StartLayoutCollection>'
$layoutXml += '<defaultlayout:StartLayout GroupCellWidth="6" /></StartLayoutCollection></DefaultLayoutOverride>'
$layoutXml += '<CustomTaskbarLayoutCollection PinListPlacement="Replace">'
$layoutXml += '<defaultlayout:TaskbarLayout><taskbar:TaskbarPinList>'
$layoutXml += '<taskbar:DesktopApp DesktopApplicationID="Chrome" />'
$layoutXml += '<taskbar:UWA AppUserModelID="windows.immersivecontrolpanel_cw5n1h2txyewy!microsoft.windows.immersivecontrolpanel" />'
$layoutXml += '</taskbar:TaskbarPinList></defaultlayout:TaskbarLayout></CustomTaskbarLayoutCollection>'
$layoutXml += '</LayoutModificationTemplate>'
Set-Content -Path $layoutPath -Value $layoutXml -Encoding UTF8 -Force
Import-StartLayout -LayoutPath $layoutPath -MountPath ($env:SystemDrive + "\")

$pinnedDir = Join-Path $env:APPDATA "Microsoft\Internet Explorer\Quick Launch\User Pinned\TaskBar\*"
Remove-Item -Path $pinnedDir -Force
Remove-Item -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Taskband" -Recurse -Force

$polExp = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Explorer"
Set-RegKey -RegPath $polExp -RegName "StartLayoutFile"   -RegVal $layoutPath -RegType "String"
Set-RegKey -RegPath $polExp -RegName "LockedStartLayout" -RegVal 1

Set-RegKey -RegPath "HKCU:\Control Panel\Colors"  -RegName "Background" -RegVal "0 0 0" -RegType "String"
Set-RegKey -RegPath "HKCU:\Control Panel\Desktop" -RegName "Wallpaper"  -RegVal ""      -RegType "String"

$win32Api = @"
using System;
using System.Runtime.InteropServices;
public class PInvoke {
    [DllImport("user32.dll", CharSet = CharSet.Auto)]
    public static extern int SystemParametersInfo(int uAction, int uParam, string lpvParam, int fuWinIni);
    [DllImport("user32.dll")]
    public static extern bool SetSysColors(int cElements, int[] lpaElements, uint[] lpaRgbValues);
}
"@
Add-Type -TypeDefinition $win32Api
$null = [PInvoke]::SystemParametersInfo(20, 0, '', 3)
$null = [PInvoke]::SetSysColors(1, @(1), @([uint32]0))

# ============================================================================
# [5/8] KHOI DONG LAI EXPLORER + KICH HOAT CAN GIUA TASKBAR
# ============================================================================
Write-Host "[5/8] Khoi dong lai Windows Explorer..." -ForegroundColor Cyan
Start-Process "explorer.exe"
Start-Sleep -Seconds 3
Remove-ItemProperty -Path $polExp -Name "LockedStartLayout" -Force
Remove-ItemProperty -Path $polExp -Name "StartLayoutFile"   -Force

$tbxPath = Join-Path $ScriptDir "TaskbarX\TaskbarX.exe"
if (Test-Path $tbxPath) {
    Start-Process $tbxPath -ArgumentList "-tbs=0 -c=1"
}

# ============================================================================
# [6/8] CAI DAT CON TRO CHUOT
# ============================================================================
Write-Host "[6/8] Cai dat bo con tro chuot..." -ForegroundColor Cyan
$cursorList = @(
    (Join-Path $ScriptDir "Cursors\Install.inf"),
    (Join-Path $ScriptDir "Mr v5 Cursors\Mr v5 MegaPack\Install.inf"),
    "C:\Users\Administrator\Downloads\Setup\Cursors\Install.inf"
)
foreach ($curInf in $cursorList) {
    if (Test-Path $curInf) {
        Push-Location (Split-Path $curInf -Parent)
        Start-Process "rundll32.exe" -ArgumentList "advpack.dll,LaunchINFSection Install.inf,DefaultInstall" -Wait
        Pop-Location
        break
    }
}

# ============================================================================
# [7/8] CHAY CAC UNG DUNG THEO LUA CHON (GAMING HOAC OFFICE)
# ============================================================================
Write-Host "[7/8] Dang khoi chay cac ung dung..." -ForegroundColor Cyan
foreach ($fName in $TargetAppFolders) {
    $searchDirs = @(
        (Join-Path $ScriptDir "Apps\$fName"),
        "C:\Users\Administrator\Downloads\Setup\Apps\$fName"
    )
    foreach ($currDir in $searchDirs) {
        if (Test-Path $currDir) {
            Get-ChildItem -Path $currDir -Filter "*.exe" -Recurse -File | ForEach-Object {
                Write-Host " -> Dang mo: " -NoNewline -ForegroundColor Green
                Write-Host $_.Name -ForegroundColor White
                Start-Process -FilePath $_.FullName -WorkingDirectory $_.DirectoryName
            }
            break
        }
    }
}

# ============================================================================
# [8/8] MO BANG CHON CHUOT + CHROME
# ============================================================================
Write-Host "[8/8] Hoan tat! Dang mo Mouse Properties va Google Chrome..." -ForegroundColor Cyan
Start-Process "control.exe" -ArgumentList "main.cpl,,1"
Start-Process "chrome.exe"  -ArgumentList "--disable-background-networking --disable-component-update --disable-default-apps --no-default-browser-check --no-first-run"

# ============================================================================
# DONE
# ============================================================================
Write-Banner "SETUP HOAN TAT / ALL DONE" "Green"
Write-Host "  Temp files: $TempDir" -ForegroundColor DarkGray
Write-Host ""
Write-Host "  Nhan phim bat ky de thoat / Press any key to exit..." -ForegroundColor Gray
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
