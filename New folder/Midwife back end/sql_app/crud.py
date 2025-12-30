import smtplib
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart
import secrets
import string
from typing import List
from sqlalchemy.orm import Session
from sqlalchemy import or_
from . import models, schemas
from sqlalchemy import or_, and_
from passlib.context import CryptContext
from datetime import datetime, timedelta

# --- CONFIGURATION (Replace with your details) ---
# For development, using Gmail App Password is easiest.
# 1. Turn on 2-Step Verification in Google Account.
# 2. Search for "App Passwords" and create one.
SMTP_SERVER = "smtp.gmail.com"
SMTP_PORT = 587
SENDER_EMAIL = "akithaperera6@gmail.com" # <--- REPLACE THIS
SENDER_PASSWORD = "yorzrasoojnanqpd"   # <--- REPLACE THIS (16 chars)

# Setup password hashing
pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")

def get_password_hash(password):
    password_bytes = password.encode('utf-8')
    if len(password_bytes) > 72:
        password_bytes = password_bytes[:72]
    return pwd_context.hash(password_bytes)

def verify_password(plain_password, hashed_password):
    return pwd_context.verify(plain_password, hashed_password)

# --- Helper: Generate Random Password ---
def generate_secure_password(length=10):
    alphabet = string.ascii_letters + string.digits + "!@#$%"
    return ''.join(secrets.choice(alphabet) for i in range(length))

# --- Helper: Send Email ---
def send_credentials_email(to_email, username, password, name):
    try:
        message = MIMEMultipart()
        message["From"] = SENDER_EMAIL
        message["To"] = to_email
        message["Subject"] = "Welcome to Rakawaranaya - Your Credentials"

        body = f"""
        Dear {name},

        Welcome to the Rakawaranaya National Midwife System.
        Your account has been successfully created by the Medical Officer of Health.

        Here are your login credentials for the Mobile Application:
        --------------------------------------------------
        Username: {username}
        Password: {password}
        --------------------------------------------------

        Please log in to the app and change your password immediately.

        Best regards,
        Ministry of Health (MOH)
        """
        
        message.attach(MIMEText(body, "plain"))

        # Connect to Server
        server = smtplib.SMTP(SMTP_SERVER, SMTP_PORT)
        server.starttls() # Secure the connection
        server.login(SENDER_EMAIL, SENDER_PASSWORD)
        server.sendmail(SENDER_EMAIL, to_email, message.as_string())
        server.quit()
        
        print(f"Email sent successfully to {to_email}")
        return True
    except Exception as e:
        print(f"Failed to send email: {e}")
        return False

# ---------------------------------------------------------
# ------------------- MOH OFFICER CRUD --------------------
# ---------------------------------------------------------

def get_moh_officer_by_username(db: Session, username: str):
    return db.query(models.MOHOfficer).filter(models.MOHOfficer.username == username).first()

def create_moh_officer(db: Session, moh: schemas.MOHOfficerCreate):
    hashed_password = get_password_hash(moh.password)
    db_moh = models.MOHOfficer(
        username=moh.username, 
        hashed_password=hashed_password, 
        full_name=moh.full_name,
        moh_area=moh.moh_area,
        email=moh.email
    )
    db.add(db_moh)
    db.commit()
    db.refresh(db_moh)
    return db_moh

# ---------------------------------------------------------
# --------------------- MIDWIFE CRUD ----------------------
# ---------------------------------------------------------

def get_midwife(db: Session, midwife_id: int):
    return db.query(models.Midwife).filter(models.Midwife.id == midwife_id).first()

def get_midwife_by_username(db: Session, username: str):
    return db.query(models.Midwife).filter(models.Midwife.username == username).first()

def update_midwife_password(db: Session, midwife_id: int, password_data: schemas.PasswordChange):
    db_midwife = get_midwife(db, midwife_id)
    if not db_midwife:
        return False
        
    if not verify_password(password_data.old_password, db_midwife.hashed_password):
        return False 
        
    new_hash = get_password_hash(password_data.new_password)
    db_midwife.hashed_password = new_hash
    db.add(db_midwife)
    db.commit()
    db.refresh(db_midwife)
    return True

# Legacy function (Mobile App Registration - if needed)
def create_midwife(db: Session, midwife: schemas.MidwifeCreate):
    hashed_password = get_password_hash(midwife.password)
    db_midwife = models.Midwife(
        username=midwife.username, 
        hashed_password=hashed_password, 
        full_name=midwife.full_name
    )
    db.add(db_midwife)
    db.commit()
    db.refresh(db_midwife)
    return db_midwife

