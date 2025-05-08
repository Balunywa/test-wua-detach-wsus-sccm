# Define log file
$logPath = "$PSScriptRoot\WUA_Reset_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"

function Write-Log {
    param([string]$message)
    $message | Tee-Object -FilePath $logPath -Append
}

Write-Log "`n=== Resetting WSUS/SCCM Update Configuration ==="

# 1. Remove WSUS Group Policy registry keys
try {
    $wuRegPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate"
    if (Test-Path $wuRegPath) {
        Remove-Item -Path $wuRegPath -Recurse -Force
        Write-Log "Removed WSUS-related GPO registry settings."
    } else {
        Write-Log "No WSUS GPO registry settings found."
    }
} catch {
    Write-Log "Error removing WSUS GPO settings: $_"
}

# 2. Stop and disable SCCM client service (CcmExec)
try {
    $sccmService = Get-Service -Name CcmExec -ErrorAction Stop
    if ($sccmService.Status -eq "Running") {
        Stop-Service -Name CcmExec -Force
        Write-Log "SCCM client service (CcmExec) stopped."
    }
    Set-Service -Name CcmExec -StartupType Disabled
    Write-Log "SCCM client service (CcmExec) disabled."
} catch {
    Write-Log "SCCM client service not found or already disabled."
}

# 3. Force registration with Microsoft Update (not just Windows Update)
try {
    $ServiceManager = New-Object -ComObject "Microsoft.Update.ServiceManager"
    $ServiceManager.AddService2('7971f918-a847-4430-9279-4a52d1efe18d', 7, '')
    Write-Log "Microsoft Update service registered successfully."
} catch {
    Write-Log "Failed to register Microsoft Update service: $_"
}

# 4. Restart the Windows Update Agent service
try {
    Restart-Service wuauserv -Force
    Write-Log "Windows Update service (wuauserv) restarted."
} catch {
    Write-Log "Failed to restart Windows Update service: $_"
}

# 5. Trigger a scan to Microsoft Update
try {
    Start-Process -FilePath "UsoClient.exe" -ArgumentList "StartScan" -NoNewWindow -Wait
    Write-Log "Triggered update scan using UsoClient."
} catch {
    Write-Log "Failed to trigger scan: $_"
}

# 6. Confirm current default update source
try {
    Write-Log "`n=== Current Windows Update Source ==="
    $ServiceManager = New-Object -ComObject "Microsoft.Update.ServiceManager"
    $ServiceManager.Services | ForEach-Object {
        $line = "Name: $($_.Name) | ServiceID: $($_.ServiceID) | IsDefault: $($_.IsDefaultAUService)"
        Write-Log $line
    }
} catch {
    Write-Log "Failed to query current update service source: $_"
}

Write-Log "`n=== Reset Complete. Log saved to $logPath ==="
