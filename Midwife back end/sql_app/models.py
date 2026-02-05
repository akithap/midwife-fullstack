from sqlalchemy import Boolean, Column, ForeignKey, Integer, String, Date, TEXT, Time, DECIMAL, DateTime
from sqlalchemy.orm import relationship
from .database import Base
from datetime import datetime

# --- UPDATED MODEL: Midwife ---
class Midwife(Base):
    __tablename__ = "midwives"
    id = Column(Integer, primary_key=True, index=True)
    username = Column(String(255), unique=True, index=True, nullable=False)
    hashed_password = Column(String(255), nullable=False)
    full_name = Column(String(255))
    
    # NEW FIELDS FROM WEB FORM
    nic = Column(String(20))
    date_of_birth = Column(Date)
    phone_number = Column(String(20))
    email = Column(String(255))
    residential_address = Column(TEXT)
    slmc_reg_no = Column(String(50))
    service_grade = Column(String(50))
    
    # Structure Fix: Link to Office ID
    moh_office_id = Column(Integer, ForeignKey("moh_offices.id"), nullable=True)
    assigned_moh_area = Column(String(100)) # Keep for legacy check
    
    is_active = Column(Boolean, default=True) # For suspension
    created_at = Column(DateTime, default=datetime.utcnow)
    
    mothers = relationship("Mother", back_populates="owner")
    appointments = relationship("Appointment", back_populates="midwife")

    office = relationship("MOHOffice", back_populates="midwives")

class Mother(Base):
    __tablename__ = "mothers"
    id = Column(Integer, primary_key=True, index=True)
    full_name = Column(String(255), nullable=False)
    nic = Column(String(20), unique=True)
    address = Column(TEXT)
    contact_number = Column(String(20))
    hashed_password = Column(String(255), nullable=False)
    
    # Geolocation
    latitude = Column(DECIMAL(9, 6), nullable=True)
    longitude = Column(DECIMAL(9, 6), nullable=True)

    midwife_id = Column(Integer, ForeignKey("midwives.id"), nullable=False)
    
    # Smart Care Plan Fields
    status = Column(String(50), default="Eligible") # Eligible, Pregnant, Postnatal, Completed
    risk_level = Column(String(50), default="Low") # Low, High
    pregnancy_start_date = Column(Date) # LMP
    delivery_date = Column(Date) # Actual Delivery Date
    
    owner = relationship("Midwife", back_populates="mothers")
    health_records = relationship("HealthRecord", back_populates="mother")
    pregnancy_records = relationship("PregnancyRecord", back_populates="mother")
    past_pregnancies = relationship("PastPregnancy", back_populates="mother")
    delivery_records = relationship("DeliveryRecord", back_populates="mother")
    antenatal_plans = relationship("AntenatalPlan", back_populates="mother")
    appointments = relationship("Appointment", back_populates="mother")
    appointments = relationship("Appointment", back_populates="mother")
    anc_visits = relationship("ANCVisit", back_populates="mother")
    pnc_visits = relationship("PNCVisit", back_populates="mother")
    created_at = Column(DateTime, default=datetime.utcnow)

class ANCVisit(Base):
    __tablename__ = "anc_visits"
    id = Column(Integer, primary_key=True, index=True)
    mother_id = Column(Integer, ForeignKey("mothers.id"), nullable=False)
    appointment_id = Column(Integer, ForeignKey("appointments.id"), unique=True, nullable=False)
    
    # 9 Clinical Fields
    visit_date = Column(Date, nullable=False)
    poa_weeks = Column(String(20)) # Period of Amenorrhea
    weight_kg = Column(DECIMAL(5, 2))
    bp_systolic = Column(Integer)
    bp_diastolic = Column(Integer)
    pallor = Column(String(50)) # Present/Absent
    oedema = Column(String(50)) # Absent/+/++
    fundal_height_cm = Column(DECIMAL(5, 2))
    fetal_lie = Column(String(50)) # Cephalic/Breech/Transverse
    fetal_heart_sound = Column(String(50)) # + / - / 140bpm
    fetal_movement = Column(String(50)) # + / -
    urine_sugar = Column(String(50)) # Neg / + / ++
    urine_albumin = Column(String(50)) # Neg / + / ++
    
    # Health Education (Yes/No)
    nutrient_supplements = Column(Boolean, default=False) # Iron/Calcium
    counsel_nutrition = Column(Boolean, default=False)
    counsel_danger_signs = Column(Boolean, default=False)
    counsel_family_planning = Column(Boolean, default=False)
    counsel_breastfeeding = Column(Boolean, default=False)
    counsel_delivery_plan = Column(Boolean, default=False)
    counsel_emergency_prep = Column(Boolean, default=False)
    counsel_postnatal_care = Column(Boolean, default=False) # Last Trimester
    
    mother = relationship("Mother", back_populates="anc_visits")
    appointment = relationship("Appointment", back_populates="anc_visit")

