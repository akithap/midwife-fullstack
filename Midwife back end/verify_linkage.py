from sql_app.database import SessionLocal
from sql_app import models

db = SessionLocal()

def verify_linkage():
    print("--- Checking Midwife Linkage ---")
    mw = db.query(models.Midwife).first()
    if mw:
        print(f"Midwife: {mw.username}")
        print(f"Assigned MOH Area: {mw.assigned_moh_area}")
        
        if mw.assigned_moh_area == "Colombo":
            print("SUCCESS: Midwife linked to Colombo MOH area.")
        else:
            print("FAILURE: Midwife area mismatch.")
    else:
        print("No midwife found!")
        
    print("\n--- Checking Data Counts Again ---")
    # Quick count check
    total = db.query(models.Mother).count()
    print(f"Total Mothers: {total}")

if __name__ == "__main__":
    verify_linkage()
