# AutoInstall.ps1
# Запускать как администратор

If (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(
    [Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Error "Запустите скрипт от имени администратора."
    exit 1
}

$ErrorActionPreference = "Stop"
$TMP = "$env:TEMP\AutoInstall"
New-Item -Path $TMP -ItemType Directory -Force | Out-Null

winget source update

# --- Установка пакетов через winget ---
$wingetList = @(
    "Google.Chrome",
    "Python.Python.3.12",
    "TeamViewer.TeamViewer",
    "BlenderFoundation.Blender",
    "Ultimaker.Cura",
    "Microsoft.VisualStudio.2022.Community",
    "Microsoft.VisualStudioCode",
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

# --- Программы из GitHub ---
# Укажи свою директорию на GitHub, например: https://github.com/YourUser/Windows_tools/raw/main/
$ghBase = "https://github.com/Pythonch1ck/Windows_tools/raw/main/"

$programs = @(
    @{ Name="Thymio Suite"; File="ThymioSuite.exe"; Args="/S" },
    @{ Name="LEGO Mindstorms EV3"; File="EV3.exe"; Args="/S" }
)

foreach ($p in $programs) {
    $url = "$ghBase$($p.File)"
    $dest = Join-Path $TMP $p.File
    Write-Output "Скачиваю $($p.Name) из $url ..."
    Invoke-WebRequest -Uri $url -OutFile $dest -UseBasicParsing
    Write-Output "Устанавливаю $($p.Name) ..."
    Start-Process $dest -ArgumentList $p.Args -Wait
}

Write-Output "Установка завершена."