class PNCVisit(Base):
    __tablename__ = "pnc_visits"
    id = Column(Integer, primary_key=True, index=True)
    mother_id = Column(Integer, ForeignKey("mothers.id"), nullable=False)
    appointment_id = Column(Integer, ForeignKey("appointments.id"), unique=True, nullable=False)
    
    visit_date = Column(Date, nullable=False)
    
    # --- Mother Fields ---
    temperature = Column(DECIMAL(4, 1)) # e.g. 37.0
    pallor = Column(String(50)) # Present/Absent/Clinically Anemic
    breast_condition = Column(String(50)) # Normal / Cracked / Engorged / Infected
    uterus_involution = Column(String(50)) # Contracted / Boggy / Fundal Height cm
    lochia_character = Column(String(50)) # Red / White / Pink
    lochia_smell = Column(String(50)) # Normal / Foul
    perineum_infection = Column(Boolean, default=False) # True if infected/gaping
    fissure_infection = Column(Boolean, default=False) # For CS wound or episiotomy
    
    vitamin_a_given = Column(Boolean, default=False)
    family_planning_method = Column(String(50)) # None, Pill, Implant, LRT
    referred_to_hospital = Column(Boolean, default=False)
    
    # --- Baby Fields ---
    baby_color = Column(String(50)) # Pink, Pale, Icteric (Yellow), Blue
    cord_status = Column(String(50)) # Normal, Bleeding, Infected/Pus
    breastfeeding = Column(String(50)) # Establishing well, Poor sucking
    baby_stool = Column(String(50)) # Passed, Not passed
    baby_weight = Column(DECIMAL(5, 2))
    
    mother = relationship("Mother", back_populates="pnc_visits")
    appointment = relationship("Appointment", back_populates="pnc_visit")

class HealthRecord(Base):
    __tablename__ = "health_records"
    id = Column(Integer, primary_key=True, index=True)
    visit_date = Column(DateTime, nullable=False)
    weight_kg = Column(DECIMAL(5, 2))
    blood_pressure = Column(String(20))
    notes = Column(TEXT)
    mother_id = Column(Integer, ForeignKey("mothers.id"), nullable=False)
    mother = relationship("Mother", back_populates="health_records")

class PregnancyRecord(Base):
    __tablename__ = "pregnancy_records"
    id = Column(Integer, primary_key=True, index=True)
    mother_id = Column(Integer, ForeignKey("mothers.id"), nullable=False)
    created_at = Column(DateTime)
    
    # Registration Details
    registration_no = Column(String(50))
    registration_date = Column(Date)
    registration_place = Column(String(100))
    family_register_no = Column(String(50))
    village_division = Column(String(100))
    moh_division = Column(String(100))
    moh_province = Column(String(100)) # NEW: Province
    moh_district = Column(String(100)) # NEW: District
    phi_area = Column(String(100))
    
    # Personal Info (Mother)
    mother_age = Column(Integer)
    mother_education = Column(String(100))
    mother_occupation = Column(String(100))
    distance_to_clinic = Column(DECIMAL(5, 2))
    
    # Personal Info (Husband)
    husband_name = Column(String(255))
    husband_age = Column(Integer)
    husband_education = Column(String(100))
    husband_occupation = Column(String(100))
    
    # Relationship/Marriage
    married_age = Column(Integer)
    consanguinity = Column(Boolean, default=False)
    
    # Vitals & Pre-Conditions
    bmi = Column(DECIMAL(5, 2))
    height_cm = Column(DECIMAL(5, 2))
    weight_kg = Column(DECIMAL(5, 2)) # Pre-pregnancy weight
    blood_group = Column(String(10))
    
    rubella_immunization = Column(Boolean, default=False)
    pre_pregnancy_screening = Column(Boolean, default=False)
    folic_acid = Column(Boolean, default=False)
    history_of_subfertility = Column(Boolean, default=False)
    
    # Family History
    family_diabetes = Column(Boolean, default=False)
    family_hypertension = Column(Boolean, default=False)
    family_twins = Column(Boolean, default=False)
    other_family_history = Column(TEXT)

    # Current Pregnancy
    gravidity = Column(Integer) # G
    parity = Column(Integer) # P
    num_living_children = Column(Integer)
    age_of_youngest_child = Column(String(50))
    
    lrmp = Column(Date)
    edd = Column(Date)
    us_corrected_edd = Column(Date)
    poa_at_registration = Column(String(50))
    
    # Risk Factors Checklist (Booleans for simplicity in Checklist)
    risk_age_lt_20_gt_35 = Column(Boolean, default=False)
    risk_5th_pregnancy = Column(Boolean, default=False)
    risk_birth_interval_lt_1yr = Column(Boolean, default=False)
    risk_history_pph = Column(Boolean, default=False)
    
    risk_diabetes = Column(Boolean, default=False)
    risk_malaria = Column(Boolean, default=False)
    risk_cardiac = Column(Boolean, default=False)
    risk_renal = Column(Boolean, default=False)
    
    other_risk_factors = Column(TEXT)

    # Note: Past Obstetric History needs a separate table (One-to-Many) or JSON.
    # For now, let's keep it simple or store as JSON string if complex.
    # Let's create a separate table for Past Pregnancies? 
    # Decision: For MVP, maybe JSON string or 6 fixed columns?
    # Let's stick to the current basic Past History fields unless user asks for tabular entry.
    
    created_at = Column(DateTime)
    
    # Relationship
    mother = relationship("Mother", back_populates="pregnancy_records")

