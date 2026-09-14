"""
===============================================================================
GitHub Analytics Database
Insertion Script: Insert Data into Bronze Tables (Source -> Bronze)
===============================================================================
Script Purpose:
    This stored procedure loads data into the 'bronze' schema from external CSV & JSON files. 
    It performs the following actions:
    - Truncates the bronze tables before loading data.
    - Uses the `COPY FROM` command to load data from csv & json Files to bronze tables.

Database:
    PostgreSQL

Parameters:
    None. 
	This Script does not accept any parameters or return any values.
"""

import psycopg2
from psycopg2.extensions import ISOLATION_LEVEL_AUTOCOMMIT
import logging
import os 
import time

# ===============================
# Logging Configuration
# ===============================
LOG_DIR = "Logs"
LOG_FILE = "Load_Bronze.log"

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
# File Paths
# =============================
DATA_PATH = "./Data/Raw" 

CSV_FILES = [
    ("bronze.programming_languages" , "programming_languages.csv"),
    ("bronze.users" , "users.csv"),
    ("bronze.organizations" , "organizations.csv"),
    ("bronze.organization_members" , "organization_members.csv"),
    ("bronze.repositories" , "repositories.csv"),
    ("bronze.repository_languages" , "repository_languages.csv"),
    ("bronze.repository_contributors" , "repository_contributors.csv", ),
    ("bronze.branches" , "branches.csv"),
    ("bronze.commits" , "commits.csv"),
    ("bronze.pull_requests" , "pull_requests.csv"),
    ("bronze.pull_request_reviews" , "pull_request_reviews.csv"),
    ("bronze.issues" , "issues.csv"),
    ("bronze.releases" , "releases.csv"),
    ("bronze.stars" , "stars.csv"),
    ("bronze.forks" , "forks.csv")
]

TABLE_NAMES = [
"bronze.programming_languages",
"bronze.users",
"bronze.organizations",
"bronze.organization_members",
"bronze.repositories",
"bronze.repository_languages",
"bronze.repository_contributors",
"bronze.branches",
"bronze.commits",
"bronze.pull_requests",
"bronze.pull_request_reviews",
"bronze.issues",
"bronze.releases",
"bronze.stars",
"bronze.forks"
]


# =============================
# Connect to PostgreSQL
# =============================
def create_connection():
    try:
        logging.info("Connecting to PostgreSQL database...")
        conn = psycopg2.connect(
            dbname=DB_NAME,
            user=DB_USER,
            password=DB_PASSWORD,
            host=DB_HOST,
            port=DB_PORT
        )
        conn.set_isolation_level(ISOLATION_LEVEL_AUTOCOMMIT)
        logging.info("Database connection established successfully.\n")
        return conn
    
    except Exception as e:
        # Show Logs error details & Stops execution if DB fails
        logging.error(f"Database connection failed: {e}\n") 
        raise


# =============================
# Truncate Tables
# =============================
def truncate_tables(conn):
    try:
        cursor = conn.cursor()
        
        logging.info("=" * 70)
        logging.info("TRUNCATING TABLES")
        logging.info("=" * 70)

        for table_name in TABLE_NAMES:
            # Get row count before truncate
            cursor.execute(f"SELECT COUNT(*) FROM {table_name};")
            before_count = cursor.fetchone()[0]
            
            # Truncate Table
            cursor.execute(f"TRUNCATE TABLE {table_name}")
            
            # Verify truncate
            cursor.execute(f"SELECT COUNT(*) FROM {table_name};")
            after_count = cursor.fetchone()[0]
            
            logging.info(
                f"Truncated {table_name}: "
                f"{before_count:,} rows deleted, {after_count} remaining"
            )

        cursor.close()
        logging.info("=" * 70)
        logging.info("All tables truncated successfully")
        logging.info("=" * 70 + "\n")

    except Exception as e:
        logging.error(f"Error during table truncation: {e}\n")
        raise


