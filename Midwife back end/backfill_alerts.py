from sqlalchemy.orm import Session
from sql_app.database import SessionLocal, engine
from sql_app import models, risk_engine

def backfill_alerts():
    db = SessionLocal()
    try:
        print("Starting Alert Backfill...")
        
        # 1. Backfill Static Risks
        mothers = db.query(models.Mother).all()
        print(f"Scanning {len(mothers)} mothers for static risks...")
        
        for mother in mothers:
            record = db.query(models.PregnancyRecord).filter(models.PregnancyRecord.mother_id == mother.id).first()
            if record:
                risk_engine.RiskEngine.evaluate_static_risks(db, mother, record)
        
        # 2. Backfill Dynamic Risks (Latest Visit Only)
        print("Scanning latest visits for dynamic risks...")
        for mother in mothers:
            # Get latest ANc visit
            visit = db.query(models.ANCVisit)\
                .filter(models.ANCVisit.mother_id == mother.id)\
                .order_by(models.ANCVisit.visit_date.desc())\
                .first()
                
            if visit:
                risk_engine.RiskEngine.evaluate_dynamic_risks(db, mother, visit)
                
        # Commit happens inside RiskEngine methods but let's ensure
        db.commit()
        print("✅ Backfill Complete! refreshing dashboard should show alerts.")
        
    except Exception as e:
        print(f"❌ Error during backfill: {e}")
    finally:
        db.close()

if __name__ == "__main__":
    backfill_alerts()
