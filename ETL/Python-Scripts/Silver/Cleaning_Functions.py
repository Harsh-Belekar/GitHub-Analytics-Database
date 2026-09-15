import psycopg2
from psycopg2.extensions import ISOLATION_LEVEL_AUTOCOMMIT
import logging
import os 
import time

# ===============================
# Logging Configuration
# ===============================
LOG_DIR = "Logs"
LOG_FILE = "Cleaning_Functions.log"

# Creates Logs/ folder if it doesn’t exist
os.makedirs(LOG_DIR, exist_ok=True) 

logging.basicConfig(
    filename=os.path.join(LOG_DIR, LOG_FILE),
    level=logging.INFO,
    format="%(asctime)s | %(levelname)s | %(message)s"
)


# =============================
# Database Configuration
# =============================
DB_NAME = "GitHub-Data-Warehouse"
DB_USER = "postgres"
DB_PASSWORD = "your_password" # Replace this with Your Password 
DB_HOST = "localhost"
DB_PORT = "5432"


# ============================================================
# SHARED CLEANING FUNCTIONS
# ============================================================
SCHEMA = "CREATE SCHEMA IF NOT EXISTS cleaning;"


FN_PARSE_DATE = """
CREATE OR REPLACE FUNCTION cleaning.fn_parse_date(raw_value TEXT)
RETURNS TIMESTAMP
LANGUAGE PLPGSQL
AS $$
DECLARE
    cleaned TEXT := TRIM(raw_value);
BEGIN
    IF cleaned IS NULL OR cleaned = '' THEN
        RETURN NULL;
    END IF;

    BEGIN
        RETURN cleaned::TIMESTAMP;                          -- YYYY-MM-DD HH24:MI:SS[.US]
    EXCEPTION WHEN others THEN
        NULL; -- fall through to next attempt
    END;

    BEGIN
        RETURN TO_TIMESTAMP(cleaned, 'DD/MM/YYYY HH24:MI');
    EXCEPTION WHEN others THEN
        NULL;
    END;

    BEGIN
        RETURN TO_TIMESTAMP(cleaned, 'MM-DD-YYYY');
    EXCEPTION WHEN others THEN
        NULL;
    END;

    BEGIN
        RETURN TO_TIMESTAMP(cleaned, 'DD Mon YYYY HH12:MI AM');
    EXCEPTION WHEN others THEN
        NULL;
    END;

    RETURN NULL; -- genuinely unparseable
END;
$$;
"""

FN_TO_BOOLEAN = """
CREATE OR REPLACE FUNCTION cleaning.fn_to_boolean(raw_value TEXT)
RETURNS BOOLEAN
LANGUAGE PLPGSQL
AS $$
DECLARE
    cleaned TEXT := LOWER(TRIM(raw_value));
BEGIN
    IF cleaned IS NULL OR cleaned = '' THEN
        RETURN NULL;
    ELSIF cleaned IN ('true', 't', '1', 'yes', 'y') THEN
        RETURN TRUE;
    ELSIF cleaned IN ('false', 'f', '0', 'no', 'n') THEN
        RETURN FALSE;
    ELSE
        RETURN NULL;
    END IF;
END;
$$;
"""

FN_CLEAN_EMAIL = """
CREATE OR REPLACE FUNCTION cleaning.fn_clean_email(raw_value TEXT)
RETURNS TEXT
LANGUAGE PLPGSQL
AS $$
DECLARE
    cleaned TEXT;
BEGIN
    IF raw_value IS NULL THEN
        RETURN NULL;
    END IF;

    cleaned := LOWER(TRIM(raw_value));
    cleaned := REPLACE(cleaned, ' ', '');
    cleaned := REPLACE(cleaned, '_at_', '@');
    cleaned := REGEXP_REPLACE(cleaned, '\.{2,}', '.', 'g');

    RETURN cleaned;
END;
$$;
"""


