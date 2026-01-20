from sql_app import database, models
from sqlalchemy import text
import random
from datetime import datetime, timedelta

def migrate_and_seed():
    db = database.SessionLocal()
    
    print("1. Adding created_at column to midwives table...")
    try:
        db.execute(text("ALTER TABLE midwives ADD COLUMN created_at TIMESTAMP"))
        db.commit()
        print("   - Success.")
    except Exception as e:
        print(f"   - column might already exist: {e}")
        db.rollback()

    print("2. Adding created_at column to mothers table...")
    try:
        db.execute(text("ALTER TABLE mothers ADD COLUMN created_at TIMESTAMP"))
        db.commit()
        print("   - Success.")
    except Exception as e:
        print(f"   - column might already exist: {e}")
        db.rollback()

    print("3. Backfilling Data with History (Last 12 Months)...")
    
    # helper to get random date
    def get_random_date():
        days_back = random.randint(0, 365)
        return datetime.now() - timedelta(days=days_back)

    # Seed Midwives
    midwives = db.query(models.Midwife).all()
    for m in midwives:
        # If it's null, update it
        if not m.created_at:
            m.created_at = get_random_date()
    
    # Seed Mothers
    mothers = db.query(models.Mother).all()
    for mom in mothers:
        if not mom.created_at:
            mom.created_at = get_random_date()
            
    db.commit()
    print("   - Backfilling complete.")
    db.close()

if __name__ == "__main__":
    migrate_and_seed()
