import json
import os
import sys

# Add python path
sys.path.append(os.getcwd())

from sql_app import models, database
from sqlalchemy.orm import Session

def seed_offices():
    db = database.SessionLocal()
    
    # 1. Create Tables if not exist (This will create moh_offices)
    models.Base.metadata.create_all(bind=database.engine)
    
    # 2. Load JSON
    with open('moh_offices.json', 'r') as f:
        data = json.load(f)
        
    print("Seeding MOH Offices...")
    count = 0
    
    for province, districts in data.items():
        for district, areas in districts.items():
            for area_name in areas:
                # Check if exists
                exists = db.query(models.MOHOffice).filter_by(name=area_name).first()
                if not exists:
                    office = models.MOHOffice(
                        name=area_name,
                        district=district,
                        province=province
                    )
                    db.add(office)
                    count += 1
                    
    db.commit()
    print(f"Successfully seeded {count} new MOH Offices.")
    db.close()

if __name__ == "__main__":
    seed_offices()
