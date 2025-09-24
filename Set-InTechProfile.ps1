# Setup User Profiles Script
# Requires Administrator privileges

param(
    [string]$NewAdminPassword = "123456@gl"
)

Write-Host "Starting user profile configuration..." -ForegroundColor Green

# Проверка прав администратора
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "This script must be run as Administrator!" -ForegroundColor Red
    exit 1
}

try {
    # 1. Demote School user to standard user
    Write-Host "Demoting School user to standard user..." -ForegroundColor Yellow
    $schoolUser = Get-LocalUser -Name "School" -ErrorAction SilentlyContinue
    if ($schoolUser) {
        Remove-LocalGroupMember -Group "Administrators" -Member "School" -ErrorAction SilentlyContinue
        Write-Host "✓ School user demoted to standard user" -ForegroundColor Green
    } else {
        Write-Host "! School user not found" -ForegroundColor Yellow
    }

    # 2. Create new admin user InTech_Admin
    Write-Host "Creating new admin user InTech_Admin..." -ForegroundColor Yellow
    $adminUser = Get-LocalUser -Name "InTech_Admin" -ErrorAction SilentlyContinue
    if (-not $adminUser) {
        $securePassword = ConvertTo-SecureString $NewAdminPassword -AsPlainText -Force
        New-LocalUser -Name "InTech_Admin" -Password $securePassword -AccountNeverExpires -PasswordNeverExpires -Description "Administrator account for InTech system"
        Add-LocalGroupMember -Group "Administrators" -Member "InTech_Admin"
        Write-Host "✓ Admin user InTech_Admin created" -ForegroundColor Green
    } else {
        Write-Host "! Admin user InTech_Admin already exists" -ForegroundColor Yellow
    }

    # 3. Restrict desktop editing for School user
    Write-Host "Configuring desktop restrictions for School user..." -ForegroundColor Yellow
    if ($schoolUser) {
        # Method 1: Registry modifications
        $schoolProfilePath = "C:\Users\School\NTUSER.DAT"
        if (Test-Path $schoolProfilePath) {
            try {
                # Load School user registry hive
                reg load "HKU\School_Temp" $schoolProfilePath 2>$null
                
                # Disable saving desktop settings
                reg add "HKEY_USERS\School_Temp\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer" /v NoSaveSettings /t REG_DWORD /d 1 /f 2>$null
                
                # Disable wallpaper changes
                reg add "HKEY_USERS\School_Temp\Software\Microsoft\Windows\CurrentVersion\Policies\ActiveDesktop" /v NoChangingWallpaper /t REG_DWORD /d 1 /f 2>$null
                
                # Disable desktop context menu
                reg add "HKEY_USERS\School_Temp\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer" /v NoViewContextMenu /t REG_DWORD /d 1 /f 2>$null
                
                # Unload registry hive
                reg unload "HKU\School_Temp" 2>$null
                
                Write-Host "✓ Desktop restrictions applied to School user" -ForegroundColor Green
            }
            catch {
                Write-Host "! Could not apply registry restrictions: $($_.Exception.Message)" -ForegroundColor Red
            }
        } else {
            Write-Host "! School user profile not found for registry modifications" -ForegroundColor Yellow
        }

        # Method 2: File system permissions (optional)
        $desktopPath = "C:\Users\School\Desktop"
        if (Test-Path $desktopPath) {
            try {
                $acl = Get-Acl $desktopPath
                $rule = New-Object System.Security.AccessControl.FileSystemAccessRule("School", "Write", "ContainerInherit,ObjectInherit", "None", "Deny")
                $acl.AddAccessRule($rule)
                Set-Acl $desktopPath $acl
                Write-Host "✓ Desktop folder write permissions restricted" -ForegroundColor Green
            }
            catch {
                Write-Host "! Could not set folder permissions: $($_.Exception.Message)" -ForegroundColor Yellow
            }
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

    Write-Host "✓ All configurations completed successfully!" -ForegroundColor Green
    Write-Host "`nSummary:" -ForegroundColor Cyan
    Write-Host "- School user: Standard user with restricted desktop" -ForegroundColor White
    Write-Host "- InTech_Admin: Administrator (Password: $NewAdminPassword)" -ForegroundColor White
    Write-Host "`nNote: Some changes may require logout/login to take effect." -ForegroundColor Yellow
}
catch {
    Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}
