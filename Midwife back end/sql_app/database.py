import os
from sqlalchemy import create_engine
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker

# 1. Get the Database URL from environment variables (for Railway).
# 2. If not found (running locally), use your hardcoded local connection.
SQLALCHEMY_DATABASE_URL = os.getenv(
    "DATABASE_URL", 
    "mysql+mysqlconnector://root:1234@localhost/midwife_db"
)

# CRITICAL FIX FOR RAILWAY:
# Railway provides URLs starting with "mysql://", but the driver 
# 'mysql-connector-python' (which you have in requirements.txt) 
# strictly requires "mysql+mysqlconnector://".
if SQLALCHEMY_DATABASE_URL.startswith("mysql://"):
    SQLALCHEMY_DATABASE_URL = SQLALCHEMY_DATABASE_URL.replace("mysql://", "mysql+mysqlconnector://", 1)
elif SQLALCHEMY_DATABASE_URL.startswith("mysql+pymysql://"):
    SQLALCHEMY_DATABASE_URL = SQLALCHEMY_DATABASE_URL.replace("mysql+pymysql://", "mysql+mysqlconnector://", 1)

# OPTIMIZATION FOR VERCEL / SERVERLESS:
# 1. pool_pre_ping=True: Checks connection liveliness before using it (prevents "Gone Away" errors).
# 2. pool_recycle=300: Recycles connections every 5 minutes (TiDB/MySQL defaults often kill idle ones).
# 3. pool_size=5, max_overflow=10: Default is usually fine, but explicit is good.
engine = create_engine(
    SQLALCHEMY_DATABASE_URL,
    pool_pre_ping=True, 
    pool_recycle=300
)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
Base = declarative_base()