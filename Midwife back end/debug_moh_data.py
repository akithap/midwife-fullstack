from sql_app.database import SessionLocal
from sql_app import models

db = SessionLocal()

def check_moh():
    print("--- MOH Officers ---")
    officers = db.query(models.MOHOfficer).all()
    for o in officers:
        print(f"ID: {o.id} | User: {o.username} | Area: '{o.moh_area}'")

    print("\n--- Midwives in Colombo ---")
    mws = db.query(models.Midwife).filter(models.Midwife.assigned_moh_area == "Colombo").all()
    print(f"Count: {len(mws)}")
    for mw in mws:
        print(f"  - {mw.username} (Area: {mw.assigned_moh_area})")

if __name__ == "__main__":
    check_moh()
