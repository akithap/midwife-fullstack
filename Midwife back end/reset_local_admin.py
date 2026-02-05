from sql_app.database import SessionLocal
from sql_app import models, crud
from passlib.context import CryptContext

# Setup Hashing
pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")

def reset_password():
    db = SessionLocal()
    try:
        user = db.query(models.MOHOfficer).filter(models.MOHOfficer.username == "moh_admin").first()
        if user:
            print(f"Found user: {user.username}")
            hashed = pwd_context.hash("admin123")
            user.hashed_password = hashed
            db.commit()
            print("Password reset to 'admin123'")
        else:
            print("User 'moh_admin' not found.")
    except Exception as e:
        print(f"Error: {e}")
    finally:
        db.close()

if __name__ == "__main__":
    reset_password()
