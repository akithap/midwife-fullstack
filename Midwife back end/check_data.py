from sqlalchemy import text
from sql_app.database import engine

def check_data():
    try:
        with engine.connect() as connection:
            print("--- Database Counts ---")
            
            # Midwives
            midwives = connection.execute(text("SELECT id, username FROM midwives")).fetchall()
            print("\n-- MIDWIVES --")
            for m in midwives:
                print(f"ID: {m[0]}, Username: {m[1]}")

            # Mothers
            mothers = connection.execute(text("SELECT id, full_name, midwife_id, latitude, longitude, status, risk_level FROM mothers")).fetchall()
            print("\n-- MOTHERS --")
            for m in mothers:
                print(f"ID: {m[0]}, Name: {m[1]}, AssignedTo: {m[2]}, Lat: {m[3]}, Lng: {m[4]}, Status: {m[5]}, RiskContext: {m[6]}")
                
            # Count Check
            if midwives:
                mw_id = midwives[0][0]
                count = connection.execute(text(f"SELECT COUNT(*) FROM mothers WHERE midwife_id = {mw_id}")).scalar()
                print(f"\nExpected Count for Midwife {mw_id}: {count}")

    except Exception as e:
        print(f"Error connecting to DB: {e}")

if __name__ == "__main__":
    check_data()
