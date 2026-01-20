import requests

BASE_URL = "http://127.0.0.1:8000"

def test_api():
    # 1. Login
    print("Logging in...")
    try:
        resp = requests.post(f"{BASE_URL}/token", data={"username": "test_midwife", "password": "123"})
        if resp.status_code != 200:
            print(f"Login Failed: {resp.status_code} {resp.text}")
            return
        
        token = resp.json()["access_token"]
        print("Login Success. Token received.")
        
        # 2. Get Stats
        headers = {"Authorization": f"Bearer {token}"}
        resp = requests.get(f"{BASE_URL}/midwives/dashboard-stats", headers=headers)
        
        print("\n--- API Response ---")
        print(f"Status: {resp.status_code}")
        print(f"Body: {resp.json()}")
        
    except Exception as e:
        print(f"Error: {e}")

if __name__ == "__main__":
    test_api()
