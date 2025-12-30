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
    # Currently returns all midwives; can be filtered by moh_area if needed later
    return db.query(models.Midwife).all()



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
    return crud.get_mothers_by_risk(db, current_midwife.id, risk_type)


# --- TEMPORARY SEED ENDPOINT ---
@app.get("/seed-moh")
def seed_moh(db: Session = Depends(get_db)):
    existing = crud.get_moh_officer_by_username(db, "moh_admin")
    if existing:
        # Force Reset Password
        existing.hashed_password = crud.get_password_hash("password123")
        db.commit()
        return {"message": "User 'moh_admin' exists. PASSWORD RESET to: password123"}
    

@app.get("/seed-moh")
def seed_moh(db: Session = Depends(get_db)):
    # 1. Check if MOH Admin exists
    moh = crud.get_moh_officer_by_username(db, "moh_admin")
    if not moh:
        moh_data = schemas.MOHOfficerCreate(
            username="moh_admin",
            password="password123",
            full_name="System Admin",
            moh_area="Colombo"
        )
        crud.create_moh_officer(db, moh_data)
        return {"message": "Created MOH Admin: moh_admin / password123"}
    return {"message": "MOH Admin already exists"}

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

@app.get("/seed-dashboard")
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

    return {"message": "Seeded Dashboard: 1 Midwife, 5 Mothers, 3 Appointments"}

# This tells FastAPI: "If someone goes to http://localhost:8000/static/login.html, show them that file."
app.mount("/static", StaticFiles(directory="static"), name="static")