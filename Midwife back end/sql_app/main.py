from fastapi import Depends, FastAPI, HTTPException, status
from fastapi.security import OAuth2PasswordBearer, OAuth2PasswordRequestForm
from sqlalchemy.orm import Session
from typing import List, Optional
from jose import JWTError, jwt
from datetime import datetime, timedelta

from . import crud, models, schemas
from .database import SessionLocal, engine

from datetime import date 

from fastapi.staticfiles import StaticFiles
import json
import os

# --- Auth Constants ---

SECRET_KEY = "YOUR_VERY_SECRET_KEY_GOES_HERE" # Change this!
ALGORITHM = "HS256"
ACCESS_TOKEN_EXPIRE_MINUTES = 60 * 24 

models.Base.metadata.create_all(bind=engine)

app = FastAPI()

from fastapi.middleware.cors import CORSMiddleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"], 
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Mount Static Files (MOH Website)
import os

@app.get("/")
def read_root():
    return {"status": "active", "message": "Midwife Backend API is running. Go to /static/login.html to log in."}

@app.get("/health")
def health_check():
    return {"status": "ok"}

# We assume uvicorn is run from 'Midwife back end' folder
# We assume uvicorn is run from 'Midwife back end' folder
if os.path.exists("static"):
    app.mount("/static", StaticFiles(directory="static", html=True), name="static")
else:
    # Fallback for running from within sql_app or elsewhere
    if os.path.exists("../static"):
        app.mount("/static", StaticFiles(directory="../static", html=True), name="static")

def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

oauth2_scheme = OAuth2PasswordBearer(tokenUrl="token")
oauth2_scheme_mother = OAuth2PasswordBearer(tokenUrl="mother/token")
oauth2_scheme_moh = OAuth2PasswordBearer(tokenUrl="moh/token") # MOH Web Portal (NEW)

# --- Auth Functions (Same as before) ---
def create_access_token(data: dict, expires_delta: Optional[timedelta] = None):
    to_encode = data.copy()
    if expires_delta:
        expire = datetime.utcnow() + expires_delta
    else:
        expire = datetime.utcnow() + timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES)
    to_encode.update({"exp": expire})
    encoded_jwt = jwt.encode(to_encode, SECRET_KEY, algorithm=ALGORITHM)
    return encoded_jwt

# --- Dependency Functions (Updated) ---

async def get_current_midwife(db: Session = Depends(get_db), token: str = Depends(oauth2_scheme)):
    # ... (Keep existing code) ...
    credentials_exception = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Could not validate credentials",
        headers={"WWW-Authenticate": "Bearer"},
    )
    try:
        payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
        username: str = payload.get("sub")
        if username is None:
            raise credentials_exception
        token_data = schemas.TokenData(username=username)
    except JWTError:
        raise credentials_exception
    midwife = crud.get_midwife_by_username(db, username=token_data.username)
    if midwife is None:
        raise credentials_exception
    return midwife

async def get_current_mother(db: Session = Depends(get_db), token: str = Depends(oauth2_scheme_mother)):
    credentials_exception = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Could not validate credentials",
        headers={"WWW-Authenticate": "Bearer"},
    )
    try:
        payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
        nic: str = payload.get("sub")
        if nic is None:
            raise credentials_exception
        token_data = schemas.TokenData(sub_id=nic)
    except JWTError:
        raise credentials_exception
    mother = crud.get_mother_by_nic(db, nic=token_data.sub_id)
    if mother is None:
        raise credentials_exception
    return mother

# --- NEW: MOH Auth Dependency ---
async def get_current_moh(db: Session = Depends(get_db), token: str = Depends(oauth2_scheme_moh)):
    credentials_exception = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Could not validate credentials (MOH)",
        headers={"WWW-Authenticate": "Bearer"},
    )
    try:
        payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
        username: str = payload.get("sub")
        if username is None:
            raise credentials_exception
        token_data = schemas.TokenData(username=username)
    except JWTError:
        raise credentials_exception
    moh = crud.get_moh_officer_by_username(db, username=token_data.username)
    if moh is None:
        raise credentials_exception
    return moh


# --- API ENDPOINTS ---

# 1. MOH Self-Registration (For System Admin to create the first MOH account)
@app.post("/moh/register", response_model=schemas.MOHOfficer)
def register_moh(moh: schemas.MOHOfficerCreate, db: Session = Depends(get_db)):
    db_moh = crud.get_moh_officer_by_username(db, username=moh.username)
    if db_moh:
        raise HTTPException(status_code=400, detail="MOH Username already registered")
    return crud.create_moh_officer(db=db, moh=moh)

# 1.5 Get Current MOH (Profile)
@app.get("/moh/me", response_model=schemas.MOHOfficer)
def read_moh_me(current_moh: schemas.MOHOfficer = Depends(get_current_moh)):
    return current_moh

# 2. MOH Login (Web Login)
@app.post("/moh/token", response_model=schemas.Token)
async def login_for_moh(db: Session = Depends(get_db), form_data: OAuth2PasswordRequestForm = Depends()):
    moh = crud.get_moh_officer_by_username(db, username=form_data.username)
    if not moh or not crud.verify_password(form_data.password, moh.hashed_password):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect username or password",
            headers={"WWW-Authenticate": "Bearer"},
        )
    access_token = create_access_token(data={"sub": moh.username})
    return {"access_token": access_token, "token_type": "bearer"}

# 3. Midwife Registration (Used by the MOH Web Form)
@app.post("/midwives/full", response_model=schemas.Midwife, status_code=status.HTTP_201_CREATED)
def register_new_midwife_from_web(
    midwife_data: schemas.MidwifeRegistration, 
    db: Session = Depends(get_db),
    # Ensure only a logged-in MOH can access this endpoint
    current_moh: schemas.MOHOfficer = Depends(get_current_moh) 
):
    db_midwife = crud.register_full_midwife(db=db, midwife_data=midwife_data)
    
    if db_midwife is None:
        raise HTTPException(status_code=400, detail="Username or NIC already exists.")
        
    return db_midwife

