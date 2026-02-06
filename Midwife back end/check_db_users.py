from sqlalchemy import create_engine, text
import certifi

# Hosted TiDB Connection
TIDB_URL = "mysql+pymysql://28Zi1CmK1JPgXpM.root:MGo6riH1oRH2v1Mh@gateway01.ap-southeast-1.prod.aws.tidbcloud.com:4000/test"
connect_args = {"ssl": {"ca": certifi.where(), "check_hostname": False}}

def check_users():
    try:
        print("Connecting to Hosted Database...")
        engine = create_engine(TIDB_URL, connect_args=connect_args)
        
        with engine.connect() as connection:
            print("Connected.")
            
            # Check Midwives
            print("\n--- Midwives ---")
            result = connection.execute(text("SELECT id, username, is_active FROM midwives"))
            rows = result.fetchall()
            if not rows:
                print("No midwives found.")
            else:
                for row in rows:
                    print(f"ID: {row.id}, User: {row.username}, Active: {row.is_active}")

            # Check MOH Officers
            print("\n--- MOH Officers ---")
            result = connection.execute(text("SELECT id, username FROM moh_officers"))
            rows = result.fetchall()
            if not rows:
                print("No MOH officers found.")
            else:
                for row in rows:
                    print(f"ID: {row.id}, User: {row.username}")

    except Exception as e:
        print(f"Error: {e}")

if __name__ == "__main__":
    check_users()
