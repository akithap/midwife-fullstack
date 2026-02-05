from sql_app import models, crud, schemas, database
from sqlalchemy.orm import Session

def seed_colombo():
    db = database.SessionLocal()
    
    # 1. Get the Specific Office
    office_name = "Colombo MC District 1"
    office = db.query(models.MOHOffice).filter(models.MOHOffice.name == office_name).first()
    
    if not office:
        print(f"Error: Office '{office_name}' not found!")
        return

    print(f"Found Office: {office.name} (ID: {office.id})")

    # 2. Create MOH Officer
    username = "admin_colombo"
    if not db.query(models.MOHOfficer).filter(models.MOHOfficer.username == username).first():
        print(f"Creating {username}...")
        crud.create_moh_officer(db, schemas.MOHOfficerCreate(
            username=username, 
            password="123", 
            full_name="MOH Officer Colombo 1",
            moh_area=office.name,
            moh_office_id=office.id
        ))
    else:
        print(f"User {username} already exists.")
            
    db.commit()
    print("Done! Login with 'admin_colombo' / '123'")

if __name__ == "__main__":
    seed_colombo()