# 4. View All Midwives (For MOH Directory/Management)
@app.get("/midwives/", response_model=List[schemas.Midwife])
def get_all_midwives_for_moh(
    db: Session = Depends(get_db),
    current_moh: schemas.MOHOfficer = Depends(get_current_moh)
):
    # Filter by the logged-in MOH's office ID (Strict Hierarchy)
    return db.query(models.Midwife).filter(models.Midwife.moh_office_id == current_moh.moh_office_id).all()



# ... (Register and Login endpoints stay the same) ...
@app.post("/register/", response_model=schemas.Midwife)
def register_midwife(midwife: schemas.MidwifeCreate, db: Session = Depends(get_db)):
    db_midwife = crud.get_midwife_by_username(db, username=midwife.username)
    if db_midwife:
        raise HTTPException(status_code=400, detail="Username already registered")
    return crud.create_midwife(db=db, midwife=midwife)

@app.post("/token", response_model=schemas.Token)
async def login_for_midwife(db: Session = Depends(get_db), form_data: OAuth2PasswordRequestForm = Depends()):
    midwife = crud.get_midwife_by_username(db, username=form_data.username)
    if not midwife or not crud.verify_password(form_data.password, midwife.hashed_password):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect username or password",
            headers={"WWW-Authenticate": "Bearer"},
        )
    access_token = create_access_token(data={"sub": midwife.username})
    return {"access_token": access_token, "token_type": "bearer"}

@app.get("/midwives/me/", response_model=schemas.Midwife)
async def read_midwives_me(current_midwife: schemas.Midwife = Depends(get_current_midwife)):
    return current_midwife

@app.put("/midwives/me/password", response_model=dict)
def change_midwife_password(
    password_data: schemas.PasswordChange,
    db: Session = Depends(get_db),
    current_midwife: schemas.Midwife = Depends(get_current_midwife)
):
    success = crud.update_midwife_password(db, midwife_id=current_midwife.id, password_data=password_data)
    if not success:
        raise HTTPException(status_code=400, detail="Incorrect old password")
        
    return {"message": "Password updated successfully"}

@app.post("/mother/token", response_model=schemas.Token)
async def login_for_mother(db: Session = Depends(get_db), form_data: OAuth2PasswordRequestForm = Depends()):
    mother = crud.get_mother_by_nic(db, nic=form_data.username)
    if not mother or not crud.verify_password(form_data.password, mother.hashed_password):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect NIC or password",
            headers={"WWW-Authenticate": "Bearer"},
        )
    access_token = create_access_token(data={"sub": mother.nic})
    return {"access_token": access_token, "token_type": "bearer"}

@app.get("/mothers/me/", response_model=schemas.Mother)
async def read_mothers_me(current_mother: schemas.Mother = Depends(get_current_mother)):
    return current_mother

@app.get("/midwives/dashboard-stats")
def get_dashboard_stats(
    db: Session = Depends(get_db),
    current_midwife: schemas.Midwife = Depends(get_current_midwife)
):
    assigned_mothers = crud.get_mother_count_by_midwife(db, current_midwife.id)
    todays_visits = crud.get_todays_appointments_count(db, current_midwife.id)
    
    return {
        "assigned_mothers": assigned_mothers,
        "todays_visits": todays_visits
    }

# --- MIDWIFE ACTIONS (UPDATED) ---

@app.post("/mothers/", response_model=schemas.Mother)
def create_mother_for_midwife(
    mother: schemas.MotherCreate, 
    db: Session = Depends(get_db), 
    current_midwife: schemas.Midwife = Depends(get_current_midwife)
):
    db_mother = crud.get_mother_by_nic(db, nic=mother.nic)
    if db_mother:
        raise HTTPException(status_code=400, detail="Mother with this NIC already registered")
    return crud.create_mother(db=db, mother=mother, midwife_id=current_midwife.id)

# UPDATED: Accepts 'search' parameter
@app.get("/mothers/", response_model=List[schemas.Mother])
def read_mothers_for_midwife(
    skip: int = 0, 
    limit: int = 100, 
    search: Optional[str] = None, # New parameter
    db: Session = Depends(get_db),
    current_midwife: schemas.Midwife = Depends(get_current_midwife)
):
    mothers = crud.get_mothers_by_midwife(db, midwife_id=current_midwife.id, skip=skip, limit=limit, search=search)
    return mothers

# NEW: Update Mother Details
@app.put("/mothers/{mother_id}", response_model=schemas.Mother)
def update_mother_details(
    mother_id: int,
    mother_update: schemas.MotherUpdate,
    db: Session = Depends(get_db),
    current_midwife: schemas.Midwife = Depends(get_current_midwife)
):
    # 1. Check if mother exists
    db_mother = crud.get_mother(db, mother_id=mother_id)
    if not db_mother:
        raise HTTPException(status_code=404, detail="Mother not found")
        
    # 2. Security Check: Ensure this mother belongs to this midwife
    if db_mother.midwife_id != current_midwife.id:
        raise HTTPException(status_code=403, detail="Not authorized to edit this mother")
        
    # 3. Update
    return crud.update_mother(db=db, mother_id=mother_id, mother_update=mother_update)

@app.post("/mothers/{mother_id}/records/", response_model=schemas.HealthRecord)
def create_record_for_mother(
    mother_id: int,
    record: schemas.HealthRecordCreate,
    db: Session = Depends(get_db),
    current_midwife: schemas.Midwife = Depends(get_current_midwife)
):
    return crud.create_health_record(db=db, record=record, mother_id=mother_id)