# --- WEB PORTAL: Full Midwife Registration with Auto-Credentials ---
def register_full_midwife(db: Session, midwife_data: schemas.MidwifeRegistration):
    # 1. Auto-set Username
    final_username = midwife_data.nic
    
    # 2. Check for ANY conflict (NIC, Username, Email, Phone)
    existing_midwife = db.query(models.Midwife).filter(
        or_(
            models.Midwife.username == final_username,
            models.Midwife.nic == midwife_data.nic,
            models.Midwife.email == midwife_data.email,
            models.Midwife.phone_number == midwife_data.phone_number
        )
    ).first()

    if existing_midwife:
        # Ideally, you'd return WHICH field failed, but returning None triggers the 400 error
        return None 
    
    # 3. Generate Password
    generated_password = generate_secure_password()
    hashed_password = get_password_hash(generated_password)
    
    # 4. Create DB Object
    db_midwife = models.Midwife(
        username=final_username,
        hashed_password=hashed_password,
        full_name=midwife_data.full_name,
        nic=midwife_data.nic,
        date_of_birth=midwife_data.date_of_birth,
        phone_number=midwife_data.phone_number,
        email=midwife_data.email,
        residential_address=midwife_data.residential_address,
        slmc_reg_no=midwife_data.slmc_reg_no,
        service_grade=midwife_data.service_grade,
        assigned_moh_area=midwife_data.assigned_moh_area,
        is_active=midwife_data.is_active
    )
    
    db.add(db_midwife)
    db.commit()
    db.refresh(db_midwife)
    
    # 5. Send Email
    print(f"\n[CREDENTIALS GENERATED] ...") 
    if midwife_data.email:
        send_credentials_email(midwife_data.email, final_username, generated_password, midwife_data.full_name)
    
    return db_midwife
# ---------------------------------------------------------
# ---------------------- MOTHER CRUD ----------------------
# ---------------------------------------------------------

def get_mother_by_nic(db: Session, nic: str):
    return db.query(models.Mother).filter(models.Mother.nic == nic).first()

def get_mother(db: Session, mother_id: int):
    return db.query(models.Mother).filter(models.Mother.id == mother_id).first()

def get_mothers_by_midwife(db: Session, midwife_id: int, skip: int = 0, limit: int = 100, search: str = None):
    query = db.query(models.Mother).filter(models.Mother.midwife_id == midwife_id)
    
    if search:
        search_format = f"%{search}%"
        query = query.filter(
            or_(
                models.Mother.full_name.like(search_format),
                models.Mother.nic.like(search_format)
            )
        )
        
    return query.offset(skip).limit(limit).all()

def create_mother(db: Session, mother: schemas.MotherCreate, midwife_id: int):
    hashed_password = get_password_hash(mother.password)
    db_mother = models.Mother(
        full_name=mother.full_name,
        nic=mother.nic,
        address=mother.address,
        contact_number=mother.contact_number,
        hashed_password=hashed_password,
        midwife_id=midwife_id
    )
    db.add(db_mother)
    db.commit()
    db.refresh(db_mother)
    return db_mother

def update_mother(db: Session, mother_id: int, mother_update: schemas.MotherUpdate):
    db_mother = get_mother(db, mother_id)
    if not db_mother:
        return None
    
    update_data = mother_update.dict(exclude_unset=True)
    for key, value in update_data.items():
        setattr(db_mother, key, value)

    db.add(db_mother)
    db.commit()
    db.refresh(db_mother)
    return db_mother

def update_mother_password(db: Session, mother_id: int, password_data: schemas.PasswordChange):
    db_mother = get_mother(db, mother_id)
    if not db_mother:
        return False
        
    if not verify_password(password_data.old_password, db_mother.hashed_password):
        return False 
        
    new_hash = get_password_hash(password_data.new_password)
    db_mother.hashed_password = new_hash
    db.add(db_mother)
    db.commit()
    db.refresh(db_mother)
    return True

# ---------------------------------------------------------
# ------------------ HEALTH RECORDS CRUD ------------------
# ---------------------------------------------------------

def create_health_record(db: Session, record: schemas.HealthRecordCreate, mother_id: int):
    db_record = models.HealthRecord(**record.dict(), mother_id=mother_id)
    db.add(db_record)
    db.commit()
    db.refresh(db_record)
    return db_record

