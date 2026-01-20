from sql_app.database import SessionLocal
from sql_app import crud

db = SessionLocal()

def verify_reports():
    print("--- Testing get_moh_reports('Colombo') ---")
    try:
        stats = crud.get_moh_reports(db, "Colombo")
        print("SUCCESS! Stats received:")
        print(stats)
    except Exception as e:
        print("FAILURE! Error:")
        import traceback
        traceback.print_exc()

if __name__ == "__main__":
    verify_reports()