@app.get("/mothers/{mother_id}/records/", response_model=List[schemas.HealthRecord])
def read_records_for_mother(
    mother_id: int,
    db: Session = Depends(get_db),
    current_midwife: schemas.Midwife = Depends(get_current_midwife)
):
    records = crud.get_health_records_for_mother(db, mother_id=mother_id)
    return records
            
# --- PREGNANCY RECORD ENDPOINTS ---

@app.post("/mothers/{mother_id}/pregnancy-records/", response_model=schemas.PregnancyRecord)
def create_pregnancy_record_for_mother(
    mother_id: int,
    record: schemas.PregnancyRecordCreate,
    db: Session = Depends(get_db),
    current_midwife: schemas.Midwife = Depends(get_current_midwife)
):
    # Check if mother exists
    db_mother = crud.get_mother(db, mother_id=mother_id)
    if not db_mother:
        raise HTTPException(status_code=404, detail="Mother not found")
        
    return crud.create_pregnancy_record(db=db, record=record, mother_id=mother_id)

@app.get("/mothers/{mother_id}/pregnancy-records/", response_model=List[schemas.PregnancyRecord])
def read_pregnancy_records_for_mother(
    mother_id: int,
    db: Session = Depends(get_db),
    current_midwife: schemas.Midwife = Depends(get_current_midwife)
):
    return crud.get_pregnancy_records_for_mother(db, mother_id=mother_id)

@app.get("/mothers/{mother_id}/pregnancy-record", response_model=schemas.PregnancyRecord)
def read_latest_pregnancy_record_for_mother(
    mother_id: int,
    db: Session = Depends(get_db),
    current_midwife: schemas.Midwife = Depends(get_current_midwife)
):
    records = crud.get_pregnancy_records_for_mother(db, mother_id=mother_id)
    if not records:
        raise HTTPException(status_code=404, detail="No pregnancy record found")
    # Return the latest one (assuming ID order or date)
    return records[-1]

# --- DELIVERY RECORD ENDPOINTS ---

@app.post("/mothers/{mother_id}/delivery-records/", response_model=schemas.DeliveryRecord)
def create_delivery_record_for_mother(
    mother_id: int,
    record: schemas.DeliveryRecordCreate,
    db: Session = Depends(get_db),
    current_midwife: schemas.Midwife = Depends(get_current_midwife)
):
    # Check if mother exists
    db_mother = crud.get_mother(db, mother_id=mother_id)
    if not db_mother:
        raise HTTPException(status_code=404, detail="Mother not found")
        
    return crud.create_delivery_record(db=db, record=record, mother_id=mother_id)

@app.get("/mothers/{mother_id}/delivery-records/", response_model=List[schemas.DeliveryRecord])
def read_delivery_records_for_mother(
    mother_id: int,
    db: Session = Depends(get_db),
    current_midwife: schemas.Midwife = Depends(get_current_midwife)
):
    return crud.get_delivery_records_for_mother(db, mother_id=mother_id)

# --- ANTENATAL PLAN ENDPOINTS ---

@app.post("/mothers/{mother_id}/antenatal-plans/", response_model=schemas.AntenatalPlan)
def create_antenatal_plan_for_mother(
    mother_id: int,
    plan: schemas.AntenatalPlanCreate,
    db: Session = Depends(get_db),
    current_midwife: schemas.Midwife = Depends(get_current_midwife)
):
    # Check if mother exists
    db_mother = crud.get_mother(db, mother_id=mother_id)
    if not db_mother:
        raise HTTPException(status_code=404, detail="Mother not found")
        
    return crud.create_antenatal_plan(db=db, plan=plan, mother_id=mother_id)

@app.get("/mothers/{mother_id}/antenatal-plans/", response_model=List[schemas.AntenatalPlan])
def read_antenatal_plans_for_mother(
    mother_id: int,
    db: Session = Depends(get_db),
    current_midwife: schemas.Midwife = Depends(get_current_midwife)
):
    return crud.get_antenatal_plans_for_mother(db, mother_id=mother_id)

# --- MOTHER PORTAL ENDPOINTS (READ-ONLY) ---

@app.get("/my-pregnancy-records/", response_model=List[schemas.PregnancyRecord])
def read_my_pregnancy_records(
    db: Session = Depends(get_db),
    current_mother: schemas.Mother = Depends(get_current_mother)
):
    # The 'current_mother' dependency ensures this is a valid mother login
    return crud.get_pregnancy_records_for_mother(db, mother_id=current_mother.id)

@app.get("/my-delivery-records/", response_model=List[schemas.DeliveryRecord])
def read_my_delivery_records(
    db: Session = Depends(get_db),
    current_mother: schemas.Mother = Depends(get_current_mother)
):
    return crud.get_delivery_records_for_mother(db, mother_id=current_mother.id)

@app.get("/my-antenatal-plans/", response_model=List[schemas.AntenatalPlan])
def read_my_antenatal_plans(
    db: Session = Depends(get_db),
    current_mother: schemas.Mother = Depends(get_current_mother)
):
    return crud.get_antenatal_plans_for_mother(db, mother_id=current_mother.id)

@app.get("/my-appointments/", response_model=List[schemas.Appointment])
def read_my_appointments(
    db: Session = Depends(get_db),
    current_mother: schemas.Mother = Depends(get_current_mother)
):
    return crud.get_appointments_by_mother(db, mother_id=current_mother.id)

# --- APPOINTMENT ENDPOINTS (Midwife) ---