def get_health_records_for_mother(db: Session, mother_id: int, skip: int = 0, limit: int = 100):
    return db.query(models.HealthRecord).filter(models.HealthRecord.mother_id == mother_id).offset(skip).limit(limit).all()

# ---------------------------------------------------------
# ----------------- PREGNANCY RECORDS CRUD ----------------
# ---------------------------------------------------------

def create_pregnancy_record(db: Session, record: schemas.PregnancyRecordCreate, mother_id: int):
    db_record = models.PregnancyRecord(**record.dict(), mother_id=mother_id)
    db.add(db_record)
    db.commit()
    db.refresh(db_record)
    return db_record

def get_pregnancy_records_for_mother(db: Session, mother_id: int):
    return db.query(models.PregnancyRecord).filter(models.PregnancyRecord.mother_id == mother_id).all()

# ---------------------------------------------------------
# ----------------- DELIVERY RECORDS CRUD -----------------
# ---------------------------------------------------------

def create_delivery_record(db: Session, record: schemas.DeliveryRecordCreate, mother_id: int):
    db_record = models.DeliveryRecord(**record.dict(), mother_id=mother_id)
    db.add(db_record)
    db.commit()
    db.refresh(db_record)
    return db_record

def get_delivery_records_for_mother(db: Session, mother_id: int):
    return db.query(models.DeliveryRecord).filter(models.DeliveryRecord.mother_id == mother_id).all()

# ---------------------------------------------------------
# ------------------ ANTENATAL PLAN CRUD ------------------
# ---------------------------------------------------------

def create_antenatal_plan(db: Session, plan: schemas.AntenatalPlanCreate, mother_id: int):
    db_plan = models.AntenatalPlan(**plan.dict(), mother_id=mother_id)
    db.add(db_plan)
    db.commit()
    db.refresh(db_plan)
    return db_plan

def get_antenatal_plans_for_mother(db: Session, mother_id: int):
    return db.query(models.AntenatalPlan).filter(models.AntenatalPlan.mother_id == mother_id).all()

# ---------------------------------------------------------
# -------------------- APPOINTMENTS CRUD ------------------
# ---------------------------------------------------------

def create_appointment(db: Session, appointment: schemas.AppointmentCreate, midwife_id: int, mother_id: int):
    db_appointment = models.Appointment(
        **appointment.dict(), 
        midwife_id=midwife_id, 
        mother_id=mother_id,
        status="Scheduled"
    )
    db.add(db_appointment)
    db.commit()
    db.refresh(db_appointment)
    return db_appointment

def get_appointments_by_mother(db: Session, mother_id: int):
    return db.query(models.Appointment).filter(models.Appointment.mother_id == mother_id).order_by(models.Appointment.date_time.asc()).all()

def get_appointments_by_midwife(db: Session, midwife_id: int, start_date=None, end_date=None):
    query = db.query(models.Appointment).filter(models.Appointment.midwife_id == midwife_id)
    if start_date:
        query = query.filter(models.Appointment.date_time >= start_date)
    if end_date:
        query = query.filter(models.Appointment.date_time <= end_date)
    return query.order_by(models.Appointment.date_time.asc()).all()

def get_mother_count_by_midwife(db: Session, midwife_id: int):
    return db.query(models.Mother).filter(models.Mother.midwife_id == midwife_id).count()

def get_todays_appointments_count(db: Session, midwife_id: int):
    today_start = datetime.now().replace(hour=0, minute=0, second=0, microsecond=0)
    today_end = today_start + timedelta(days=1)
    return db.query(models.Appointment).filter(
        models.Appointment.midwife_id == midwife_id,
        models.Appointment.date_time >= today_start,
        models.Appointment.date_time < today_end,
        models.Appointment.status == "Completed"
    ).count()

def update_appointment(db: Session, appointment_id: int, update_data: schemas.AppointmentUpdate):
    db_appt = db.query(models.Appointment).filter(models.Appointment.id == appointment_id).first()
    if db_appt:
        data_dict = update_data.dict(exclude_unset=True)
        for key, value in data_dict.items():
            setattr(db_appt, key, value)
        db.commit()
        db.refresh(db_appt)
    return db_appt

def delete_appointment(db: Session, appointment_id: int):
    db_appt = db.query(models.Appointment).filter(models.Appointment.id == appointment_id).first()
    if db_appt:
        db.delete(db_appt)
        db.commit()
        return True
    return False

