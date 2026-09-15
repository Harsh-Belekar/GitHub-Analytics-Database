"""
===============================================================================
GitHub Analytics Database
DDL Script: Create Silver Tables
===============================================================================
Script Purpose:
    This script creates tables in the 'silver' schema, dropping existing tables 
    if they already exist.
	Run this script to re-define the DDL structure of 'bronze' Tables
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
LOG_FILE = "DDL_Silver.log"

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

PROGRAMMING_LANGUAGES_TABLE = """
CREATE TABLE silver.programming_languages (
    language_id          INT PRIMARY KEY,
    language_name        VARCHAR(100) NOT NULL,
    file_extension       VARCHAR(20)  NOT NULL,
    language_type        VARCHAR(50)  NOT NULL,
    first_release_year   INT          NOT NULL,
    is_popular           BOOLEAN      NOT NULL,
    created_at           TIMESTAMP    NOT NULL,
    CONSTRAINT uq_languages_name UNIQUE (language_name)
);
"""

USERS_TABLE = """
CREATE TABLE silver.users (
    user_id         INT PRIMARY KEY,
    first_name      VARCHAR(100) NOT NULL,
    last_name       VARCHAR(100) NOT NULL,
    username        VARCHAR(100) NOT NULL,
    email           VARCHAR(255) NOT NULL,
    country         VARCHAR(100) NOT NULL,
    city            VARCHAR(100),
    bio             TEXT,
    company         VARCHAR(150),
    hireable        BOOLEAN NOT NULL,
    verified        BOOLEAN NOT NULL,
    followers       INT NOT NULL,
    following       INT NOT NULL,
    public_repos    INT NOT NULL,
    public_gists    INT NOT NULL,
    account_type    VARCHAR(30) NOT NULL,
    avatar_url      VARCHAR(500),
    profile_url     VARCHAR(500) NOT NULL,
    created_at      TIMESTAMP NOT NULL,
    updated_at      TIMESTAMP NOT NULL,
    CONSTRAINT uq_users_username UNIQUE (username),
    CONSTRAINT uq_users_email UNIQUE (email)
);
"""

ORGANIZATIONS_TABLE = """
CREATE TABLE silver.organizations (
    organization_id       INT PRIMARY KEY,
    organization_name     VARCHAR(150) NOT NULL,
    organization_type     VARCHAR(50)  NOT NULL,
    country               VARCHAR(100) NOT NULL,
    city                  VARCHAR(100),
    website               VARCHAR(255),
    email                 VARCHAR(255),
    industry              VARCHAR(100) NOT NULL,
    total_repositories    INT NOT NULL DEFAULT 0,
    total_members         INT NOT NULL DEFAULT 0,
    verified              BOOLEAN NOT NULL,
    created_at            TIMESTAMP NOT NULL,
    CONSTRAINT uq_organizations_name UNIQUE (organization_name)
);
"""

ORGANIZATIONS_MENBERS_TABLE = """
CREATE TABLE silver.organization_members (
    membership_id       INT PRIMARY KEY,
    organization_id     INT NOT NULL,
    user_id             INT NOT NULL,
    role                VARCHAR(30) NOT NULL,
    joined_at           TIMESTAMP NOT NULL,
    is_public           BOOLEAN NOT NULL,
    CONSTRAINT uq_org_members_user_org UNIQUE (organization_id, user_id)
);
"""

REPOSITORIES_TABLE = """
CREATE TABLE silver.repositories (
    repository_id            INT PRIMARY KEY,
    owner_id                 INT NOT NULL,
    organization_id          INT,
    repository_name          VARCHAR(200) NOT NULL,
    description              TEXT,
    visibility               VARCHAR(20) NOT NULL,
    default_branch           VARCHAR(50) NOT NULL,
    primary_language_id      INT NOT NULL,
    license                  VARCHAR(100),
    repository_size_mb       DECIMAL(10, 2) NOT NULL,
    has_issues               BOOLEAN NOT NULL,
    has_wiki                 BOOLEAN NOT NULL,
    has_projects             BOOLEAN NOT NULL,
    archived                 BOOLEAN NOT NULL,
    created_at               TIMESTAMP NOT NULL,
    updated_at               TIMESTAMP NOT NULL,
    CONSTRAINT uq_repositories_owner_name UNIQUE (owner_id, repository_name),
    CONSTRAINT chk_repositories_visibility CHECK (visibility IN ('Public', 'Private'))
);
"""

REPOSITORIES_LANGUAGES_TABLE = """
CREATE TABLE silver.repository_languages (
    repository_language_id      INT PRIMARY KEY,
    repository_id               INT NOT NULL,
    language_id                 INT NOT NULL,
    percentage_used             DECIMAL(5, 2) NOT NULL,
    CONSTRAINT uq_repo_languages_repo_lang UNIQUE (repository_id, language_id),
    CONSTRAINT chk_repo_languages_pct CHECK (percentage_used >= 0 AND percentage_used <= 100)
);
"""

REPOSITORIES_CONTRIBUTORS_TABLE = """
CREATE TABLE silver.repository_contributors (
    contributor_id           INT PRIMARY KEY,
    repository_id            INT NOT NULL,
    user_id                  INT NOT NULL,
    total_commits            INT NOT NULL,
    first_commit_date        TIMESTAMP NOT NULL,
    last_commit_date         TIMESTAMP NOT NULL,
    CONSTRAINT uq_repo_contributors_repo_user UNIQUE (repository_id, user_id),
    CONSTRAINT chk_repo_contributors_dates CHECK (last_commit_date >= first_commit_date)
);
"""

BRANCHES_TABLE = """
CREATE TABLE silver.branches (
    branch_id          INT PRIMARY KEY,
    repository_id      INT NOT NULL,
    branch_name        VARCHAR(100) NOT NULL,
    created_by         INT NOT NULL,
    is_default         BOOLEAN NOT NULL,
    created_at         TIMESTAMP NOT NULL,
    CONSTRAINT uq_branches_repo_name UNIQUE (repository_id, branch_name)
);
"""

COMMITS_TABLE = """
CREATE TABLE silver.commits (
    commit_id             BIGINT PRIMARY KEY,
    commit_hash           VARCHAR(40) NOT NULL,
    repository_id         INT NOT NULL,
    branch_id             INT NOT NULL,
    user_id               INT NOT NULL,
    commit_message        VARCHAR(500) NOT NULL,
    files_changed         INT NOT NULL,
    lines_added           INT NOT NULL,
    lines_deleted         INT NOT NULL,
    commit_timestamp      TIMESTAMP NOT NULL,
    CONSTRAINT uq_commits_hash UNIQUE (commit_hash),
    CONSTRAINT chk_commits_lines_added CHECK (lines_added >= 0),
    CONSTRAINT chk_commits_lines_deleted CHECK (lines_deleted >= 0)
);

