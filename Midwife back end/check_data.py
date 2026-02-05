from sql_app.database import SessionLocal
from sql_app import models

def check_data_link():
    db = SessionLocal()
    try:
        # 1. Check MOH Admin Office
        admin = db.query(models.MOHOfficer).filter(models.MOHOfficer.username == "moh_admin").first()
        if admin:
            print(f"MOH Admin: {admin.username}, Office ID: {admin.moh_office_id}")
        else:
            print("MOH Admin not found!")

        # 2. Check Midwives
        midwives = db.query(models.Midwife).all()
        print(f"\nTotal Midwives: {len(midwives)}")
        for m in midwives:
            print(f"Midwife: {m.username}, Office ID: {m.moh_office_id}")
            
        # 3. Check Records
        mothers = db.query(models.Mother).all()
        print(f"\nTotal Mothers: {len(mothers)}")
        
        # 4. Check Analytics Query Logic Manually
        if admin:
             count = db.query(models.PregnancyRecord)\
                .join(models.Mother)\
                .join(models.Midwife)\
                .filter(models.Midwife.moh_office_id == admin.moh_office_id)\
                .count()
             print(f"\nManual Query Count for Office {admin.moh_office_id}: {count}")

    finally:
        db.close()

if __name__ == "__main__":
    check_data_link()
