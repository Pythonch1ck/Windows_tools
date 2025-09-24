<#
.SYNOPSIS
    Configures user profiles - demotes School to standard user and creates InTech_Admin account

.DESCRIPTION
    This script:
    - Demotes School user to standard user
    - Creates new admin account InTech_Admin
    - Restricts desktop editing for School user
    - Applies security settings

.PARAMETER NewAdminPassword
    Password for the new InTech_Admin account (default: 123456@gl)

.EXAMPLE
    .\Set-InTechProfile.ps1
    .\Set-InTechProfile.ps1 -NewAdminPassword "MySecurePassword123"

.NOTES
    Requires Administrator privileges
    Some changes may require restart to take effect
#>

param(
    [string]$NewAdminPassword = "123456@gl"
)

# Check Administrator privileges
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]"Administrator")) {
    Write-Error "This script must be run as Administrator! Please run PowerShell as Administrator."
    exit 1
}

Write-Host "=== InTech Profile Configuration ===" -ForegroundColor Cyan
Write-Host "Starting configuration process..." -ForegroundColor Green

try {
    # 1. Process School user
    Write-Host "`n1. Processing School user..." -ForegroundColor Yellow
    $schoolUser = Get-LocalUser -Name "School" -ErrorAction SilentlyContinue
    
    if ($schoolUser) {
        # Remove from Administrators group
        Remove-LocalGroupMember -Group "Administrators" -Member "School" -ErrorAction SilentlyContinue
        Write-Host "   - School user demoted to standard user" -ForegroundColor Green
        
        # Disable password change
        Set-LocalUser -Name "School" -UserMayChangePassword $false
        Write-Host "   - Password change disabled for School user" -ForegroundColor Green
    } else {
        Write-Host "   - School user not found" -ForegroundColor Yellow
    }

    # 2. Create admin user
    Write-Host "`n2. Creating admin account..." -ForegroundColor Yellow
    $adminUser = Get-LocalUser -Name "InTech_Admin" -ErrorAction SilentlyContinue
    
    if ($adminUser) {
        Write-Host "   - InTech_Admin user already exists" -ForegroundColor Yellow
    } else {
        $securePassword = ConvertTo-SecureString $NewAdminPassword -AsPlainText -Force
        New-LocalUser -Name "InTech_Admin" -Password $securePassword -AccountNeverExpires -PasswordNeverExpires -Description "InTech Administrator Account"
        Add-LocalGroupMember -Group "Administrators" -Member "InTech_Admin"
        Write-Host "   - InTech_Admin user created and added to Administrators group" -ForegroundColor Green
    }
    
    # Disable password change for admin
    Set-LocalUser -Name "InTech_Admin" -UserMayChangePassword $false
    Write-Host "   - Password change disabled for InTech_Admin" -ForegroundColor Green

    # 3. Apply desktop restrictions for School user
    Write-Host "`n3. Applying desktop restrictions..." -ForegroundColor Yellow
    if ($schoolUser) {
        $schoolProfilePath = "C:\Users\School\NTUSER.DAT"
        
        if (Test-Path $schoolProfilePath) {
            try {
                # Load registry hive
                Start-Process -FilePath "reg" -ArgumentList "load", "HKU\SchoolProfile", $schoolProfilePath -Wait -WindowStyle Hidden -ErrorAction Stop
                
                # Apply desktop restrictions
                $registryPaths = @(
                    @{Path = "HKEY_USERS\SchoolProfile\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer"; Name = "NoSaveSettings"; Value = 1},
                    @{Path = "HKEY_USERS\SchoolProfile\Software\Microsoft\Windows\CurrentVersion\Policies\ActiveDesktop"; Name = "NoChangingWallpaper"; Value = 1},
                    @{Path = "HKEY_USERS\SchoolProfile\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer"; Name = "NoViewContextMenu"; Value = 1}
                )
                
                foreach ($reg in $registryPaths) {
                    Start-Process -FilePath "reg" -ArgumentList "add", $reg.Path, "/v", $reg.Name, "/t", "REG_DWORD", "/d", $reg.Value, "/f" -Wait -WindowStyle Hidden
                }
                
                # Unload registry hive
                Start-Process -FilePath "reg" -ArgumentList "unload", "HKU\SchoolProfile" -Wait -WindowStyle Hidden
                
                Write-Host "   - Desktop restrictions applied successfully" -ForegroundColor Green
            }
            catch {
                Write-Host "   - Warning: Could not apply registry restrictions. User might be logged in." -ForegroundColor Red
            }
        } else {
            Write-Host "   - School user profile not found for registry modifications" -ForegroundColor Yellow
        }
    }

    # 4. Final summary
    Write-Host "`n=== Configuration Complete ===" -ForegroundColor Cyan
    Write-Host "Summary of changes:" -ForegroundColor White
    Write-Host "- School user: Standard user with restricted desktop" -ForegroundColor White
    Write-Host "- InTech_Admin: Administrator account created" -ForegroundColor White
    Write-Host "- Password for InTech_Admin: $NewAdminPassword" -ForegroundColor White
    Write-Host "`nNote: Some changes may require restart or logout/login to take full effect." -ForegroundColor Yellow

}
catch {
    Write-Error "Configuration failed: $($_.Exception.Message)"
    exit 1
}

Write-Host "`nScript execution completed." -ForegroundColor Green
