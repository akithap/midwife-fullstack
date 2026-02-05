
from sqlalchemy import create_engine, text
import certifi

# Working TiDB Connection (from check_tidb.py)
TIDB_URL = "mysql+pymysql://28Zi1CmK1JPgXpM.root:MGo6riH1oRH2v1Mh@gateway01.ap-southeast-1.prod.aws.tidbcloud.com:4000/test"
connect_args = {"ssl": {"ca": certifi.where(), "check_hostname": False}}

def check_db():
    try:
        print("Connecting to hosted database...")
        engine = create_engine(TIDB_URL, connect_args=connect_args)
        
        with engine.connect() as connection:
            print("--- MIDWIVES ---")
            result = connection.execute(text("SELECT username, full_name FROM midwife LIMIT 5"))
            midwives = result.fetchall()
            
            if not midwives:
                print("No midwives found.")
            else:
                for mw in midwives:
                    print(f"User: {mw.username}, Name: {mw.full_name}")

            print("\n--- MOH OFFICERS ---")
            result = connection.execute(text("SELECT username, role, moh_office_id FROM moh_officers LIMIT 5"))
            officers = result.fetchall()
            
            if not officers:
                print("No MOH officers found.")
            else:
                for off in officers:
                    print(f"User: {off.username}, Role: {off.role}")

    except Exception as e:
        print(f"Error: {e}")

if __name__ == "__main__":
    check_db()
