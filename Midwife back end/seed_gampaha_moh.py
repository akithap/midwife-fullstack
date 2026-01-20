from sql_app import models, crud, schemas, database
from sqlalchemy.orm import Session

def seed_gampaha():
    db = database.SessionLocal()
    
    # 1. Get a DIFFERENT Office (e.g., Gampaha)
    office_name = "Gampaha"
    office = db.query(models.MOHOffice).filter(models.MOHOffice.name == office_name).first()
    
    if not office:
        print(f"Error: Office '{office_name}' not found!")
        # Fallback search if exact name differs
        office = db.query(models.MOHOffice).filter(models.MOHOffice.district == "Gampaha").first()
        if not office:
             print("Critical Error: No Gampaha office found.")
             return

    print(f"Found Office: {office.name} (ID: {office.id})")

    # 2. Create MOH Officer
    username = "admin_gampaha"
    if not db.query(models.MOHOfficer).filter(models.MOHOfficer.username == username).first():
        print(f"Creating {username}...")
        crud.create_moh_officer(db, schemas.MOHOfficerCreate(
            username=username, 
            password="123", 
            full_name="MOH Gampaha",
            moh_area=office.name,
            moh_office_id=office.id
        ))
    else:
        print(f"User {username} already exists.")
            
    db.commit()
    print("Done!")

if __name__ == "__main__":
    seed_gampaha()
