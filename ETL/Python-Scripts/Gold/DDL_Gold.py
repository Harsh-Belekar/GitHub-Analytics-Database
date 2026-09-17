"""
===============================================================================
GitHub Analytics Database
DDL Script: Create Gold Tables ( Dimensions & Facts )
===============================================================================
Script Purpose:
    This script creates tables in the 'gold' schema, dropping existing tables 
    if they already exist.
	Run this script to re-define the DDL structure of 'silver' Tables
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
LOG_FILE = "DDL_Gold.log"

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

DIM_DATE_TABLE = """
CREATE TABLE gold.dim_date (
    date_key        INT PRIMARY KEY,      
    full_date       DATE NOT NULL,
    year            INT NOT NULL,
    quarter         INT NOT NULL,
    month           INT NOT NULL,
    month_name      VARCHAR(20) NOT NULL,
    day             INT NOT NULL,
    day_name        VARCHAR(20) NOT NULL,
    day_of_week     INT NOT NULL,
    week_of_year    INT NOT NULL,
    is_weekend      BOOLEAN NOT NULL
);
"""

DIM_USERS_TABLE = """
CREATE TABLE gold.dim_users (
    user_id               INT PRIMARY KEY,
    username              VARCHAR(100) NOT NULL,
    full_name             VARCHAR(200) NOT NULL,
    email                 VARCHAR(255) NOT NULL,
    country               VARCHAR(100) NOT NULL,
    city                  VARCHAR(100),
    company               VARCHAR(150),
    account_type          VARCHAR(30) NOT NULL,
    hireable              BOOLEAN,
    verified              BOOLEAN,
    followers             INT,
    following             INT,
    public_repos          INT,
    public_gists          INT,
    joined_platform_at    TIMESTAMP
);
"""

DIM_ORGANIZATIONS_TABLE = """
CREATE TABLE gold.dim_organizations (
    organization_id           INT PRIMARY KEY,
    organization_name         VARCHAR(150) NOT NULL,
    organization_type         VARCHAR(50) NOT NULL,
    country                   VARCHAR(100) NOT NULL,
    city                      VARCHAR(100),
    industry                  VARCHAR(100) NOT NULL,
    verified                  BOOLEAN,
    total_repositories        INT,
    total_members             INT,
    organization_created_at   TIMESTAMP
);
"""

DIM_LANGUAGES_TABLE = """
CREATE TABLE gold.dim_languages (
    language_id           INT PRIMARY KEY,
    language_name         VARCHAR(100) NOT NULL,
    file_extension        VARCHAR(20) NOT NULL,
    language_type         VARCHAR(50) NOT NULL,
    first_release_year    INT NOT NULL,
    is_popular            BOOLEAN NOT NULL
);
"""

DIM_REPOSITORIES_TABLE = """
CREATE TABLE gold.dim_repositories (
    repository_id               INT PRIMARY KEY,
    repository_name             VARCHAR(200) NOT NULL,
    owner_id                    INT NOT NULL,
    owner_username              VARCHAR(100) NOT NULL,
    organization_id             INT,
    organization_name           VARCHAR(150),
    primary_language_id         INT NOT NULL,
    primary_language_name       VARCHAR(100) NOT NULL,
    visibility                  VARCHAR(20) NOT NULL,
    license                     VARCHAR(100),
    repository_size_mb          DECIMAL(10, 2),
    has_issues                  BOOLEAN,
    has_wiki                    BOOLEAN,
    has_projects                BOOLEAN,
    archived                    BOOLEAN,
    ownership_type              VARCHAR(20) NOT NULL,
    created_at                  TIMESTAMP,
    updated_at                  TIMESTAMP
);
"""

DIM_BRANCHES_TABLE = """
CREATE TABLE gold.dim_branches (
    branch_id                INT PRIMARY KEY,
    repository_id            INT NOT NULL,
    repository_name          VARCHAR(200) NOT NULL,
    branch_name              VARCHAR(100) NOT NULL,
    created_by               INT NOT NULL,
    created_by_username      VARCHAR(100) NOT NULL,
    is_default               BOOLEAN NOT NULL,
    created_at               TIMESTAMP
);
"""

FACT_COMMITS_TABLE = """
CREATE TABLE gold.fact_commits (
    commit_id               BIGINT PRIMARY KEY,
    commit_hash             VARCHAR(40) NOT NULL,
    repository_id           INT NOT NULL,
    branch_id               INT NOT NULL,
    user_id                 INT NOT NULL,
    commit_message          VARCHAR(500),
    files_changed           INT,
    lines_added             INT,
    lines_deleted           INT,
    total_lines_changed     INT,
    commit_timestamp        TIMESTAMP,
    date_key                INT
);
"""

FACT_PULL_REQUESTS_TABLE = """
CREATE TABLE gold.fact_pull_requests (
    pull_request_id         INT PRIMARY KEY,
    repository_id           INT NOT NULL,
    author_id               INT NOT NULL,
    source_branch_id        INT NOT NULL,
    target_branch_id        INT NOT NULL,
    title                   VARCHAR(300),
    status                  VARCHAR(20),
    files_changed           INT,
    created_at              TIMESTAMP,
    merged_at               TIMESTAMP,
    hours_to_merge          NUMERIC(12, 2),
    date_key                INT
);
"""

FACT_PULL_REQUEST_REVIEWS_TABLE = """
CREATE TABLE gold.fact_pull_request_reviews (
    review_id           INT PRIMARY KEY,
    pull_request_id     INT NOT NULL,
    repository_id       INT NOT NULL,
    reviewer_id         INT NOT NULL,
    pr_author_id        INT NOT NULL,
    review_state        VARCHAR(30),
    reviewed_at         TIMESTAMP,
    date_key            INT
);
"""

FACT_ISSUES_TABLE = """
CREATE TABLE gold.fact_issues (
    issue_id            INT PRIMARY KEY,
    repository_id       INT NOT NULL,
    user_id             INT NOT NULL,
    title               VARCHAR(300),
    issue_type          VARCHAR(30),
    priority            VARCHAR(20),
    status              VARCHAR(20),
    created_at          TIMESTAMP,
    closed_at           TIMESTAMP,
    hours_to_resolve    NUMERIC(12, 2),
    date_key            INT
);
"""

FACT_RELEASES_TABLE = """
CREATE TABLE gold.fact_releases (
    release_id                      INT PRIMARY KEY,
    repository_id                   INT NOT NULL,
    tag_name                        VARCHAR(50),
    version                         VARCHAR(50),
    release_title                   VARCHAR(300),
    published_by                    INT NOT NULL,
    published_at                    TIMESTAMP,
    major_version                   INT,
    minor_version                   INT,
    patch_version                   INT,
    release_type                    VARCHAR(10),
    previous_release_at             TIMESTAMP,
    days_since_previous_release     NUMERIC(10, 1),
    date_key                        INT
);
"""

FACT_STARS_TABLE = """
CREATE TABLE gold.fact_stars (
    star_id             BIGINT PRIMARY KEY,
    repository_id       INT NOT NULL,
    user_id             INT NOT NULL,
    starred_at          TIMESTAMP,
    date_key            INT
);
"""

FACT_FORKS_TABLE = """
CREATE TABLE gold.fact_forks (
    fork_id                 BIGINT PRIMARY KEY,
    source_repository_id    INT NOT NULL,
    forked_repository_id    INT NOT NULL,
    user_id                 INT NOT NULL,
    forked_at               TIMESTAMP,
    date_key                INT
);
"""

FACT_REPOSITORIES_CONTRIBUTORS_TABLE = """
CREATE TABLE gold.fact_repository_contributors (
    contributor_id          INT PRIMARY KEY,
    repository_id           INT NOT NULL,
    user_id                 INT NOT NULL,
    total_commits           INT,
    first_commit_date       TIMESTAMP,
    last_commit_date        TIMESTAMP
);
"""

FACT_REPOSITORIES_LANGUAGES_TABLE = """
CREATE TABLE gold.fact_repository_languages (
    repository_language_id      INT PRIMARY KEY,
    repository_id               INT NOT NULL,
    language_id                 INT NOT NULL,
    percentage_used             NUMERIC(5, 2)
);
"""

FACT_ORGANIZATIONS_MENBERS_TABLE = """
CREATE TABLE gold.fact_organization_members (
    membership_id       INT PRIMARY KEY,
    organization_id     INT NOT NULL,
    user_id             INT NOT NULL,
    role                VARCHAR(30),
    joined_at           TIMESTAMP,
    is_public           BOOLEAN
);
"""

Tables = [
    (DIM_DATE_TABLE, "dim_date"),
    (DIM_USERS_TABLE, "dim_users"),
    (DIM_ORGANIZATIONS_TABLE, "dim_organizations"),
    (DIM_LANGUAGES_TABLE, "dim_languages"),
    (DIM_REPOSITORIES_TABLE, "dim_repositories"),
    (DIM_BRANCHES_TABLE, "dim_branches"),
    (FACT_COMMITS_TABLE, "fact_commits"),
    (FACT_PULL_REQUESTS_TABLE, "fact_pull_requests"),
    (FACT_PULL_REQUEST_REVIEWS_TABLE, "fact_pull_request_reviews"),
    (FACT_ISSUES_TABLE, "fact_issues"),
    (FACT_RELEASES_TABLE, "fact_releases"),
    (FACT_STARS_TABLE, "fact_stars"),
    (FACT_FORKS_TABLE, "fact_forks"),
    (FACT_REPOSITORIES_CONTRIBUTORS_TABLE, "fact_repository_contributors"),
    (FACT_REPOSITORIES_LANGUAGES_TABLE, "fact_repository_languages"),
    (FACT_ORGANIZATIONS_MENBERS_TABLE, "fact_organization_members")
]

Indexes = [
    ("idx_gold_commits_repo","gold.fact_commits (repository_id)"),
    ("idx_gold_commits_user","gold.fact_commits (user_id)"),
    ("idx_gold_commits_date","gold.fact_commits (date_key)"),
    ("idx_gold_prs_repo","gold.fact_pull_requests (repository_id)"),
    ("idx_gold_prs_author","gold.fact_pull_requests (author_id)"),
    ("idx_gold_prs_date","gold.fact_pull_requests (date_key)"),
    ("idx_gold_reviews_repo","gold.fact_pull_request_reviews (repository_id)"),
    ("idx_gold_reviews_reviewer","gold.fact_pull_request_reviews (reviewer_id)"),
    ("idx_gold_issues_repo","gold.fact_issues (repository_id)"),
    ("idx_gold_issues_user","gold.fact_issues (user_id)"),
    ("idx_gold_issues_date","gold.fact_issues (date_key)"),
    ("idx_gold_releases_repo","gold.fact_releases (repository_id)"),
    ("idx_gold_stars_repo","gold.fact_stars (repository_id)"),
    ("idx_gold_forks_source_repo","gold.fact_forks (source_repository_id)"),
    ("idx_gold_contributors_repo","gold.fact_repository_contributors (repository_id)"),
    ("idx_gold_repo_languages_repo","gold.fact_repository_languages (repository_id)"),
    ("idx_gold_org_members_org","gold.fact_organization_members (organization_id)"),
    ("idx_gold_dim_repos_org","gold.dim_repositories (organization_id)"),
    ("idx_gold_dim_repos_owner","gold.dim_repositories (owner_id)"),
    ("idx_gold_dim_branches_repo","gold.dim_branches (repository_id)")
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
    logging.info("Starting Gold Layer Table Creation Process...")
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
            cursor.execute(f"DROP TABLE IF EXISTS gold.{name} CASCADE;")
            logging.info(f"Dropped table: {name}")
            dropped_count += 1
        
        except Exception as e:
            logging.warning(f"Table {name} not found (probably doesn't exist yet)")
    
    cursor.close()

    logging.info("=" * 70)
    logging.info(f"Dropped {dropped_count}/{len(Tables)} tables")
    logging.info("=" * 70 + "\n")


# =============================
# Create Indexes
# =============================
def create_all_indexes(conn):
    logging.info("=" * 70)
    logging.info("Starting Gold Layer Indexes Creation Process...")
    logging.info("=" * 70)
    cursor = conn.cursor()
    
    success_count = 0
    failed_count = 0
    
    for name, table in Indexes:
        try:
            query = f"CREATE INDEX {name} ON {table}"
            logging.info(f"Executing: {query} Index Query")
            start_time = time.time()
            cursor.execute(query)
            end_time = time.time()
            duration = end_time - start_time
            logging.info(f"{name} Index Created Successfully in ({duration:.2f}s).")
            success_count += 1
        except Exception as e:
            failed_count += 1
            logging.error(f"Skipping {name} Index due to error")
        
    cursor.close()
    logging.info("=" * 70)
    logging.info("INDEX CREATION SUMMARY")
    logging.info("=" * 70)
    logging.info(f"Total operations: {len(Indexes)}")
    logging.info(f"Successful: {success_count}")
    logging.info(f"Failed: {failed_count}")
    logging.info("=" * 70 + "\n")
    
    if failed_count == 0:
        logging.info("All Indexes created successfully!\n")
    else:
        logging.warning(f"{failed_count} operation(s) failed. Check logs above.\n")


# =============================
# Drop Tables
# =============================
def drop_all_indexes(conn):
    logging.info("=" * 70)
    logging.info("DROPPING EXISTING INDEXES")
    logging.info("=" * 70)
    cursor = conn.cursor()
    
    dropped_count = 0
    
    for name, table in Indexes:
        try:
            cursor.execute(f"DROP INDEX IF EXISTS {name} CASCADE;")
            logging.info(f"Dropped index: {name}")
            dropped_count += 1
        
        except Exception as e:
            logging.warning(f"Table {name} not found (probably doesn't exist yet)")
    
    cursor.close()

    logging.info("=" * 70)
    logging.info(f"Dropped {dropped_count}/{len(Indexes)} tables")
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
        
        # Create all tables 
        create_all_tables(conn)
        
        # Drop existing indexes
        drop_all_indexes(conn)
        
        # Create all indexes
        create_all_indexes(conn)
        
        # Success message
        end_time = time.time()
        duration = end_time - start_time
        
        logging.info("=" * 70)
        logging.info("GOLD LAYER TABLES & INDEXES CREATION COMPLETED SUCCESSFULLY")
        logging.info(f"Total time: {duration:.2f} seconds")
        logging.info("=" * 70 + "\n")
        
        print("\n" + "=" * 70)
        print("All Tables & Index Created Successfully!")
        print(f"Time taken: {duration:.2f} seconds")
        print(f"Check logs: {os.path.join(LOG_DIR, LOG_FILE)}")
        print("=" * 70 + "\n")
    
    except Exception as e:
        logging.error("=" * 70)
        logging.error("GOLD LAYER TABLES & INDEXES CREATION FAILED")
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