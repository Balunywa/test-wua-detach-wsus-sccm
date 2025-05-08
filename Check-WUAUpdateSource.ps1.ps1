
# Define log file
$logPath = "$PSScriptRoot\WUA_Check_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"

# Helper to write both to console and log file
function Write-Log {
    param([string]$message)
    $message | Tee-Object -FilePath $logPath -Append
}

# Confirm the default Windows Update source
Write-Log "`n=== Windows Update Source ==="
try {
    $ServiceManager = New-Object -ComObject "Microsoft.Update.ServiceManager"
    $ServiceManager.Services | ForEach-Object {
        $line = "Name: $($_.Name) | ServiceID: $($_.ServiceID) | IsDefault: $($_.IsDefaultAUService)"
        Write-Log $line
    }
} catch {
    Write-Log "Failed to retrieve update service info: $_"
}

# Check if SCCM (ConfigMgr) agent is installed and running
Write-Log "`n=== SCCM Client (CcmExec) Status ==="
try {
    $ccm = Get-Service -Name CcmExec -ErrorAction Stop
    Write-Log "CcmExec Status: $($ccm.Status)"
} catch {
    Write-Log "CcmExec service not found (SCCM likely not installed)"
}

# Check for GPO enforcement of WSUS/SCCM update settings
Write-Log "`n=== WSUS/SCCM Group Policy Settings ==="
try {
    $wuPolicy = Get-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate" -ErrorAction Stop
    $wuPolicy | Format-List | Out-String | ForEach-Object { Write-Log $_ }
} catch {
    Write-Log "No WSUS-related GPO settings found."
}

Write-Log "`n=== Script Complete. Log saved to $logPath ==="
