from sql_app import models, database
from sqlalchemy.orm import Session

def debug_linkage():
    db = database.SessionLocal()
    
    # 1. Check Admin
    admin = db.query(models.MOHOfficer).filter(models.MOHOfficer.username == "admin").first()
    if admin:
        office_name = admin.office.name if admin.office else "None"
        print(f"User 'admin': Office ID = {admin.moh_office_id}, Name = {office_name}")
    else:
        print("User 'admin' not found.")

    # 2. Check Midwives
    print("\n--- Midwives ---")
    midwives = db.query(models.Midwife).all()
    for mw in midwives:
        office_name = mw.office.name if mw.office else "None"
        print(f"Midwife '{mw.username}': Office ID = {mw.moh_office_id}, Name = {office_name}")

    # 3. Check 'Colombo' Offices
    print("\n--- Colombo Offices ---")
    offices = db.query(models.MOHOffice).filter(models.MOHOffice.name.like("%Colombo%")).all()
    for o in offices:
        print(f"Office ID {o.id}: {o.name}")

    db.close()

if __name__ == "__main__":
    debug_linkage()
