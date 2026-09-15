"""
===============================================================================
GitHub Analytics Database
Insertion Script: Load Silver Layer (Bronze -> Silver)
===============================================================================
Script Purpose:
    This stored procedure performs the ETL (Extract, Transform, Load) process to 
    populate the 'silver' schema tables from the 'bronze' schema.
	Actions Performed:
		- Truncates Silver tables.
		- Inserts transformed and cleansed data from Bronze into Silver tables.

Database:
    PostgreSQL

Parameters:
    None. 
		This Script does not accept any parameters or return any values.
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
LOG_FILE = "Load_Silver.log"

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

PROGRAMMING_LANGUAGES_TABLE = """
INSERT INTO silver.programming_languages
    (
        language_id, language_name, file_extension, language_type,
        first_release_year, is_popular, created_at
    )
    SELECT
        TRIM(language_id::TEXT)::INT,
        TRIM(language_name),
        TRIM(file_extension),
        TRIM(language_type),
        TRIM(first_release_year::TEXT)::INT,
        cleaning.fn_to_boolean(is_popular::TEXT),
        cleaning.fn_parse_date(created_at::TEXT)
    FROM bronze.programming_languages
    WHERE TRIM(language_id::TEXT)~ '^[0-9]+$'
    ORDER BY language_id::INT ASC;
"""

USERS_TABLE = """
WITH deduped AS (
        SELECT *,
            ROW_NUMBER() OVER (PARTITION BY TRIM(user_id::TEXT) ORDER BY TRIM(user_id::TEXT)) AS rn
        FROM bronze.users
        WHERE TRIM(user_id ::TEXT) ~ '^[0-9]+$'
    )
    INSERT INTO silver.users
    (
        user_id, first_name, last_name, username, email, country, city, bio,
        company, hireable, verified, followers, following, public_repos,
        public_gists, account_type, avatar_url, profile_url, created_at, updated_at
    )
    SELECT
        TRIM(user_id::TEXT)::INT,
        TRIM(first_name),
        TRIM(last_name),
        TRIM(username),
        cleaning.fn_clean_email(email),
        INITCAP(LOWER(TRIM(country))),
        NULLIF(TRIM(city), ''),
        NULLIF(TRIM(bio), ''),
        NULLIF(TRIM(company), ''),
        cleaning.fn_to_boolean(hireable::TEXT),
        cleaning.fn_to_boolean(verified::TEXT),
        CASE WHEN TRIM(followers::TEXT) ~ '^-?[0-9]+$' THEN ABS(TRIM(followers::TEXT)::INT) ELSE 0 END,
        CASE WHEN TRIM(following::TEXT) ~ '^-?[0-9]+$' THEN ABS(TRIM(following::TEXT)::INT) ELSE 0 END,
        CASE WHEN TRIM(public_repos::TEXT) ~ '^-?[0-9]+$' THEN ABS(TRIM(public_repos::TEXT)::INT) ELSE 0 END,
        CASE WHEN TRIM(public_gists::TEXT) ~ '^-?[0-9]+$' THEN ABS(TRIM(public_gists::TEXT)::INT) ELSE 0 END,
        TRIM(account_type),
        NULLIF(TRIM(avatar_url), ''),
        TRIM(profile_url),
        cleaning.fn_parse_date(created_at::TEXT),
        cleaning.fn_parse_date(updated_at::TEXT)
    FROM deduped
    WHERE rn = 1
    ORDER BY user_id::INT ASC;
"""

ORGANIZATIONS_TABLE = """
WITH deduped AS (
        SELECT *,
            ROW_NUMBER() OVER (PARTITION BY TRIM(organization_id::TEXT) ORDER BY TRIM(organization_id::TEXT)) AS rn
        FROM bronze.organizations
        WHERE TRIM(organization_id::TEXT) ~ '^[0-9]+$'
    )
    INSERT INTO silver.organizations
    (
        organization_id, organization_name, organization_type, country, city,
        website, email, industry, total_repositories, total_members, verified, created_at
    )
    SELECT
        TRIM(organization_id::TEXT)::INT,
        INITCAP(LOWER(TRIM(organization_name))),
        TRIM(organization_type),
        INITCAP(LOWER(TRIM(country))),
        NULLIF(TRIM(city), ''),
        NULLIF(TRIM(website), ''),
        NULLIF(LOWER(TRIM(email)), ''),
        TRIM(industry),
        TRIM(total_repositories::TEXT)::INT,
        TRIM(total_members::TEXT)::INT,
        cleaning.fn_to_boolean(verified::TEXT),
        cleaning.fn_parse_date(created_at::TEXT)
    FROM deduped
    WHERE rn = 1
    ORDER BY organization_id::INT ASC;
