import requests

BASE_URL = "http://127.0.0.1:8000"

def get_token(username, password):
    resp = requests.post(f"{BASE_URL}/moh/token", data={"username": username, "password": password})
    if resp.status_code == 200:
        return resp.json()["access_token"]
    print(f"Login failed for {username}: {resp.status_code} {resp.text}")
    return None

def check_analytics(name, username, password):
    print(f"\n--- Checking for {name} ({username}) ---")
    token = get_token(username, password)
    if not token: return

    headers = {"Authorization": f"Bearer {token}"}
    
    try:
        # Check General Stats (Top Health Issues source)
        r = requests.get(f"{BASE_URL}/reports/stats", headers=headers)
        stats = r.json()
        print(f"Stats Risks ({r.status_code}): {stats.get('risks', {}).get('factors', {})}")

        # Check Hotspots
        r = requests.get(f"{BASE_URL}/moh/analytics/hotspots", headers=headers)
        print(f"Hotspots ({r.status_code}): {r.json()}")
        
        # Check Dashboard Stats
        r = requests.get(f"{BASE_URL}/moh/dashboard/stats", headers=headers)
        if r.status_code == 200:
            print(f"Dashboard (200): Summary={r.json().get('summary')}")
        else:
            print(f"Dashboard Error ({r.status_code}): {r.text}")
        
        # Check Defaulters
        r = requests.get(f"{BASE_URL}/moh/analytics/defaulters", headers=headers)
        print(f"Defaulters ({r.status_code}): {r.json()}")

    except Exception as e:
        print(f"Error: {e}")

if __name__ == "__main__":
    check_analytics("Colombo", "admin", "123")
    check_analytics("Gampaha", "admin_gampaha", "123")
