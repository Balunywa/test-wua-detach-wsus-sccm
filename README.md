# Windows Update Source Assessment and Reset Scripts

##  IMPORTANT DISCLAIMER

> **WARNING: These scripts are for testing purposes only and should only be executed on test or isolated virtual machines (VMs).**  
> Running these scripts on production systems may break compliance, update delivery, or impact system manageability via SCCM or WSUS.
>
> Use at your own risk. No support or guarantees are provided.

---

##  Overview

This repository contains **two PowerShell scripts** designed to assess and optionally remove Group Policy and ConfigMgr (SCCM)-based controls over Windows Update on a Windows VM. These scripts are useful for lab and development environments where you want to test how a system behaves when **freed from WSUS and SCCM control** and pointed to **Microsoft Update** directly.

---

##  Use Case Scenarios

- You need to test how a VM behaves when updates are pulled directly from Microsoft Update.
- You want to validate the current Windows Update Agent (WUA) source and determine whether it is using WSUS or Microsoft Update.
- You are evaluating cleanup steps before onboarding to Azure Update Manager or using standalone Windows Update.
- You are working in a dev/test lab where GPOs and SCCM are not required.

---

##  Scripts Included

### 1. `Check-WUAUpdateSource.ps1`

This **read-only script** checks and logs the following:

- What update service the WUA is using (`Microsoft Update`, `Windows Update`, or `WSUS`)
- Whether the SCCM client (`CcmExec`) is installed and running
- Whether Group Policy registry keys exist that redirect the VM to WSUS

 **Run this script first** to understand the current state of your VM.

---

### 2. `Reset-WindowsUpdateSource.ps1`

This **reset script** attempts to:

- Remove WSUS-related GPO registry keys
- Stop and disable the SCCM agent (`CcmExec`)
- Register Microsoft Update as the WUA's active source
- Restart the Windows Update service
- Trigger a manual update scan
- Log everything for review

 **Run this second** — but only after reviewing the assessment results and confirming this is a test machine.

---

##  GPO Caveat (IMPORTANT)

Even if `Reset-WindowsUpdateSource.ps1` removes WSUS registry keys, **Group Policy will reapply** on the next GPO refresh cycle (every 90 minutes or on reboot), unless:

- The VM is moved to an **OU that does not apply WSUS/SCCM GPOs**, or
- Local GPOs override domain policies (rare and not guaranteed)

If your environment is managed via Active Directory and you do **not** control GPOs, this reset is only temporary.

---

##  Recommended Usage Flow

1. **Run `Check-WUAUpdateSource.ps1`**  
   Review the log output to confirm the current Windows Update source, SCCM client status, and any WSUS GPO configuration.

2. **If safe, run `Reset-WindowsUpdateSource.ps1`**  
   This removes WSUS registry settings, disables SCCM, registers Microsoft Update, restarts the Windows Update service, and triggers a scan.  
   Review the log to ensure the WUA is now using Microsoft Update.

3. **Move the VM to a GPO-neutral OU (if needed)**  
   Group Policies will reapply unless the VM is:
   - Moved to an OU that does **not apply WSUS/SCCM policies**, or
   - Disconnected from domain GPO enforcement (e.g., local-only environment)

>  **Important:** Even after running the reset script, GPOs will override your changes unless the VM is isolated from WSUS/SCCM-related policies.

---

## Log Output

Each script writes a log file in the same directory where it's executed.  
The file is timestamped (e.g., `WUA_Reset_20250508_112503.log`) for easy review and tracking.

---

## Author Notes

These scripts were developed to assist with internal validation and reproducibility during test scenarios involving:
- Windows Update behavior
- Azure Arc integration
- SCCM/WSUS detachment testing

Use responsibly and only in lab/test environments.

---

## 📜 License

MIT License  
> These scripts are intended for **test/lab use only**. Do not use in production environments.
