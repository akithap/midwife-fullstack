from sql_app.database import SessionLocal, engine
from sql_app import models, crud, schemas
from datetime import datetime, timedelta, date
import random

db = SessionLocal()

def seed_analytics_data():
    print("Seeding Analytics Data...")
    
    # 1. Ensure MOH Officer exists
    if not db.query(models.MOHOfficer).first():
        print("Creating Admin...")
        crud.create_moh_officer(db, schemas.MOHOfficerCreate(username="admin", password="123", full_name="Admin", moh_area="Colombo"))

    # 2. Create Midwife
    midwife = db.query(models.Midwife).first()
    if not midwife:
        print("Creating Midwife...")
        midwife = crud.create_midwife(db, schemas.MidwifeCreate(username="mw1", password="123", name="Sister Mary", slmc_reg_number="SLMC001", moh_area="Colombo", phm_area="Kandy Region 1"))

    # 3. Create High Risk Mothers (Hotspots)
    areas = ["Kandy Region 1", "Kandy Region 2", "Colombo Central", "Galle Fort", "Matara"]
    
    for i in range(10):
        area = random.choice(areas)
        risk = "High"
        
        # Create Mother
        m = models.Mother(
            full_name=f"Mother {area} {i}",
            nic=f"90000{i}V",
            # age removed - not in Mother model
            contact_number=f"077123456{i}", # Corrected from phone
            address=area,
            latitude=0.0, # Correct fields
            longitude=0.0,
            # phi_area removed - not in Mother model
            # moh_area removed - not in Mother model
            hashed_password="hash",
            midwife_id=midwife.id,
            risk_level=risk,
            status="Pregnant",
            pregnancy_start_date=date.today() - timedelta(days=90) # Added defaults
        )
        db.add(m)
        db.commit()
        db.refresh(m)
        
        # Create Pregnancy Record (for EDD and detailed PHI)
        edd_days = random.randint(10, 60) # Some in next 30 days (Forecast), some later
        preg_rec = models.PregnancyRecord(
            mother_id=m.id,
            phi_area=area,
            moh_division="Colombo",
            edd=date.today() + timedelta(days=edd_days),
            risk_diabetes=(i % 2 == 0),
            risk_cardiac=(i % 3 == 0),
            created_at=datetime.now()
        )
        db.add(preg_rec)
        
        # 4. Silent Risks (Defaulters)
        # Mother 0-2 will have NO visit (Defaulter if created > 30 days ago)
        # Let's manually set one defaulter
        if i < 3:
            # Create Appointment Requirement
            appt = models.Appointment(
                mother_id=m.id,
                midwife_id=midwife.id,
                date=datetime.now() - timedelta(days=40),
                status="Completed",
                title="Old Visit"
            )
            db.add(appt)
            db.commit()

            # Simulate old Visit
            visit = models.ANCVisit(
                mother_id=m.id,
                appointment_id=appt.id,
                visit_date=date.today() - timedelta(days=40), # 40 days ago
                weight_kg=60, bp_systolic=120, bp_diastolic=80,
                pallor="No", oedema="No", fundal_height_cm=20, fetal_lie="L", fetal_heart_sound="Could be heard", fetal_movement="Yes", urine_sugar="Nil", urine_albumin="Nil"
            )
            db.add(visit)
    
    db.commit()
    print("Seeding Complete!")

if __name__ == "__main__":
    seed_analytics_data()
