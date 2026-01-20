from sqlalchemy import text
from sql_app.database import engine

def migrate():
    try:
        with engine.connect() as connection:
            # MySQL syntax to add columns if they don't exist
            # Note: generic 'ADD COLUMN' works for MySQL
            
            # 1. LATITUDE
            try:
                connection.execute(text("ALTER TABLE mothers ADD COLUMN latitude DECIMAL(9, 6) NULL"))
                print("Added latitude column.")
            except Exception as e:
                print(f"Latitude column might already exist or error: {e}")

            # 2. LONGITUDE
            try:
                connection.execute(text("ALTER TABLE mothers ADD COLUMN longitude DECIMAL(9, 6) NULL"))
                print("Added longitude column.")
            except Exception as e:
                print(f"Longitude column might already exist or error: {e}")

            # 3. MOH PROVINCE & DISTRICT (Pregnancy Record)
            try:
                connection.execute(text("ALTER TABLE pregnancy_records ADD COLUMN moh_province VARCHAR(100) NULL"))
                print("Added moh_province column.")
            except Exception as e:
                print(f"moh_province column might already exist or error: {e}")

            try:
                connection.execute(text("ALTER TABLE pregnancy_records ADD COLUMN moh_district VARCHAR(100) NULL"))
                print("Added moh_district column.")
            except Exception as e:
                print(f"moh_district column might already exist or error: {e}")

            # 4. IS_READ (Messages)
            try:
                connection.execute(text("ALTER TABLE messages ADD COLUMN is_read BOOLEAN DEFAULT 0"))
                print("Added is_read column to messages.")
            except Exception as e:
                print(f"is_read column might already exist or error: {e}")

            try:
                connection.execute(text("ALTER TABLE pregnancy_records ADD COLUMN moh_district VARCHAR(100) NULL"))
                print("Added moh_district column.")
            except Exception as e:
                print(f"moh_district column might already exist or error: {e}")

            connection.commit()
            print("Migration script finished.")
    except Exception as e:
        print(f"Connection failed: {e}")

if __name__ == "__main__":
    migrate()
