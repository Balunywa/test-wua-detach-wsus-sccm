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

📥 **Run this script first** to understand the current state of your VM.

---

### 2. `Reset-WindowsUpdateSource.ps1`

This **reset script** attempts to:

- Remove WSUS-related GPO registry keys
- Stop and disable the SCCM agent (`CcmExec`)
- Register Microsoft Update as the WUA's active source
- Restart the Windows Update service
- Trigger a manual update scan
- Log everything for review

📥 **Run this second** — but only after reviewing the assessment results and confirming this is a test machine.

---

##  GPO Caveat (IMPORTANT)

Even if `Reset-WindowsUpdateSource.ps1` removes WSUS registry keys, **Group Policy will reapply** on the next GPO refresh cycle (every 90 minutes or on reboot), unless:

- The VM is moved to an **OU that does not apply WSUS/SCCM GPOs**, or
- Local GPOs override domain policies (rare and not guaranteed)

If your environment is managed via Active Directory and you do **not** control GPOs, this reset is only temporary.

---

## Recommended Flow

```text
1. Run Check-WUAUpdateSource.ps1
   ↳ Review log output
2. If safe, run Reset-WindowsUpdateSource.ps1
   ↳ Review log and verify WUA now uses Microsoft Update
3. Move VM to GPO-neutral OU or isolate from domain if needed

---
## Log Output
Both scripts save their logs in the same directory where the script is located, with a timestamped .log file name for easy review and auditing.

---
## Author Notes
These scripts were created to provide internal validation and reproducibility during test scenarios involving Windows Update, Azure Arc, and other configuration validation use cases. Use responsibly.

---
##  License
MIT License – but again, these are intended for test use only.
