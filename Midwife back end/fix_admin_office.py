from sql_app.database import SessionLocal
from sql_app import models

def fix_admin():
    db = SessionLocal()
    try:
        admin = db.query(models.MOHOfficer).filter(models.MOHOfficer.username == "moh_admin").first()
        if admin:
            print(f"Updating Admin {admin.username}...")
            admin.moh_office_id = 1
            db.commit()
            print("Admin assigned to Office ID 1.")
        else:
            print("Admin not found.")
            
    finally:
        db.close()

if __name__ == "__main__":
    fix_admin()