Cleaning_Func = [
    (SCHEMA, "cleaning Schema"),
    (FN_PARSE_DATE, "fn_parse_date Function"),
    (FN_TO_BOOLEAN, "fn_to_boolean Function"),
    (FN_CLEAN_EMAIL, "fn_clean_email Function")
]


# =============================
# # Connect to PostgreSQL
# =============================
def create_connection():
    try:
        logging.info("Connecting to PostgreSQL Database...")
        conn = psycopg2.connect(
            dbname=DB_NAME,
            user=DB_USER,
            password=DB_PASSWORD,
            host=DB_HOST,
            port=DB_PORT
        )
        conn.set_isolation_level(ISOLATION_LEVEL_AUTOCOMMIT)
        logging.info("Database connection Established Successfully.\n")
        return conn
    
    except Exception as e:
        # Show Logs error details & Stops execution if DB fails
        logging.error(f"Database Connection Failed: {e}\n") 
        raise


# =============================
# Execute Query
# =============================    
def execute_query(cursor,query, query_name):
    try:
        logging.info(f"Executing: {query_name} Query")
        start_time = time.time()
        cursor.execute(query)
        end_time = time.time()
        duration = end_time - start_time
        logging.info(f"{query_name} Created Successfully in ({duration:.2f}s).")
    
    except Exception as e:
        logging.error(f"Failed to Execute {query_name} Query : {str(e)}")
        raise


# =============================
# Create Tables
# =============================
def create_clean_func(conn):
    logging.info("=" * 70)
    logging.info("Starting Cleaning Function Creation Process...")
    logging.info("=" * 70)
    cursor = conn.cursor()
    
    success_count = 0
    failed_count = 0
    
    for query, name in Cleaning_Func:
        try:
            execute_query(cursor, query, name)
            success_count += 1
        except Exception as e:
            failed_count += 1
            logging.error(f"Skipping {name} due to error")
        
    cursor.close()
    logging.info("=" * 70)
    logging.info("CLEANING FUNCTION SUMMARY")
    logging.info("=" * 70)
    logging.info(f"Total operations: {len(Cleaning_Func)}")
    logging.info(f"Successful: {success_count}")
    logging.info(f"Failed: {failed_count}")
    logging.info("=" * 70 + "\n")
    
    if failed_count == 0:
        logging.info("All CLEANING Function created successfully!\n")
    else:
        logging.warning(f"{failed_count} operation(s) failed. Check logs above.\n")


# =============================
# Run Script
# =============================
if __name__ == "__main__":
    start_time = time.time()
    
    logging.info("=" * 70)
    logging.info("CLEANING FUNCTION SETUP - STARTING")
    logging.info("=" * 70)
    
    conn = None
    
    try:
        # Connect to database
        conn = create_connection()
        
        # Create all CLEANING Function
        create_clean_func(conn)
        
        # Success message
        end_time = time.time()
        duration = end_time - start_time
        
        logging.info("=" * 70)
        logging.info("CLEANING FUNCTION CREATION COMPLETED SUCCESSFULLY")
        logging.info(f"Total time: {duration:.2f} seconds")
        logging.info("=" * 70 + "\n")
        
        print("\n" + "=" * 70)
        print("All CLEANING Functions Created Successfully!")
        print(f"Time taken: {duration:.2f} seconds")
        print(f"Check logs: {os.path.join(LOG_DIR, LOG_FILE)}")
        print("=" * 70 + "\n")
    
    except Exception as e:
        logging.error("=" * 70)
        logging.error("CLEANING FUNCTION CREATION FAILED")
        logging.error(f"Error: {str(e)}")
        logging.error("=" * 70 + "\n")
        
        print("\n" + "=" * 70)
        print("ERROR: Database setup failed!")
        print(f"Check logs for details: {os.path.join(LOG_DIR, LOG_FILE)}")
        print("=" * 70 + "\n")
    
    finally:
        # Always close connection
        if conn:
            conn.close()
            logging.info("Database connection closed.")
            