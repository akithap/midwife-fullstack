
from sqlalchemy import create_engine, text
from passlib.context import CryptContext

# 1. Setup Hashing (Same as crud.py)
pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")

def verify_password(plain_password, hashed_password):
    return pwd_context.verify(plain_password, hashed_password)

# 2. TiDB Connection
TIDB_URL = "mysql+pymysql://RoMjWYzY1Cfb1aC.root:YoegBR8HPT4UIGgJ@gateway01.ap-southeast-1.prod.aws.tidbcloud.com:4000/test"
connect_args = {"ssl": {"check_hostname": False}}

USERNAME = "moh_admin"
PASSWORD = "admin123"

try:
    print(f"Attempting to verify login for user '{USERNAME}' with password '{PASSWORD}'...")
    
    engine = create_engine(TIDB_URL, connect_args=connect_args)
    with engine.connect() as connection:
        # Get User
        result = connection.execute(text("SELECT username, hashed_password FROM moh_officers WHERE username = :u"), {"u": USERNAME})
        user = result.fetchone()
        
        if not user:
            print("FAILURE: User not found in database.")
        else:
            print(f"User found. Stored Hash: {user.hashed_password[:20]}...")
            if verify_password(PASSWORD, user.hashed_password):
                print("SUCCESS: Password verified correctly!")
            else:
                print("FAILURE: Password verification failed.")

except Exception as e:
    print(f"Error: {e}")
