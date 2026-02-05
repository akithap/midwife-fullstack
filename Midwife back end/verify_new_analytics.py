import requests
import json
from datetime import datetime, timedelta

# BASE_URL = "http://localhost:8000"
BASE_URL = "http://127.0.0.1:8000"

def get_moh_token():
    # Ensure Admin Exists
    try:
        requests.get(f"{BASE_URL}/setup_admin")
        print("Called /setup_admin to ensure user exists.")
    except:
        pass

    print("Logging in as MOH Admin...")
    try:
        response = requests.post(f"{BASE_URL}/moh/token", data={"username": "moh_admin", "password": "admin123"})
        if response.status_code == 200:
            token = response.json()["access_token"]
            print("MOH Login Success.")
            return token
        else:
            print(f"MOH Login Failed: {response.text}")
            return None
    except Exception as e:
        print(f"Connection Error: {e}")
        return None

def verify_analytics(token):
    headers = {"Authorization": f"Bearer {token}"}
    
    # 1. Registration Timing
    print("\n--- 1. Registration Timing ---")
    res = requests.get(f"{BASE_URL}/moh/analytics/registration", headers=headers)
    if res.status_code == 200:
        data = res.json()
        print(f"Response: {data}")
        if data.get("total", 0) > 0:
            print("PASS: Data Found (> 0)")
        else:
            print("WARNING: Data is 0 (Charts will be empty)")
    else:
        print(f"FAIL: {res.status_code} - {res.text}")

    # 2. Delivery Outcomes
    print("\n--- 2. Delivery Outcomes ---")
    res = requests.get(f"{BASE_URL}/moh/analytics/delivery", headers=headers)
    if res.status_code == 200:
        data = res.json()
        print(f"Response: {data}")
        # Expected: {"normal": X, "cs": Y, "other": Z, "total": T}
        if "normal" in data:
            print("PASS: Structure Valid")
    else:
        print(f"FAIL: {res.status_code} - {res.text}")

    # 3. Nutrition (Birth Weight)
    print("\n--- 3. Newborn Nutrition ---")
    res = requests.get(f"{BASE_URL}/moh/analytics/nutrition", headers=headers)
    if res.status_code == 200:
        data = res.json()
        print(f"Response: {data}")
        if "low_weight" in data:
            print("PASS: Structure Valid")
    else:
        print(f"FAIL: {res.status_code} - {res.text}")

    # 4. Midwife Performance
    print("\n--- 4. Midwife Performance ---")
    res = requests.get(f"{BASE_URL}/moh/analytics/performance", headers=headers)
    if res.status_code == 200:
        data = res.json()
        print(f"Response: {data}")
        if isinstance(data, list):
             print(f"PASS: Returned List of {len(data)} Midwives")
             for mw in data:
                 print(f" - {mw}")
    else:
        print(f"FAIL: {res.status_code} - {res.text}")
        
    # 5. Hotspots (Existing)
    print("\n--- 5. Hotspots (Existing) ---")
    res = requests.get(f"{BASE_URL}/moh/analytics/hotspots", headers=headers)
    if res.status_code == 200:
        print(f"Response (First 2): {res.json()[:2]}")
        print("PASS: Existing Endpoint Working")

    # 6. Main Dashboard Stats
    print("\n--- 6. MAIN DASHBOARD (/reports/stats) ---")
    res = requests.get(f"{BASE_URL}/reports/stats", headers=headers)
    if res.status_code == 200:
        data = res.json()
        print(f"Response Keys: {data.keys()}")
        print("PASS: Dashboard Stats Working")
    else:
        print(f"FAIL: {res.status_code} - {res.text}")

    # 7. Defaulters (Silent Risk)
    print("\n--- 7. SILENT RISK (Defaulters) ---")
    res = requests.get(f"{BASE_URL}/moh/analytics/defaulters", headers=headers)
    if res.status_code == 200:
        print(f"Response: {res.json()}")
        print("PASS: Defaulters Endpoint Working")
    else:
        print(f"FAIL: {res.status_code} - {res.text}")

    # 8. Forecast
    print("\n--- 8. DELIVERY FORECAST ---")
    res = requests.get(f"{BASE_URL}/moh/analytics/forecast", headers=headers)
    if res.status_code == 200:
        print(f"Response: {res.json()}")
        print("PASS: Forecast Endpoint Working")
    else:
        print(f"FAIL: {res.status_code} - {res.text}")

if __name__ == "__main__":
    token = get_moh_token()
    if token:
        verify_analytics(token)