class PastPregnancy(Base):
    __tablename__ = "past_pregnancies"
    id = Column(Integer, primary_key=True, index=True)
    mother_id = Column(Integer, ForeignKey("mothers.id"), nullable=False)
    
    # H 512 Table Columns
    pregnancy_order = Column(String(10)) # G1, G2...
    outcome = Column(String(50)) # Live, Still, Abortion
    delivery_mode = Column(String(50)) # Normal, LSCS, Forceps
    place_of_delivery = Column(String(100))
    complications = Column(TEXT)
    birth_weight = Column(DECIMAL(5, 2))
    sex = Column(String(10))
    age_if_alive = Column(String(50))
    
    mother = relationship("Mother", back_populates="past_pregnancies")

class DeliveryRecord(Base):
    __tablename__ = "delivery_records"
    id = Column(Integer, primary_key=True, index=True)
    mother_id = Column(Integer, ForeignKey("mothers.id"), nullable=False)
    created_at = Column(DateTime)
    
    # Delivery
    delivery_date = Column(DateTime)
    delivery_mode = Column(String(50))
    episiotomy = Column(Boolean, default=False)
    temp_normal = Column(Boolean, default=False)
    vaginal_exam_done = Column(Boolean, default=False)
    maternal_complications = Column(TEXT)
    wound_infection = Column(Boolean, default=False)
    family_planning_discussed = Column(Boolean, default=False)
    danger_signals_explained = Column(Boolean, default=False)
    breast_feeding_established = Column(Boolean, default=False)
    
    # Baby
    birth_weight = Column(DECIMAL(5, 2))
    poa_at_birth = Column(Integer)
    apgar_score = Column(Integer)
    abnormalities = Column(TEXT)
    
    # Discharge
    vitamin_a_given = Column(Boolean, default=False)
    rubella_given = Column(Boolean, default=False)
    anti_d_given = Column(Boolean, default=False)
    diagnosis_card_given = Column(Boolean, default=False)
    chdr_completed = Column(Boolean, default=False)
    prescription_given = Column(Boolean, default=False)
    referred_to_phm = Column(Boolean, default=False)
    special_notes = Column(TEXT)
    discharge_date = Column(DateTime)
    
    mother = relationship("Mother", back_populates="delivery_records")

class AntenatalPlan(Base):
    __tablename__ = "antenatal_plans"
    id = Column(Integer, primary_key=True, index=True)
    mother_id = Column(Integer, ForeignKey("mothers.id"), nullable=False)
    created_at = Column(DateTime)
    
    next_clinic_date = Column(DateTime)
    
    class_1st_date = Column(DateTime)
    class_1st_husband = Column(Boolean, default=False)
    class_1st_wife = Column(Boolean, default=False)
    class_1st_other = Column(String(100))
    
    class_2nd_date = Column(DateTime)
    class_2nd_husband = Column(Boolean, default=False)
    class_2nd_wife = Column(Boolean, default=False)
    class_2nd_other = Column(String(100))
    
    class_3rd_date = Column(DateTime)
    class_3rd_husband = Column(Boolean, default=False)
    class_3rd_wife = Column(Boolean, default=False)
    class_3rd_other = Column(String(100))
    
    book_antenatal_issued = Column(DateTime)
    book_antenatal_returned = Column(DateTime)
    book_breastfeeding_issued = Column(DateTime)
    book_breastfeeding_returned = Column(DateTime)
    book_eccd_issued = Column(DateTime)
    book_eccd_returned = Column(DateTime)
    leaflet_fp_issued = Column(DateTime)
    leaflet_fp_returned = Column(DateTime)
    
    emergency_contact_name = Column(String(255))
    emergency_contact_address = Column(TEXT)
    emergency_contact_phone = Column(String(20))
    moh_office_phone = Column(String(20))
    phm_phone = Column(String(20))
    grama_niladari_div = Column(String(255))
    
    mother = relationship("Mother", back_populates="antenatal_plans")

    mother = relationship("Mother", back_populates="antenatal_plans")

