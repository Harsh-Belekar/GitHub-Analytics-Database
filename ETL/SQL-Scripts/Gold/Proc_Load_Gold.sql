/*
===============================================================================
Stored Procedure: Load Gold Layer (Silver -> Gold)
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

Parameters:
    None.

Usage Example:
    CALL gold.load_gold();

Prerequisites:
    - silver.* tables populated (CALL silver.load_silver() first)
    - gold.* tables created (see Create_Gold_Dimensions_Facts.sql)

Note: gold.dim_date is NOT touched here — it's static calendar data
generated once in Create_Gold_Dimensions_Facts.sql, unrelated to Silver.
===============================================================================
*/

CREATE OR REPLACE PROCEDURE gold.load_gold()
LANGUAGE PLPGSQL
AS $$
DECLARE
    start_time TIMESTAMP;
    end_time TIMESTAMP;
    batch_start_time TIMESTAMP;
    batch_end_time TIMESTAMP;
    duration_seconds NUMERIC;
BEGIN
    batch_start_time := clock_timestamp();
    RAISE NOTICE '================================================';
    RAISE NOTICE 'Loading Gold Layer — GitHub Analytics Database';
    RAISE NOTICE '================================================';

    RAISE NOTICE '------------------------------------------------';
    RAISE NOTICE 'Loading Dimensions';
    RAISE NOTICE '------------------------------------------------';

    -- gold.dim_users
    start_time := clock_timestamp();
    RAISE NOTICE '>> Truncating Table: gold.dim_users';
    TRUNCATE TABLE gold.dim_users;
    RAISE NOTICE '>> Inserting Data Into: gold.dim_users';
    INSERT INTO gold.dim_users
    SELECT
        u.user_id, u.username, u.first_name || ' ' || u.last_name, u.email,
        u.country, u.city, u.company, u.account_type, u.hireable, u.verified,
        u.followers, u.following, u.public_repos, u.public_gists, u.created_at
    FROM silver.users u;
    end_time := clock_timestamp();
    duration_seconds := EXTRACT(EPOCH FROM (end_time - start_time));
    RAISE NOTICE '>> Load Duration: % seconds', duration_seconds;
    RAISE NOTICE '>> -------------';

    -- gold.dim_organizations
    start_time := clock_timestamp();
    RAISE NOTICE '>> Truncating Table: gold.dim_organizations';
    TRUNCATE TABLE gold.dim_organizations;
    RAISE NOTICE '>> Inserting Data Into: gold.dim_organizations';
    INSERT INTO gold.dim_organizations
    SELECT
        o.organization_id, o.organization_name, o.organization_type, o.country,
        o.city, o.industry, o.verified, o.total_repositories, o.total_members, o.created_at
    FROM silver.organizations o;
    end_time := clock_timestamp();
    duration_seconds := EXTRACT(EPOCH FROM (end_time - start_time));
    RAISE NOTICE '>> Load Duration: % seconds', duration_seconds;
    RAISE NOTICE '>> -------------';

    -- gold.dim_languages
    start_time := clock_timestamp();
    RAISE NOTICE '>> Truncating Table: gold.dim_languages';
    TRUNCATE TABLE gold.dim_languages;
    RAISE NOTICE '>> Inserting Data Into: gold.dim_languages';
    INSERT INTO gold.dim_languages
    SELECT language_id, language_name, file_extension, language_type, first_release_year, is_popular
    FROM silver.programming_languages;
    end_time := clock_timestamp();
    duration_seconds := EXTRACT(EPOCH FROM (end_time - start_time));
    RAISE NOTICE '>> Load Duration: % seconds', duration_seconds;
    RAISE NOTICE '>> -------------';

    -- gold.dim_repositories
    start_time := clock_timestamp();
    RAISE NOTICE '>> Truncating Table: gold.dim_repositories';
    TRUNCATE TABLE gold.dim_repositories;
    RAISE NOTICE '>> Inserting Data Into: gold.dim_repositories';
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
    end_time := clock_timestamp();
    duration_seconds := EXTRACT(EPOCH FROM (end_time - start_time));
    RAISE NOTICE '>> Load Duration: % seconds', duration_seconds;
    RAISE NOTICE '>> -------------';

    -- gold.dim_branches
    start_time := clock_timestamp();
    RAISE NOTICE '>> Truncating Table: gold.dim_branches';
    TRUNCATE TABLE gold.dim_branches;
    RAISE NOTICE '>> Inserting Data Into: gold.dim_branches';
    INSERT INTO gold.dim_branches
    SELECT
        b.branch_id, b.repository_id, r.repository_name, b.branch_name,
        b.created_by, u.username, b.is_default, b.created_at
    FROM silver.branches b
    JOIN silver.repositories r ON r.repository_id = b.repository_id
    JOIN silver.users u ON u.user_id = b.created_by;
    end_time := clock_timestamp();
    duration_seconds := EXTRACT(EPOCH FROM (end_time - start_time));
    RAISE NOTICE '>> Load Duration: % seconds', duration_seconds;
    RAISE NOTICE '>> -------------';


    RAISE NOTICE '------------------------------------------------';
    RAISE NOTICE 'Loading Facts';
    RAISE NOTICE '------------------------------------------------';

    -- gold.fact_commits
    start_time := clock_timestamp();
    RAISE NOTICE '>> Truncating Table: gold.fact_commits';
    TRUNCATE TABLE gold.fact_commits;
    RAISE NOTICE '>> Inserting Data Into: gold.fact_commits';
    INSERT INTO gold.fact_commits
    SELECT
        c.commit_id, c.commit_hash, c.repository_id, c.branch_id, c.user_id,
        c.commit_message, c.files_changed, c.lines_added, c.lines_deleted,
        c.lines_added + c.lines_deleted, c.commit_timestamp,
        TO_CHAR(c.commit_timestamp, 'YYYYMMDD')::INT
    FROM silver.commits c;
    end_time := clock_timestamp();
    duration_seconds := EXTRACT(EPOCH FROM (end_time - start_time));
    RAISE NOTICE '>> Load Duration: % seconds', duration_seconds;
    RAISE NOTICE '>> -------------';

    -- gold.fact_pull_requests
    start_time := clock_timestamp();
    RAISE NOTICE '>> Truncating Table: gold.fact_pull_requests';
    TRUNCATE TABLE gold.fact_pull_requests;
    RAISE NOTICE '>> Inserting Data Into: gold.fact_pull_requests';
    INSERT INTO gold.fact_pull_requests
    SELECT
        p.pull_request_id, p.repository_id, p.user_id, p.source_branch_id,
        p.target_branch_id, p.title, p.status, p.files_changed, p.created_at, p.merged_at,
        CASE WHEN p.merged_at IS NOT NULL
            THEN ROUND(EXTRACT(EPOCH FROM (p.merged_at - p.created_at)) / 3600.0, 2)
        END,
        TO_CHAR(p.created_at, 'YYYYMMDD')::INT
    FROM silver.pull_requests p;
    end_time := clock_timestamp();
    duration_seconds := EXTRACT(EPOCH FROM (end_time - start_time));
    RAISE NOTICE '>> Load Duration: % seconds', duration_seconds;
    RAISE NOTICE '>> -------------';

    -- gold.fact_pull_request_reviews
    start_time := clock_timestamp();
    RAISE NOTICE '>> Truncating Table: gold.fact_pull_request_reviews';
    TRUNCATE TABLE gold.fact_pull_request_reviews;
    RAISE NOTICE '>> Inserting Data Into: gold.fact_pull_request_reviews';
    INSERT INTO gold.fact_pull_request_reviews
    SELECT
        rv.review_id, rv.pull_request_id, pr.repository_id, rv.reviewer_id,
        pr.user_id, rv.review_state, rv.reviewed_at,
        TO_CHAR(rv.reviewed_at, 'YYYYMMDD')::INT
    FROM silver.pull_request_reviews rv
    JOIN silver.pull_requests pr ON rv.pull_request_id = pr.pull_request_id;
    end_time := clock_timestamp();
    duration_seconds := EXTRACT(EPOCH FROM (end_time - start_time));
    RAISE NOTICE '>> Load Duration: % seconds', duration_seconds;
    RAISE NOTICE '>> -------------';

    -- gold.fact_issues
    start_time := clock_timestamp();
    RAISE NOTICE '>> Truncating Table: gold.fact_issues';
    TRUNCATE TABLE gold.fact_issues;
    RAISE NOTICE '>> Inserting Data Into: gold.fact_issues';
    INSERT INTO gold.fact_issues
    SELECT
        i.issue_id, i.repository_id, i.user_id, i.title, i.issue_type, i.priority,
        i.status, i.created_at, i.closed_at,
        CASE WHEN i.closed_at IS NOT NULL
            THEN ROUND(EXTRACT(EPOCH FROM (i.closed_at - i.created_at)) / 3600.0, 2)
        END,
        TO_CHAR(i.created_at, 'YYYYMMDD')::INT
    FROM silver.issues i;
    end_time := clock_timestamp();
    duration_seconds := EXTRACT(EPOCH FROM (end_time - start_time));
    RAISE NOTICE '>> Load Duration: % seconds', duration_seconds;
    RAISE NOTICE '>> -------------';

    -- gold.fact_releases
    start_time := clock_timestamp();
    RAISE NOTICE '>> Truncating Table: gold.fact_releases';
    TRUNCATE TABLE gold.fact_releases;
    RAISE NOTICE '>> Inserting Data Into: gold.fact_releases';
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
    end_time := clock_timestamp();
    duration_seconds := EXTRACT(EPOCH FROM (end_time - start_time));
    RAISE NOTICE '>> Load Duration: % seconds', duration_seconds;
    RAISE NOTICE '>> -------------';

    -- gold.fact_stars
    start_time := clock_timestamp();
    RAISE NOTICE '>> Truncating Table: gold.fact_stars';
    TRUNCATE TABLE gold.fact_stars;
    RAISE NOTICE '>> Inserting Data Into: gold.fact_stars';
    INSERT INTO gold.fact_stars
    SELECT star_id, repository_id, user_id, starred_at, TO_CHAR(starred_at, 'YYYYMMDD')::INT
    FROM silver.stars;
    end_time := clock_timestamp();
    duration_seconds := EXTRACT(EPOCH FROM (end_time - start_time));
    RAISE NOTICE '>> Load Duration: % seconds', duration_seconds;
    RAISE NOTICE '>> -------------';

    -- gold.fact_forks
    start_time := clock_timestamp();
    RAISE NOTICE '>> Truncating Table: gold.fact_forks';
    TRUNCATE TABLE gold.fact_forks;
    RAISE NOTICE '>> Inserting Data Into: gold.fact_forks';
    INSERT INTO gold.fact_forks
    SELECT fork_id, source_repository_id, forked_repository_id, user_id, forked_at,
        TO_CHAR(forked_at, 'YYYYMMDD')::INT
    FROM silver.forks;
    end_time := clock_timestamp();
    duration_seconds := EXTRACT(EPOCH FROM (end_time - start_time));
    RAISE NOTICE '>> Load Duration: % seconds', duration_seconds;
    RAISE NOTICE '>> -------------';

    -- gold.fact_repository_contributors
    start_time := clock_timestamp();
    RAISE NOTICE '>> Truncating Table: gold.fact_repository_contributors';
    TRUNCATE TABLE gold.fact_repository_contributors;
    RAISE NOTICE '>> Inserting Data Into: gold.fact_repository_contributors';
    INSERT INTO gold.fact_repository_contributors
    SELECT contributor_id, repository_id, user_id, total_commits, first_commit_date, last_commit_date
    FROM silver.repository_contributors;
    end_time := clock_timestamp();
    duration_seconds := EXTRACT(EPOCH FROM (end_time - start_time));
    RAISE NOTICE '>> Load Duration: % seconds', duration_seconds;
    RAISE NOTICE '>> -------------';

    -- gold.fact_repository_languages
    start_time := clock_timestamp();
    RAISE NOTICE '>> Truncating Table: gold.fact_repository_languages';
    TRUNCATE TABLE gold.fact_repository_languages;
    RAISE NOTICE '>> Inserting Data Into: gold.fact_repository_languages';
    INSERT INTO gold.fact_repository_languages
    SELECT repository_language_id, repository_id, language_id, percentage_used
    FROM silver.repository_languages;
    end_time := clock_timestamp();
    duration_seconds := EXTRACT(EPOCH FROM (end_time - start_time));
    RAISE NOTICE '>> Load Duration: % seconds', duration_seconds;
    RAISE NOTICE '>> -------------';

    -- gold.fact_organization_members
    start_time := clock_timestamp();
    RAISE NOTICE '>> Truncating Table: gold.fact_organization_members';
    TRUNCATE TABLE gold.fact_organization_members;
    RAISE NOTICE '>> Inserting Data Into: gold.fact_organization_members';
    INSERT INTO gold.fact_organization_members
    SELECT membership_id, organization_id, user_id, role, joined_at, is_public
    FROM silver.organization_members;
    end_time := clock_timestamp();
    duration_seconds := EXTRACT(EPOCH FROM (end_time - start_time));
    RAISE NOTICE '>> Load Duration: % seconds', duration_seconds;
    RAISE NOTICE '>> -------------';


    batch_end_time := clock_timestamp();
    duration_seconds := EXTRACT(EPOCH FROM (batch_end_time - batch_start_time));
    RAISE NOTICE '==========================================';
    RAISE NOTICE '>> Loading Gold Layer is Completed';
    RAISE NOTICE '>> Total Load Duration: % seconds ', duration_seconds;
    RAISE NOTICE '==========================================';

EXCEPTION
    WHEN others THEN
        RAISE NOTICE '==========================================';
        RAISE NOTICE '❌ ERROR OCCURRED DURING LOADING GOLD LAYER';
        RAISE NOTICE 'Error Message %', SQLERRM;
        RAISE NOTICE 'Error SQL State Code: %', SQLSTATE;
        RAISE NOTICE '==========================================';
END
$$;
