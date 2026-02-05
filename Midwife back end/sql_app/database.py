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

import certifi

# OPTIMIZATION FOR VERCEL / SERVERLESS:
# 1. pool_pre_ping=True: Checks connection liveliness before using it (prevents "Gone Away" errors).
# 2. pool_recycle=300: Recycles connections every 5 minutes (TiDB/MySQL defaults often kill idle ones).
# 3. SSL: TiDB requires SSL (Secure Transport).
#    Using 'certifi' guarantees we have a valid CA bundle, fixing the "Insecure transport" error.
# 3. SSL: TiDB requires SSL (Secure Transport).
#    Only apply SSL for remote connections (not localhost) to avoid "self-signed certificate" errors locally.
connect_args = {}
if "localhost" not in SQLALCHEMY_DATABASE_URL and "127.0.0.1" not in SQLALCHEMY_DATABASE_URL:
    connect_args["ssl"] = {
        "ca": certifi.where(),
        "check_hostname": False
    }

engine = create_engine(
    SQLALCHEMY_DATABASE_URL,
    pool_pre_ping=True, 
    pool_recycle=300,
    connect_args=connect_args
)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
Base = declarative_base()