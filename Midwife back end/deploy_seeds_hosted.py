
from sqlalchemy import create_engine, text
import certifi
from passlib.context import CryptContext

# Hosted TiDB Connection
TIDB_URL = "mysql+pymysql://28Zi1CmK1JPgXpM.root:MGo6riH1oRH2v1Mh@gateway01.ap-southeast-1.prod.aws.tidbcloud.com:4000/test"
connect_args = {"ssl": {"ca": certifi.where(), "check_hostname": False}}

# Password Hashing
pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")

def get_password_hash(password):
    return pwd_context.hash(password)

def deploy_seeds():
    try:
        print("Connecting to Hosted Database...")
        engine = create_engine(TIDB_URL, connect_args=connect_args)
        
        with engine.connect() as connection:
            print("Connected.")
            
            # 1. Ensure MOH Office Exists
            office_name = "Colombo MC District 1"
            print(f"Checking for Office: '{office_name}'...")
            
            result = connection.execute(text("SELECT id FROM moh_offices WHERE name = :name"), {"name": office_name})
            office = result.fetchone()
            
            office_id = None
            if not office:
                print(f"Office not found. Creating '{office_name}'...")
                # Insert Office
                connection.execute(
                    text("INSERT INTO moh_offices (name, district, province) VALUES (:name, :district, :province)"),
                    {"name": office_name, "district": "Colombo", "province": "Western Province"}
                )
                connection.commit()
                
                # Fetch ID back
                result = connection.execute(text("SELECT id FROM moh_offices WHERE name = :name"), {"name": office_name})
                office_id = result.scalar()
                print(f"Created Office ID: {office_id}")
            else:
                office_id = office.id
                print(f"Found Office ID: {office_id}")

            # 2. Seed Midwives
            midwives = [
                {"user": "mw_colombo_1", "name": "Sister Anne (Col 1)", "pass": "123"},
                {"user": "mw_colombo_2", "name": "Sister Kate (Col 1)", "pass": "123"}
            ]
            
            for m in midwives:
                print(f"Checking Midwife: {m['user']}...")
                result = connection.execute(text("SELECT id FROM midwives WHERE username = :u"), {"u": m['user']})
                existing = result.fetchone()
                
                if not existing:
                    print(f"Creating {m['user']}...")
                    hashed = get_password_hash(m['pass'])
                    
                    sql = """
                        INSERT INTO midwives 
                        (username, hashed_password, full_name, assigned_moh_area, moh_office_id, is_active, created_at)
                        VALUES (:u, :p, :n, :area, :oid, :active, COMPLETED)
                    """.replace("COMPLETED", "NOW()")

                    connection.execute(text(sql), 
                    {
                        "u": m['user'],
                        "p": hashed,
                        "n": m['name'],
                        "area": office_name,
                        "oid": office_id,
                        "active": True
                    })
                    print(f"Created {m['user']}")
                else:
                    print(f"Midwife {m['user']} already exists (ID: {existing.id})")
            
            connection.commit()
            print("\nSUCCESS: Seeding Complete!")

    except Exception as e:
        print(f"\nFAILURE: {e}")

if __name__ == "__main__":
    deploy_seeds()
