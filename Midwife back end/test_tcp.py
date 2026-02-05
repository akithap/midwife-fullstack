
import socket

HOST = "gateway01.ap-southeast-1.prod.aws.tidbcloud.com"
PORT = 4000

print(f"Testing TCP connection to {HOST}:{PORT}...")

try:
    sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    sock.settimeout(5) # 5 second timeout
    result = sock.connect_ex((HOST, PORT))
    
    if result == 0:
        print("SUCCESS: Port is OPEN/Reachable.")
    else:
        print(f"FAILURE: Port is CLOSED/Blocked (Error Code: {result})")
    sock.close()

except Exception as e:
    print(f"ERROR: {e}")
