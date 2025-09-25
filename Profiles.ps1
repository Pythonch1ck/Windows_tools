$adminPass = ConvertTo-SecureString "123456@gl" -AsPlainText -Force
New-LocalUser "InTech_Admin" -Password $adminPass

$userPass = ConvertTo-SecureString "7654321" -AsPlainText -Force
New-LocalUser "InTech" -Password $userPass

function Get-GroupNameBySID {
    param([string]$SID)
    (New-Object System.Security.Principal.SecurityIdentifier($SID)).Translate([System.Security.Principal.NTAccount]).Value.Split('\')[1]
}

$AdminsGroup = Get-GroupNameBySID "S-1-5-32-544"
$UsersGroup  = Get-GroupNameBySID "S-1-5-32-545"

Add-LocalGroupMember -Group $AdminsGroup -Member "InTech_Admin"
Add-LocalGroupMember -Group $UsersGroup -Member "InTech"

$SID = (Get-LocalUser InTech).SID
$regPath = "Registry::HKEY_USERS\$SID\Software\Microsoft\Windows\CurrentVersion\Policies"

New-Item -Path "$regPath\System" -Force | Out-Null
New-ItemProperty -Path "$regPath\System" -Name "NoDispBackgroundPage" -Value 1 -PropertyType DWord -Force
New-ItemProperty -Path "$regPath\System" -Name "NoControlPanel" -Value 1 -PropertyType DWord -Force

New-Item -Path "$regPath\Explorer" -Force | Out-Null
New-ItemProperty -Path "$regPath\Explorer" -Name "NoFileAssociate" -Value 1 -PropertyType DWord -Force
