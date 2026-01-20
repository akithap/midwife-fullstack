from sql_app import models, database
from sqlalchemy.orm import Session
import random

def cleanup_data():
    db = database.SessionLocal()
    
    # 1. Get Colombo Office
    colombo_office = db.query(models.MOHOffice).filter(models.MOHOffice.name == "Colombo MC District 1").first()
    if not colombo_office: return

    # 2. Get Midwives in Colombo
    midwives = db.query(models.Midwife).filter(models.Midwife.moh_office_id == colombo_office.id).all()
    mw_ids = [m.id for m in midwives]
    
    print(f"Cleaning data for {len(mw_ids)} midwives in Colombo...")

    # 3. Find High Risk Records for these Midwives
    # We need to update PregnancyRecord.phi_area
    
    records = db.query(models.PregnancyRecord).join(models.Mother).filter(
        models.Mother.midwife_id.in_(mw_ids)
    ).all()

    valid_areas = ["Colombo 1", "Colombo 2", "Colombo 3", "Colombo 4", "Borella", "Dematagoda"]
    
    count = 0
    for rec in records:
        # If current area looks "wrong" (like Gampaha areas), fix it
        if rec.phi_area in ["Gampaha", "Kadawatha", "Kelaniya", "Ja-Ela", "Kandana", "Unknown", 
                            "Biyagama", "Ragama", "Wattala", "Mahara", "Kiribathgoda", "kadawatha"]:
            rec.phi_area = random.choice(valid_areas)
            count += 1
            
    db.commit()
    print(f"Updated {count} records to have valid Colombo areas.")
    db.close()

if __name__ == "__main__":
    cleanup_data()
