
import os
import sys

# Get the current directory (sql_app)
current_dir = os.path.dirname(os.path.abspath(__file__))

# Go up one level to the backend root (Midwife back end)
backend_root = os.path.dirname(current_dir)

# Add the backend root to sys.path
sys.path.append(backend_root)

# Now we can mock the import structure
from sql_app.database import engine, Base
from sql_app import models

def create_tables():
    print("Creating database tables...")
    Base.metadata.create_all(bind=engine)
    print("Tables created successfully!")

if __name__ == "__main__":
    create_tables()
