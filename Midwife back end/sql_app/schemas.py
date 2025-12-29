from pydantic import BaseModel
from datetime import datetime, date
from typing import List, Optional

# --- HealthRecord Schemas ---
class HealthRecordBase(BaseModel):
    visit_date: datetime
    weight_kg: Optional[float] = None
    blood_pressure: Optional[str] = None
    notes: Optional[str] = None

class HealthRecordCreate(HealthRecordBase):
    pass

class HealthRecord(HealthRecordBase):
    id: int
    mother_id: int
    class Config:
        from_attributes = True

# --- Past Pregnancy Schemas (H 512 Table) ---
class PastPregnancyBase(BaseModel):
    pregnancy_order: str # G1, G2
    outcome: Optional[str] = None
    delivery_mode: Optional[str] = None
    place_of_delivery: Optional[str] = None
    complications: Optional[str] = None
    birth_weight: Optional[float] = None
    sex: Optional[str] = None
    age_if_alive: Optional[str] = None
    class Config:
        from_attributes = True

class PastPregnancyCreate(PastPregnancyBase):
    pass

class PastPregnancy(PastPregnancyBase):
    id: int
    mother_id: int
    class Config:
        from_attributes = True

# --- Pregnancy Record Schemas (H 512 Form) ---
class PregnancyRecordBase(BaseModel):
    class Config:
        from_attributes = True
    # Registration
    registration_no: Optional[str] = None
    registration_date: Optional[date] = None
    registration_place: Optional[str] = None
    family_register_no: Optional[str] = None
    village_division: Optional[str] = None
    moh_division: Optional[str] = None
    phi_area: Optional[str] = None
    
    # Personal Info
    mother_age: Optional[int] = None
    mother_education: Optional[str] = None
    mother_occupation: Optional[str] = None
    distance_to_clinic: Optional[float] = None
    
    husband_name: Optional[str] = None
    husband_age: Optional[int] = None
    husband_education: Optional[str] = None
    husband_occupation: Optional[str] = None
    
    married_age: Optional[int] = None
    consanguinity: bool = False
    
    # Vitals
    bmi: Optional[float] = None
    height_cm: Optional[float] = None
    weight_kg: Optional[float] = None
    blood_group: Optional[str] = None
    
    rubella_immunization: bool = False
    pre_pregnancy_screening: bool = False
    folic_acid: bool = False
    history_of_subfertility: bool = False
    
    # Family History
    family_diabetes: bool = False
    family_hypertension: bool = False
    family_twins: bool = False
    other_family_history: Optional[str] = None
    
    # Current Pregnancy
    gravidity: Optional[int] = None
    parity: Optional[int] = None
    num_living_children: Optional[int] = None
    age_of_youngest_child: Optional[str] = None
    
    lrmp: Optional[date] = None
    edd: Optional[date] = None
    us_corrected_edd: Optional[date] = None
    poa_at_registration: Optional[str] = None
    
    # Risks Checklist
    risk_age_lt_20_gt_35: bool = False
    risk_5th_pregnancy: bool = False
    risk_birth_interval_lt_1yr: bool = False
    risk_history_pph: bool = False
    risk_diabetes: bool = False
    risk_malaria: bool = False
    risk_cardiac: bool = False
    risk_renal: bool = False
    other_risk_factors: Optional[str] = None

class PregnancyRecordCreate(PregnancyRecordBase):
    pass

class PregnancyRecord(PregnancyRecordBase):
    id: int
    mother_id: int
    created_at: Optional[datetime] = None
    class Config:
        from_attributes = True

# --- Delivery Record Schemas ---
class DeliveryRecordBase(BaseModel):
    delivery_date: Optional[datetime] = None
    delivery_mode: Optional[str] = None
    episiotomy: bool = False
    temp_normal: bool = False
    vaginal_exam_done: bool = False
    maternal_complications: Optional[str] = None
    wound_infection: bool = False
    family_planning_discussed: bool = False
    danger_signals_explained: bool = False
    breast_feeding_established: bool = False
    birth_weight: Optional[float] = None
    poa_at_birth: Optional[int] = None
    apgar_score: Optional[int] = None
    abnormalities: Optional[str] = None
    vitamin_a_given: bool = False
    rubella_given: bool = False
    anti_d_given: bool = False
    diagnosis_card_given: bool = False
    chdr_completed: bool = False
    prescription_given: bool = False
    referred_to_phm: bool = False
    special_notes: Optional[str] = None
    discharge_date: Optional[datetime] = None

