from sql_app import database, models, crud
from sqlalchemy.orm import Session

def debug_data():
    db = database.SessionLocal()
    
    # 1. Get the target office (assuming Colombo MC District 1 for admin)
    office = db.query(models.MOHOffice).filter(models.MOHOffice.name == "Colombo MC District 1").first()
    
    if not office:
        print("CRITICAL: 'Colombo MC District 1' office not found.")
        return

    print(f"--- Debugging for Office: {office.name} (ID: {office.id}) ---")
    
    # 2. Check Midwives in this office
    midwives = db.query(models.Midwife).filter(models.Midwife.moh_office_id == office.id).all()
    print(f"Total Midwives linked to Office ID {office.id}: {len(midwives)}")
    
    if len(midwives) == 0:
        print("  -> ERROR: No midwives are linked to this office via moh_office_id!")
        print("  -> Checking unlinked midwives...")
        unlinked = db.query(models.Midwife).filter(models.Midwife.moh_office_id == None).all()
        print(f"  -> Found {len(unlinked)} midwives with moh_office_id=None.")
        for m in unlinked[:3]:
             print(f"     - {m.username} (Area: {m.assigned_moh_area})")
    else:
        # 3. Check created_at timestamps
        print("  -> Checking timestamps for linked midwives...")
        for m in midwives:
            print(f"     - {m.username}: created_at={m.created_at}")

debug_data()
