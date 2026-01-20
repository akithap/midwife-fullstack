from sql_app import models, database
from sqlalchemy.orm import Session

def check_areas():
    db = database.SessionLocal()
    colombo_office = db.query(models.MOHOffice).filter(models.MOHOffice.name == "Colombo MC District 1").first()
    
    results = db.query(models.PregnancyRecord.phi_area).join(models.Mother).join(models.Midwife).filter(
        models.Midwife.moh_office_id == colombo_office.id
    ).distinct().all()
    
    print("--- UNIQUE AREAS IN COLOMBO OFFICE ---")
    for (area,) in results:
        print(area)

if __name__ == "__main__":
    check_areas()
