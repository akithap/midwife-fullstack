from sql_app.database import SessionLocal, engine
from sql_app import models, crud
from datetime import datetime, timedelta
import random

def seed_analytics():
    db = SessionLocal()
    try:
        print("Seeding Analytics Data...")
        
        # 1. Get MOH Office
        office = db.query(models.MOHOffice).first()
        if not office:
            print("Creating MOH Office...")
            office = models.MOHOffice(id=1, name="Colombo Central", district="Colombo", province="Western")
            db.add(office)
            db.commit()
            
        # 2. Get or Create Midwives
        midwives = db.query(models.Midwife).filter(models.Midwife.moh_office_id == office.id).all()
        if not midwives:
            print("Creating Midwives...")
            m1 = models.Midwife(
                username="mw_anne", hashed_password="123", full_name="Anne Perera", 
                moh_office_id=office.id, area="Colombo 1", is_active=True
            )
            m2 = models.Midwife(
                username="mw_sita", hashed_password="123", full_name="Sita Silva", 
                moh_office_id=office.id, area="Colombo 2", is_active=True
            )
            db.add_all([m1, m2])
            db.commit()
            midwives = [m1, m2]
        else:
            print(f"Found {len(midwives)} midwives.")

        # 3. Create Mothers & Records
        print("Creating Mothers and Analytics Records...")
        
        # Scenario A: Early Registration (6 weeks)
        mother_early = models.Mother(
            nic=f"90000{random.randint(1000,9999)}V", 
            hashed_password="123", 
            full_name="Indrani (Early Reg)", 
            midwife_id=midwives[0].id,
            status="Pregnant", risk_level="Low"
        )
        db.add(mother_early)
        db.commit()
        
        preg_early = models.PregnancyRecord(
            mother_id=mother_early.id,
            poa_at_registration="6 weeks", # < 8 weeks
            edd=datetime.now().date() + timedelta(days=100)
        )
        db.add(preg_early)

        # Scenario B: Late Registration (12 weeks)
        mother_late = models.Mother(
            nic=f"91000{random.randint(1000,9999)}V", 
            hashed_password="123", 
            full_name="Kanthi (Late Reg)", 
            midwife_id=midwives[1].id,
            status="Pregnant", risk_level="High"
        )
        db.add(mother_late)
        db.commit()
        
        preg_late = models.PregnancyRecord(
            mother_id=mother_late.id,
            poa_at_registration="12 weeks", # > 8 weeks
            edd=datetime.now().date() + timedelta(days=50)
        )
        db.add(preg_late)

        # Scenario C: Delivery Records (Normal & C-Section, Low Birth Weight)
        mother_del_1 = models.Mother(
            nic=f"92000{random.randint(1000,9999)}V", 
            hashed_password="123", 
            full_name="Mala (Delivered Normal)", 
            midwife_id=midwives[0].id,
            status="Postnatal", risk_level="Low"
        )
        db.add(mother_del_1)
        db.commit()
        
        del_1 = models.DeliveryRecord(
            mother_id=mother_del_1.id,
            delivery_date=datetime.now(),
            delivery_mode="Normal Vaginal",
            birth_weight=3.2 # Normal
        )
        db.add(del_1)

        mother_del_2 = models.Mother(
            nic=f"93000{random.randint(1000,9999)}V", 
            hashed_password="123", 
            full_name="Chitra (Delivered LSCS & Low Weight)", 
            midwife_id=midwives[1].id,
            status="Postnatal", risk_level="High"
        )
        db.add(mother_del_2)
        db.commit()
        
        del_2 = models.DeliveryRecord(
            mother_id=mother_del_2.id,
            delivery_date=datetime.now(),
            delivery_mode="LSCS",
            birth_weight=2.1 # Low (< 2.5)
        )
        db.add(del_2)
        
        # 4. Create Completed Appointments (For Performance)
        print("Creating Completed Appointments...")
        for _ in range(5):
            appt = models.Appointment(
                midwife_id=midwives[0].id,
                mother_id=mother_early.id,
                date_time=datetime.now(),
                visit_type="Clinic",
                status="Completed"
            )
            db.add(appt)
            
        for _ in range(8):
             appt = models.Appointment(
                midwife_id=midwives[1].id,
                mother_id=mother_late.id,
                date_time=datetime.now(),
                visit_type="Home Visit",
                status="Completed"
            )
             db.add(appt)

        db.commit()
        print("Seeding Complete. Analytics should now have data.")
        
    except Exception as e:
        print(f"Error seeding: {e}")
        db.rollback()
    finally:
        db.close()

if __name__ == "__main__":
    seed_analytics()
