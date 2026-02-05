from sql_app.database import engine, Base
from sql_app import models
from sqlalchemy import text

def fix_schema():
    print("Attempting to fix database schema for 'leave_requests'...")
    try:
        with engine.connect() as connection:
            # Check if table exists
            result = connection.execute(text("SHOW TABLES LIKE 'leave_requests'"))
            table_exists = result.fetchone()
            
            if table_exists:
                print("Table 'leave_requests' exists. Checking for 'created_at' column...")
                # Check columns
                result = connection.execute(text("SHOW COLUMNS FROM leave_requests LIKE 'created_at'"))
                col_exists = result.fetchone()
                
                if not col_exists:
                    print("Column 'created_at' is MISSING. Dropping table to allow full recreation...")
                    connection.execute(text("DROP TABLE leave_requests"))
                    print("Table dropped.")
                else:
                    print("Column 'created_at' already exists.")
            else:
                print("Table 'leave_requests' does not exist.")
                
            connection.commit()
            
        # Re-create tables
        print("Running create_all to recreate missing tables/columns...")
        models.Base.metadata.create_all(bind=engine)
        print("Schema update complete.")
        
    except Exception as e:
        print(f"Error fixing schema: {e}")

if __name__ == "__main__":
    fix_schema()
