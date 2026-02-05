
from sqlalchemy import create_engine, text

# Local Connection (Default from database.py)
local_db_url = "mysql+mysqlconnector://root:1234@localhost/midwife_db"

print(f"Testing local connection: {local_db_url}")

try:
    engine = create_engine(local_db_url)
    with engine.connect() as connection:
        print("SUCCESS: Connected to Local DB.")
        
        # Check for data
        tables = ["mothers", "midwives", "moh_officers", "appointments"]
        for t in tables:
            try:
                result = connection.execute(text(f"SELECT COUNT(*) FROM {t}"))
                count = result.scalar()
                print(f"Table '{t}': {count} rows")
            except Exception as e:
                print(f"Table '{t}': Could not read ({e})")
                
except Exception as e:
    print(f"FAILURE: Could not connect to local DB.")
    print(e)