"""

ORGANIZATIONS_MENBERS_TABLE = """
WITH deduped AS (
        SELECT *,
            ROW_NUMBER() OVER (PARTITION BY TRIM(membership_id::TEXT) ORDER BY TRIM(membership_id::TEXT)) AS rn
        FROM bronze.organization_members
        WHERE TRIM(membership_id::TEXT) ~ '^[0-9]+$'
    )
    INSERT INTO silver.organization_members
    (
        membership_id, organization_id, user_id, role, joined_at, is_public
    )
    SELECT
        TRIM(membership_id::TEXT)::INT,
        TRIM(organization_id::TEXT)::INT,
        TRIM(user_id::TEXT)::INT,
        INITCAP(LOWER(TRIM(role))),
        cleaning.fn_parse_date(joined_at::TEXT),
        cleaning.fn_to_boolean(is_public::TEXT)
    FROM deduped
    WHERE rn = 1
    ORDER BY membership_id::INT ASC;
"""

REPOSITORIES_TABLE = """
WITH deduped AS (
        SELECT *,
            ROW_NUMBER() OVER (PARTITION BY TRIM(repository_id::TEXT) ORDER BY TRIM(repository_id::TEXT)) AS rn
        FROM bronze.repositories
        WHERE TRIM(repository_id::TEXT) ~ '^[0-9]+$'
    )
    INSERT INTO silver.repositories
    (
        repository_id, owner_id, organization_id, repository_name, description,
        visibility, default_branch, primary_language_id, license,
        repository_size_mb, has_issues, has_wiki, has_projects, archived,
        created_at, updated_at
    )
    SELECT
        TRIM(repository_id::TEXT)::INT,
        TRIM(owner_id::TEXT)::INT,
        CASE WHEN TRIM(organization_id::TEXT) ~ '^[0-9]+(\.[0-9]+)?$'
            THEN TRIM(organization_id::TEXT)::NUMERIC::INT ELSE NULL END,
        TRIM(repository_name),
        NULLIF(TRIM(description), ''),
        INITCAP(LOWER(TRIM(visibility))),
        TRIM(default_branch),
        TRIM(primary_language_id::TEXT)::INT,
        NULLIF(TRIM(license), ''),
        CASE WHEN TRIM(repository_size_mb::TEXT) ~ '^-?[0-9]+(\.[0-9]+)?$'
            THEN ABS(TRIM(repository_size_mb::TEXT)::NUMERIC) ELSE 0 END,
        cleaning.fn_to_boolean(has_issues::TEXT),
        cleaning.fn_to_boolean(has_wiki::TEXT),
        cleaning.fn_to_boolean(has_projects::TEXT),
        cleaning.fn_to_boolean(archived::TEXT),
        cleaning.fn_parse_date(created_at::TEXT),
        cleaning.fn_parse_date(updated_at::TEXT)
    FROM deduped
    WHERE rn = 1
    ORDER BY repository_id::INT ASC;
"""

REPOSITORIES_LANGUAGES_TABLE = """
WITH deduped AS (
        SELECT *,
            ROW_NUMBER() OVER (PARTITION BY TRIM(repository_language_id::TEXT) ORDER BY TRIM(repository_language_id::TEXT)) AS rn
        FROM bronze.repository_languages
        WHERE TRIM(repository_language_id::TEXT) ~ '^[0-9]+$'
    )
    INSERT INTO silver.repository_languages
    (
        repository_language_id, repository_id, language_id, percentage_used
    )
    SELECT
        TRIM(repository_language_id::TEXT)::INT,
        TRIM(repository_id::TEXT)::INT,
        TRIM(language_id::TEXT)::INT,
        CASE WHEN TRIM(percentage_used::TEXT) ~ '^-?[0-9]+(\.[0-9]+)?$'
            THEN LEAST(ABS(TRIM(percentage_used::TEXT)::NUMERIC), 100)
            ELSE 0 END
    FROM deduped
    WHERE rn = 1
    ORDER BY repository_language_id::INT ASC;
