# Переключаем консоль в UTF-8, чтобы русские символы не превращались в иероглифы
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
chcp 65001 | Out-Null

# Создаём админа
$adminPass = ConvertTo-SecureString "123456@gl" -AsPlainText -Force
New-LocalUser "InTech_Admin" -Password $adminPass
Add-LocalGroupMember -Group "Администраторы" -Member "InTech_Admin"

# Создаём обычного пользователя
$userPass = ConvertTo-SecureString "7654321" -AsPlainText -Force
New-LocalUser "InTech" -Password $userPass
Add-LocalGroupMember -Group "Пользователи" -Member "InTech"

# SID профиля InTech
$SID = (Get-LocalUser InTech).SID
$regPath = "Registry::HKEY_USERS\$SID\Software\Microsoft\Windows\CurrentVersion\Policies"

# Запрет изменения фона рабочего стола
New-Item -Path "$regPath\System" -Force | Out-Null
New-ItemProperty -Path "$regPath\System" -Name "NoDispBackgroundPage" -Value 1 -PropertyType DWord -Force

# Запрет панели управления и параметров
New-ItemProperty -Path "$regPath\System" -Name "NoControlPanel" -Value 1 -PropertyType DWord -Force

# Запрет изменения ассоциаций файлов (ограничение скачивания и установки софта)
New-Item -Path "$regPath\Explorer" -Force | Out-Null
New-ItemProperty -Path "$regPath\Explorer" -Name "NoFileAssociate" -Value 1 -PropertyType DWord -Force
