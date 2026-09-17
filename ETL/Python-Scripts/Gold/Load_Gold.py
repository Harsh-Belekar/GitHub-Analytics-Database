"""
===============================================================================
GitHub Analytics Database
Insertion Script: Load Gold Layer (Silver -> Gold)
===============================================================================
Script Purpose:
    Populates the physical gold.dim_* / gold.fact_* tables from the 'silver'
    schema. Mirrors the shape of silver.load_silver(): per-table TRUNCATE +
    INSERT, RAISE NOTICE timing, EXCEPTION handler.

    Each table's population query is self-contained (sources from silver.*
    directly, computing its own joins/denormalization) rather than reading
    from other gold tables — this avoids any load-order dependency between
    gold tables, since none of them rely on another gold table already
    being populated.

Database:
    PostgreSQL

Parameters:
    None. 

Prerequisites:
    - silver.* tables populated (CALL silver.load_silver() first)
    - gold.* tables created (see Create_Gold_Dimensions_Facts.sql)
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
LOG_FILE = "Load_Gold.log"

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
# Cleaning & Insertion QUERIES
# =====================================================================

DIM_DATE_TABLE = """
INSERT INTO gold.dim_date
SELECT
    TO_CHAR(d, 'YYYYMMDD')::INT,
    d,
    EXTRACT(YEAR FROM d)::INT,
    EXTRACT(QUARTER FROM d)::INT,
    EXTRACT(MONTH FROM d)::INT,
    TO_CHAR(d, 'Month'),
    EXTRACT(DAY FROM d)::INT,
    TO_CHAR(d, 'Day'),
    EXTRACT(ISODOW FROM d)::INT,
    EXTRACT(WEEK FROM d)::INT,
    EXTRACT(ISODOW FROM d) IN (6, 7)
FROM GENERATE_SERIES('2015-01-01'::DATE, '2027-12-31'::DATE, INTERVAL '1 day') AS d;
"""

DIM_USERS_TABLE = """
INSERT INTO gold.dim_users
    SELECT
        u.user_id, u.username, u.first_name || ' ' || u.last_name, u.email,
        u.country, u.city, u.company, u.account_type, u.hireable, u.verified,
        u.followers, u.following, u.public_repos, u.public_gists, u.created_at
    FROM silver.users u;
"""

DIM_ORGANIZATIONS_TABLE = """
INSERT INTO gold.dim_organizations
    SELECT
        o.organization_id, o.organization_name, o.organization_type, o.country,
        o.city, o.industry, o.verified, o.total_repositories, o.total_members, o.created_at
    FROM silver.organizations o;
"""

DIM_LANGUAGES_TABLE = """
INSERT INTO gold.dim_languages
    SELECT language_id, language_name, file_extension, language_type, first_release_year, is_popular
    FROM silver.programming_languages;
"""

DIM_REPOSITORIES_TABLE = """
INSERT INTO gold.dim_repositories
    SELECT
        r.repository_id, r.repository_name, r.owner_id, u.username, r.organization_id,
        o.organization_name, r.primary_language_id, l.language_name, r.visibility,
        r.license, r.repository_size_mb, r.has_issues, r.has_wiki, r.has_projects,
        r.archived,
        CASE WHEN r.organization_id IS NULL THEN 'Personal' ELSE 'Organization' END,
        r.created_at, r.updated_at
    FROM silver.repositories r
    JOIN silver.users u ON r.owner_id = u.user_id
    LEFT JOIN silver.organizations o ON r.organization_id = o.organization_id
    JOIN silver.programming_languages l ON r.primary_language_id = l.language_id;
"""

DIM_BRANCHES_TABLE = """
INSERT INTO gold.dim_branches
    SELECT
        b.branch_id, b.repository_id, r.repository_name, b.branch_name,
        b.created_by, u.username, b.is_default, b.created_at
    FROM silver.branches b
    JOIN silver.repositories r ON r.repository_id = b.repository_id
    JOIN silver.users u ON u.user_id = b.created_by;
"""

FACT_COMMITS_TABLE = """
INSERT INTO gold.fact_commits
    SELECT
        c.commit_id, c.commit_hash, c.repository_id, c.branch_id, c.user_id,
        c.commit_message, c.files_changed, c.lines_added, c.lines_deleted,
        c.lines_added + c.lines_deleted, c.commit_timestamp,
        TO_CHAR(c.commit_timestamp, 'YYYYMMDD')::INT
    FROM silver.commits c;