"""

REPOSITORIES_CONTRIBUTORS_TABLE = """
WITH deduped AS (
        SELECT *,
            ROW_NUMBER() OVER (PARTITION BY TRIM(contributor_id::TEXT) ORDER BY TRIM(contributor_id::TEXT)) AS rn
        FROM bronze.repository_contributors
        WHERE TRIM(contributor_id::TEXT) ~ '^[0-9]+$'
    )
    INSERT INTO silver.repository_contributors
    (
        contributor_id, repository_id, user_id, total_commits,
        first_commit_date, last_commit_date
    )
    SELECT
        TRIM(contributor_id::TEXT)::INT,
        TRIM(repository_id::TEXT)::INT,
        TRIM(user_id::TEXT)::INT,
        CASE WHEN TRIM(total_commits::TEXT) ~ '^-?[0-9]+$' THEN ABS(TRIM(total_commits::TEXT)::INT) ELSE 0 END,
        cleaning.fn_parse_date(first_commit_date::TEXT),
        cleaning.fn_parse_date(last_commit_date::TEXT)
    FROM deduped
    WHERE rn = 1
    ORDER BY contributor_id::INT ASC;
"""

BRANCHES_TABLE = """
WITH deduped AS (
        SELECT *,
            ROW_NUMBER() OVER (PARTITION BY TRIM(branch_id::TEXT) ORDER BY TRIM(branch_id::TEXT)) AS rn
        FROM bronze.branches
        WHERE TRIM(branch_id::TEXT) ~ '^[0-9]+$'
    )
    INSERT INTO silver.branches
    (
        branch_id, repository_id, branch_name, created_by, is_default, created_at
    )
    SELECT
        TRIM(branch_id::TEXT)::INT,
        TRIM(repository_id::TEXT)::INT,
        LOWER(TRIM(branch_name)),
        TRIM(created_by::TEXT)::INT,
        cleaning.fn_to_boolean(is_default::TEXT),
        cleaning.fn_parse_date(created_at::TEXT)
    FROM deduped
    WHERE rn = 1
    ORDER BY branch_id::INT ASC;
"""

COMMITS_TABLE = """
WITH deduped AS (
        SELECT *,
            ROW_NUMBER() OVER (PARTITION BY TRIM(commit_id::TEXT) ORDER BY TRIM(commit_id::TEXT)) AS rn
        FROM bronze.commits
        WHERE TRIM(commit_id::TEXT) ~ '^[0-9]+$'
    )
    INSERT INTO silver.commits
    (
        commit_id, commit_hash, repository_id, branch_id, user_id,
        commit_message, files_changed, lines_added, lines_deleted, commit_timestamp
    )
    SELECT
        TRIM(commit_id::TEXT)::BIGINT,
        TRIM(commit_hash),
        TRIM(repository_id::TEXT)::INT,
        TRIM(branch_id::TEXT)::INT,
        TRIM(user_id::TEXT)::INT,
        COALESCE(NULLIF(TRIM(commit_message), ''), '(no commit message provided)'),
        CASE WHEN TRIM(files_changed::TEXT) ~ '^-?[0-9]+$' THEN ABS(TRIM(files_changed::TEXT)::INT) ELSE 0 END,
        CASE WHEN TRIM(lines_added::TEXT) ~ '^-?[0-9]+$' THEN ABS(TRIM(lines_added::TEXT)::INT) ELSE 0 END,
        CASE WHEN TRIM(lines_deleted::TEXT) ~ '^-?[0-9]+$' THEN ABS(TRIM(lines_deleted::TEXT)::INT) ELSE 0 END,
        cleaning.fn_parse_date(commit_timestamp::TEXT)
    FROM deduped
    WHERE rn = 1
    ORDER BY commit_id::BIGINT ASC;