@app.post("/appointments/", response_model=schemas.Appointment)
def create_appointment(
    appointment: schemas.AppointmentCreate,
    mother_id: int, # Pass as query param for simplicity, or in body
    db: Session = Depends(get_db),
    current_midwife: schemas.Midwife = Depends(get_current_midwife)
):
    # Verify mother belongs to midwife
    db_mother = crud.get_mother(db, mother_id)
    if not db_mother or db_mother.midwife_id != current_midwife.id:
        raise HTTPException(status_code=400, detail="Invalid Mother ID")
        
    return crud.create_appointment(db, appointment, current_midwife.id, mother_id)

@app.get("/appointments/", response_model=List[schemas.Appointment])
def get_midwife_appointments(
    start_date: Optional[datetime] = None,
    end_date: Optional[datetime] = None,
    db: Session = Depends(get_db),
    current_midwife: schemas.Midwife = Depends(get_current_midwife)
):
    return crud.get_appointments_by_midwife(db, current_midwife.id, start_date, end_date)

@app.put("/appointments/{appointment_id}", response_model=schemas.Appointment)
def update_appointment(
    appointment_id: int,
    status_update: schemas.AppointmentUpdate,
    db: Session = Depends(get_db),
    current_midwife: schemas.Midwife = Depends(get_current_midwife)
):
    # Ensure ownership
    appt = db.query(models.Appointment).filter(models.Appointment.id == appointment_id).first()
    if not appt or appt.midwife_id != current_midwife.id:
        raise HTTPException(status_code=404, detail="Appointment not found")

    # VALIDATION: Cannot complete if records are missing
    if status_update.status == "Completed":
        # Check Mother Status
        if appt.mother.status == "Pregnant":
            # Must have ANC visit
            anc_visit = crud.get_anc_visit_by_appointment(db, appointment_id)
            if not anc_visit:
                print(f"DEBUG: Blocking Completion. Mother={appt.mother.id} (Pregnant), No ANC Visit.")
                raise HTTPException(status_code=400, detail="Cannot mark as Completed. Please fill the ANC Record first.")
                
        elif appt.mother.status == "Postnatal":
            # Must have PNC visit
            pnc_visit = crud.get_pnc_visit_by_appointment(db, appointment_id)
            if not pnc_visit:
                print(f"DEBUG: Blocking Completion. Mother={appt.mother.id} (Postnatal), No PNC Visit.")
                raise HTTPException(status_code=400, detail="Cannot mark as Completed. Please fill the PNC Record first.")
        
    return crud.update_appointment(db, appointment_id, status_update)

@app.delete("/appointments/{appointment_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_appointment(
    appointment_id: int,
    db: Session = Depends(get_db),
    current_midwife: schemas.Midwife = Depends(get_current_midwife)
):
    # Ensure ownership/permission
    appt = db.query(models.Appointment).filter(models.Appointment.id == appointment_id).first()
    if not appt:
        raise HTTPException(status_code=404, detail="Appointment not found")
        
    if appt.midwife_id != current_midwife.id:
        raise HTTPException(status_code=403, detail="Not authorized to delete this appointment")
    
    return crud.delete_appointment(db, appointment_id)

# --- ANC Visits ---
@app.post("/anc-visits/", response_model=schemas.ANCVisit)
def create_anc_visit(visit: schemas.ANCVisitCreate, db: Session = Depends(get_db)):
    # Check if already exists?
    existing = crud.get_anc_visit_by_appointment(db, visit.appointment_id)
    if existing:
        raise HTTPException(status_code=400, detail="ANC Data already recorded for this appointment")
    return crud.create_anc_visit(db, visit)

@app.get("/appointments/{appointment_id}/anc-visit", response_model=schemas.ANCVisit)
def get_anc_visit(appointment_id: int, db: Session = Depends(get_db)):
    visit = crud.get_anc_visit_by_appointment(db, appointment_id)
    if visit is None:
        raise HTTPException(status_code=404, detail="ANC Data not found")
    return visit

@app.get("/mothers/{mother_id}/anc-visits", response_model=List[schemas.ANCVisit])
def get_mother_anc_visits(mother_id: int, db: Session = Depends(get_db)):
    return crud.get_mother_anc_visits(db, mother_id)


# --- PNC Visits ---
@app.post("/pnc-visits/", response_model=schemas.PNCVisit)
def create_pnc_visit(visit: schemas.PNCVisitCreate, db: Session = Depends(get_db)):
    # Check if already exists?
    existing = crud.get_pnc_visit_by_appointment(db, visit.appointment_id)
    if existing:
        raise HTTPException(status_code=400, detail="PNC Data already recorded for this appointment")
    return crud.create_pnc_visit(db, visit)

@app.get("/appointments/{appointment_id}/pnc-visit", response_model=schemas.PNCVisit)
def get_pnc_visit(appointment_id: int, db: Session = Depends(get_db)):
    visit = crud.get_pnc_visit_by_appointment(db, appointment_id)
    if visit is None:
        raise HTTPException(status_code=404, detail="PNC Data not found")
    return visit

@app.get("/mothers/{mother_id}/pnc-visits", response_model=List[schemas.PNCVisit])
def get_mother_pnc_visits(mother_id: int, db: Session = Depends(get_db)):
    return crud.get_mother_pnc_visits(db, mother_id)


# --- LEAVE REQUEST ENDPOINTS ---

@app.post("/leave-requests/", response_model=schemas.LeaveRequest)
def create_leave_request(
    leave: schemas.LeaveRequestCreate,
    db: Session = Depends(get_db),
    current_midwife: schemas.Midwife = Depends(get_current_midwife)
):
    leave_req = crud.create_leave_request(db, leave, current_midwife.id)
    if leave_req is None:
        raise HTTPException(status_code=400, detail="Duplicate or Overlapping Leave Request")
    return leave_req

