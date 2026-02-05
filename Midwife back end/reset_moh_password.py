
from sqlalchemy import create_engine, text
from passlib.context import CryptContext

# 1. Setup Hashing
pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")

def get_password_hash(password):
    return pwd_context.hash(password)

import certifi

# 2. TiDB Connection
TIDB_URL = "mysql+pymysql://28Zi1CmK1JPgXpM.root:MGo6riH1oRH2v1Mh@gateway01.ap-southeast-1.prod.aws.tidbcloud.com:4000/test"
connect_args = {"ssl": {"ca": certifi.where(), "check_hostname": False}}

NEW_USER = "moh_admin"
NEW_PASS = "admin123"

try:
    print(f"Hashing password '{NEW_PASS}'...")
    hashed_password = get_password_hash(NEW_PASS)
    
    engine = create_engine(TIDB_URL, connect_args=connect_args)
    with engine.connect() as connection:
        print(f"Updating password for user '{NEW_USER}'...")
        
        stmt = text("UPDATE moh_officers SET hashed_password = :h, username = :u WHERE id = 1")
        connection.execute(stmt, {"h": hashed_password, "u": NEW_USER})
        connection.commit()
        
        print("SUCCESS: Password reset complete.")

except Exception as e:
    print(f"FAILURE: {e}")
