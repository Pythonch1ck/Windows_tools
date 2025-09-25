[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
chcp 65001 | Out-Null

function Get-GroupNameBySID {
    param([string]$SID)
    (New-Object System.Security.Principal.SecurityIdentifier($SID)).Translate([System.Security.Principal.NTAccount]).Value.Split('\')[1]
}

$AdminsGroup = Get-GroupNameBySID "S-1-5-32-544"
$UsersGroup  = Get-GroupNameBySID "S-1-5-32-545"

# Удаляем старых пользователей InTech и InTech 1
foreach ($u in @("InTech","InTech 1")) {
    if (Get-LocalUser -Name $u -ErrorAction SilentlyContinue) {
        try { Remove-LocalUser -Name $u } catch {}
        $profilePath = "C:\Users\$u"
        if (Test-Path $profilePath) {
            try { Remove-Item -Path $profilePath -Recurse -Force } catch {}
        }
    }
}

# Создаём админа
$adminPass = ConvertTo-SecureString "123456@gl" -AsPlainText -Force
if (-not (Get-LocalUser -Name "InTech_Admin" -ErrorAction SilentlyContinue)) {
    New-LocalUser "InTech_Admin" -Password $adminPass
}
Add-LocalGroupMember -Group $AdminsGroup -Member "InTech_Admin" -ErrorAction SilentlyContinue
try { Remove-LocalGroupMember -Group $UsersGroup -Member "InTech_Admin" -ErrorAction SilentlyContinue } catch {}

# Создаём обычного пользователя InTech 1
$userPass = ConvertTo-SecureString "7654321" -AsPlainText -Force
New-LocalUser "InTech 1" -Password $userPass
Add-LocalGroupMember -Group $UsersGroup -Member "InTech 1" -ErrorAction SilentlyContinue
try { Remove-LocalGroupMember -Group $AdminsGroup -Member "InTech 1" -ErrorAction SilentlyContinue } catch {}

# Получаем SID админа и пользователя
$SID_Admin = (Get-LocalUser "InTech_Admin").SID
$SID_User  = (Get-LocalUser "InTech 1").SID

# Ограничения для InTech 1
$regPath = "Registry::HKEY_USERS\$SID_User\Software\Microsoft\Windows\CurrentVersion\Policies"

New-Item -Path "$regPath\System" -Force | Out-Null
New-ItemProperty -Path "$regPath\System" -Name "NoDispBackgroundPage" -Value 1 -PropertyType DWord -Force
New-ItemProperty -Path "$regPath\System" -Name "NoControlPanel" -Value 1 -PropertyType DWord -Force

New-Item -Path "$regPath\Explorer" -Force | Out-Null
New-ItemProperty -Path "$regPath\Explorer" -Name "NoFileAssociate" -Value 1 -PropertyType DWord -Force