"""

PULL_REQUESTS_TABLE = """
CREATE TABLE silver.pull_requests (
    pull_request_id        INT PRIMARY KEY,
    repository_id          INT NOT NULL,
    user_id                INT NOT NULL,
    source_branch_id       INT NOT NULL,
    target_branch_id       INT NOT NULL,
    title                  VARCHAR(300) NOT NULL,
    status                 VARCHAR(20) NOT NULL,
    files_changed          INT NOT NULL,
    created_at             TIMESTAMP NOT NULL,
    merged_at              TIMESTAMP,
    CONSTRAINT chk_pr_status CHECK (status IN ('Open', 'Closed', 'Merged')),
    CONSTRAINT chk_pr_merged_after_created CHECK (merged_at IS NULL OR merged_at >= created_at)
);
"""

PULL_REQUEST_REVIEWS_TABLE = """
CREATE TABLE silver.pull_request_reviews (
    review_id            INT PRIMARY KEY,
    pull_request_id      INT NOT NULL,
    reviewer_id          INT NOT NULL,
    review_state         VARCHAR(30) NOT NULL,
    review_comment       TEXT,
    reviewed_at          TIMESTAMP NOT NULL,
    CONSTRAINT chk_review_state CHECK (review_state IN ('Approved', 'Changes Requested', 'Commented'))
);
"""

ISSUES_TABLE = """
CREATE TABLE silver.issues (
    issue_id            INT PRIMARY KEY,
    repository_id       INT NOT NULL,
    user_id             INT NOT NULL,
    title               VARCHAR(300) NOT NULL,
    issue_type          VARCHAR(30) NOT NULL,
    priority            VARCHAR(20) NOT NULL,
    status              VARCHAR(20) NOT NULL,
    created_at          TIMESTAMP NOT NULL,
    closed_at           TIMESTAMP,
    CONSTRAINT chk_issues_type CHECK (issue_type IN ('Bug', 'Feature', 'Documentation', 'Enhancement')),
    CONSTRAINT chk_issues_priority CHECK (priority IN ('Low', 'Medium', 'High', 'Critical')),
    CONSTRAINT chk_issues_status CHECK (status IN ('Open', 'Closed')),
    CONSTRAINT chk_issues_closed_after_created CHECK (closed_at IS NULL OR closed_at >= created_at)
);
"""

RELEASES_TABLE = """
CREATE TABLE silver.releases (
    release_id          INT PRIMARY KEY,
    repository_id       INT NOT NULL,
    tag_name            VARCHAR(50) NOT NULL,
    version             VARCHAR(50) NOT NULL,
    release_title       VARCHAR(300) NOT NULL,
    release_notes       TEXT,
    published_by        INT NOT NULL,
    published_at        TIMESTAMP NOT NULL,
    CONSTRAINT uq_releases_repo_version UNIQUE (repository_id, version)
);
"""

STARS_TABLE = """
CREATE TABLE silver.stars (
    star_id           BIGINT PRIMARY KEY,
    repository_id     INT NOT NULL,
    user_id           INT NOT NULL,
    starred_at        TIMESTAMP NOT NULL,
    CONSTRAINT uq_stars_repo_user UNIQUE (repository_id, user_id)
);
"""

FORKS_TABLE = """
CREATE TABLE silver.forks (
    fork_id                  INT PRIMARY KEY,
    source_repository_id     INT NOT NULL,
    forked_repository_id     INT NOT NULL,
    user_id                  INT NOT NULL,
    forked_at                TIMESTAMP NOT NULL,
    CONSTRAINT chk_forks_source_ne_forked CHECK (source_repository_id <> forked_repository_id)
);
"""

Tables = [
    (PROGRAMMING_LANGUAGES_TABLE, "programming_languages"),
    (USERS_TABLE, "users"),
    (ORGANIZATIONS_TABLE, "organizations"),
    (ORGANIZATIONS_MENBERS_TABLE, "organization_members"),
    (REPOSITORIES_TABLE, "repositories"),
    (REPOSITORIES_LANGUAGES_TABLE, "repository_languages"),
    (REPOSITORIES_CONTRIBUTORS_TABLE, "repository_contributors"),
    (BRANCHES_TABLE, "branches"),
    (COMMITS_TABLE, "commits"),
    (PULL_REQUESTS_TABLE, "pull_requests"),
    (PULL_REQUEST_REVIEWS_TABLE, "pull_request_reviews"),
    (ISSUES_TABLE, "issues"),
    (RELEASES_TABLE, "releases"),
    (STARS_TABLE, "stars"),
    (FORKS_TABLE, "forks")
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
    logging.info("Starting Silver Layer Table Creation Process...")
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
            cursor.execute(f"DROP TABLE IF EXISTS silver.{name} CASCADE;")
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
        logging.info("SILVER LAYER TABLES CREATION COMPLETED SUCCESSFULLY")
        logging.info(f"Total time: {duration:.2f} seconds")
        logging.info("=" * 70 + "\n")
        
        print("\n" + "=" * 70)
        print("All Tables Created Successfully!")
        print(f"Time taken: {duration:.2f} seconds")
        print(f"Check logs: {os.path.join(LOG_DIR, LOG_FILE)}")
        print("=" * 70 + "\n")
    
    except Exception as e:
        logging.error("=" * 70)
        logging.error("SILVER LAYER TABLES CREATION FAILED")
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