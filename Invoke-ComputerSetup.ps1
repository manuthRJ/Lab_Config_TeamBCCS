# Function to create a new local user
function New-LocalUser {
    param (
        [string]$Username,
        [string]$Password,
        [string]$FullName,
        [string]$Description,
        [bool]$PasswordNeverExpires = $false,
        [bool]$UserMayNotChangePassword = $false
    )
    
    $SecurePassword = ConvertTo-SecureString -String $Password -AsPlainText -Force
    New-LocalUser -Name $Username -Password $SecurePassword -FullName $FullName -Description $Description -PasswordNeverExpires:$PasswordNeverExpires -UserMayNotChangePassword:$UserMayNotChangePassword
}

# Function to set user permissions and restrictions
function Set-UserPermissions {
    param (
        [string]$Username,
        [bool]$IsAdmin = $false
    )
    
    if ($IsAdmin) {
        Add-LocalGroupMember -Group 'Administrators' -Member $Username
    } else {
        Add-LocalGroupMember -Group 'Users' -Member $Username
        Remove-LocalGroupMember -Group 'Administrators' -Member $Username
        
        # Disable access to removable storage
        $StudentSID = (Get-LocalUser -Name $Username).SID
        $KeyPath = "HKU\$StudentSID\Software\Policies\Microsoft\Windows\RemovableStorageDevices"
        if (-Not (Test-Path $KeyPath)) { New-Item -Path $KeyPath -Force }
        New-ItemProperty -Path $KeyPath -Name 'Deny_All' -Value 1 -PropertyType 'DWORD' -Force
        
        # Block system applications that allow changing settings
        $DisallowedApps = @(
            "ms-settings:",
            "control",
            "gpedit.msc",
            "regedit.exe",
            "cmd.exe",
            "powershell.exe"
        )
        $KeyPath = "HKU\$StudentSID\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer\DisallowRun"
        if (-Not (Test-Path $KeyPath)) { New-Item -Path $KeyPath -Force }
        for ($i = 0; $i -lt $DisallowedApps.Count; $i++) {
            New-ItemProperty -Path $KeyPath -Name ($i + 1).ToString() -Value $DisallowedApps[$i] -PropertyType 'String' -Force
        }
        
        # Apply registry changes
        Invoke-Command -ScriptBlock {
            reg save 'HKU\Student' 'C:\Users\Student\NTUSER.DAT' /y
        }
    }
}

# Function to set wallpapers and lock screen images
function Set-Wallpapers {
    param (
        [string]$Username,
        [string]$WallpaperPath,
        [string]$LockScreenPath
    )
    
    $SID = (Get-LocalUser -Name $Username).SID
    $HKU = "HKU\$SID"
    $WallpaperKey = "$HKU\Control Panel\Desktop"
    $LockScreenKey = "$HKU\Software\Microsoft\Windows\CurrentVersion\PersonalizationCSP"
    
    if (-Not (Test-Path $WallpaperKey)) { New-Item -Path $WallpaperKey -Force }
    Set-ItemProperty -Path $WallpaperKey -Name 'Wallpaper' -Value $WallpaperPath -Force
    Set-ItemProperty -Path $WallpaperKey -Name 'WallpaperStyle' -Value 6 -Force  # Fit
    
    if (-Not (Test-Path $LockScreenKey)) { New-Item -Path $LockScreenKey -Force }
    New-ItemProperty -Path $LockScreenKey -Name 'LockScreenImageStatus' -Value 1 -PropertyType 'DWORD' -Force
    New-ItemProperty -Path $LockScreenKey -Name 'LockScreenImagePath' -Value $LockScreenPath -PropertyType 'String' -Force
    
    # Apply registry changes
    Invoke-Command -ScriptBlock {
        reg save 'HKU\Student' 'C:\Users\Student\NTUSER.DAT' /y
    }
}

# Function to set explicit content warning
function Set-ExplicitContentWarning {
    $Script = @"
param([string]\$Query)
\$ExplicitKeywords = @('explicit', 'porn', 'xxx', 'adult', 'sex', 'nude', 'erotic', 'fucking', 'fuck', 'dick', 'hutto', 'hutta', 'Hukanawa', 'Ponnaya', 'pacaya', 'pakaya', 'kariya')
foreach (\$Keyword in \$ExplicitKeywords) {
    if (\$Query -match \$Keyword) {
        Add-Type -AssemblyName PresentationCore,PresentationFramework
        [System.Windows.MessageBox]::Show('Warning: Explicit Content Detected! You are now being monitored by #TeamBCCS. Proceeding may result in immediate tracking of your activity. Think twice before continuing.', 'Warning', 'OK', 'Error')
        break
    }
}
"@
    $ScriptPath = "C:\Windows\Lab_Config\ShowWarning.ps1"
    Set-Content -Path $ScriptPath -Value $Script

    $Trigger = New-ScheduledTaskTrigger -AtLogOn
    $Action = New-ScheduledTaskAction -Execute 'powershell.exe' -Argument "-File $ScriptPath"
    Register-ScheduledTask -TaskName "ExplicitContentWarning" -Trigger $Trigger -Action $Action -User 'SYSTEM' -RunLevel Highest
}

# Create accounts
New-LocalUser -Username "BCCS" -Password "#TeamBCCS25@PC" -FullName "BCCS" -Description "Administrator account" -PasswordNeverExpires $true
New-LocalUser -Username "Student" -Password "studenT" -FullName "Student" -Description "Student account" -PasswordNeverExpires $true -UserMayNotChangePassword $true

# Set permissions
Set-UserPermissions -Username "BCCS" -IsAdmin $true
Set-UserPermissions -Username "Student" -IsAdmin $false

# Set wallpapers
$WallpaperPath = "C:\Windows\Lab_Config\images\background.jpg"
$LockScreenPath = "C:\Windows\Lab_Config\images\Lockscreen.jpg"
Set-Wallpapers -Username "BCCS" -WallpaperPath $WallpaperPath -LockScreenPath $LockScreenPath
Set-Wallpapers -Username "Student" -WallpaperPath $WallpaperPath -LockScreenPath $LockScreenPath

# Set explicit content warning
Set-ExplicitContentWarning

# Restart the computer to apply changes
Restart-Computer -Force
