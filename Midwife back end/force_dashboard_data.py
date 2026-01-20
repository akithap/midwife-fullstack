from sql_app import database, models
from datetime import datetime, timedelta
import random

def force_data():
    db = database.SessionLocal()
    
    # Target Office
    office = db.query(models.MOHOffice).filter(models.MOHOffice.name == "Colombo MC District 1").first()
    if not office:
        print("Office not found")
        return

    print(f"Forcing recent data for {office.name}...")
    
    # 1. Update Midwives (Last 4 months distribution)
    midwives = db.query(models.Midwife).filter(models.Midwife.moh_office_id == office.id).all()
    print(f"Found {len(midwives)} midwives.")
    
    for i, m in enumerate(midwives):
        # Distribute them: 1 month ago, 2 months ago...
        months_ago = i % 4 
        m.created_at = datetime.now() - timedelta(days=months_ago * 30 + 5)
        print(f"  - Midwife {m.username} -> {m.created_at.date()}")
        
    db.commit()
    
    # 2. Update Mothers (Last 6 months volume)
    midwife_ids = [m.id for m in midwives]
    mothers = db.query(models.Mother).filter(models.Mother.midwife_id.in_(midwife_ids)).all()
    print(f"Found {len(mothers)} mothers.")
    
    for m in mothers:
        days_ago = random.randint(1, 150) # Last 5 months
        m.created_at = datetime.now() - timedelta(days=days_ago)
        
    db.commit()
    print("Done. Refresh dashboard.")

if __name__ == "__main__":
    force_data()
