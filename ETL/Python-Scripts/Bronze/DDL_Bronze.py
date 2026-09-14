"""
===============================================================================
GitHub Analytics Database
DDL Script: Create Bronze Tables
===============================================================================
Script Purpose:
    This script creates tables in the 'bronze' schema, dropping existing tables 
    if they already exist.
	Run this script to re-define the DDL structure of 'bronze' Tables

Author       : Harsh Belekar
Project      : GitHub Analytics Database
Pipeline     : Raw → Bronze → Silver → Gold
===============================================================================
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
LOG_FILE = "DDL_Bronze.log"

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


# =====================================================================
# TABLE CREATION QUERIES
# =====================================================================


CREATE_PROGRAMMING_LANGUAGES_TABLE = """
CREATE TABLE bronze.programming_languages (
    language_id          INT,
    language_name        VARCHAR(100),
    file_extension       VARCHAR(20),
    language_type        VARCHAR(50),
    first_release_year   INT,
    is_popular           BOOLEAN,
    created_at           TIMESTAMP
);
"""

CREATE_USERS_TABLE = """
CREATE TABLE bronze.users (
    user_id         INT,
    first_name      VARCHAR(100),
    last_name       VARCHAR(100),
    username        VARCHAR(100),
    email           VARCHAR(255),
    country         VARCHAR(100),
    city            VARCHAR(100),
    bio             TEXT,
    company         VARCHAR(150),
    hireable        BOOLEAN,
    verified        BOOLEAN,
    followers       INT,
    following       INT,
    public_repos    INT,
    public_gists    INT,
    account_type    VARCHAR(30),
    avatar_url      VARCHAR(500),
    profile_url     VARCHAR(500),
    created_at      TIMESTAMP,
    updated_at      TIMESTAMP
);
"""

CREATE_ORGANIZATIONS_TABLE = """
CREATE TABLE bronze.organizations (
    organization_id       INT,
    organization_name     VARCHAR(150),
    organization_type     VARCHAR(50),
    country               VARCHAR(100),
    city                  VARCHAR(100),
    website               VARCHAR(255),
    email                 VARCHAR(255),
    industry              VARCHAR(100),
    total_repositories    INT,
    total_members         INT,
    verified              BOOLEAN,
    created_at            TIMESTAMP
);
"""

CREATE_ORGANIZATIONS_MENBERS_TABLE = """
CREATE TABLE bronze.organization_members (
    membership_id       INT,
    organization_id     INT,
    user_id             INT,
    role                VARCHAR(30),
    joined_at           TIMESTAMP,
    is_public           BOOLEAN
);
"""

CREATE_REPOSITORIES_TABLE = """
CREATE TABLE bronze.repositories (
    repository_id          INT,
    owner_id               INT,
    organization_id        FLOAT,
    repository_name        VARCHAR(200),
    description            TEXT,
    visibility             VARCHAR(20),
    default_branch         VARCHAR(50),
    primary_language_id    INT,
    license                VARCHAR(100),
    repository_size_mb     DECIMAL(10, 2),
    has_issues             BOOLEAN,
    has_wiki               BOOLEAN,
    has_projects           BOOLEAN,
    archived               BOOLEAN,
    created_at             TIMESTAMP,
    updated_at             TIMESTAMP
);
"""

CREATE_REPOSITORIES_LANGUAGES_TABLE = """
CREATE TABLE bronze.repository_languages (
    repository_language_id    INT,
    repository_id             INT,
    language_id               INT,
    percentage_used           DECIMAL(5, 2)
);
"""

CREATE_REPOSITORIES_CONTRIBUTORS_TABLE = """
CREATE TABLE bronze.repository_contributors (
    contributor_id       INT,
    repository_id        INT,
    user_id              INT,
    total_commits        INT,
    first_commit_date    TIMESTAMP,
    last_commit_date     TIMESTAMP
);
"""

CREATE_BRANCHES_TABLE = """
CREATE TABLE bronze.branches (
    branch_id        INT,
    repository_id    INT,
    branch_name      VARCHAR(100),
    created_by       INT,
    is_default       BOOLEAN,
    created_at       TIMESTAMP
);
"""

CREATE_COMMITS_TABLE = """
CREATE TABLE bronze.commits (
    commit_id           BIGINT,
    commit_hash         VARCHAR(40),
    repository_id       INT,
    branch_id           INT,
    user_id             INT,
    commit_message      VARCHAR(500),
    files_changed       INT,
    lines_added         INT,
    lines_deleted       INT,
    commit_timestamp    TIMESTAMP
);
"""

CREATE_PULL_REQUESTS_TABLE = """
CREATE TABLE bronze.pull_requests (
    pull_request_id      INT,
    repository_id        INT,
    user_id              INT,
    source_branch_id     INT,
    target_branch_id     INT,
    title                VARCHAR(300),
    status               VARCHAR(20),
    files_changed        INT,
    created_at           TIMESTAMP,
    merged_at            TIMESTAMP
);
"""

CREATE_PULL_REQUEST_REVIEWS_TABLE = """
CREATE TABLE bronze.pull_request_reviews (
    review_id          INT,
    pull_request_id    INT,
    reviewer_id        INT,
    review_state       VARCHAR(30),
    review_comment     TEXT,
    reviewed_at        TIMESTAMP
);
"""

CREATE_ISSUES_TABLE = """
CREATE TABLE bronze.issues (
    issue_id        INT,
    repository_id   INT,
    user_id         INT,
    title           VARCHAR(300),
    issue_type      VARCHAR(30),
    priority        VARCHAR(20),
    status          VARCHAR(20),
    created_at      TIMESTAMP,
    closed_at       TIMESTAMP
);
"""

CREATE_RELEASES_TABLE = """
CREATE TABLE bronze.releases (
    release_id        INT,
    repository_id     INT,
    tag_name          VARCHAR(50),
    version           VARCHAR(50),
    release_title     VARCHAR(300),
    release_notes     TEXT,
    published_by      INT,
    published_at      TIMESTAMP
);
"""

CREATE_STARS_TABLE = """
CREATE TABLE bronze.stars (
    star_id         BIGINT,
    repository_id   INT,
    user_id         INT,
    starred_at      TIMESTAMP
);
"""

CREATE_FORKS_TABLE = """
CREATE TABLE bronze.forks (
    fork_id                 INT,
    source_repository_id    INT,
    forked_repository_id    INT,
    user_id                 INT,
    forked_at               TIMESTAMP
);
"""

Tables = [
    (CREATE_PROGRAMMING_LANGUAGES_TABLE, "programming_languages"),
    (CREATE_USERS_TABLE, "users"),
    (CREATE_ORGANIZATIONS_TABLE, "organizations"),
    (CREATE_ORGANIZATIONS_MENBERS_TABLE, "organization_members"),
    (CREATE_REPOSITORIES_TABLE, "repositories"),
    (CREATE_REPOSITORIES_LANGUAGES_TABLE, "repository_languages"),
    (CREATE_REPOSITORIES_CONTRIBUTORS_TABLE, "repository_contributors"),
    (CREATE_BRANCHES_TABLE, "branches"),
    (CREATE_COMMITS_TABLE, "commits"),
    (CREATE_PULL_REQUESTS_TABLE, "pull_requests"),
    (CREATE_PULL_REQUEST_REVIEWS_TABLE, "pull_request_reviews"),
    (CREATE_ISSUES_TABLE, "issues"),
    (CREATE_RELEASES_TABLE, "releases"),
    (CREATE_STARS_TABLE, "stars"),
    (CREATE_FORKS_TABLE, "forks")
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
        logging.info(f"Executing: {query_name} Table Query")
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
def create_all_tables(conn):
    logging.info("=" * 70)
    logging.info("Starting Bronze Layer Table Creation Process...")
    logging.info("=" * 70)
    cursor = conn.cursor()
    
    success_count = 0
    failed_count = 0
    
    for query, name in Tables:
        try:
            execute_query(cursor, query, name)
            success_count += 1
        except Exception as e:
            failed_count += 1
            logging.error(f"Skipping {name} Table due to error")
        
    cursor.close()
    logging.info("=" * 70)
    logging.info("TABLE CREATION SUMMARY")
    logging.info("=" * 70)
    logging.info(f"Total operations: {len(Tables)}")
    logging.info(f"Successful: {success_count}")
    logging.info(f"Failed: {failed_count}")
    logging.info("=" * 70 + "\n")
    
    if failed_count == 0:
        logging.info("All Tables created successfully!\n")
    else:
        logging.warning(f"{failed_count} operation(s) failed. Check logs above.\n")


# =============================
# Drop Tables
# =============================
def drop_all_tables(conn):
    logging.info("=" * 70)
    logging.info("DROPPING EXISTING TABLES")
    logging.info("=" * 70)
    cursor = conn.cursor()
    
    dropped_count = 0
    
    for query, name in Tables:
        try:
            cursor.execute(f"DROP TABLE IF EXISTS bronze.{name} CASCADE;")
            logging.info(f"Dropped table: {name}")
            dropped_count += 1
        
        except Exception as e:
            logging.warning(f"Table {name} not found (probably doesn't exist yet)")
    
    cursor.close()

    logging.info("=" * 70)
    logging.info(f"Dropped {dropped_count}/{len(Tables)} tables")
    logging.info("=" * 70 + "\n")


# =============================
# Run Script
# =============================
if __name__ == "__main__":
    start_time = time.time()
    
    logging.info("=" * 70)
    logging.info("GitHub Data WAREHOUSE SETUP - STARTING")
    logging.info("=" * 70)
    
    conn = None
    
    try:
        # Connect to database
        conn = create_connection()
        
        # Drop existing tables
        drop_all_tables(conn)
        
        # Create all tables and indexes
        create_all_tables(conn)
        
        # Success message
        end_time = time.time()
        duration = end_time - start_time
        
        logging.info("=" * 70)
        logging.info("BRONZE LAYER TABLES CREATION COMPLETED SUCCESSFULLY")
        logging.info(f"Total time: {duration:.2f} seconds")
        logging.info("=" * 70 + "\n")
        
        print("\n" + "=" * 70)
        print("All Tables Created Successfully!")
        print(f"Time taken: {duration:.2f} seconds")
        print(f"Check logs: {os.path.join(LOG_DIR, LOG_FILE)}")
        print("=" * 70 + "\n")
    
    except Exception as e:
        logging.error("=" * 70)
        logging.error("BRONZE LAYER TABLES CREATION FAILED")
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