class DeliveryRecordCreate(DeliveryRecordBase):
    pass

class DeliveryRecord(DeliveryRecordBase):
    id: int
    mother_id: int
    created_at: Optional[datetime] = None
    class Config:
        from_attributes = True

# --- Antenatal Plan Schemas ---
class AntenatalPlanBase(BaseModel):
    next_clinic_date: Optional[datetime] = None
    class_1st_date: Optional[datetime] = None
    class_1st_husband: bool = False
    class_1st_wife: bool = False
    class_1st_other: Optional[str] = None
    class_2nd_date: Optional[datetime] = None
    class_2nd_husband: bool = False
    class_2nd_wife: bool = False
    class_2nd_other: Optional[str] = None
    class_3rd_date: Optional[datetime] = None
    class_3rd_husband: bool = False
    class_3rd_wife: bool = False
    class_3rd_other: Optional[str] = None
    book_antenatal_issued: Optional[datetime] = None
    book_antenatal_returned: Optional[datetime] = None
    book_breastfeeding_issued: Optional[datetime] = None
    book_breastfeeding_returned: Optional[datetime] = None
    book_eccd_issued: Optional[datetime] = None
    book_eccd_returned: Optional[datetime] = None
    leaflet_fp_issued: Optional[datetime] = None
    leaflet_fp_returned: Optional[datetime] = None
    emergency_contact_name: Optional[str] = None
    emergency_contact_address: Optional[str] = None
    emergency_contact_phone: Optional[str] = None
    moh_office_phone: Optional[str] = None
    phm_phone: Optional[str] = None
    grama_niladari_div: Optional[str] = None

class AntenatalPlanCreate(AntenatalPlanBase):
    pass

class AntenatalPlan(AntenatalPlanBase):
    id: int
    mother_id: int
    created_at: Optional[datetime] = None
    class Config:
        from_attributes = True

# --- Mother Schemas ---
class MotherBase(BaseModel):
    full_name: str
    nic: Optional[str] = None
    address: Optional[str] = None
    contact_number: Optional[str] = None
    # New Fields
    status: Optional[str] = "Eligible"
    risk_level: Optional[str] = "Low"
    pregnancy_start_date: Optional[date] = None
    delivery_date: Optional[date] = None

# Input Schemas for Smart Actions
class PregnancyStart(BaseModel):
    # This now accepts the FULL record + Past History List
    record_data: PregnancyRecordCreate
    past_history: List[PastPregnancyCreate] = [] # NEW: List of past pregnancies
    risk_level: str # 'Low' or 'High'

class DeliveryReport(BaseModel):
    delivery_date: str # Format YYYY-MM-DD

class MotherCreate(MotherBase):
    password: str 
    # Optional overrides for creation if needed, otherwise defaults apply

class MotherUpdate(BaseModel):
    full_name: Optional[str] = None
    address: Optional[str] = None
    contact_number: Optional[str] = None
    status: Optional[str] = None
    risk_level: Optional[str] = None
    pregnancy_start_date: Optional[date] = None
    delivery_date: Optional[date] = None

class Mother(MotherBase):
    id: int
    midwife_id: int
    health_records: List[HealthRecord] = []
    pregnancy_records: List[PregnancyRecord] = []
    delivery_records: List[DeliveryRecord] = []
    antenatal_plans: List[AntenatalPlan] = []
    
    # Computed Fields for UI
    age: Optional[int] = None
    poa: Optional[str] = None
    active_risks: List[str] = []



    class Config:
        from_attributes = True

# --- NEW: Appointment Schemas ---
class AppointmentBase(BaseModel):
    date_time: datetime
    visit_type: Optional[str] = "Home Visit"
    notes: Optional[str] = None

class AppointmentCreate(AppointmentBase):
    pass

class AppointmentUpdate(BaseModel):
    status: Optional[str] = None
    notes: Optional[str] = None
    date_time: Optional[datetime] = None

class Appointment(AppointmentBase):
    id: int
    midwife_id: int
    mother_id: int
    status: str
    
    # We might want to embed a mini-mother object here if needed for lists
    # mother: Optional[MotherBase] = None 
    
    class Config:
        from_attributes = True

# --- NEW: Leave Request Schemas ---
class LeaveRequestBase(BaseModel):
    start_date: date
    end_date: date
    reason: str

class LeaveRequestCreate(LeaveRequestBase):
    pass

