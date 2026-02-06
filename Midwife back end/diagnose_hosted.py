import requests

BASE_URL = "https://midwife-website-hazel.vercel.app"
# BASE_URL = "http://localhost:8000"

def fix_hosted_accounts():
    print(f"Targeting: {BASE_URL}")
    
    # 0. Check Root/Docs
    try:
        print("Checking Root...")
        r = requests.get(f"{BASE_URL}/")
        print(f"Root: {r.status_code}")
    except: pass

    # 1. Ensure Admin Exists (Trigger Setup)
    try:
        print("Triggering /setup_admin...")
        r = requests.get(f"{BASE_URL}/setup_admin")
        print(f"Setup Admin: {r.status_code}")
    except Exception as e:
        print(f"Setup warning: {e}")

    # 2. Login as Admin
    print("Logging in as moh_admin (/moh/token)...")
    token = None
    try:
        res = requests.post(f"{BASE_URL}/moh/token", data={"username": "moh_admin", "password": "admin123"})
        if res.status_code == 200:
            token = res.json()["access_token"]
            print("SUCCESS: Admin Login OK.")
        else:
            print(f"FAIL: Admin Login Failed ({res.status_code}). Endpoint might be missing.")
            
            # TRY OLD LOGIN
            print("Attempting old /token endpoint for Midwife...")
            res2 = requests.post(f"{BASE_URL}/token", data={"username": "mw_colombo_1", "password": "123"})
            print(f"Midwife Login (/token): {res2.status_code} - {res2.text}")
            return
    except Exception as e:
        print(f"FAIL: Connection Error: {e}")
        return
    except Exception as e:
        print(f"FAIL: Connection Error: {e}")
        return

    # 3. Create Midwife Account via API
    headers = {"Authorization": f"Bearer {token}"}
    
    print("Checking/Creating 'mw_colombo_1'...")
    # There isn't a check endpoint easily accessible without iterating, so just try creating.
    # If it exists, it might fail, which is fine.
    
    midwife_data = {
        "username": "mw_colombo_1",
        "password": "123",
        "full_name": "Sister Anne (Hosted)",
        "assigned_moh_area": "Colombo MC District 1",
        "moh_office_id": 1,
        "email": "anne@moh.gov.lk",
        "phone_number": "0771234567",
        "slmc_reg_number": "SLMC-001"
    }
    
    res = requests.post(f"{BASE_URL}/midwives/full", json=midwife_data, headers=headers)
    if res.status_code == 201:
        print("SUCCESS: Created 'mw_colombo_1' with password '123'.")
    elif res.status_code == 400 and "already registered" in res.text:
        print("INFO: 'mw_colombo_1' already exists.")
        # Optional: We could try to reset password if we had an endpoint for it, but we don't for admins to reset others yet?
        # Actually main.py doesn't show an admin-reset-midwife-password endpoint.
        # But if it exists, the password key is "123" stored previously.
    else:
        print(f"FAIL: Could not create midwife. {res.status_code} - {res.text}")

if __name__ == "__main__":
    fix_hosted_accounts()
