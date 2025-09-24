# Запуск от администратора обязателен
If (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)) {
    Write-Error "Запустите этот скрипт от имени администратора."
    exit 1
}

# Список системных учёток, которых не трогаем
$skip = @('Administrator','Guest','DefaultAccount','WDAGUtilityAccount','S-1-5-18')

# Получаем первого пользователя (в порядке Get-LocalUser), кроме системных и отключённых
$first = Get-LocalUser | Where-Object { $_.Enabled -eq $true -and -not ($skip -contains $_.Name) } | Select-Object -First 1

if (-not $first) {
    Write-Error "Не найдено подходящих локальных пользователей."
    exit 1
}

Write-Output "Выбран для переименования: '$($first.Name)' (SID: $($first.SID))"

# Целевые имена и пароли
$targetAdminBase = "InTech_Admin"
$adminPasswordPlain = "123456@gl"

$targetUserBase = "InTech"
$userPasswordPlain = "7654321"

# Функция: получить свободное имя (если уже занято — добавить метку времени)
function Get-FreeName($baseName) {
    if (-not (Get-LocalUser -Name $baseName -ErrorAction SilentlyContinue)) { return $baseName }
    $stamp = (Get-Date).ToString("yyyyMMddHHmmss")
    return "${baseName}_$stamp"
}

$targetAdmin = Get-FreeName $targetAdminBase
$targetUser  = Get-FreeName $targetUserBase

# Переименовать первого пользователя в $targetAdmin
try {
    Rename-LocalUser -Name $first.Name -NewName $targetAdmin -ErrorAction Stop
    Write-Output "Пользователь '$($first.Name)' переименован в '$targetAdmin'."
} catch {
    Write-Error "Ошибка при переименовании: $_"
    exit 1
}

# Задать пароль для InTech_Admin (используем net user для совместимости)
try {
    net user $targetAdmin $adminPasswordPlain | Out-Null
    Write-Output "Пароль для '$targetAdmin' установлен."
} catch {
    Write-Warning "Не удалось установить пароль через net user: $_"
}

# Добавить в группу Администраторов
try {
    Add-LocalGroupMember -Group "Administrators" -Member $targetAdmin -ErrorAction Stop
    Write-Output "Пользователь '$targetAdmin' добавлен в группу Administrators."
} catch {
    Write-Warning "Не удалось добавить '$targetAdmin' в Administrators или он уже там: $_"
}

# Создать нового пользователя InTech (если ещё не существует)
try {
    if (-not (Get-LocalUser -Name $targetUser -ErrorAction SilentlyContinue)) {
        # Создаём учётку и задаём пароль через net user (удобно)
        net user $targetUser $userPasswordPlain /add /Y | Out-Null
        Write-Output "Создан пользователь '$targetUser' (пароль: $userPasswordPlain)."
        # Убедимся в наличии записи в локальных пользователях (иногда задержка)
        Start-Sleep -Seconds 1
    } else {
        Write-Output "Пользователь '$targetUser' уже существует — пропускаю создание."
    }
} catch {
    Write-Error "Ошибка при создании пользователя '$targetUser': $_"
}

# Убедиться, что новый пользователь НЕ в Administrators
try {
    if (Get-LocalGroupMember -Group "Administrators" -Member $targetUser -ErrorAction SilentlyContinue) {
        Remove-LocalGroupMember -Group "Administrators" -Member $targetUser -ErrorAction Stop
        Write-Output "Пользователь '$targetUser' удалён из Administrators (сделан обычным)."
    } else {
        Write-Output "Пользователь '$targetUser' не состоит в Administrators."
    }
} catch {
    Write-Warning "Ошибка при корректировке групп '$targetUser': $_"
}

Write-Output "Готово."
Write-Output "Проверьте: Get-LocalUser, Get-LocalGroupMember -Group Administrators."

# Напоминание о папках профилей
Write-Warning "Внимание: команда переименовала только логин. Папка профиля в C:\Users\<старое_имя> НЕ будет автоматически переименована. Если нужно переименовать профиль (ProfileImagePath, NTUSER.DAT и т.д.) — это отдельная рискованная операция; скажите — дам безопасную инструкцию."
