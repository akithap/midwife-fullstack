from sql_app import models, database
from sqlalchemy.orm import Session

def fix_admin():
    db = database.SessionLocal()
    
    # 1. Get correct office
    office_name = "Colombo MC District 1"
    office = db.query(models.MOHOffice).filter(models.MOHOffice.name == office_name).first()
    
    if not office:
        print("Office not found!")
        return

    # 2. Get Admin
    admin = db.query(models.MOHOfficer).filter(models.MOHOfficer.username == "admin").first()
    if admin:
        print(f"Updating admin from Office ID {admin.moh_office_id} to {office.id}...")
        admin.moh_office_id = office.id
        admin.moh_area = office.name # Sync string too
        db.commit()
        print("Admin updated successfully!")
    else:
        print("Admin user not found.")
        
    db.close()

if __name__ == "__main__":
    fix_admin()
