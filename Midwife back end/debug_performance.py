from sql_app.database import SessionLocal
from sql_app import models
from sqlalchemy import extract
from datetime import datetime

def debug():
    db = SessionLocal()
    try:
        print("Debugging Performance Data...")
        
        # 1. Check Total Appointments
        total = db.query(models.Appointment).count()
        print(f"Total Appointments: {total}")
        
        # 2. Check Completed
        completed = db.query(models.Appointment).filter(models.Appointment.status == "Completed").all()
        print(f"Completed Appointments: {len(completed)}")
        
        if completed:
            print(f"Sample Date: {completed[0].date_time} (Type: {type(completed[0].date_time)})")
            
        # 3. Check Date Filter (Current Month)
        current_month = datetime.now().month
        current_year = datetime.now().year
        print(f"Target: Month={current_month}, Year={current_year}")
        
        filtered = db.query(models.Appointment).filter(
            models.Appointment.status == "Completed",
            extract('month', models.Appointment.date_time) == current_month,
            extract('year', models.Appointment.date_time) == current_year
        ).all()
        
        print(f"Filtered Count (Direct Query): {len(filtered)}")
        
        # 4. Filter in Python to compare
        py_filtered = [a for a in completed if a.date_time.month == current_month and a.date_time.year == current_year]
        print(f"Filtered Count (Python): {len(py_filtered)}")

    except Exception as e:
        print(f"Error: {e}")
    finally:
        db.close()

if __name__ == "__main__":
    debug()
