@echo off
:: === Создание пользователей InTech_Admin и InTech + ограничения для InTech ===
chcp 65001 >nul

set ADMINUSER=InTech_Admin
set ADMINPASS=123456@gl

set STDUSER=InTech
set STDPASS=7654321

echo --- Создание администратора %ADMINUSER% ---
net user %ADMINUSER% %ADMINPASS% /add
net localgroup Administrators %ADMINUSER% /add

echo --- Создание обычного пользователя %STDUSER% ---
net user %STDUSER% %STDPASS% /add
net localgroup Administrators %STDUSER% /delete

:: --- Поиск SID пользователя InTech ---
for /f "tokens=2 delims==" %%S in ('wmic useraccount where name^="%STDUSER%" get sid /value ^| findstr "SID"') do (
    set USERSID=%%S
)

if not defined USERSID (
    echo.
    echo ВНИМАНИЕ: SID для %STDUSER% пока не найден.
    echo Это значит, что пользователь ещё не заходил в систему.
    echo 1. Войдите один раз под %STDUSER%.
    echo 2. Выйдите и снова запустите этот скрипт.
    echo.
    goto :end
)

echo Найден SID %USERSID% для %STDUSER%

:: --- Ограничения в реестре ---
echo Запрет правого клика, смены обоев и персонализации...
reg add "HKU\%USERSID%\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer" /v NoViewContextMenu /t REG_DWORD /d 1 /f
reg add "HKU\%USERSID%\Software\Microsoft\Windows\CurrentVersion\Policies\ActiveDesktop" /v NoChangingWallPaper /t REG_DWORD /d 1 /f
reg add "HKU\%USERSID%\Software\Microsoft\Windows\CurrentVersion\Policies\System" /v NoDispAppearancePage /t REG_DWORD /d 1 /f
reg add "HKU\%USERSID%\Software\Microsoft\Windows\CurrentVersion\Policies\System" /v NoDispBackgroundPage /t REG_DWORD /d 1 /f
reg add "HKU\%USERSID%\Software\Microsoft\Windows\CurrentVersion\Policies\System" /v NoDispScrSavPage /t REG_DWORD /d 1 /f
reg add "HKU\%USERSID%\Software\Microsoft\Windows\CurrentVersion\Policies\System" /v NoDispCPL /t REG_DWORD /d 1 /f

:: --- Запрет на сохранение файлов на рабочем столе ---
set DESKPATH=C:\Users\%STDUSER%\Desktop
if exist "%DESKPATH%" (
    echo Запрещаем сохранение файлов на рабочем столе %DESKPATH% ...
    icacls "%DESKPATH%" /inheritance:r >nul
    icacls "%DESKPATH%" /remove:g %STDUSER% >nul
    icacls "%DESKPATH%" /grant:r %STDUSER%:(RX) >nul
    echo Права изменены: %STDUSER% может только читать, но не сохранять файлы на рабочем столе.
) else (
    echo Папка %DESKPATH% ещё не создана. Ограничения нужно применить после первого входа InTech.
)

:end
echo.
echo === ГОТОВО ===
echo Админ: %ADMINUSER% (пароль %ADMINPASS%)
echo Пользователь: %STDUSER% (пароль %STDPASS%)
echo.
pause