class LeaveRequestUpdate(BaseModel):
    status: str
    moh_comment: Optional[str] = None

class LeaveRequest(LeaveRequestBase):
    id: int
    midwife_id: int
    status: str
    moh_comment: Optional[str] = None
    
    class Config:
        from_attributes = True

# ------------------------------
# MOH & MIDWIFE MANAGEMENT SCHEMAS
# ------------------------------

# 1. MOH Officer
class MOHOfficerBase(BaseModel):
    username: str
    full_name: str
    moh_area: Optional[str] = None
    email: Optional[str] = None

class MOHOfficerCreate(MOHOfficerBase):
    password: str
    
class MOHOfficer(MOHOfficerBase):
    id: int
    class Config:
        from_attributes = True

# 2. Comprehensive Midwife Registration (Web Portal)
class MidwifeRegistration(BaseModel):
    username: str
    password: str
    full_name: str
    nic: str
    date_of_birth: date 
    phone_number: str
    email: Optional[str] = None
    residential_address: str
    slmc_reg_no: str
    service_grade: Optional[str] = None
    assigned_moh_area: str
    user_must_change_password: bool = True
    is_active: bool = True

# 3. Legacy Midwife Create (Mobile/Old) - Restored to prevent crash
class MidwifeCreate(BaseModel):
    username: str
    password: str
    full_name: Optional[str] = None

# 4. Midwife Response Model
class MidwifeBase(BaseModel):
    username: str
    full_name: Optional[str] = None
    nic: Optional[str] = None
    date_of_birth: Optional[date] = None
    phone_number: Optional[str] = None
    email: Optional[str] = None
    residential_address: Optional[str] = None
    slmc_reg_no: Optional[str] = None
    service_grade: Optional[str] = None
    assigned_moh_area: Optional[str] = None
    is_active: bool = True

class Midwife(MidwifeBase):
    id: int
    mothers: List[Mother] = []
    class Config:
        from_attributes = True

# --- Token Schemas ---
class Token(BaseModel):
    access_token: str
    token_type: str

class TokenData(BaseModel):
    username: Optional[str] = None
    sub_id: Optional[str] = None

class PasswordChange(BaseModel):
    old_password: str
    new_password: str

# --- ANC Visit Schemas ---
class ANCVisitBase(BaseModel):
    visit_date: date
    poa_weeks: Optional[str] = None
    weight_kg: Optional[float] = None
    bp_systolic: Optional[int] = None
    bp_diastolic: Optional[int] = None
    pallor: Optional[str] = None
    oedema: Optional[str] = None
    fundal_height_cm: Optional[float] = None
    fetal_lie: Optional[str] = None
    fetal_heart_sound: Optional[str] = None
    fetal_movement: Optional[str] = None
    urine_sugar: Optional[str] = None
    urine_albumin: Optional[str] = None
    
    # Counsel
    nutrient_supplements: bool = False
    counsel_nutrition: bool = False
    counsel_danger_signs: bool = False
    counsel_family_planning: bool = False
    counsel_breastfeeding: bool = False
    counsel_delivery_plan: bool = False
    counsel_emergency_prep: bool = False
    counsel_postnatal_care: bool = False

class ANCVisitCreate(ANCVisitBase):
    mother_id: int
    appointment_id: int

class ANCVisit(ANCVisitBase):
    id: int
    mother_id: int
    appointment_id: int
    class Config:
        from_attributes = True

# --- PNC Visit Schemas ---
class PNCVisitBase(BaseModel):
    visit_date: date
    # Mother
    temperature: Optional[float] = None
    pallor: Optional[str] = None
    breast_condition: Optional[str] = None
    uterus_involution: Optional[str] = None
    lochia_character: Optional[str] = None
    lochia_smell: Optional[str] = None
    perineum_infection: bool = False
    fissure_infection: bool = False
    vitamin_a_given: bool = False
    family_planning_method: Optional[str] = None
    referred_to_hospital: bool = False
    
    # Baby
    baby_color: Optional[str] = None
    cord_status: Optional[str] = None
    breastfeeding: Optional[str] = None
    baby_stool: Optional[str] = None
    baby_weight: Optional[float] = None

class PNCVisitCreate(PNCVisitBase):
    mother_id: int
    appointment_id: int

class PNCVisit(PNCVisitBase):
    id: int
    mother_id: int
    appointment_id: int
    class Config:
        from_attributes = True