# =============================
# Insert CSV Data into Tables
# =============================
def insert_csv(table_name, csv_file, conn):
    start_time = time.time()

    try:
        cursor = conn.cursor()
        file_path = os.path.join(DATA_PATH, csv_file)
        
        # Get file size for logging
        file_size = os.path.getsize(file_path) / (1024 * 1024)  # MB
        
        logging.info(
            f"Started inserting '{csv_file}' data into '{table_name}' "
            f"(File size: {file_size:.2f} MB)"
        )
        
        # Get row count before insert
        cursor.execute(f"SELECT COUNT(*) FROM {table_name};")
        before_count = cursor.fetchone()[0]

        with open(file_path, 'r', encoding='utf-8') as f:
            cursor.copy_expert(
                sql=f"""
                COPY {table_name}
                FROM STDIN
                WITH CSV HEADER
                """,
                file=f
            )
            
        # Get row count after insert
        cursor.execute(f"SELECT COUNT(*) FROM {table_name};")
        after_count = cursor.fetchone()[0]
        rows_inserted = after_count - before_count

        elapsed_time = round(time.time() - start_time, 2)
        
        # Calculate insertion rate
        rows_per_second = int(rows_inserted / elapsed_time) if elapsed_time > 0 else 0
        
        logging.info(
            f"Completed '{table_name}': "
            f"{rows_inserted:,} rows inserted in {elapsed_time}s "
            f"({rows_per_second:,} rows/sec)"
        )

        cursor.close()
    
    except FileNotFoundError:
        logging.error(f"File not found: {file_path}")
        raise
    except psycopg2.Error as e:
        logging.error(f"PostgreSQL error inserting {csv_file}: {e}")
        raise
    except Exception as e:
        logging.error(f"Unexpected error inserting {csv_file}: {e}")
        raise


# =============================
# Main Execution Flow
# =============================
def main():
    start_time = time.time()
    
    logging.info("=" * 70)
    logging.info("BRONZE LAYER DATA INSERTION PROCESS STARTED")
    logging.info("=" * 70)

    conn = None
    success_count = 0

    try:
        
        # Connect to database
        conn = create_connection()
        
        # Clear existing data
        truncate_tables(conn)
        
        # Insert data from CSV files
        for table_name, csv_file in CSV_FILES:
            insert_csv(table_name, csv_file, conn)
            success_count += 1
        
        # Calculate total time
        total_time = time.time() - start_time
        
        logging.info("=" * 70)
        logging.info("DATA INSERTION SUMMARY")
        logging.info("=" * 70)
        logging.info(f"Tables processed: {len(CSV_FILES)}")
        logging.info(f"Successful: {success_count}")
        logging.info(f"Failed: {len(CSV_FILES) - success_count}")
        logging.info(f"Total time: {total_time:.2f} seconds\n")
        logging.info("=" * 70)
        logging.info("BRONZE LAYER DATA INSERTION COMPLETED SUCCESSFULLY")
        logging.info("=" * 70 + "\n")

    except Exception as e:
        logging.error("=" * 70)
        logging.error("DATA INSERTION FAILED")
        logging.error(f"Error: {str(e)}")
        logging.error("=" * 70 + "\n")
        raise
        
    finally:
        # Always close connection
        if conn:
            conn.close()
            logging.info("Database connection closed.")


# =============================
# Run Script
# =============================
if __name__ == "__main__":    
    try:
        main()
        
        print("\n" + "=" * 70)
        print("BRONZE LAYER DATA INSERTION COMPLETED SUCCESSFULLY!")
        print(f"Check logs: {os.path.join(LOG_DIR, LOG_FILE)}")
        print("=" * 70 + "\n")
        
    except Exception as e:
        print("\n" + "=" * 70)
        print("ERROR: Data insertion failed!")
        print(f"Check logs for details: {os.path.join(LOG_DIR, LOG_FILE)}")
        print("=" * 70 + "\n")
        exit(1)  # Exit with error code