from sql_app import models, crud, schemas, database
from sqlalchemy.orm import Session

def seed_midwives():
    db = database.SessionLocal()
    
    # 1. Get the Specific Office
    office_name = "Colombo MC District 1"
    office = db.query(models.MOHOffice).filter(models.MOHOffice.name == office_name).first()
    
    if not office:
        print(f"Error: Office '{office_name}' not found!")
        return

    print(f"Found Office: {office.name} (ID: {office.id})")

    # 2. Create Midwives
    midwives_to_create = [
        {"user": "mw_colombo_1", "name": "Sister Anne (Col 1)"},
        {"user": "mw_colombo_2", "name": "Sister Kate (Col 1)"}
    ]

    for m_data in midwives_to_create:
        existing = db.query(models.Midwife).filter(models.Midwife.username == m_data["user"]).first()
        if not existing:
            print(f"Creating {m_data['user']}...")
            crud.create_midwife(db, schemas.MidwifeCreate(
                username=m_data["user"], 
                password="123", 
                full_name=m_data["name"],
                assigned_moh_area=office.name,
                moh_office_id=office.id
            ))
        else:
            print(f"Midwife {m_data['user']} already exists.")
            
    db.commit()
    print("Done!")

if __name__ == "__main__":
    seed_midwives()
