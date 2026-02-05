
import httpx
import asyncio

URL = "https://midwifebackend-git-main-akithas-projects-04f8a73b.vercel.app/moh/register"

PAYLOAD = {
    "username": "vercel_admin",
    "password": "vercel123",
    "full_name": "Vercel Admin Checking"
}

async def register():
    print(f"Registering user at {URL}...")
    async with httpx.AsyncClient() as client:
        try:
            response = await client.post(URL, json=PAYLOAD, timeout=20.0)
            print(f"Status: {response.status_code}")
            print(f"Response: {response.text}")
            
            if response.status_code in [200, 201]:
                print("SUCCESS: User created!")
            elif response.status_code == 400 and "already registered" in response.text:
                print("User already exists. You can try logging in.")
            else:
                print("FAILURE: Could not create user.")
                
        except Exception as e:
            print(f"Network Error: {e}")

if __name__ == "__main__":
    asyncio.run(register())
