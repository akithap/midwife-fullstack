
from sqlalchemy import create_engine, text

import certifi

# TiDB Connection
TIDB_URL = "mysql+pymysql://28Zi1CmK1JPgXpM.root:MGo6riH1oRH2v1Mh@gateway01.ap-southeast-1.prod.aws.tidbcloud.com:4000/test"
connect_args = {"ssl": {"ca": certifi.where(), "check_hostname": False}}

print(f"Checking TiDB stats...")

try:
    engine = create_engine(TIDB_URL, connect_args=connect_args)
    with engine.connect() as connection:
        print("SUCCESS: Connected to TiDB.")
        
        # Check counts
        tables = ["mothers", "midwives", "moh_officers", "appointments"]
        for t in tables:
            try:
                result = connection.execute(text(f"SELECT COUNT(*) FROM {t}"))
                count = result.scalar()
                print(f"Table '{t}': {count} rows")
            except Exception as e:
                print(f"Table '{t}': Could not read ({e})")
                
except Exception as e:
    print(f"FAILURE: Could not connect to TiDB.")
    print(e)
