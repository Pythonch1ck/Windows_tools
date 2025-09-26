# Укажи путь к файлу обоев
$WallpaperPath = "C:\Windows\System32\Windows_tools\wallpaper.png"

# Проверяем, существует ли файл
if (-Not (Test-Path $WallpaperPath)) {
    Write-Error "Файл не найден: $WallpaperPath"
    exit 1
}

# Подключаем API Windows для изменения обоев
Add-Type @"
using System.Runtime.InteropServices;

public class Wallpaper {
    [DllImport("user32.dll", SetLastError = true)]
    public static extern bool SystemParametersInfo(int uAction, int uParam, string lpvParam, int fuWinIni);
}
"@

# Константы
$SPI_SETDESKWALLPAPER = 0x0014
$SPIF_UPDATEINIFILE   = 0x01
$SPIF_SENDWININICHANGE = 0x02

# Устанавливаем обои
$result = [Wallpaper]::SystemParametersInfo($SPI_SETDESKWALLPAPER, 0, $WallpaperPath, $SPIF_UPDATEINIFILE -bor $SPIF_SENDWININICHANGE)

if ($result) {
    Write-Output "Обои успешно установлены: $WallpaperPath"
} else {
    Write-Error "Не удалось установить обои."
}