@app.get("/leave-requests/me", response_model=List[schemas.LeaveRequest])
def get_my_leave_requests(
    db: Session = Depends(get_db),
    current_midwife: schemas.Midwife = Depends(get_current_midwife)
):
    return crud.get_leave_requests_by_midwife(db, current_midwife.id)

# For MOH
@app.get("/leave-requests/", response_model=List[schemas.LeaveRequest])
def get_all_leave_requests(
    db: Session = Depends(get_db),
    current_moh: schemas.MOHOfficer = Depends(get_current_moh)
):
    return crud.get_all_leave_requests(db)

@app.put("/leave-requests/{leave_id}", response_model=schemas.LeaveRequest)
def update_leave_request(
    leave_id: int,
    update_data: schemas.LeaveRequestUpdate,
    db: Session = Depends(get_db),
    current_moh: schemas.MOHOfficer = Depends(get_current_moh)
):
    return crud.update_leave_request(db, leave_id, update_data)
            
# --- MOTHER PASSWORD CHANGE ---

@app.put("/mothers/me/password", response_model=dict)
def change_mother_password(
    password_data: schemas.PasswordChange,
    db: Session = Depends(get_db),
    current_mother: schemas.Mother = Depends(get_current_mother)
):
    success = crud.update_mother_password(db, mother_id=current_mother.id, password_data=password_data)
    if not success:
        raise HTTPException(status_code=400, detail="Incorrect old password")
        
    return {"message": "Password updated successfully"}

# --- SMART CARE PLAN ENDPOINTS ---

@app.post("/mothers/{mother_id}/pregnancy", response_model=schemas.Mother)
def start_pregnancy(mother_id: int, data: schemas.PregnancyStart, db: Session = Depends(get_db), current_midwife: models.Midwife = Depends(get_current_midwife)):
    db_mother = crud.get_mother(db, mother_id)
    if not db_mother or db_mother.midwife_id != current_midwife.id:
        raise HTTPException(status_code=404, detail="Mother not found or not assigned to you")
        
    updated_mother = crud.start_pregnancy(db, mother_id, data.record_data, data.past_history, data.risk_level)
    return updated_mother

@app.get("/mothers/{mother_id}/pregnancy", response_model=schemas.PregnancyStart)
def get_pregnancy_record(mother_id: int, db: Session = Depends(get_db)):
    # Note: Returns the data shape matching the Input form, not the raw DB model
    db_record = crud.get_pregnancy_record_by_mother(db, mother_id)
    if not db_record:
        raise HTTPException(status_code=404, detail="No pregnancy record found")
    
    past_history = crud.get_past_pregnancies_by_mother(db, mother_id)
    db_mother = crud.get_mother(db, mother_id)
    
    return schemas.PregnancyStart(
        record_data=db_record,
        past_history=past_history,
        risk_level=db_mother.risk_level if db_mother else "Low"
    )

@app.put("/mothers/{mother_id}/pregnancy", response_model=schemas.Mother)
def update_pregnancy_record(mother_id: int, data: schemas.PregnancyStart, db: Session = Depends(get_db), current_midwife: models.Midwife = Depends(get_current_midwife)):
    db_mother = crud.get_mother(db, mother_id)
    if not db_mother or db_mother.midwife_id != current_midwife.id:
         raise HTTPException(status_code=404, detail="Mother not found or not assigned")
    
    updated_mother = crud.update_pregnancy_record(db, mother_id, data.record_data, data.past_history, data.risk_level)
    return updated_mother

@app.post("/mothers/{mother_id}/delivery", response_model=schemas.Mother)
def report_delivery(
    mother_id: int,
    data: schemas.DeliveryReport,
    db: Session = Depends(get_db),
    current_midwife: schemas.Midwife = Depends(get_current_midwife)
):
    # Verify ownership
    db_mother = crud.get_mother(db, mother_id)
    if not db_mother or db_mother.midwife_id != current_midwife.id:
        raise HTTPException(status_code=404, detail="Mother not found or not assigned to you")
        
    updated_mother = crud.report_delivery(db, mother_id, data.delivery_date)
    return updated_mother

@app.get("/midwives/me", response_model=schemas.Midwife)
def read_users_me(current_midwife: schemas.Midwife = Depends(get_current_midwife)):
    return current_midwife



# --- CHAT ENDPOINTS ---

@app.post("/midwives/messages/", response_model=schemas.Message)
def send_message_as_midwife(
    message: schemas.MessageCreate,
    db: Session = Depends(get_db),
    current_midwife: schemas.Midwife = Depends(get_current_midwife)
):
    # Midwife sending to Mother (receiver_id is Mother ID)
    return crud.create_message(db, message, sender_id=current_midwife.id, sender_role="midwife")

@app.post("/mothers/messages/", response_model=schemas.Message)
def send_message_as_mother(
    message: schemas.MessageCreate,
    db: Session = Depends(get_db),
    current_mother: schemas.Mother = Depends(get_current_mother)
):
    # Mother sending to Midwife (receiver_id is Midwife ID)
    return crud.create_message(db, message, sender_id=current_mother.id, sender_role="mother")

@app.get("/midwives/messages/{mother_id}", response_model=List[schemas.Message])
def get_chat_history_midwife(
    mother_id: int,
    db: Session = Depends(get_db),
    current_midwife: schemas.Midwife = Depends(get_current_midwife)
):
    return crud.get_chat_messages(db, user1_id=current_midwife.id, user1_role="midwife", user2_id=mother_id)

@app.get("/mothers/messages/{midwife_id}", response_model=List[schemas.Message])
def get_chat_history_mother(
    midwife_id: int,
    db: Session = Depends(get_db),
    current_mother: schemas.Mother = Depends(get_current_mother)
):
    return crud.get_chat_messages(db, user1_id=current_mother.id, user1_role="mother", user2_id=midwife_id)

