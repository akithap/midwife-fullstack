from sqlalchemy.orm import Session
from sql_app import models, database

db = database.SessionLocal()

def debug_data():
    print("--- DEBUG DATA DUMP ---")
    
    # 1. MOH Officers
    mohs = db.query(models.MOHOfficer).all()
    print(f"\n[MOH OFFICERS] ({len(mohs)})")
    for m in mohs:
        print(f"  ID: {m.id} | User: {m.username} | Area: '{m.moh_area}'")

    # 2. Midwives
    midwives = db.query(models.Midwife).all()
    print(f"\n[MIDWIVES] ({len(midwives)})")
    if not midwives:
        print("  NO MIDWIVES FOUND!")
    for m in midwives:
        print(f"  ID: {m.id} | User: {m.username} | Area: '{m.assigned_moh_area}' | Mothers: {len(m.mothers)}")

    # 3. Check Reporting Logic for First MOH
    if mohs:
        target_moh = mohs[0]
        print(f"\n[TEST REPORT] For MOH '{target_moh.username}' (Area: '{target_moh.moh_area}')")
        
        matching_midwives = [m for m in midwives if m.assigned_moh_area == target_moh.moh_area]
        print(f"  Matching Midwives: {len(matching_midwives)}")
        
        if matching_midwives:
            total_mothers = sum(len(m.mothers) for m in matching_midwives)
            print(f"  Total Mothers Linked: {total_mothers}")
        else:
            print("  -> ZERO MATCHES implies Area String Mismatch (Case Sensitive?) or pure lack of data.")

debug_data()
