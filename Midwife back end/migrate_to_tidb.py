
import sqlalchemy
from sqlalchemy import create_engine, MetaData, Table, text, inspect
import logging

# Setup Logging
logging.basicConfig(level=logging.INFO, format='%(levelname)s: %(message)s')
logger = logging.getLogger(__name__)

# --- CONFIGURATION ---

# 1. Local Database (Source)
LOCAL_DB_URL = "mysql+mysqlconnector://root:1234@localhost/midwife_db"

# 2. TiDB Cloud (Destination)
# Using PyMySQL with generic SSL
TIDB_URL = "mysql+pymysql://28Zi1CmK1JPgXpM.root:MGo6riH1oRH2v1Mh@gateway01.ap-southeast-1.prod.aws.tidbcloud.com:4000/test"

import certifi

# Connect Args for Windows/Generic SSL (Avoids /etc/ssl/cert.pem error)
connect_args = {
    "ssl": {"ca": certifi.where(), "check_hostname": False} 
}
# Note: For PyMySQL, passing an empty dict or ssl=True usually triggers default SSL context.

def migrate():
    # Connect
    logger.info("Connecting to Source (Local)...")
    source_engine = create_engine(LOCAL_DB_URL)
    
    logger.info("Connecting to Destination (TiDB)...")
    # Note: connect_args passed here
    dest_engine = create_engine(TIDB_URL, connect_args={"ssl": {"check_hostname": False}}) 

    metadata = MetaData()
    
    # Reflect tables from Source
    logger.info("Reflecting tables from Source...")
    metadata.reflect(bind=source_engine)
    
    # Get tables sorted by dependency (to handle Foreign Keys)
    # sorted_tables is a property of metadata if reflection is complete
    # However, circular dependencies can break this.
    # We will try topological sort or a hardcoded list if that fails.
    
    try:
        tables = metadata.sorted_tables
    except Exception as e:
        logger.warning(f"Could not sort tables automatically: {e}. Using raw list.")
        tables = metadata.tables.values()

    # Create tables in Destination if they don't exist
    # logger.info("Creating schema in Destination...")
    # metadata.create_all(bind=dest_engine) 
    # (Assuming schema exists from deployment, but create_all is safe to run)
    
    with source_engine.connect() as source_conn, dest_engine.connect() as dest_conn:
        # Disable Foreign Key Checks on Destination temporarily to allow easier insertion
        # (This is TiDB/MySQL specific)
        dest_conn.execute(text("SET FOREIGN_KEY_CHECKS=0"))
        
        for table in tables:
            table_name = table.name
            logger.info(f"Migrating table: {table_name}")
            
            # Read from Source
            stmt = table.select()
            data = source_conn.execute(stmt).fetchall()
            
            if not data:
                logger.info(f"  -> No data. Skipping.")
                continue
                
            logger.info(f"  -> Found {len(data)} rows. Inserting...")
            
            # Insert into Destination
            # We use chunks to avoid huge packets
            chunk_size = 100
            total_inserted = 0
            
            # Convert list of Rows to list of Dicts
            # SQLAlchemy 1.4/2.0+ returns Row objects which are dict-like but explicit conversion is safer
            data_dicts = [dict(row._mapping) for row in data]
            
            # Simple chunking
            for i in range(0, len(data_dicts), chunk_size):
                chunk = data_dicts[i:i+chunk_size]
                try:
                    # 'insert()' statement
                    # We assume table exists on dest (created via create_all or previous alembic)
                    # If not, create_all above handles it.
                    
                    # NOTE: dest_engine might not know about the table structure if we didn't reflect from dest.
                    # Use the same 'table' object (which is bound to metadata, not engine specific for SQL generation)
                    dest_conn.execute(table.insert(), chunk)
                    dest_conn.commit()
                    total_inserted += len(chunk)
                except Exception as e:
                    logger.error(f"  -> Error inserting chunk {i}: {e}")
                    # Try raw insert or continue?
                    # For duplicate keys, we might want to skip.
                    # TiDB might throw IntegrityError.
            
            logger.info(f"  -> Inserted {total_inserted}/{len(data)} rows.")

        # Re-enable Foreign Key Checks
        dest_conn.execute(text("SET FOREIGN_KEY_CHECKS=1"))
        
    logger.info("Migration Complete!")

if __name__ == "__main__":
    migrate()