@app.get("/mothers/messages/unread/count")
def get_unread_count_mother(
    db: Session = Depends(get_db),
    current_mother: schemas.Mother = Depends(get_current_mother)
):
    return {"count": crud.get_unread_message_count(db, user_id=current_mother.id, user_role="mother")}

@app.get("/mothers/messages/unread/senders", response_model=List[schemas.UnreadSender])
def get_unread_senders_mother(
    db: Session = Depends(get_db),
    current_mother: schemas.Mother = Depends(get_current_mother)
):
    return crud.get_unread_senders(db, user_id=current_mother.id, user_role="mother")

@app.put("/mothers/messages/{midwife_id}/read")
def mark_messages_read_mother(
    midwife_id: int,
    db: Session = Depends(get_db),
    current_mother: schemas.Mother = Depends(get_current_mother)
):
    crud.mark_chat_read(db, user_id=current_mother.id, user_role="mother", other_user_id=midwife_id)
    return {"status": "success"}

@app.get("/midwives/messages/unread/count")
def get_unread_count_midwife(
    db: Session = Depends(get_db),
    current_midwife: schemas.Midwife = Depends(get_current_midwife)
):
    return {"count": crud.get_unread_message_count(db, user_id=current_midwife.id, user_role="midwife")}

@app.get("/midwives/messages/unread/senders", response_model=List[schemas.UnreadSender])
def get_unread_senders_midwife(
    db: Session = Depends(get_db),
    current_midwife: schemas.Midwife = Depends(get_current_midwife)
):
    return crud.get_unread_senders(db, user_id=current_midwife.id, user_role="midwife")

@app.put("/midwives/messages/{mother_id}/read")
def mark_messages_read_midwife(
    mother_id: int,
    db: Session = Depends(get_db),
    current_midwife: schemas.Midwife = Depends(get_current_midwife)
):
    crud.mark_chat_read(db, user_id=current_midwife.id, user_role="midwife", other_user_id=mother_id)
    return {"status": "success"}


# new section added for the web ---

@app.get("/mothers/risks/stats")
def get_risk_stats(
    db: Session = Depends(get_db),
    current_midwife: models.Midwife = Depends(get_current_midwife)
):
    # Returns counts for each risk category
    return crud.get_risk_stats(db, current_midwife.id)

@app.get("/mothers/risks/{risk_type}", response_model=List[schemas.Mother])
def get_mothers_by_risk(
    risk_type: str,
    db: Session = Depends(get_db),
    current_midwife: models.Midwife = Depends(get_current_midwife)
):
    # risk_type: "high_risk", "diabetes", "cardiac", "age", "pph", "gravidity"
    # risk_type: "high_risk", "diabetes", "cardiac", "age", "pph", "gravidity"
    # risk_type: "high_risk", "diabetes", "cardiac", "age", "pph", "gravidity"
    return crud.get_mothers_by_risk(db, current_midwife.id, risk_type)


# --- MONTHLY ANALYTICS ENDPOINTS (MOH WEBSITE) ---

@app.get("/moh/analytics/hotspots")
def get_analytics_hotspots(
    db: Session = Depends(get_db),
    current_moh: schemas.MOHOfficer = Depends(get_current_moh)
):
    return crud.get_analytics_hotspots(db, current_moh.moh_office_id)

@app.get("/moh/analytics/defaulters")
def get_analytics_defaulters(
    db: Session = Depends(get_db),
    current_moh: schemas.MOHOfficer = Depends(get_current_moh)
):
    return crud.get_analytics_defaulters(db, current_moh.moh_office_id)

@app.get("/moh/analytics/forecast")
def get_analytics_forecast(
    db: Session = Depends(get_db),
    current_moh: schemas.MOHOfficer = Depends(get_current_moh)
):
    return crud.get_analytics_forecast(db, current_moh.moh_office_id)

@app.get("/moh/dashboard/stats")
def get_moh_dashboard_stats(
    db: Session = Depends(get_db),
    current_moh: schemas.MOHOfficer = Depends(get_current_moh)
):
    return crud.get_moh_dashboard_stats(db, current_moh.moh_office_id)

# --- MIDWIFE ANALYTICS (DETAILED) ---

@app.get("/midwives/analytics/defaulters")
def get_midwife_defaulters(
    db: Session = Depends(get_db),
    current_midwife: models.Midwife = Depends(get_current_midwife)
):
    return crud.get_midwife_defaulters(db, current_midwife.id)

@app.get("/midwives/analytics/forecast")
def get_midwife_forecast(
    db: Session = Depends(get_db),
    current_midwife: models.Midwife = Depends(get_current_midwife)
):
    return crud.get_midwife_forecast(db, current_midwife.id)



# --- RISK ALERT ENDPOINTS ---

@app.get("/midwives/alerts", response_model=List[schemas.Alert])
def get_alerts_dashboard(
    db: Session = Depends(get_db),
    current_midwife: models.Midwife = Depends(get_current_midwife)
):
    return crud.get_alerts_for_midwife(db, current_midwife.id)

@app.get("/mothers/health-tip")
def get_daily_health_tip(
    db: Session = Depends(get_db),
    current_mother: models.Mother = Depends(get_current_mother)
):
    # Returns personalized tip text
    return {"content": crud.get_latest_health_tip(db, current_mother.id)}

@app.get("/mothers/alerts", response_model=List[schemas.Alert])
def get_my_alerts(
    db: Session = Depends(get_db),
    current_mother: models.Mother = Depends(get_current_mother)
):
    return crud.get_active_alerts_for_mother(db, current_mother.id)


