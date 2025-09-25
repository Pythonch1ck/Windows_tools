$adminPass = ConvertTo-SecureString "123456@gl" -AsPlainText -Force
New-LocalUser "InTech_Admin" -Password $adminPass
Add-LocalGroupMember -Group "S-1-5-32-544" -Member "InTech_Admin"

$userPass = ConvertTo-SecureString "7654321" -AsPlainText -Force
New-LocalUser "InTech" -Password $userPass
Add-LocalGroupMember -Group "S-1-5-32-545" -Member "InTech"

$SID = (Get-LocalUser InTech).SID
$regPath = "Registry::HKEY_USERS\$SID\Software\Microsoft\Windows\CurrentVersion\Policies"

New-Item -Path "$regPath\System" -Force | Out-Null
New-ItemProperty -Path "$regPath\System" -Name "NoDispBackgroundPage" -Value 1 -PropertyType DWord -Force
New-ItemProperty -Path "$regPath\System" -Name "NoControlPanel" -Value 1 -PropertyType DWord -Force

New-Item -Path "$regPath\Explorer" -Force | Out-Null
New-ItemProperty -Path "$regPath\Explorer" -Name "NoFileAssociate" -Value 1 -PropertyType DWord -Force
