# Define log file
$logPath = "$PSScriptRoot\WUA_Reset_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"

function Write-Log {
    param([string]$message)
    $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    "$timestamp`t$message" | Tee-Object -FilePath $logPath -Append
}

Write-Log "`n=== Starting WSUS/SCCM Update Configuration Reset ==="

# Detect OS version
$os = Get-CimInstance -ClassName Win32_OperatingSystem
$version = [version]$os.Version
if ($version -ge [version]"10.0.14393") {
    Write-Log "Detected Windows Server 2016 or later (Build $($version.ToString()))."
    $is2016Plus = $true
} else {
    Write-Log "Detected pre-2016 Windows Server (Build $($version.ToString()))."
    $is2016Plus = $false
}

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

# 3. Enable Microsoft Update (branch by OS)
try {
    if ($is2016Plus) {
        Write-Log "Using registry method to enable Microsoft Update on 2016+."
        # Use registry keys instead of COM on 2016+
        New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" -Force | Out-Null
        New-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" `
            -Name "UseWUServer" -Value 0 -PropertyType DWORD -Force
        Write-Log "Registry configured for Microsoft Update (UseWUServer=0)."
    } else {
        Write-Log "Using COM method to register Microsoft Update on pre-2016."
        $svcMgr = New-Object -ComObject "Microsoft.Update.ServiceManager"
        $svcMgr.AddService2('7971f918-a847-4430-9279-4a52d1efe18d', 7, '')
        Write-Log "Microsoft Update service registered via COM."
    }
} catch {
    Write-Log "Failed to enable Microsoft Update: $_"
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
    $svcMgr2 = New-Object -ComObject "Microsoft.Update.ServiceManager"
    $svcMgr2.Services | ForEach-Object {
        $line = "Name: $($_.Name) | ServiceID: $($_.ServiceID) | IsDefault: $($_.IsDefaultAUService)"
        Write-Log $line
    }
} catch {
    Write-Log "Failed to query current update service source: $_"
}

Write-Log "`n=== Reset Complete. Log saved to $logPath ==="