# --- TEMPORARY SEED ENDPOINT ---
@app.get("/seed-moh")
def seed_moh(db: Session = Depends(get_db)):
    # Check if MOH Admin exists
    moh = crud.get_moh_officer_by_username(db, "moh_admin")
    if moh:
        # Reset Password to '123' for consistency with dashboard seed
        moh.hashed_password = crud.get_password_hash("123")
        db.commit()
        return {"message": "User 'moh_admin' exists. PASSWORD RESET to: 123"}

    # Create if not exists
    moh_data = schemas.MOHOfficerCreate(
        username="moh_admin",
        password="123",
        full_name="System Admin",
        moh_area="Colombo"
    )
    crud.create_moh_officer(db, moh_data)
    return {"message": "Created MOH Admin: moh_admin / 123"}

@app.get("/moh-offices")
def get_moh_offices():
    # File is in the parent directory of sql_app (which is where main.py is, but python runs from root usually)
    # If running from 'Midwife back end', then moh_offices.json is in current dir.
    # main.py is in sql_app/main.py.
    
    # Try different paths to be safe
    paths = ["moh_offices.json", "../moh_offices.json", "Midwife back end/moh_offices.json"]
    
    for path in paths:
        if os.path.exists(path):
            with open(path, "r") as f:
                return json.load(f)
                
    # Fallback: Try relative to this file
    current_dir = os.path.dirname(os.path.abspath(__file__))
    parent_dir = os.path.dirname(current_dir) # Midwife back end
    file_path = os.path.join(parent_dir, "moh_offices.json")
    
    if os.path.exists(file_path):
         with open(file_path, "r") as f:
                return json.load(f)

    raise HTTPException(status_code=404, detail=f"MOH Data File not found. Searched in: {paths} and {file_path}")

@app.get("/seed-leave")
def seed_leave(db: Session = Depends(get_db)):
    # 1. Get or Create a Midwife
    midwife = db.query(models.Midwife).first()
    if not midwife:
        midwife = models.Midwife(
            username="test_midwife",
            hashed_password=crud.get_password_hash("123"),
            full_name="Test Midwife",
            nic="123456789V"
        )
        db.add(midwife)
        db.commit()
        db.refresh(midwife)
    
    # 2. Create Leave Request via CRUD (checks overlapping)
    # Use random date to allow multiple tests if needed, or stick to today to test overlap
    start_d = datetime.now().date()
    end_d = datetime.now().date()
    
    leave_data = schemas.LeaveRequestCreate(
        start_date=start_d,
        end_date=end_d,
        reason="Medical Leave (Test Request)"
    )
    
    # Try to create
    leave = crud.create_leave_request(db, leave_data, midwife.id)
    if not leave:
        return {"message": "Request FAILED: Duplicate request for this date already exists!"}
        
    return {"message": f"Created Leave Request for Midwife: {midwife.full_name}"}
    return {"message": f"Created Leave Request for Midwife: {midwife.full_name}"}

    return {"message": "Created Leave Request for Midwife: {midwife.full_name}"}

@app.get("/reset-db-smart")
def reset_db_smart():
    # WARNING: This deletes all data!
    models.Base.metadata.drop_all(bind=engine)
    models.Base.metadata.create_all(bind=engine)
    return {"message": "Database has been RESET for Smart Care Plan features. Please re-seed data."}

@app.get("/seed-dashboard-v2")
def seed_dashboard(db: Session = Depends(get_db)):
    midwife = crud.get_midwife_by_username(db, "test_midwife")
    if not midwife:
        # Create midwife if not exists (after reset)
        midwife = models.Midwife(
            username="test_midwife",
            hashed_password=crud.get_password_hash("123"),
            full_name="Test Midwife",
            nic="123456789V"
        )
        db.add(midwife)
        db.commit()
        db.refresh(midwife)

    # 1.5 Create MOH Officer
    moh = db.query(models.MOHOfficer).filter(models.MOHOfficer.username == "moh_admin").first()
    if not moh:
        moh = models.MOHOfficer(
            username="moh_admin",
            hashed_password=crud.get_password_hash("123"),
            full_name="MOH Admin",
            moh_area="Colombo",
            email="moh@admin.com"
        )
        db.add(moh)
        db.commit()
    
    # 2. Add 5 Mothers
    for i in range(1, 6):
        nic = f"90000000{i}V"
        if not crud.get_mother_by_nic(db, nic):
            crud.create_mother(db, schemas.MotherCreate(
                nic=nic, full_name=f"Mother {i}", password="123", contact_number="0771234567",
                status="Eligible" # Default logic check
            ), midwife.id)

    # 3. Add 3 Appointments for TODAY (Manually for now, or via Smart Plan)
    # Let's add manual ones for Dashboard testing
    today = datetime.now()
    mothers = db.query(models.Mother).filter(models.Mother.midwife_id == midwife.id).all()
    if mothers:
        for i in range(3):
            # i+9 hours -> 9am, 10am, 11am
            appt_time = today.replace(hour=9+i, minute=0, second=0)
            db.add(models.Appointment(
                midwife_id=midwife.id,
                mother_id=mothers[0].id, # Assign to first mother
                date_time=appt_time,
                visit_type="Clinic",
                status="Scheduled",
                notes="Routine Checkup"
            ))
        db.commit()

    return {"message": "Seeded Dashboard: 1 Midwife, 5 Mothers, 3 Appointments, 1 MOH Officer (moh_admin)"}