# --- NEW MODEL: MOH Office (The Unit) ---
class MOHOffice(Base):
    __tablename__ = "moh_offices"
    id = Column(Integer, primary_key=True, index=True)
    name = Column(String(255), unique=True, index=True) # e.g., "Colombo MC District 1"
    district = Column(String(100)) # e.g., "Colombo"
    province = Column(String(100)) # e.g., "Western Province"
    
    officers = relationship("MOHOfficer", back_populates="office")
    midwives = relationship("Midwife", back_populates="office")

# --- UPDATED MODEL: MOH Officer ---
class MOHOfficer(Base):
    __tablename__ = "moh_officers"
    id = Column(Integer, primary_key=True, index=True)
    username = Column(String(255), unique=True, index=True, nullable=False)
    hashed_password = Column(String(255), nullable=False)
    full_name = Column(String(255))
    
    # Structure Fix: Link to Office ID instead of just String
    moh_office_id = Column(Integer, ForeignKey("moh_offices.id"), nullable=True) 
    moh_area = Column(String(100)) # Keep for legacy/backward compat for now
    
    email = Column(String(255))
    
    office = relationship("MOHOffice", back_populates="officers")

# --- NEW: Appointment Model ---
class Appointment(Base):
    __tablename__ = "appointments"
    
    id = Column(Integer, primary_key=True, index=True)
    midwife_id = Column(Integer, ForeignKey("midwives.id"), nullable=False)
    mother_id = Column(Integer, ForeignKey("mothers.id"), nullable=False)
    
    date_time = Column(DateTime, nullable=False)
    visit_type = Column(String(50)) # e.g., "Home Visit", "Clinic"
    status = Column(String(50), default="Scheduled") # Scheduled, Completed, Cancelled
    notes = Column(TEXT)
    
    midwife = relationship("Midwife", back_populates="appointments")
    mother = relationship("Mother", back_populates="appointments")
    anc_visit = relationship("ANCVisit", uselist=False, back_populates="appointment")
    pnc_visit = relationship("PNCVisit", uselist=False, back_populates="appointment")



# --- NEW: Message Model (Chat) ---
class Message(Base):
    __tablename__ = "messages"
    
    id = Column(Integer, primary_key=True, index=True)
    sender_id = Column(Integer, nullable=False) # Midwife ID or Mother ID
    receiver_id = Column(Integer, nullable=False) # Midwife ID or Mother ID
    
    # "midwife" or "mother"
    sender_role = Column(String(50), nullable=False) 
    
    content = Column(TEXT, nullable=False)
    timestamp = Column(DateTime, default=datetime.now)
    is_read = Column(Boolean, default=False)
    
    # Alternatively, we could have used a polymorphic association, but this is simpler for MVP.

# --- NEW: Risk Alert Model ---
class Alert(Base):
    __tablename__ = "alerts"
    
    id = Column(Integer, primary_key=True, index=True)
    mother_id = Column(Integer, ForeignKey("mothers.id"), nullable=False)
    
    # Severity: "High", "Medium", "Info"
    severity = Column(String(50), nullable=False)
    
    # Type: "BP", "Diabetes", "BMI", "Age", "General"
    alert_type = Column(String(50), nullable=False)
    
    # The personalized message: "Hey [Name]..."
    message = Column(TEXT, nullable=False)
    
    is_resolved = Column(Boolean, default=False)
    created_at = Column(DateTime, default=datetime.now)
    
    mother = relationship("Mother", back_populates="alerts")

    mother = relationship("Mother", back_populates="alerts")

# --- NEW: Leave Request Model (for MOH Dashboard) ---
class LeaveRequest(Base):
    __tablename__ = "leave_requests"
    
    id = Column(Integer, primary_key=True, index=True)
    midwife_id = Column(Integer, ForeignKey("midwives.id"), nullable=False)
    
    start_date = Column(Date, nullable=False)
    end_date = Column(Date, nullable=False)
    reason = Column(TEXT)
    status = Column(String(50), default="Pending") # Pending, Approved, Rejected
    created_at = Column(DateTime, default=datetime.now)
    
    midwife = relationship("Midwife", back_populates="leave_requests")

# Update Relationships
Mother.alerts = relationship("Alert", back_populates="mother")
Midwife.leave_requests = relationship("LeaveRequest", back_populates="midwife")