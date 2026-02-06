from sqlalchemy import create_engine, text
from passlib.context import CryptContext
import certifi

# Hosted TiDB Connection (Direct)
TIDB_URL = "mysql+pymysql://28Zi1CmK1JPgXpM.root:MGo6riH1oRH2v1Mh@gateway01.ap-southeast-1.prod.aws.tidbcloud.com:4000/test"
connect_args = {"ssl": {"ca": certifi.where(), "check_hostname": False}}

# Password Context (Must match crud.py)
pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")

def reset_midwife():
    try:
        print("Connecting to Hosted Database...")
        engine = create_engine(TIDB_URL, connect_args=connect_args)
        
        username = "mw_colombo_1"
        raw_pass = "123"
        hashed_pass = pwd_context.hash(raw_pass)
        
        with engine.connect() as connection:
            print("Connected.")
            
            # Check if exists
            result = connection.execute(text("SELECT id FROM midwives WHERE username = :u"), {"u": username})
            existing = result.fetchone()
            
            if existing:
                print(f"User '{username}' exists. Updating password...")
                connection.execute(
                    text("UPDATE midwives SET hashed_password = :p, is_active = :a WHERE username = :u"),
                    {"p": hashed_pass, "a": True, "u": username}
                )
            else:
                print(f"User '{username}' NOT found. Creating...")
                # Ensure Office Exists
                office_res = connection.execute(text("SELECT id FROM moh_offices WHERE name = 'Colombo MC District 1'"))
                office = office_res.fetchone()
                office_id = office.id if office else 1
                
                connection.execute(
                    text("""
                        INSERT INTO midwives 
                        (username, hashed_password, full_name, assigned_moh_area, moh_office_id, is_active, created_at)
                        VALUES (:u, :p, 'Sister Anne (Col 1)', 'Colombo MC District 1', :oid, :active, NOW())
                    """),
                    {"u": username, "p": hashed_pass, "oid": office_id, "active": True}
                )
            
            connection.commit()
            print(f"\nSUCCESS: Password for '{username}' set to '{raw_pass}'.")
            print("Please try logging in again.")

    except Exception as e:
        print(f"\nFAILURE: {e}")

if __name__ == "__main__":
    reset_midwife()
