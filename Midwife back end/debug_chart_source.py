from sql_app import models, database
from sqlalchemy.orm import Session

def debug_data():
    db = database.SessionLocal()
    
    # 1. Get Colombo Office ID
    colombo_office = db.query(models.MOHOffice).filter(models.MOHOffice.name == "Colombo MC District 1").first()
    if not colombo_office:
        print("Colombo Office not found.")
        return
    
    print(f"Checking Data for Office: {colombo_office.name} (ID: {colombo_office.id})")

    # 2. Query the exact chain used in analytics
    # Only High Risk + Pregnant
    results = db.query(
        models.Midwife.username,
        models.Midwife.moh_office_id,
        models.Mother.full_name,
        models.PregnancyRecord.phi_area
    ).select_from(models.Midwife).join(models.Mother).join(models.PregnancyRecord).filter(
        models.Midwife.moh_office_id == colombo_office.id,
        models.Mother.risk_level == "High",
        models.Mother.status == "Pregnant"
    ).all()

    print(f"\nFound {len(results)} high-risk records linked to this office:")
    
    unique_areas = set()
    for mw_name, off_id, mother_name, area in results:
        unique_areas.add(area)
        # Print a few examples
        if len(unique_areas) <= 5: 
             print(f"  - Midwife: {mw_name} | Mother: {mother_name} | Area: {area}")

    print("\nSummary of Areas found in this Office's Analytics:")
    for a in unique_areas:
        print(f"  - {a}")

    if "Gampaha" in unique_areas or "Kelaniya" in unique_areas:
        print("\n[CONFIRMED] Data Mismatch: Colombo Office has Gampaha data via its Midwives.")

    db.close()

if __name__ == "__main__":
    debug_data()