"""

PULL_REQUESTS_TABLE = """
WITH deduped AS (
        SELECT *,
            ROW_NUMBER() OVER (PARTITION BY TRIM(pull_request_id::TEXT) ORDER BY TRIM(pull_request_id::TEXT)) AS rn
        FROM bronze.pull_requests
        WHERE TRIM(pull_request_id::TEXT) ~ '^[0-9]+$'
    )
    INSERT INTO silver.pull_requests
    (
        pull_request_id, repository_id, user_id, source_branch_id,
        target_branch_id, title, status, files_changed, created_at, merged_at
    )
    SELECT
        TRIM(pull_request_id::TEXT)::INT,
        TRIM(repository_id::TEXT)::INT,
        TRIM(user_id::TEXT)::INT,
        TRIM(source_branch_id::TEXT)::INT,
        TRIM(target_branch_id::TEXT)::INT,
        TRIM(title),
        INITCAP(LOWER(TRIM(status))),
        CASE WHEN TRIM(files_changed::TEXT) ~ '^-?[0-9]+$' THEN ABS(TRIM(files_changed::TEXT)::INT) ELSE 0 END,
        cleaning.fn_parse_date(created_at::TEXT),
        cleaning.fn_parse_date(merged_at::TEXT)
    FROM deduped
    WHERE rn = 1
    ORDER BY pull_request_id::INT ASC;
"""

PULL_REQUEST_REVIEWS_TABLE = """
WITH deduped AS (
        SELECT *,
            ROW_NUMBER() OVER (PARTITION BY TRIM(review_id::TEXT) ORDER BY TRIM(review_id::TEXT)) AS rn
        FROM bronze.pull_request_reviews
        WHERE TRIM(review_id::TEXT) ~ '^[0-9]+$'
    )
    INSERT INTO silver.pull_request_reviews
    (
        review_id, pull_request_id, reviewer_id, review_state, review_comment, reviewed_at
    )
    SELECT
        TRIM(review_id::TEXT)::INT,
        TRIM(pull_request_id::TEXT)::INT,
        TRIM(reviewer_id::TEXT)::INT,
        INITCAP(LOWER(TRIM(review_state))),
        NULLIF(TRIM(review_comment), ''),
        cleaning.fn_parse_date(reviewed_at::TEXT)
    FROM deduped
    WHERE rn = 1
    ORDER BY review_id::INT ASC;
"""

ISSUES_TABLE = """
WITH deduped AS (
        SELECT *,
            ROW_NUMBER() OVER (PARTITION BY TRIM(issue_id::TEXT) ORDER BY TRIM(issue_id::TEXT)) AS rn
        FROM bronze.issues
        WHERE TRIM(issue_id::TEXT) ~ '^[0-9]+$'
    )
    INSERT INTO silver.issues
    (
        issue_id, repository_id, user_id, title, issue_type, priority,
        status, created_at, closed_at
    )
    SELECT
        TRIM(issue_id::TEXT)::INT,
        TRIM(repository_id::TEXT)::INT,
        TRIM(user_id::TEXT)::INT,
        COALESCE(NULLIF(TRIM(title), ''), '(untitled issue)'),
        INITCAP(LOWER(TRIM(issue_type))),
        INITCAP(LOWER(TRIM(priority))),
        INITCAP(LOWER(TRIM(status))),
        cleaning.fn_parse_date(created_at::TEXT),
        cleaning.fn_parse_date(closed_at::TEXT)
    FROM deduped
    WHERE rn = 1
    ORDER BY issue_id::INT ASC;
"""

RELEASES_TABLE = """
WITH deduped AS (
        SELECT *,
            ROW_NUMBER() OVER (PARTITION BY TRIM(release_id::TEXT) ORDER BY TRIM(release_id::TEXT)) AS rn
        FROM bronze.releases
        WHERE TRIM(release_id::TEXT) ~ '^[0-9]+$'
    )
    INSERT INTO silver.releases
    (
        release_id, repository_id, tag_name, version, release_title,
        release_notes, published_by, published_at
    )
    SELECT
        TRIM(release_id::TEXT)::INT,
        TRIM(repository_id::TEXT)::INT,
        TRIM(tag_name),
        TRIM(version),
        TRIM(release_title),
        NULLIF(TRIM(release_notes), ''),
        TRIM(published_by::TEXT)::INT,
        cleaning.fn_parse_date(published_at::TEXT)
    FROM deduped
    WHERE rn = 1
    ORDER BY release_id::INT ASC;
