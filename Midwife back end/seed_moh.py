from sql_app.database import SessionLocal, engine
from sql_app import models, crud, schemas

# Create tables if they don't exist
models.Base.metadata.create_all(bind=engine)

def create_admin():
    db = SessionLocal()
    try:
        # Check if exists
        existing = crud.get_moh_officer_by_username(db, "moh_admin")
        if existing:
            print("User 'moh_admin' already exists.")
            return

        # Create new
        moh_data = schemas.MOHOfficerCreate(
            username="moh_admin",
            password="password123",  # Simple password for testing
            full_name="Chief Medical Officer",
            moh_area="Colombo",
            email="moh@example.com"
        )
        crud.create_moh_officer(db, moh_data)
        print("Successfully created MOH Officer:")
        print("Username: moh_admin")
        print("Password: password123")
    except Exception as e:
        print(f"Error: {e}")
    finally:
        db.close()

if __name__ == "__main__":
    create_admin()
