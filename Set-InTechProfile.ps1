# Set-InTechProfile.ps1
# Назначение: создать локального админа InTech_Admin, сделать InTech обычным пользователем,
# и запретить запись в C:\Users\InTech\Desktop
# Запускать от администратора.

$logFile = "C:\Windows\Temp\Set-InTechProfile.log"
function Log {
    param([string]$msg)
    $t = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    $line = "$t`t$msg"
    $line | Out-File -FilePath $logFile -Encoding UTF8 -Append
    Write-Output $line
}

Try {
    Log "=== START ==="

    $adminName = "InTech_Admin"
    $adminPassPlain = "123456@gl"
    $userName = "InTech"
    $desktopPath = "C:\Users\$userName\Desktop"

    # Проверим, доступен ли модуль LocalAccounts (Get-LocalUser и т.п.)
    $hasLocalAccounts = (Get-Command -Name Get-LocalUser -ErrorAction SilentlyContinue) -ne $null

    if ($hasLocalAccounts) {
        Log "Модуль LocalAccounts доступен. Работаем через Get-LocalUser / New-LocalUser."
        # Создать/проверить аккаунт администратора
        $securePass = ConvertTo-SecureString $adminPassPlain -AsPlainText -Force
        $exists = Get-LocalUser -Name $adminName -ErrorAction SilentlyContinue
        if (-not $exists) {
            New-LocalUser -Name $adminName -Password $securePass -FullName "InTech Admin" `
                -Description "Локальная админ-учётка" -PasswordNeverExpires:$true
            Add-LocalGroupMember -Group "Administrators" -Member $adminName
            Log "Создана учётка $adminName и добавлена в Administrators."
        } else {
            Log "Учётка $adminName уже существует."
            # Убедимся, что в группе Administrators
            $isAdmin = Get-LocalGroupMember -Group "Administrators" -ErrorAction SilentlyContinue | Where-Object { $_.Name -eq $adminName }
            if (-not $isAdmin) {
                Add-LocalGroupMember -Group "Administrators" -Member $adminName
                Log "Добавил $adminName в группу Administrators."
            } else {
                Log "$adminName уже в группе Administrators."
            }
        }

        # Сделать InTech обычным пользователем: удалить из Administrators, если там есть
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
    } else {
        Log "Модуль LocalAccounts НЕ доступен. Будем использовать net user / net localgroup (совместимость)."

        # Создать админ-учётку через net user, если её нет
        $checkAdmin = (net user $adminName 2>$null) -ne $null
        if (-not $checkAdmin) {
            net user $adminName $adminPassPlain /add /fullname:"InTech Admin" /passwordreq:yes | Out-Null
            net localgroup Administrators $adminName /add | Out-Null
            Log "Создана учётка $adminName (net user) и добавлена в Administrators."
        } else {
            Log "Учётка $adminName уже существует (net user)."
            # Убедимся, что в группе Administrators
            & net localgroup Administrators | Select-String -Pattern $adminName | Out-Null
            if ($LASTEXITCODE -ne 0) {
                net localgroup Administrators $adminName /add | Out-Null
                Log "Добавил $adminName в группу Administrators (net localgroup)."
            } else {
                Log "$adminName уже в Administrators (net localgroup)."
            }
        }

        # Удаляем InTech из админов, если присутствует
        & net localgroup Administrators | Select-String -Pattern $userName | Out-Null
        if ($LASTEXITCODE -eq 0) {
            net localgroup Administrators $userName /delete | Out-Null
            Log "Пользователь $userName удалён из Administrators (net localgroup)."
        } else {
            Log "Пользователь $userName не состоит в Administrators (net localgroup)."
        }
    }

    # 3) Запрет редактирования рабочего стола для InTech (NTFS)
    if (Test-Path $desktopPath) {
        try {
            # Удаляем наследование, но сохраняем текущие разрешения как копию
            icacls $desktopPath /inheritance:d | Out-Null  # /inheritance:d - convert to explicit (preserve) — совместимее
        } catch {
            # Если команда вернула ошибку, попробуем /inheritance:r как раньше
            icacls $desktopPath /inheritance:r | Out-Null
        }

        # Установим базовые разрешения: Administrators & SYSTEM — полный; Users — чтение/выполнение
        icacls $desktopPath /grant:r "Administrators:(OI)(CI)F" "SYSTEM:(OI)(CI)F" "Users:(OI)(CI)RX" | Out-Null

        # Установим явный запрет на запись для пользователя InTech
        # Проверяем, не установлен ли уже deny
        $acl = (Get-Acl -Path $desktopPath)
        $denyExists = $false
        foreach ($ace in $acl.Access) {
            if ($ace.IdentityReference -like "*\$userName" -and $ace.FileSystemRights.ToString().Contains("Write") -and $ace.AccessControlType -eq "Deny") {
                $denyExists = $true
                break
            }
        }
        if (-not $denyExists) {
            icacls $desktopPath /deny "$userName:(OI)(CI)W" | Out-Null
            Log "Изменены NTFS-разрешения на $desktopPath: запись запрещена для $userName."
        } else {
            Log "Запрет записи для $userName на $desktopPath уже установлен."
        }
    } else {
        Log "Путь $desktopPath не найден. Возможно профиль называется иначе или ещё не создан."
    }

    Log "=== FINISH ==="
} Catch {
    Log "Unhandled error: $_"
    throw
}