"""

FACT_PULL_REQUESTS_TABLE = """
INSERT INTO gold.fact_pull_requests
    SELECT
        p.pull_request_id, p.repository_id, p.user_id, p.source_branch_id,
        p.target_branch_id, p.title, p.status, p.files_changed, p.created_at, p.merged_at,
        CASE WHEN p.merged_at IS NOT NULL
            THEN ROUND(EXTRACT(EPOCH FROM (p.merged_at - p.created_at)) / 3600.0, 2)
        END,
        TO_CHAR(p.created_at, 'YYYYMMDD')::INT
    FROM silver.pull_requests p;
"""

FACT_PULL_REQUEST_REVIEWS_TABLE = """
INSERT INTO gold.fact_pull_request_reviews
    SELECT
        rv.review_id, rv.pull_request_id, pr.repository_id, rv.reviewer_id,
        pr.user_id, rv.review_state, rv.reviewed_at,
        TO_CHAR(rv.reviewed_at, 'YYYYMMDD')::INT
    FROM silver.pull_request_reviews rv
    JOIN silver.pull_requests pr ON rv.pull_request_id = pr.pull_request_id;
"""

FACT_ISSUES_TABLE = """
INSERT INTO gold.fact_issues
    SELECT
        i.issue_id, i.repository_id, i.user_id, i.title, i.issue_type, i.priority,
        i.status, i.created_at, i.closed_at,
        CASE WHEN i.closed_at IS NOT NULL
            THEN ROUND(EXTRACT(EPOCH FROM (i.closed_at - i.created_at)) / 3600.0, 2)
        END,
        TO_CHAR(i.created_at, 'YYYYMMDD')::INT
    FROM silver.issues i;
"""

FACT_RELEASES_TABLE = """
WITH versioned AS (
        SELECT
            rl.release_id, rl.repository_id, rl.tag_name, rl.version,
            rl.release_title, rl.published_by, rl.published_at,
            SPLIT_PART(rl.version, '.', 1)::INT AS major_version,
            SPLIT_PART(rl.version, '.', 2)::INT AS minor_version,
            SPLIT_PART(rl.version, '.', 3)::INT AS patch_version,
            LAG(SPLIT_PART(rl.version, '.', 1)::INT) OVER w AS prev_major,
            LAG(SPLIT_PART(rl.version, '.', 2)::INT) OVER w AS prev_minor,
            LAG(rl.published_at) OVER w AS previous_release_at
        FROM silver.releases rl
        WINDOW w AS (PARTITION BY rl.repository_id ORDER BY rl.published_at)
    )
    INSERT INTO gold.fact_releases
    SELECT
        release_id, repository_id, tag_name, version, release_title, published_by, published_at,
        major_version, minor_version, patch_version,
        CASE
            WHEN prev_major IS NULL THEN 'Major'
            WHEN major_version > prev_major THEN 'Major'
            WHEN minor_version > prev_minor THEN 'Minor'
            ELSE 'Patch'
        END,
        previous_release_at,
        ROUND(EXTRACT(EPOCH FROM (published_at - previous_release_at)) / 86400.0, 1),
        TO_CHAR(published_at, 'YYYYMMDD')::INT
    FROM versioned;
"""

FACT_STARS_TABLE = """
    INSERT INTO gold.fact_stars
    SELECT star_id, repository_id, user_id, starred_at, TO_CHAR(starred_at, 'YYYYMMDD')::INT
    FROM silver.stars;
"""

FACT_FORKS_TABLE = """
INSERT INTO gold.fact_forks
    SELECT fork_id, source_repository_id, forked_repository_id, user_id, forked_at,
        TO_CHAR(forked_at, 'YYYYMMDD')::INT
    FROM silver.forks;
"""

FACT_REPOSITORIES_CONTRIBUTORS_TABLE = """
INSERT INTO gold.fact_repository_contributors
    SELECT contributor_id, repository_id, user_id, total_commits, 
        first_commit_date, last_commit_date
    FROM silver.repository_contributors;
"""

FACT_REPOSITORIES_LANGUAGES_TABLE = """
INSERT INTO gold.fact_repository_languages
    SELECT repository_language_id, repository_id, language_id, percentage_used
    FROM silver.repository_languages;