# --- ANC Visits ---
def create_anc_visit(db: Session, visit: schemas.ANCVisitCreate):
    db_visit = models.ANCVisit(**visit.dict())
    db.add(db_visit)
    db.commit()
    db.refresh(db_visit)
    return db_visit

def get_anc_visit_by_appointment(db: Session, appointment_id: int):
    return db.query(models.ANCVisit).filter(models.ANCVisit.appointment_id == appointment_id).first()

def get_mother_anc_visits(db: Session, mother_id: int):
    return db.query(models.ANCVisit).filter(models.ANCVisit.mother_id == mother_id).order_by(models.ANCVisit.visit_date).all()

# --- PNC Visits ---
def create_pnc_visit(db: Session, visit: schemas.PNCVisitCreate):
    db_visit = models.PNCVisit(**visit.dict())
    db.add(db_visit)
    db.commit()
    db.refresh(db_visit)
    return db_visit

def get_pnc_visit_by_appointment(db: Session, appointment_id: int):
    return db.query(models.PNCVisit).filter(models.PNCVisit.appointment_id == appointment_id).first()

def get_mother_pnc_visits(db: Session, mother_id: int):
    return db.query(models.PNCVisit).filter(models.PNCVisit.mother_id == mother_id).order_by(models.PNCVisit.visit_date).all()



# ---------------------------------------------------------
# ------------------- RISK MANAGEMENT CRUD ----------------
# ---------------------------------------------------------

def get_risk_stats(db: Session, midwife_id: int):
    # Get all active mothers for this midwife
    mothers = db.query(models.Mother).filter(
        models.Mother.midwife_id == midwife_id,
        models.Mother.status.in_(["Pregnant", "Postnatal"]) # Only active cases
    ).all()
    
    stats = {
        "total_high_risk": 0,
        "diabetes": 0,
        "cardiac": 0,
        "age_risk": 0,
        "history_pph": 0,
        "fifth_pregnancy": 0
    }
    
    for mother in mothers:
        if mother.risk_level == "High":
            stats["total_high_risk"] += 1
            
        # Check latest pregnancy record for specific risks
        preg_record = get_pregnancy_record_by_mother(db, mother.id)
        if preg_record:
            if preg_record.risk_diabetes:
                stats["diabetes"] += 1
            if preg_record.risk_cardiac:
                stats["cardiac"] += 1
            if preg_record.risk_age_lt_20_gt_35:
                stats["age_risk"] += 1
            if preg_record.risk_history_pph:
                stats["history_pph"] += 1
            if preg_record.risk_5th_pregnancy:
                stats["fifth_pregnancy"] += 1
                
    return stats

def get_mothers_by_risk(db: Session, midwife_id: int, risk_type: str):
    # risk_type can be: "high_risk", "diabetes", "cardiac", "age", "pph", "gravidity"
    
    base_query = db.query(models.Mother).filter(
        models.Mother.midwife_id == midwife_id,
        models.Mother.status.in_(["Pregnant", "Postnatal"])
    )
    
    if risk_type == "high_risk":
        return base_query.filter(models.Mother.risk_level == "High").all()
        
    # For specific flags, we need to join with PregnancyRecord
    # Note: This simple join works if there is only 1 pregnancy record per mother or we want any matching
    # But get_pregnancy_record_by_mother logic is "latest". 
    # For MVP SQL query:
    query = base_query.join(models.PregnancyRecord).filter(models.PregnancyRecord.mother_id == models.Mother.id)
    


    if risk_type == "diabetes":
        query = query.filter(models.PregnancyRecord.risk_diabetes == True)
    elif risk_type == "cardiac":
        query = query.filter(models.PregnancyRecord.risk_cardiac == True)
    elif risk_type == "age":
        query = query.filter(models.PregnancyRecord.risk_age_lt_20_gt_35 == True)
    elif risk_type == "pph":
        query = query.filter(models.PregnancyRecord.risk_history_pph == True)
    elif risk_type == "gravidity":
        query = query.filter(models.PregnancyRecord.risk_5th_pregnancy == True)
    elif risk_type == "malaria":
        query = query.filter(models.PregnancyRecord.risk_malaria == True)
    elif risk_type == "renal":
        query = query.filter(models.PregnancyRecord.risk_renal == True)
        
    results = query.all()
    
    # Enrich with Age, POA, and Active Risks
    today = datetime.now().date()
    for mother in results:
        mother.active_risks = [] # Initialize list
        
        # 1. Get Age & Risks from latest pregnancy record
        preg_record = get_pregnancy_record_by_mother(db, mother.id)
        if preg_record:
            if preg_record.mother_age:
                mother.age = preg_record.mother_age
            
            # Populate Active Risks List
            if preg_record.risk_age_lt_20_gt_35: mother.active_risks.append("Age Risk")
            if preg_record.risk_5th_pregnancy: mother.active_risks.append("Grand Multipara")
            if preg_record.risk_birth_interval_lt_1yr: mother.active_risks.append("Short Birth Interval")
            if preg_record.risk_history_pph: mother.active_risks.append("History of PPH")
            if preg_record.risk_diabetes: mother.active_risks.append("Diabetes")
            if preg_record.risk_malaria: mother.active_risks.append("History of Malaria")
            if preg_record.risk_cardiac: mother.active_risks.append("Heart Disease")
            if preg_record.risk_renal: mother.active_risks.append("Renal Disease")
        
        # 2. Calculate POA
        if mother.pregnancy_start_date:
            delta = today - mother.pregnancy_start_date
            weeks = delta.days // 7
            days = delta.days % 7
            mother.poa = f"{weeks} Weeks"
            
    return results




