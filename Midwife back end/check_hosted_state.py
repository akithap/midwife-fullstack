
from sqlalchemy import create_engine, text
import certifi

# TiDB Connection
TIDB_URL = "mysql+pymysql://28Zi1CmK1JPgXpM.root:MGo6riH1oRH2v1Mh@gateway01.ap-southeast-1.prod.aws.tidbcloud.com:4000/test"
connect_args = {"ssl": {"ca": certifi.where(), "check_hostname": False}}

def check_db_state():
    try:
        engine = create_engine(TIDB_URL, connect_args=connect_args)
        with engine.connect() as connection:
            # Check Offices
            print("Checking MOH Offices...")
            result = connection.execute(text("SELECT id, name FROM moh_offices"))
            offices = result.fetchall()
            if not offices:
                print("!! NO OFFICES FOUND !!")
            else:
                for off in offices:
                    print(f"Office: {off.id} - {off.name}")

            # Check Midwives
            print("\nChecking Midwives...")
            result = connection.execute(text("SELECT id, username FROM midwives"))
            mws = result.fetchall()
            if not mws:
                print("!! NO MIDWIVES FOUND !!")
            else:
                for mw in mws:
                    print(f"Midwife: {mw.id} - {mw.username}")

    except Exception as e:
        print(f"Error: {e}")

if __name__ == "__main__":
    check_db_state()
