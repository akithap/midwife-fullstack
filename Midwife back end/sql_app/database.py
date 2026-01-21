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

# CRITICAL FIX FOR VERCEL & TiDB:
# 1. Force 'mysql+pymysql' driver (more stable in serverless than mysql-connector)
# 2. Add SSL arguments required by TiDB Cloud
if SQLALCHEMY_DATABASE_URL.startswith("mysql://"):
    SQLALCHEMY_DATABASE_URL = SQLALCHEMY_DATABASE_URL.replace("mysql://", "mysql+pymysql://", 1)
elif SQLALCHEMY_DATABASE_URL.startswith("mysql+mysqlconnector://"):
    SQLALCHEMY_DATABASE_URL = SQLALCHEMY_DATABASE_URL.replace("mysql+mysqlconnector://", "mysql+pymysql://", 1)

# OPTIMIZATION FOR VERCEL / SERVERLESS:
# 1. pool_pre_ping=True: Checks connection liveliness before using it (prevents "Gone Away" errors).
# 2. pool_recycle=300: Recycles connections every 5 minutes (TiDB/MySQL defaults often kill idle ones).
# 3. SSL: TiDB requires SSL. Passing an empty dict or specific config triggers PyMySQL to use system CAs.
#    We avoid hardcoding "/etc/ssl/cert.pem" as it varies by OS (Vercel uses Amazon Linux 2).
#    Simply passing "ssl": {} often works to enforce SSL with system defaults.
engine = create_engine(
    SQLALCHEMY_DATABASE_URL,
    pool_pre_ping=True, 
    pool_recycle=300,
    connect_args={
        "ssl": {} # Use system default CA bundles
    }
)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
Base = declarative_base()