"""

STARS_TABLE = """
WITH deduped AS (
        SELECT *,
            ROW_NUMBER() OVER (PARTITION BY TRIM(star_id::TEXT) ORDER BY TRIM(star_id::TEXT)) AS rn
        FROM bronze.stars
        WHERE TRIM(star_id::TEXT) ~ '^[0-9]+$'
    )
    INSERT INTO silver.stars
    (
        star_id, repository_id, user_id, starred_at
    )
    SELECT
        TRIM(star_id::TEXT)::BIGINT,
        TRIM(repository_id::TEXT)::INT,
        TRIM(user_id::TEXT)::INT,
        cleaning.fn_parse_date(starred_at::TEXT)
    FROM deduped
    WHERE rn = 1
    ORDER BY star_id::BIGINT ASC;
"""

FORKS_TABLE = """
    WITH deduped AS (
        SELECT *,
            ROW_NUMBER() OVER (PARTITION BY TRIM(fork_id::TEXT) ORDER BY TRIM(fork_id::TEXT)) AS rn
        FROM bronze.forks
        WHERE TRIM(fork_id::TEXT) ~ '^[0-9]+$'
    )
    INSERT INTO silver.forks
    (
        fork_id, source_repository_id, forked_repository_id, user_id, forked_at
    )
    SELECT
        TRIM(fork_id::TEXT)::BIGINT,
        TRIM(source_repository_id::TEXT)::INT,
        TRIM(forked_repository_id::TEXT)::INT,
        TRIM(user_id::TEXT)::INT,
        cleaning.fn_parse_date(forked_at::TEXT)
    FROM deduped
    WHERE rn = 1
    ORDER BY fork_id::BIGINT ASC;
"""

QUERIES = [
    (PROGRAMMING_LANGUAGES_TABLE, "silver.programming_languages"),
    (USERS_TABLE, "silver.users"),
    (ORGANIZATIONS_TABLE, "silver.organizations"),
    (ORGANIZATIONS_MENBERS_TABLE, "silver.organization_members"),
    (REPOSITORIES_TABLE, "silver.repositories"),
    (REPOSITORIES_LANGUAGES_TABLE, "silver.repository_languages"),
    (REPOSITORIES_CONTRIBUTORS_TABLE, "silver.repository_contributors"),
    (BRANCHES_TABLE, "silver.branches"),
    (COMMITS_TABLE, "silver.commits"),
    (PULL_REQUESTS_TABLE, "silver.pull_requests"),
    (PULL_REQUEST_REVIEWS_TABLE, "silver.pull_request_reviews"),
    (ISSUES_TABLE, "silver.issues"),
    (RELEASES_TABLE, "silver.releases"),
    (STARS_TABLE, "silver.stars"),
    (FORKS_TABLE, "silver.forks")
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
# Insert Bronze Layer Data into Silver Layer Tables
# ======================================================
def insert_data(conn):
    logging.info("=" * 70)
    logging.info("Starting Silver Layer Data Insertion Process...")
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
    logging.info("SILVER LAYER DATA INSERTION - STARTING")
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
        logging.info("SILVER LAYER DATA INSERTION COMPLETED SUCCESSFULLY")
        logging.info(f"Total time: {duration:.2f} seconds")
        logging.info("=" * 70 + "\n")
        
        print("\n" + "=" * 70)
        print("All Data Inserted Successfully!")
        print(f"Time taken: {duration:.2f} seconds")
        print(f"Check logs: {os.path.join(LOG_DIR, LOG_FILE)}")
        print("=" * 70 + "\n")
    
    except Exception as e:
        logging.error("=" * 70)
        logging.error("SILVER LAYER DATA INSERTION FAILED")
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