def create_leave_request(db: Session, leave: schemas.LeaveRequestCreate, midwife_id: int):
    # Check for overlapping requests
    # Logic: (StartA <= EndB) and (EndA >= StartB)
    overlap = db.query(models.LeaveRequest).filter(
        models.LeaveRequest.midwife_id == midwife_id,
        models.LeaveRequest.status != "Rejected",  # Ignore rejected ones
        and_(
            models.LeaveRequest.start_date <= leave.end_date,
            models.LeaveRequest.end_date >= leave.start_date
        )
    ).first()

    if overlap:
        return None

    db_leave = models.LeaveRequest(
        **leave.dict(),
        midwife_id=midwife_id,
        status="Pending"
    )
    db.add(db_leave)
    db.commit()
    db.refresh(db_leave)
    return db_leave

def get_leave_requests_by_midwife(db: Session, midwife_id: int):
    return db.query(models.LeaveRequest).filter(models.LeaveRequest.midwife_id == midwife_id).all()

def get_all_leave_requests(db: Session):
    return db.query(models.LeaveRequest).all()

    return db_leave

# ---------------------------------------------------------
# ---------------- SMART CARE PLAN LOGIC ------------------
# ---------------------------------------------------------

def start_pregnancy(db: Session, mother_id: int, data: schemas.PregnancyRecordCreate, past_history: List[schemas.PastPregnancyCreate], risk_level: str):
    # 1. Get Mother
    db_mother = get_mother(db, mother_id)
    if not db_mother:
        return None
    
    # 2. Create Current Pregnancy Record (H 512 Data)
    db_record = models.PregnancyRecord(**data.dict(), mother_id=mother_id, created_at=datetime.now())
    db.add(db_record)

    # 3. Create Past Pregnancy Records (The Table)
    # First, clear old ones if any (to avoid dups on retry)
    db.query(models.PastPregnancy).filter(models.PastPregnancy.mother_id == mother_id).delete()
    
    for item in past_history:
        db_past = models.PastPregnancy(**item.dict(), mother_id=mother_id)
        db.add(db_past)
    
    # 4. Update Mother Status & Key Dates
    db_mother.status = "Pregnant"
    db_mother.risk_level = risk_level
    
    # Sync LMP/EDD from the record to the Mother table for quick access
    # Note: data.lrmp is a 'date' object from pydantic, models expect date object too (we updated models)
    if data.lrmp:
        db_mother.pregnancy_start_date = data.lrmp
    
    if data.edd:
        db_mother.delivery_date = data.edd
    elif data.lrmp:
         # Fallback EDD calculation if not provided in record
         db_mother.delivery_date = data.lrmp + timedelta(days=280)

    # 5. Generate Appointments
    # Clear any existing future Scheduled appointments
    db.query(models.Appointment).filter(
        models.Appointment.mother_id == mother_id, 
        models.Appointment.status == "Scheduled"
    ).delete()

    schedule_weeks = []
    if risk_level == "High":
        # Monthly from Month 3 to 9 (approx weeks 12, 16, 20, 24, 28, 32, 36, 40)
        schedule_weeks = [12, 16, 20, 24, 28, 32, 36, 40]
    else:
        # Standard: Week 12, 26, 36 (Simplified Trimester Plan)
        schedule_weeks = [12, 26, 36]

    base_date = data.lrmp if data.lrmp else datetime.now().date() # Fallback

    for week in schedule_weeks:
        appt_date = base_date + timedelta(weeks=week)
        # Check if date is in past? Maybe skip.
        if appt_date > datetime.now().date():
             db_appt = models.Appointment(
                 mother_id=mother_id,
                 midwife_id=db_mother.midwife_id, # REQUIRED
                 date_time=datetime.combine(appt_date, datetime.min.time()),
                 visit_type="Clinic", # Maps to 'visit_type', not 'type'
                 status="Scheduled",
                 notes=f"Generated Visit (Week {week})" # Maps to 'notes', not 'remarks'
             )
             db.add(db_appt)
    
    db.commit()
    db.refresh(db_mother)
    return db_mother