@app.get("/seed-full-flow")
def seed_full_flow(db: Session = Depends(get_db)):
    # 1. Ensure Midwife
    midwife = crud.get_midwife_by_username(db, "test_midwife")
    if not midwife:
        midwife = models.Midwife(
            username="test_midwife",
            hashed_password=crud.get_password_hash("123"),
            full_name="Test Midwife",
            nic="700000000V",
            assigned_moh_area="Colombo"
        )
        db.add(midwife)
        db.commit()
        db.refresh(midwife)
    
    # Helper to create mother if not exists
    def create_mother_if_not_exists(nic, name, status, risk="Low", start_date=None, delivery_date=None):
        m = crud.get_mother_by_nic(db, nic)
        if not m:
            m = models.Mother(
                nic=nic, 
                full_name=name, 
                hashed_password=crud.get_password_hash("123"),
                midwife_id=midwife.id,
                status=status,
                risk_level=risk,
                pregnancy_start_date=start_date,
                delivery_date=delivery_date,
                contact_number="0771234567",
                address="123 Test St, Combo"
            )
            db.add(m)
            db.commit()
            db.refresh(m)
        return m

    today = datetime.now().date()
    
    # 2. Mother A: Early Pregnancy (12 Weeks)
    m_early = create_mother_if_not_exists("900000001V", "Mother Early (12w)", "Pregnant", "Low", today - timedelta(weeks=12))
    if not m_early.pregnancy_records:
        pr = models.PregnancyRecord(
            mother_id=m_early.id,
            registration_date=today - timedelta(weeks=10),
            lrmp=today - timedelta(weeks=12),
            edd=today + timedelta(weeks=28),
            gravidity=1, parity=0
        )
        db.add(pr)
        db.commit()
        # Add 1 Completed ANC Visit
        appt = models.Appointment(midwife_id=midwife.id, mother_id=m_early.id, date_time=datetime.now() - timedelta(weeks=2), visit_type="Clinic", status="Completed")
        db.add(appt)
        db.commit()
        db.refresh(appt)
        anc = models.ANCVisit(mother_id=m_early.id, appointment_id=appt.id, visit_date=appt.date_time.date(), poa_weeks="10", weight_kg=55.0, bp_systolic=110, bp_diastolic=70)
        db.add(anc)
        db.commit()
    
    # 3. Mother B: Late Pregnancy (36 Weeks) - Multiple Visits
    m_late = create_mother_if_not_exists("900000002V", "Mother Late (36w)", "Pregnant", "Low", today - timedelta(weeks=36))
    if not m_late.pregnancy_records:
        pr = models.PregnancyRecord(
             mother_id=m_late.id,
             lrmp=today - timedelta(weeks=36),
             edd=today + timedelta(weeks=4),
             gravidity=2, parity=1
        )
        db.add(pr)
        db.commit()
        # Backfill 5 visits
        for i in range(5):
            weeks_ago = 20 - (i*4) # 20, 16, 12, 8, 4 weeks ago
            if weeks_ago < 0: continue
            
            appt = models.Appointment(midwife_id=midwife.id, mother_id=m_late.id, date_time=datetime.now() - timedelta(weeks=weeks_ago), visit_type="Clinic", status="Completed")
            db.add(appt)
            db.commit()
            db.refresh(appt)
            
            # Growth curve data
            poa = 36 - weeks_ago
            anc = models.ANCVisit(
                mother_id=m_late.id, appointment_id=appt.id, visit_date=appt.date_time.date(), 
                poa_weeks=str(poa), 
                weight_kg=60.0 + i, # Gaining 1kg per visit
                fundal_height_cm=20.0 + i*2 # Growing
            )
            db.add(anc)
            db.commit()

    # 4. Mother C: Postnatal (Day 5)
    delivery_d = today - timedelta(days=5)
    m_pnc = create_mother_if_not_exists("900000003V", "Mother PNC (Day 5)", "Postnatal", "Low", today - timedelta(weeks=40), delivery_d)
    if not m_pnc.delivery_records:
        dr = models.DeliveryRecord(
            mother_id=m_pnc.id,
            delivery_date=datetime.combine(delivery_d, datetime.min.time()),
            delivery_mode="Normal",
            birth_weight=3.2,
            vitamin_a_given=True
        )
        db.add(dr)
        db.commit()
        # Add PNC Visit
        appt = models.Appointment(midwife_id=midwife.id, mother_id=m_pnc.id, date_time=datetime.now(), visit_type="Home Visit", status="Completed")
        db.add(appt)
        db.commit()
        db.refresh(appt)
        pnc = models.PNCVisit(
            mother_id=m_pnc.id, appointment_id=appt.id, visit_date=appt.date_time.date(),
            baby_weight=3.1, baby_color="Pink", breastfeeding="Establishing well"
        )
        db.add(pnc)
        db.commit()

    # 5. Mother D: High Risk (Hypertension)
    m_risk = create_mother_if_not_exists("900000004V", "Mother High Risk", "Pregnant", "High Risk", today - timedelta(weeks=20))
    if not m_risk.pregnancy_records:
        pr = models.PregnancyRecord(
            mother_id=m_risk.id,
            lrmp=today - timedelta(weeks=20),
            edd=today + timedelta(weeks=20),
            risk_cardiac=True, # Hypertension often grouped or specific, using cardiac/other for now or just generic risk
            other_risk_factors="Hypertension" # Custom
        )
        # Update mother risk level explicitly
        m_risk.risk_level = "High Risk"
        db.add(pr)
        db.add(m_risk)
        db.commit()

    # 6. Mother E: Eligible
    create_mother_if_not_exists("900000005V", "Mother Eligible", "Eligible")

    return {"message": "Full System Flow Seeded! Accounts: 900000001V to 900000005V (Password: 123)"}

# --- REPORTING ENDPOINTS ---

@app.get("/reports/stats")
def read_moh_stats(
    db: Session = Depends(get_db),
    current_moh: schemas.MOHOfficer = Depends(get_current_moh)
):
    return crud.get_moh_reports(db, moh_office_id=current_moh.moh_office_id)

# This tells FastAPI: "If someone goes to http://localhost:8000/static/login.html, show them that file."
app.mount("/static", StaticFiles(directory="static"), name="static")