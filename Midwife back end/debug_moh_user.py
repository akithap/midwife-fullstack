
from sqlalchemy import create_engine, text

# TiDB Connection
TIDB_URL = "mysql+pymysql://RoMjWYzY1Cfb1aC.root:YoegBR8HPT4UIGgJ@gateway01.ap-southeast-1.prod.aws.tidbcloud.com:4000/test"
connect_args = {"ssl": {"check_hostname": False}}

print(f"Checking MOH Users in TiDB...")

try:
    engine = create_engine(TIDB_URL, connect_args=connect_args)
    with engine.connect() as connection:
        result = connection.execute(text("SELECT id, username, hashed_password FROM moh_officers"))
        rows = result.fetchall()
        
        if not rows:
            print("No MOH Officers found!")
        else:
            for row in rows:
                print(f"Found User: ID={row.id}, Username='{row.username}'")
                
except Exception as e:
    print(f"Error: {e}")