"""

FACT_ORGANIZATIONS_MENBERS_TABLE = """
INSERT INTO gold.fact_organization_members
    SELECT membership_id, organization_id, user_id, role, joined_at, is_public
    FROM silver.organization_members;
"""


QUERIES = [
    (DIM_DATE_TABLE, "gold.dim_date"),
    (DIM_USERS_TABLE, "gold.dim_users"),
    (DIM_ORGANIZATIONS_TABLE, "gold.dim_organizations"),
    (DIM_LANGUAGES_TABLE, "gold.dim_languages"),
    (DIM_REPOSITORIES_TABLE, "gold.dim_repositories"),
    (DIM_BRANCHES_TABLE, "gold.dim_branches"),
    (FACT_COMMITS_TABLE, "gold.fact_commits"),
    (FACT_PULL_REQUESTS_TABLE, "gold.fact_pull_requests"),
    (FACT_PULL_REQUEST_REVIEWS_TABLE, "gold.fact_pull_request_reviews"),
    (FACT_ISSUES_TABLE, "gold.fact_issues"),
    (FACT_RELEASES_TABLE, "gold.fact_releases"),
    (FACT_STARS_TABLE, "gold.fact_stars"),
    (FACT_FORKS_TABLE, "gold.fact_forks"),
    (FACT_REPOSITORIES_CONTRIBUTORS_TABLE, "gold.fact_repository_contributors"),
    (FACT_REPOSITORIES_LANGUAGES_TABLE, "gold.fact_repository_languages"),
    (FACT_ORGANIZATIONS_MENBERS_TABLE, "gold.fact_organization_members")
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
        logging.info(f"Executing: {query_name} Insertion Query")
        start_time = time.time()
        cursor.execute(query)
        end_time = time.time()
        duration = end_time - start_time
        logging.info(f"{query_name} Table Data Inserted Successfully in ({duration:.2f}s).")
    
    except Exception as e:
        logging.error(f"Failed to Execute {query_name} Query : {str(e)}")
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

        for query,table_name in QUERIES:
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


# ======================================================
# Insert Silver Layer Data into Gold Layer Tables
# ======================================================
def insert_data(conn):
    logging.info("=" * 70)
    logging.info("Starting Gold Layer Data Insertion Process...")
    logging.info("=" * 70)
    cursor = conn.cursor()
    
    success_count = 0
    failed_count = 0
    
    for query, name in QUERIES:
        try:
            execute_query(cursor, query, name)
            success_count += 1
        except Exception as e:
            failed_count += 1
            logging.error(f"Skipping {name} Table due to error")
        
    cursor.close()
    logging.info("=" * 70)
    logging.info("DATA INSERTION SUMMARY")
    logging.info("=" * 70)
    logging.info(f"Total operations: {len(QUERIES)}")
    logging.info(f"Successful: {success_count}")
    logging.info(f"Failed: {failed_count}")
    logging.info("=" * 70 + "\n")
    
    if failed_count == 0:
        logging.info("All Data Inserted successfully!\n")
    else:
        logging.warning(f"{failed_count} operation(s) failed. Check logs above.\n")


# =============================
# Run Script
# =============================
if __name__ == "__main__":
    start_time = time.time()
    
    logging.info("=" * 70)
    logging.info("GOLD LAYER DATA INSERTION - STARTING")
    logging.info("=" * 70)
    
    conn = None
    
    try:
        # Connect to database
        conn = create_connection()
        
        # Truncate existing tables
        truncate_tables(conn)
        
        # Insert Bronze Layer Data into Silver Layer Tables
        insert_data(conn)
        
        # Success message
        end_time = time.time()
        duration = end_time - start_time
        
        logging.info("=" * 70)
        logging.info("GOLD LAYER DATA INSERTION COMPLETED SUCCESSFULLY")
        logging.info(f"Total time: {duration:.2f} seconds")
        logging.info("=" * 70 + "\n")
        
        print("\n" + "=" * 70)
        print("All Data Inserted Successfully!")
        print(f"Time taken: {duration:.2f} seconds")
        print(f"Check logs: {os.path.join(LOG_DIR, LOG_FILE)}")
        print("=" * 70 + "\n")
    
    except Exception as e:
        logging.error("=" * 70)
        logging.error("GOLD LAYER DATA INSERTION FAILED")
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