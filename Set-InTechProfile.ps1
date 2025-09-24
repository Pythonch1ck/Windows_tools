# Set-InTechProfile.ps1
# Назначение: создать локального админа InTech_Admin, сделать InTech обычным пользователем,
# и запретить запись в C:\Users\InTech\Desktop
# Запускать от администратора.

$logFile = "C:\Windows\Temp\Set-InTechProfile.log"
function Log {
    param($msg)
    $t = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    $line = "$t `t $msg"
    $line | Out-File -FilePath $logFile -Encoding UTF8 -Append
    Write-Output $line
}

Try {
    Log "=== START ==="

    # 1) Создание локальной учётной записи InTech_Admin
    $adminName = "InTech_Admin"
    $adminPassPlain = "123456@gl"
    $securePass = ConvertTo-SecureString $adminPassPlain -AsPlainText -Force

    $exists = Get-LocalUser -Name $adminName -ErrorAction SilentlyContinue
    if (-not $exists) {
        New-LocalUser -Name $adminName -Password $securePass -FullName "InTech Admin" `
            -Description "Локальная админ-учётка" -PasswordNeverExpires:$true -UserMayNotChangePassword:$false
        Add-LocalGroupMember -Group "Administrators" -Member $adminName
        Log "Создана учётка $adminName и добавлена в Administrators."
    } else {
        Log "Учётка $adminName уже существует."
        # Убедимся, что в группе Administrators
        $isAdmin = (Get-LocalGroupMember -Group "Administrators" -ErrorAction SilentlyContinue | Where-Object Name -eq $adminName)
        if (-not $isAdmin) {
            Add-LocalGroupMember -Group "Administrators" -Member $adminName
            Log "Добавил $adminName в группу Administrators."
        } else {
            Log "$adminName уже в Administrators."
        }
    }

    # 2) Сделать InTech обычным пользователем: удалить из Administrators, если есть
    $userName = "InTech"
    $user = Get-LocalUser -Name $userName -ErrorAction SilentlyContinue
    if ($user) {
        $member = Get-LocalGroupMember -Group "Administrators" -ErrorAction SilentlyContinue | Where-Object { $_.Name -eq $userName }
        if ($member) {
            Remove-LocalGroupMember -Group "Administrators" -Member $userName -ErrorAction Stop
            Log "Пользователь $userName удалён из Administrators (теперь обычный пользователь)."
        } else {
            Log "Пользователь $userName не состоит в группе Administrators."
        }
    } else {
        Log "Пользователь $userName не найден на этой машине."
    }

    # 3) Запрет редактирования рабочего стола для InTech (NTFS)
    $desktopPath = "C:\Users\$userName\Desktop"
    if (Test-Path $desktopPath) {
        # Снимем наследование, сохранив текущие разрешения (опция: отключаем и копируем)
        try {
            icacls $desktopPath /inheritance:r | Out-Null
            icacls $desktopPath /grant "Administrators:(OI)(CI)F" "SYSTEM:(OI)(CI)F" "Users:(OI)(CI)RX" | Out-Null
            icacls $desktopPath /deny "$userName:(OI)(CI)W" | Out-Null
            Log "Изменены NTFS-разрешения на $desktopPath: запись запрещена для $userName."
        } catch {
            Log "Ошибка при изменении NTFS-разрешений: $_"
        }
    } else {
        Log "Путь $desktopPath не найден. Возможно профиль называется иначе или ещё не создан."
    }

    Log "=== FINISH ==="
} Catch {
    Log "Unhandled error: $_"
    throw
}
