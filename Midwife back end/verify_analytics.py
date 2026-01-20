from sql_app.database import SessionLocal
from sql_app import models
from sqlalchemy import func

db = SessionLocal()

def verify():
    print("--- Verification Report ---")
    mothers = db.query(models.Mother).count()
    print(f"Total Mothers: {mothers}")
    
    high_risk = db.query(models.Mother).filter(models.Mother.risk_level == "High").count()
    print(f"High Risk Mothers: {high_risk}")
    
    # Hotspots check
    print("\nMothers per PHI Area:")
    # Group by logic is not simple in ORM without mapped column in Mother (we put it in address for Mother as placeholder or PregnancyRecord)
    # Mother.address was set to phi_area in seeding.
    areas = db.query(models.Mother.address, func.count(models.Mother.id)).group_by(models.Mother.address).all()
    for area, count in areas:
        print(f"  {area}: {count}")

    # Health Issues
    diabetes = db.query(models.PregnancyRecord).filter(models.PregnancyRecord.risk_diabetes == True).count()
    print(f"\nDiabetic Pregnancies: {diabetes}")
    
    # Delivery Forecast (Next 30 days)
    # We didn't import date/timedelta here, but simple count check is enough
    
    print("---------------------------")

if __name__ == "__main__":
    verify()
