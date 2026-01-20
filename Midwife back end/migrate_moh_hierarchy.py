from sql_app import database
from sqlalchemy import text

def migrate():
    print("Migrating Database Schema for MOH Hierarchy...")
    with database.engine.connect() as conn:
        # 1. Add moh_office_id to moh_officers
        try:
            conn.execute(text("ALTER TABLE moh_officers ADD COLUMN moh_office_id INT"))
            conn.execute(text("ALTER TABLE moh_officers ADD CONSTRAINT fk_moh_officer_office FOREIGN KEY (moh_office_id) REFERENCES moh_offices(id)"))
            print("Added moh_office_id to moh_officers.")
        except Exception as e:
            print(f"Skipped moh_officers update (maybe exists): {e}")

        # 2. Add moh_office_id to midwives
        try:
            conn.execute(text("ALTER TABLE midwives ADD COLUMN moh_office_id INT"))
            conn.execute(text("ALTER TABLE midwives ADD CONSTRAINT fk_midwife_office FOREIGN KEY (moh_office_id) REFERENCES moh_offices(id)"))
            print("Added moh_office_id to midwives.")
        except Exception as e:
             print(f"Skipped midwives update (maybe exists): {e}")
             
        conn.commit()
    print("Migration Complete.")

if __name__ == "__main__":
    migrate()
