[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
chcp 65001 | Out-Null

function Get-GroupNameBySID {
    param([string]$SID)
    (New-Object System.Security.Principal.SecurityIdentifier($SID)).Translate([System.Security.Principal.NTAccount]).Value.Split('\')[1]
}

$AdminsGroup = Get-GroupNameBySID "S-1-5-32-544"
$UsersGroup  = Get-GroupNameBySID "S-1-5-32-545"

# Ask user for profile number (English)
$number = Read-Host "Enter profile number (example: 1, 2, 3...)"
$userName = "InTech $number"

# Remove old InTech and chosen InTech N
foreach ($u in @("InTech",$userName)) {
    if (Get-LocalUser -Name $u -ErrorAction SilentlyContinue) {
        try { Remove-LocalUser -Name $u } catch {}
        $profilePath = "C:\Users\$u"
        if (Test-Path $profilePath) {
            try { Remove-Item -Path $profilePath -Recurse -Force } catch {}
        }
    }
}

# Create admin
$adminPass = ConvertTo-SecureString "123456@gl" -AsPlainText -Force
if (-not (Get-LocalUser -Name "InTech_Admin" -ErrorAction SilentlyContinue)) {
    New-LocalUser "InTech_Admin" -Password $adminPass
}
Add-LocalGroupMember -Group $AdminsGroup -Member "InTech_Admin" -ErrorAction SilentlyContinue
try { Remove-LocalGroupMember -Group $UsersGroup -Member "InTech_Admin" -ErrorAction SilentlyContinue } catch {}

# Create normal user InTech N
$userPass = ConvertTo-SecureString "7654321" -AsPlainText -Force
New-LocalUser $userName -Password $userPass
Add-LocalGroupMember -Group $UsersGroup -Member $userName -ErrorAction SilentlyContinue
try { Remove-LocalGroupMember -Group $AdminsGroup -Member $userName -ErrorAction SilentlyContinue } catch {}

# SID of new user
$SID_User  = (Get-LocalUser $userName).SID

# Restrictions
$regPath = "Registry::HKEY_USERS\$SID_User\Software\Microsoft\Windows\CurrentVersion\Policies"

New-Item -Path "$regPath\System" -Force | Out-Null
New-ItemProperty -Path "$regPath\System" -Name "NoDispBackgroundPage" -Value 1 -PropertyType DWord -Force
New-ItemProperty -Path "$regPath\System" -Name "NoControlPanel" -Value 1 -PropertyType DWord -Force

New-Item -Path "$regPath\Explorer" -Force | Out-Null
New-ItemProperty -Path "$regPath\Explorer" -Name "NoFileAssociate" -Value 1 -PropertyType DWord -Force

# ======= WALLPAPER SETUP =======

# Script URL (replace with real repo URL)
$scriptUrl = "https://raw.githubusercontent.com/YourGitHubUser/YourRepo/main/setup.ps1"
$wallpaperUrl = ($scriptUrl -replace "setup.ps1","wallpaper.jpg")

$wallpaperPath = "C:\Users\Public\Pictures\InTech_Wallpaper.jpg"
Invoke-WebRequest -Uri $wallpaperUrl -OutFile $wallpaperPath -UseBasicParsing

reg add "HKU\$SID_User\Control Panel\Desktop" /v Wallpaper /t REG_SZ /d $wallpaperPath /f | Out-Null
rundll32.exe user32.dll, UpdatePerUserSystemParameters
