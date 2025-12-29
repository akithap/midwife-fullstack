
import requests
import json

BASE_URL = "http://127.0.0.1:8000"

def seed_database():
    print("\n--- Seeding Database ---")
    try:
        response = requests.get(f"{BASE_URL}/seed-dashboard")
        if response.status_code == 200:
            print(f"[PASS] Database Seeded: {response.json()['message']}")
            return True
        else:
            print(f"[FAIL] Seeding failed ({response.status_code})")
            return False
    except Exception as e:
        print(f"[ERROR] {e}")
        return False

def test_midwife_login():
    print("\n--- Testing Midwife Login ---")
    try:
        data = {"username": "test_midwife", "password": "123"}
        response = requests.post(f"{BASE_URL}/token", data=data)
        if response.status_code == 200:
            print(f"[PASS] Valid Login ({response.status_code})")
            return response.json()["access_token"]
        else:
            print(f"[FAIL] Valid Login ({response.status_code}): {response.text}")
            return None
    except Exception as e:
        print(f"[ERROR] {e}")
        return None

def test_invalid_login():
    print("\n--- Testing Invalid Login ---")
    try:
        data = {"username": "wrong", "password": "wrong"}
        response = requests.post(f"{BASE_URL}/token", data=data)
        if response.status_code != 200:
            print(f"[PASS] Invalid Login handled correctly (Status: {response.status_code})")
        else:
            print(f"[FAIL] Invalid Login allowed!")
    except Exception as e:
        print(f"[ERROR] {e}")

def test_dashboard_stats(token):
    print("\n--- Testing Dashboard Stats ---")
    headers = {"Authorization": f"Bearer {token}"}
    try:
        response = requests.get(f"{BASE_URL}/midwives/dashboard-stats", headers=headers)
        if response.status_code == 200:
            stats = response.json()
            print(f"[PASS] Stats fetched: {stats}")
        else:
            print(f"[FAIL] Stats fetch failed ({response.status_code})")
    except Exception as e:
        print(f"[ERROR] {e}")

def test_get_mothers(token):
    print("\n--- Testing Get Mothers ---")
    headers = {"Authorization": f"Bearer {token}"}
    try:
        response = requests.get(f"{BASE_URL}/mothers/", headers=headers, params={"skip": 0, "limit": 10})
        if response.status_code == 200:
            mothers = response.json()
            print(f"[PASS] Mothers fetched. Count: {len(mothers)}")
            if mothers:
                nic = mothers[0]['nic']
                print(f"      Sample NIC: {nic}")
                return nic
        else:
            print(f"[FAIL] Mothers fetch failed ({response.status_code})")
    except Exception as e:
        print(f"[ERROR] {e}")
    return None

def test_mother_login(nic):
    print("\n--- Testing Mother Login ---")
    if not nic:
        print("[SKIP] No NIC available")
        return
        
    try:
        # Based on seed_dashboard logic: password="123"
        data = {"username": nic, "password": "123"} 
        response = requests.post(f"{BASE_URL}/mother/token", data=data)
        if response.status_code == 200:
            print(f"[PASS] Mother Login Success")
        else:
            print(f"[FAIL] Mother Login Failed ({response.status_code})")
    except Exception as e:
        print(f"[ERROR] {e}")

if __name__ == "__main__":
    if seed_database():
        token = test_midwife_login()
        test_invalid_login()
        
        if token:
            test_dashboard_stats(token)
            nic = test_get_mothers(token)
            
            # Since seed creates mother with password '123'
            if nic:
                test_mother_login(nic)
