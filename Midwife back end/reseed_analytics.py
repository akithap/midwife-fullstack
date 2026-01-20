from sql_app.database import SessionLocal, engine
from sql_app import models, crud, schemas
from datetime import datetime, timedelta, date
import random
import sys

# Init DB
db = SessionLocal()

def create_moh_and_midwife():
    # 0. Get a Valid Office (Colombo MC District 1)
    office = db.query(models.MOHOffice).filter(models.MOHOffice.district == "Colombo").first() 
    if not office:
        print("ERROR: No MOH Office found for Colombo! Run seed_offices.py first.")
        return None

    # Ensure Admin exists
    if not db.query(models.MOHOfficer).filter(models.MOHOfficer.username == "admin").first():
        print("Creating Admin MOH Officer...")
        crud.create_moh_officer(db, schemas.MOHOfficerCreate(
            username="admin", 
            password="123", 
            full_name="Admin User", 
            moh_area=office.name, 
            moh_office_id=office.id # Link to Office
        ))

    # Ensure Midwife exists
    mw = db.query(models.Midwife).first()
    if not mw:
        print("Creating Default Midwife...")
        mw = crud.create_midwife(db, schemas.MidwifeCreate(
            username="mw1", 
            password="123", 
            full_name="Sister Mary", # Corrected from name
            assigned_moh_area=office.name, 
            moh_office_id=office.id
        ))
    
    # CRITICAL FIX: Ensure assigned_moh_area/office is set
    updated = False
    if not mw.assigned_moh_area:
        mw.assigned_moh_area = office.name
        updated = True
    if not mw.moh_office_id:
        mw.moh_office_id = office.id
        updated = True
        
    if updated:
        db.commit()
        
    return mw

def seed_data():
    print("--- Starting Advanced Analytics Seeding ---")
    
    midwife = create_moh_and_midwife()
    if not midwife:
        midwife = db.query(models.Midwife).first()

    # PHI Areas for Hotspots
    phi_areas = [
        "Kadawatha", "Mahara", "Kiribathgoda", "Kelaniya", "Ragama", 
        "Biyagama", "Wattala", "Ja-Ela", "Kandana", "Gampaha"
    ]

    # --- 1. Risk Hotspots (High Risk Mothers in Clusters) ---
    print("Seeding Risk Hotspots...")
    # Kadawatha gets extra high risk cases
    for i in range(15):
        # Weighted random for area: Kadawatha has higher chance
        area = "Kadawatha" if i < 8 else random.choice(phi_areas)
        
        create_mother_with_record(
            name=f"Mother HR {area} {i}",
            phi_area=area,
            risk_level="High",
            is_pregnant=True
        )

    # --- 2. Top Health Issues ---
    print("Seeding Health Issues...")
    # Diabetes
    for i in range(8):
        create_mother_with_record(f"Mother Diabetes {i}", random.choice(phi_areas), "High", 
                                  diabetes=True, bmi=28.5)
    
    # Teenage Pregnancy (Age < 20)
    for i in range(6):
        create_mother_with_record(f"Teen Mother {i}", random.choice(phi_areas), "High", 
                                  age=17)
                                  
    # Hypertension / Cardiac
    for i in range(5):
        create_mother_with_record(f"Mother Cardiac {i}", random.choice(phi_areas), "High", 
                                  cardiac=True)

    # --- 3. Delivery Forecast (Due in next 30 days) ---
    print("Seeding Delivery Forecast...")
    today = date.today()
    for i in range(7):
        # Due in 5-25 days
        due_date = today + timedelta(days=random.randint(5, 25))
        create_mother_with_record(f"Mother Due Soon {i}", "Mahara", "Low", 
                                  edd=due_date)

    # --- 4. Silent Risk (Defaulters) ---
    print("Seeding Silent Risks (Defaulters)...")
    # Mothers who haven't visited in > 35 days and are High Risk
    for i in range(5):
        m, pr = create_mother_with_record(f"Mother Defaulter {i}", "Kelaniya", "High")
        
        # Create an OLD appointment/visit (e.g., 45 days ago)
        old_date = today - timedelta(days=45)
        
        # We need to simulate that they MISSED their recent one or haven't come.
        # So we just add a very old visit and NO recent visit.
        appt = models.Appointment(
            midwife_id=midwife.id,
            mother_id=m.id,
            date_time=datetime.combine(old_date, datetime.min.time()),
            visit_type="Clinic",
            status="Completed",
            notes="Previous extraction"
        )
        db.add(appt)
        db.commit()
        db.refresh(appt)
        
        visit = models.ANCVisit(
            mother_id=m.id,
            appointment_id=appt.id,
            visit_date=old_date,
            weight_kg=65, bp_systolic=120, bp_diastolic=80
        )
        db.add(visit)
        db.commit()

    # --- 5. Deliveries (This Month) ---
    print("Seeding Deliveries (This Month)...")
    for i in range(4):
        m, pr = create_mother_with_record(f"Mother Delivered {i}", "Ragama", "Low", 
                                          status="Postnatal")
        
        del_date = today - timedelta(days=random.randint(1, 20)) # Delivered recently
        del_rec = models.DeliveryRecord(
            mother_id=m.id,
            delivery_date=del_date,
            delivery_mode="Normal" if i % 2 == 0 else "LSCS",
            birth_weight=3.2,
            created_at=datetime.now()
        )
        db.add(del_rec)
        db.commit()

    print("--- Seeding Complete! ---")


def create_mother_with_record(name, phi_area, risk_level, 
                              diabetes=False, cardiac=False, age=25, bmi=22.0, 
                              edd=None, status="Pregnant", is_pregnant=True):
    
    midwife = db.query(models.Midwife).first()
    
    # Random unique NIC
    suffix = random.randint(1000, 9999)
    nic = f"9{random.randint(50, 99)}{suffix}000V"
    
    # Mother
    m = models.Mother(
        full_name=name,
        nic=nic,
        contact_number=f"077{random.randint(1000000, 9999999)}",
        address=phi_area,
        midwife_id=midwife.id,
        risk_level=risk_level,
        status=status,
        hashed_password="hashed_placeholder",
        pregnancy_start_date=date.today() - timedelta(days=150) # Approx 5 months
    )
    db.add(m)
    db.commit()
    db.refresh(m)
    
    # Pregnancy Record (Detailed Analytics Data)
    if not edd:
        # Default edd 4 months from now
        edd = date.today() + timedelta(days=120)

    pr = models.PregnancyRecord(
        mother_id=m.id,
        phi_area=phi_area,
        moh_division="Colombo",
        moh_district="Colombo",
        moh_province="Western",
        
        risk_diabetes=diabetes,
        risk_cardiac=cardiac,
        mother_age=age,
        bmi=bmi,
        
        risk_age_lt_20_gt_35 = (age < 20 or age > 35),
        
        edd=edd,
        created_at=datetime.now()
    )
    db.add(pr)
    db.commit()
    db.refresh(pr)
    
    return m, pr

if __name__ == "__main__":
    try:
        # Debug: Print fields of Mother
        print("Mother fields:", [c.key for c in models.Mother.__table__.columns])
        seed_data()
    except Exception as e:
        import traceback
        with open("error_log.txt", "w") as f:
            f.write(str(models.Mother.__table__.columns.keys()))
            f.write("\n\n")
            traceback.print_exc(file=f)
        traceback.print_exc()

