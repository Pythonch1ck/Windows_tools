# Setup User Profiles Script
# Requires Administrator privileges

param(
    [string]$NewAdminPassword = "123456@gl"
)

Write-Host "Starting user profile configuration..." -ForegroundColor Green

# Check for Administrator privileges
$currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
if (-not $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "This script must be run as Administrator!" -ForegroundColor Red
    Write-Host "Please right-click on PowerShell and select 'Run as administrator'" -ForegroundColor Yellow
    exit 1
}

try {
    # 1. Demote School user to standard user
    Write-Host "Demoting School user to standard user..." -ForegroundColor Yellow
    $schoolUser = Get-LocalUser -Name "School" -ErrorAction SilentlyContinue
    if ($schoolUser) {
        Remove-LocalGroupMember -Group "Administrators" -Member "School" -ErrorAction SilentlyContinue
        Write-Host "School user demoted to standard user" -ForegroundColor Green
    } else {
        Write-Host "School user not found" -ForegroundColor Yellow
    }

    # 2. Create new admin user InTech_Admin
    Write-Host "Creating new admin user InTech_Admin..." -ForegroundColor Yellow
    $adminUser = Get-LocalUser -Name "InTech_Admin" -ErrorAction SilentlyContinue
    if (-not $adminUser) {
        $securePassword = ConvertTo-SecureString $NewAdminPassword -AsPlainText -Force
        New-LocalUser -Name "InTech_Admin" -Password $securePassword -AccountNeverExpires -PasswordNeverExpires -Description "Administrator account for InTech system"
        Add-LocalGroupMember -Group "Administrators" -Member "InTech_Admin"
        Write-Host "Admin user InTech_Admin created" -ForegroundColor Green
    } else {
        Write-Host "Admin user InTech_Admin already exists" -ForegroundColor Yellow
    }

    # 3. Restrict desktop editing for School user
    Write-Host "Configuring desktop restrictions for School user..." -ForegroundColor Yellow
    if ($schoolUser) {
        # Method 1: Registry modifications
        $schoolProfilePath = "C:\Users\School\NTUSER.DAT"
        if (Test-Path $schoolProfilePath) {
            try {
                # Load School user registry hive
                Start-Process -FilePath "reg" -ArgumentList "load", "HKU\School_Temp", $schoolProfilePath -Wait -WindowStyle Hidden
                
                # Disable saving desktop settings
                Start-Process -FilePath "reg" -ArgumentList "add", "HKEY_USERS\School_Temp\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer", "/v", "NoSaveSettings", "/t", "REG_DWORD", "/d", "1", "/f" -Wait -WindowStyle Hidden
                
                # Disable wallpaper changes
                Start-Process -FilePath "reg" -ArgumentList "add", "HKEY_USERS\School_Temp\Software\Microsoft\Windows\CurrentVersion\Policies\ActiveDesktop", "/v", "NoChangingWallpaper", "/t", "REG_DWORD", "/d", "1", "/f" -Wait -WindowStyle Hidden
                
                # Unload registry hive
                Start-Process -FilePath "reg" -ArgumentList "unload", "HKU\School_Temp" -Wait -WindowStyle Hidden
                
                Write-Host "Desktop restrictions applied to School user" -ForegroundColor Green
            }
            catch {
                Write-Host "Could not apply registry restrictions: $($_.Exception.Message)" -ForegroundColor Red
            }
        } else {
            Write-Host "School user profile not found for registry modifications" -ForegroundColor Yellow
        }
    }

    # 4. Additional security settings
    Write-Host "Applying additional security settings..." -ForegroundColor Yellow
    
    # Disable School user ability to change password
    if ($schoolUser) {
        Set-LocalUser -Name "School" -UserMayChangePassword $false
    }
    
    # Ensure admin user cannot change password
    Set-LocalUser -Name "InTech_Admin" -UserMayChangePassword $false

    Write-Host "All configurations completed successfully!" -ForegroundColor Green
    Write-Host ""
    Write-Host "Summary:" -ForegroundColor Cyan
    Write-Host "- School user: Standard user with restricted desktop" -ForegroundColor White
    Write-Host "- InTech_Admin: Administrator (Password: $NewAdminPassword)" -ForegroundColor White
    Write-Host ""
    Write-Host "Note: Some changes may require logout/login to take effect." -ForegroundColor Yellow
}
catch {
    Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}
