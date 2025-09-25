# AutoInstall_All.ps1
# Запускать как администратор

# Проверка: админ ли
If (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Error "Запустите скрипт от имени администратора."
    exit 1
}

$ErrorActionPreference = "Stop"
$TMP = "$env:TEMP\AutoInstall"
New-Item -Path $TMP -ItemType Directory -Force | Out-Null

# Обновляем winget
winget source update

# --- Установка пакетов через winget ---
$wingetList = @(
    "Google.Chrome",
    "Python.Python.3.12",
    "TeamViewer.TeamViewer",
    "BlenderFoundation.Blender",
    "Ultimaker.Cura",
    "Microsoft.VisualStudio.2022.Community",
    "7zip.7zip",
    "FreePascalTeam.FreePascal",
    "Bambulab.Bambustudio",
    "SoftFever.OrcaSlicer"
)

foreach ($id in $wingetList) {
    Write-Output "Устанавливаю $id ..."
    try {
        winget install -e --id $id --accept-package-agreements --accept-source-agreements -h
    } catch {
        Write-Warning "Не удалось установить $id"
    }
}

# --- Thymio Suite ---
$thymioUrl = "https://www.thymio.org/wp-content/uploads/2022/11/ThymioSuite-2.3.1-Windows-x86_64.msi"
$thymioInstaller = Join-Path $TMP "ThymioSuite.msi"
Invoke-WebRequest -Uri $thymioUrl -OutFile $thymioInstaller -UseBasicParsing
Start-Process "msiexec.exe" -ArgumentList "/i `"$thymioInstaller`" /quiet /norestart" -Wait

# --- Marty the Robot ---
$martyUrl = "https://downloads.robotical.io/MartyV2/Windows/MartyV2-1.7.3.exe"
$martyInstaller = Join-Path $TMP "MartySetup.exe"
Invoke-WebRequest -Uri $martyUrl -OutFile $martyInstaller -UseBasicParsing
Start-Process $martyInstaller -ArgumentList "/S" -Wait

# --- LEGO WeDo 2.0 ---
$wedoUrl = "https://lc-www-live-s.legocdn.com/downloads/WEDO2/LEGOEducationWeDo2.msi"
$wedoInstaller = Join-Path $TMP "WeDo.msi"
Invoke-WebRequest -Uri $wedoUrl -OutFile $wedoInstaller -UseBasicParsing
Start-Process "msiexec.exe" -ArgumentList "/i `"$wedoInstaller`" /quiet /norestart" -Wait

# --- LEGO Mindstorms EV3 ---
$ev3Url = "https://lc-www-live-s.legocdn.com/downloads/EV3/LEGOEducationEV3.msi"
$ev3Installer = Join-Path $TMP "EV3.msi"
Invoke-WebRequest -Uri $ev3Url -OutFile $ev3Installer -UseBasicParsing
Start-Process "msiexec.exe" -ArgumentList "/i `"$ev3Installer`" /quiet /norestart" -Wait

# --- Office Deployment Tool ---
$odtUrl = "https://download.microsoft.com/download/2/0/c/20c4e030-1b7b-4a0b-a49c-4c3e7a5db9cb/officedeploymenttool_16827-20258.exe"
$odtExe = Join-Path $TMP "officedeploymenttool.exe"
Invoke-WebRequest -Uri $odtUrl -OutFile $odtExe -UseBasicParsing
