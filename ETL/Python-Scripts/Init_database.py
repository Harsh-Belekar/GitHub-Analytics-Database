'''
=============================================================
GitHub Analytics Database
Create Database and Schemas
=============================================================
Author       : Harsh Belekar
Project      : GitHub Analytics Data Pipeline
Pipeline     : Raw → Bronze → Silver → Gold

Script Purpose:
    This script creates a three schemas within the database named 'GitHub_Data_Warehouse':
	'bronze', 'silver', and 'gold' after checking if it already exists.
    If the schemas exists, it is dropped and recreated.
	
WARNING:
    Running this script will drop all three Schemas 'bronze', 'silver', and 'gold' in database if it exists. 
    All data in the Schems will be permanently deleted. Proceed with caution 
    and ensure you have proper backups before running this script.
'''

import psycopg2
from psycopg2.extensions import ISOLATION_LEVEL_AUTOCOMMIT
import logging
import os 
import time

# ===============================
# Logging Configuration
# ===============================
LOG_DIR = "Logs"
LOG_FILE = "Init_database.log"

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
# Create Schemas
# =============================
def create_schema(cursor):
    logging.info("=" * 70)
    logging.info("Starting Schema Creation Process...")
    logging.info("=" * 70)
    
    Schemas = ["bronze","silver","gold"]
        
    for schema in Schemas:
        try:
            logging.info(f"Executing: `{schema}` Schema Creation Query")
            cursor.execute(f"DROP SCHEMA IF EXISTS {schema};")
            cursor.execute(f"CREATE SCHEMA {schema};")
            logging.info(f"`{schema}` Schema Created Successfully.")

        except Exception as e:
            logging.error(f"Failed to Execute `{schema}` Schema Creation Query : {str(e)}")
            raise
        
    logging.info("All Schemas created successfully!\n")

# =============================
# Run Script
# =============================
if __name__ == "__main__":
    start_time = time.time()
    
    logging.info("=" * 70)
    logging.info("GitHub WAREHOUSE SETUP - STARTING")
    logging.info("=" * 70)
    
    try:
        # Connect to database
        conn = create_connection()
        cursor = conn.cursor()
        
        # Create Schemas
        create_schema(cursor)
        
        end_time = time.time()
        duration = end_time - start_time
        
        logging.info("=" * 70)
        logging.info("GitHub WAREHOUSE SETUP COMPLETED SUCCESSFULLY")
        logging.info(f"Total time: {duration:.2f} seconds")
        logging.info("=" * 70 + "\n")
        
        print("\n" + "=" * 70)
        print("All Schemas Created Successfully!")
        print(f"Time taken: {duration:.2f} seconds")
        print(f"Check logs: {os.path.join(LOG_DIR, LOG_FILE)}")
        print("=" * 70 + "\n")
    
    except Exception as e:
        logging.error("=" * 70)
        logging.error("WAREHOUSE SETUP FAILED")
        logging.error(f"Error: {str(e)}")
        logging.error("=" * 70 + "\n")
        
        print("\n" + "=" * 70)
        print("ERROR: WAREHOUSE setup failed!")
        print(f"Check logs for details: {os.path.join(LOG_DIR, LOG_FILE)}")
        print("=" * 70 + "\n")
        
    finally:
        # Always close connection
        if conn:
            conn.close()
            logging.info("Database connection closed.")