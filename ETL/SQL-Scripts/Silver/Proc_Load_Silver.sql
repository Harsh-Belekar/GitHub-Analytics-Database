/*
===============================================================================
Stored Procedure: Load Silver Layer (Bronze -> Silver)
===============================================================================
Script Purpose:
    This stored procedure performs the ETL (Extract, Transform, Load) process to 
    populate the 'silver' schema tables from the 'bronze' schema.
	Actions Performed:
		- Truncates Silver tables.
		- Inserts transformed and cleansed data from Bronze into Silver tables.
		
Parameters:
    None. 
		This stored procedure does not accept any parameters or return any values.

Usage Example:
    CALL Silver.load_silver();
===============================================================================
*/

CREATE OR REPLACE PROCEDURE silver.load_silver()
LANGUAGE PLPGSQL
AS $$
DECLARE 
    start_time TIMESTAMP; 
    end_time TIMESTAMP; 
    batch_start_time TIMESTAMP;
    batch_end_time TIMESTAMP;
    duration_seconds NUMERIC;
BEGIN
	batch_start_time := clock_timestamp(); -- Record start time
	RAISE NOTICE '================================================';
    RAISE NOTICE 'Loading Silver Layer — GitHub Analytics Database';
	RAISE NOTICE '================================================';


    -- Loading silver.programming_languages
    start_time := clock_timestamp(); -- Record start time
	RAISE NOTICE '>> Truncating Table: silver.programming_languages';
	TRUNCATE TABLE silver.programming_languages;
	RAISE NOTICE '>> Inserting Data Into: silver.programming_languages';
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
    end_time := clock_timestamp(); -- Record end time
	duration_seconds := EXTRACT(EPOCH FROM (end_time - start_time));
	RAISE NOTICE '>> Load Duration: % seconds', duration_seconds;
    RAISE NOTICE '>> -------------';


    -- Loading silver.users
    start_time := clock_timestamp(); -- Record start time
	RAISE NOTICE '>> Truncating Table: silver.users';
	TRUNCATE TABLE silver.users;
	RAISE NOTICE '>> Inserting Data Into: silver.users';
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
    end_time := clock_timestamp(); -- Record end time
	duration_seconds := EXTRACT(EPOCH FROM (end_time - start_time));
	RAISE NOTICE '>> Load Duration: % seconds', duration_seconds;
    RAISE NOTICE '>> -------------';


    -- Loading silver.organizations
    start_time := clock_timestamp(); -- Record start time
	RAISE NOTICE '>> Truncating Table: silver.organizations';
	TRUNCATE TABLE silver.organizations;
	RAISE NOTICE '>> Inserting Data Into: silver.organizations';
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
    end_time := clock_timestamp(); -- Record end time
	duration_seconds := EXTRACT(EPOCH FROM (end_time - start_time));
	RAISE NOTICE '>> Load Duration: % seconds', duration_seconds;
    RAISE NOTICE '>> -------------';


    -- Loading silver.repositories
    start_time := clock_timestamp(); -- Record start time
	RAISE NOTICE '>> Truncating Table: silver.repositories';
	TRUNCATE TABLE silver.repositories;
	RAISE NOTICE '>> Inserting Data Into: silver.repositories';
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
    end_time := clock_timestamp(); -- Record end time
	duration_seconds := EXTRACT(EPOCH FROM (end_time - start_time));
	RAISE NOTICE '>> Load Duration: % seconds', duration_seconds;
    RAISE NOTICE '>> -------------';


    -- Loading silver.organization_members
    start_time := clock_timestamp(); -- Record start time
	RAISE NOTICE '>> Truncating Table: silver.organization_members';
	TRUNCATE TABLE silver.organization_members;
	RAISE NOTICE '>> Inserting Data Into: silver.organization_members';
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
    end_time := clock_timestamp(); -- Record end time
	duration_seconds := EXTRACT(EPOCH FROM (end_time - start_time));
	RAISE NOTICE '>> Load Duration: % seconds', duration_seconds;
    RAISE NOTICE '>> -------------';


    -- Loading silver.repository_languages
    start_time := clock_timestamp(); -- Record start time
	RAISE NOTICE '>> Truncating Table: silver.repository_languages';
	TRUNCATE TABLE silver.repository_languages;
	RAISE NOTICE '>> Inserting Data Into: silver.repository_languages';
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
    end_time := clock_timestamp(); -- Record end time
	duration_seconds := EXTRACT(EPOCH FROM (end_time - start_time));
	RAISE NOTICE '>> Load Duration: % seconds', duration_seconds;
    RAISE NOTICE '>> -------------';


    -- Loading silver.repository_contributors
    start_time := clock_timestamp(); -- Record start time
	RAISE NOTICE '>> Truncating Table: silver.repository_contributors';
	TRUNCATE TABLE silver.repository_contributors;
	RAISE NOTICE '>> Inserting Data Into: silver.repository_contributors';
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
    end_time := clock_timestamp(); -- Record end time
	duration_seconds := EXTRACT(EPOCH FROM (end_time - start_time));
	RAISE NOTICE '>> Load Duration: % seconds', duration_seconds;
    RAISE NOTICE '>> -------------';


    -- Loading silver.branches
    start_time := clock_timestamp(); -- Record start time
	RAISE NOTICE '>> Truncating Table: silver.branches';
	TRUNCATE TABLE silver.branches;
	RAISE NOTICE '>> Inserting Data Into: silver.branches';
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
    end_time := clock_timestamp(); -- Record end time
	duration_seconds := EXTRACT(EPOCH FROM (end_time - start_time));
	RAISE NOTICE '>> Load Duration: % seconds', duration_seconds;
    RAISE NOTICE '>> -------------';


    -- Loading silver.commits
    start_time := clock_timestamp(); -- Record start time
	RAISE NOTICE '>> Truncating Table: silver.commits';
	TRUNCATE TABLE silver.commits;
	RAISE NOTICE '>> Inserting Data Into: silver.commits';
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
    end_time := clock_timestamp(); -- Record end time
	duration_seconds := EXTRACT(EPOCH FROM (end_time - start_time));
	RAISE NOTICE '>> Load Duration: % seconds', duration_seconds;
    RAISE NOTICE '>> -------------';


    -- Loading silver.pull_requests
    start_time := clock_timestamp(); -- Record start time
	RAISE NOTICE '>> Truncating Table: silver.pull_requests';
	TRUNCATE TABLE silver.pull_requests;
	RAISE NOTICE '>> Inserting Data Into: silver.pull_requests';
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
    end_time := clock_timestamp(); -- Record end time
	duration_seconds := EXTRACT(EPOCH FROM (end_time - start_time));
	RAISE NOTICE '>> Load Duration: % seconds', duration_seconds;
    RAISE NOTICE '>> -------------';


    -- Loading silver.pull_request_reviews
    start_time := clock_timestamp(); -- Record start time
	RAISE NOTICE '>> Truncating Table: silver.pull_request_reviews';
	TRUNCATE TABLE silver.pull_request_reviews;
	RAISE NOTICE '>> Inserting Data Into: silver.pull_request_reviews';
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
    end_time := clock_timestamp(); -- Record end time
	duration_seconds := EXTRACT(EPOCH FROM (end_time - start_time));
	RAISE NOTICE '>> Load Duration: % seconds', duration_seconds;
    RAISE NOTICE '>> -------------';


    -- Loading silver.issues
    start_time := clock_timestamp(); -- Record start time
	RAISE NOTICE '>> Truncating Table: silver.issues';
	TRUNCATE TABLE silver.issues;
	RAISE NOTICE '>> Inserting Data Into: silver.issues';
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
    end_time := clock_timestamp(); -- Record end time
	duration_seconds := EXTRACT(EPOCH FROM (end_time - start_time));
	RAISE NOTICE '>> Load Duration: % seconds', duration_seconds;
    RAISE NOTICE '>> -------------';


    -- Loading silver.releases
    start_time := clock_timestamp(); -- Record start time
	RAISE NOTICE '>> Truncating Table: silver.releases';
	TRUNCATE TABLE silver.releases;
	RAISE NOTICE '>> Inserting Data Into: silver.releases';
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
    end_time := clock_timestamp(); -- Record end time
	duration_seconds := EXTRACT(EPOCH FROM (end_time - start_time));
	RAISE NOTICE '>> Load Duration: % seconds', duration_seconds;
    RAISE NOTICE '>> -------------';


    -- Loading silver.stars
    start_time := clock_timestamp(); -- Record start time
	RAISE NOTICE '>> Truncating Table: silver.stars';
	TRUNCATE TABLE silver.stars;
	RAISE NOTICE '>> Inserting Data Into: silver.stars';
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
    end_time := clock_timestamp(); -- Record end time
	duration_seconds := EXTRACT(EPOCH FROM (end_time - start_time));
	RAISE NOTICE '>> Load Duration: % seconds', duration_seconds;
    RAISE NOTICE '>> -------------';


    -- Loading silver.forks
    start_time := clock_timestamp(); -- Record start time
	RAISE NOTICE '>> Truncating Table: silver.forks';
	TRUNCATE TABLE silver.forks;
	RAISE NOTICE '>> Inserting Data Into: silver.forks';
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
    end_time := clock_timestamp(); -- Record end time
	duration_seconds := EXTRACT(EPOCH FROM (end_time - start_time));
	RAISE NOTICE '>> Load Duration: % seconds', duration_seconds;
    RAISE NOTICE '>> -------------';


    batch_end_time := clock_timestamp(); -- Record end time
	duration_seconds := EXTRACT(EPOCH FROM (batch_end_time - batch_start_time));
	RAISE NOTICE '==========================================';
	RAISE NOTICE '>> Loading Silver Layer is Completed';
    RAISE NOTICE '>> Total Load Duration: % seconds ', duration_seconds;
	RAISE NOTICE '==========================================';

EXCEPTION
	WHEN others THEN
		RAISE NOTICE '==========================================';
		RAISE NOTICE '❌ ERROR OCCURED DURING LOADING SILVER LAYER';
		RAISE NOTICE 'Error Message %', SQLERRM;
		RAISE NOTICE 'Error SQL State Code: %' , SQLSTATE;
		RAISE NOTICE '==========================================';
END
$$;