def get_pregnancy_record_by_mother(db: Session, mother_id: int):
    # Returns the most recent pregnancy record (assuming active pregnancy)
    # Since we only have one active pregnancy logic for now, we get the latest
    return db.query(models.PregnancyRecord)\
             .filter(models.PregnancyRecord.mother_id == mother_id)\
             .order_by(models.PregnancyRecord.created_at.desc())\
             .first()

def get_past_pregnancies_by_mother(db: Session, mother_id: int):
    return db.query(models.PastPregnancy).filter(models.PastPregnancy.mother_id == mother_id).all()

def update_pregnancy_record(db: Session, mother_id: int, data: schemas.PregnancyRecordCreate, past_history: List[schemas.PastPregnancyCreate], risk_level: str):
    # 1. Get Existing Record
    db_record = get_pregnancy_record_by_mother(db, mother_id)
    if not db_record:
        # If no record exists, simpler to just "Start" it, but let's just create one here
        # This handles the case if they are editing a record that somehow was deleted or didn't exist properly
        return start_pregnancy(db, mother_id, data, past_history, risk_level)

    # 2. Update Basic Fields
    record_dict = data.dict(exclude_unset=True)
    for key, value in record_dict.items():
        setattr(db_record, key, value)
    
    # 3. Update Past History (Delete All & Insert New - Simplest Strategy)
    db.query(models.PastPregnancy).filter(models.PastPregnancy.mother_id == mother_id).delete()
    for item in past_history:
        db_past = models.PastPregnancy(**item.dict(), mother_id=mother_id)
        db.add(db_past)

    # 4. Update Mother Metadata (Risk, Status, Dates)
    db_mother = get_mother(db, mother_id)
    if db_mother:
        db_mother.risk_level = risk_level
        # Only update status if it's eligible/postnatal? No, keep it Pregnant if editing record.
        # But allow risk level change.
        if data.lrmp:
            db_mother.pregnancy_start_date = data.lrmp
        if data.edd:
            db_mother.delivery_date = data.edd
        elif data.lrmp:
            db_mother.delivery_date = data.lrmp + timedelta(days=280)

    db.commit()
    db.refresh(db_mother)
    return db_mother


def report_delivery(db: Session, mother_id: int, delivery_date: str):
    # 1. Get Mother
    db_mother = get_mother(db, mother_id)
    if not db_mother:
        return None

    # 2. Parse Date
    try:
        dev_date = datetime.strptime(delivery_date, "%Y-%m-%d").date()
    except ValueError:
        dev_date = datetime.strptime(delivery_date, "%Y-%m-%dT%H:%M:%S.%f").date()

    # 3. Update Status
    db_mother.status = "Postnatal"
    db_mother.delivery_date = dev_date
    
    # 4. Cancel Remaining ANC Appointments
    db.query(models.Appointment).filter(
        models.Appointment.mother_id == mother_id,
        models.Appointment.visit_type == "ANC",
        models.Appointment.status == "Scheduled"
    ).delete()

    # 5. Generate PNC Schedule
    # Visit 1 (Days 1–5) -> Day 3
    # Visit 2 (Days 5–10) -> Day 7
    # Visit 3 (Days 11–28) -> Day 14
    # Visit 4 (Around Day 42) -> Day 42
    pnc_offsets = [3, 7, 14, 42]
    
    for i, day_offset in enumerate(pnc_offsets):
        appt_date = dev_date + timedelta(days=day_offset)
        db_appt = models.Appointment(
            midwife_id=db_mother.midwife_id,
            mother_id=mother_id,
            date_time=datetime.combine(appt_date, datetime.min.time()),
            visit_type="PNC",
            status="Scheduled",
            notes=f"PNC Visit {i+1} (Day {day_offset})"
        )
        db.add(db_appt)

    db.commit()
    db.refresh(db_mother)
    return db_mother
            