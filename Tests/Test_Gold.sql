-- =============================================================================
-- GitHub Analytics Database
-- Gold Layer Data Quality & Validation Tests
-- =============================================================================
-- Purpose:
--     Validate Gold dimensions, fact tables, calculated metrics,
--     relationships, reporting views, and Silver -> Gold reconciliation.
--
-- Layer:
--     Gold
--
-- Source:
--     Silver -> Gold
--
-- Expected Result:
--     Validation queries should return 0 violations unless explicitly
--     documented otherwise.
-- =============================================================================



-- =============================================================================
-- SECTION 1: GOLD TABLE EXISTENCE TESTS
-- =============================================================================

-- Gold dimension/fact tables:
-- dim_languages
-- dim_users
-- dim_organizations
-- dim_repositories
-- fact_organization_members
-- fact_repository_languages
-- fact_repository_contributors
-- fact_commits
-- fact_pull_requests
-- fact_pull_request_reviews
-- fact_issues
-- fact_releases
-- fact_stars
-- fact_forks


SELECT
    table_name
FROM information_schema.tables
WHERE table_schema = 'gold'
ORDER BY table_name;


-- Count Gold physical tables
SELECT
    COUNT(*) AS gold_table_count
FROM information_schema.tables
WHERE table_schema = 'gold';


-- Expected:
-- 14 physical Gold tables
-- Adjust this expectation if your DDL_Gold.sql contains additional tables.



-- =============================================================================
-- SECTION 2: GOLD VIEW EXISTENCE TESTS
-- =============================================================================

SELECT
    table_name AS view_name
FROM information_schema.views
WHERE table_schema = 'gold'
ORDER BY table_name;


-- Expected reporting views include:
--
-- repository_performance_summary
-- developer_productivity_summary
-- repository_monthly_activity
-- developer_monthly_activity
-- organization_summary
-- language_adoption_summary
-- pull_request_efficiency_summary
-- issue_resolution_summary
-- release_analytics_summary
-- data_quality_row_counts
-- data_quality_summary
-- data_quality_field_issues
-- executive_summary



-- =============================================================================
-- SECTION 3: GOLD ROW COUNT SUMMARY
-- =============================================================================

SELECT
    'dim_languages' AS table_name,
    COUNT(*) AS row_count
FROM gold.dim_languages

UNION ALL
SELECT 'dim_users', COUNT(*) FROM gold.dim_users

UNION ALL
SELECT 'dim_organizations', COUNT(*) FROM gold.dim_organizations

UNION ALL
SELECT 'dim_repositories', COUNT(*) FROM gold.dim_repositories

UNION ALL
SELECT 'fact_organization_members', COUNT(*)
FROM gold.fact_organization_members

UNION ALL
SELECT 'fact_repository_languages', COUNT(*)
FROM gold.fact_repository_languages

UNION ALL
SELECT 'fact_repository_contributors', COUNT(*)
FROM gold.fact_repository_contributors

UNION ALL
SELECT 'fact_commits', COUNT(*)
FROM gold.fact_commits

UNION ALL
SELECT 'fact_pull_requests', COUNT(*)
FROM gold.fact_pull_requests

UNION ALL
SELECT 'fact_pull_request_reviews', COUNT(*)
FROM gold.fact_pull_request_reviews

UNION ALL
SELECT 'fact_issues', COUNT(*)
FROM gold.fact_issues

UNION ALL
SELECT 'fact_releases', COUNT(*)
FROM gold.fact_releases

UNION ALL
SELECT 'fact_stars', COUNT(*)
FROM gold.fact_stars

UNION ALL
SELECT 'fact_forks', COUNT(*)
FROM gold.fact_forks

ORDER BY table_name;



-- =============================================================================
-- SECTION 4: DIMENSION PRIMARY KEY VALIDATION
-- =============================================================================

-- Languages
SELECT
    language_id,
    COUNT(*) AS duplicate_count
FROM gold.dim_languages
GROUP BY language_id
HAVING COUNT(*) > 1;


-- Users
SELECT
    user_id,
    COUNT(*) AS duplicate_count
FROM gold.dim_users
GROUP BY user_id
HAVING COUNT(*) > 1;


-- Organizations
SELECT
    organization_id,
    COUNT(*) AS duplicate_count
FROM gold.dim_organizations
GROUP BY organization_id
HAVING COUNT(*) > 1;


-- Repositories
SELECT
    repository_id,
    COUNT(*) AS duplicate_count
FROM gold.dim_repositories
GROUP BY repository_id
HAVING COUNT(*) > 1;


-- Expected:
-- 0 rows for every query.



-- =============================================================================
-- SECTION 5: FACT PRIMARY KEY VALIDATION
-- =============================================================================

SELECT
    commit_id,
    COUNT(*) AS duplicate_count
FROM gold.fact_commits
GROUP BY commit_id
HAVING COUNT(*) > 1;


SELECT
    pull_request_id,
    COUNT(*) AS duplicate_count
FROM gold.fact_pull_requests
GROUP BY pull_request_id
HAVING COUNT(*) > 1;


SELECT
    review_id,
    COUNT(*) AS duplicate_count
FROM gold.fact_pull_request_reviews
GROUP BY review_id
HAVING COUNT(*) > 1;


SELECT
    issue_id,
    COUNT(*) AS duplicate_count
FROM gold.fact_issues
GROUP BY issue_id
HAVING COUNT(*) > 1;


SELECT
    release_id,
    COUNT(*) AS duplicate_count
FROM gold.fact_releases
GROUP BY release_id
HAVING COUNT(*) > 1;


SELECT
    star_id,
    COUNT(*) AS duplicate_count
FROM gold.fact_stars
GROUP BY star_id
HAVING COUNT(*) > 1;


SELECT
    fork_id,
    COUNT(*) AS duplicate_count
FROM gold.fact_forks
GROUP BY fork_id
HAVING COUNT(*) > 1;


-- Expected:
-- 0 rows.



-- =============================================================================
-- SECTION 6: NULL KEY VALIDATION
-- =============================================================================

SELECT
    COUNT(*) AS invalid_language_keys
FROM gold.dim_languages
WHERE language_id IS NULL;


SELECT
    COUNT(*) AS invalid_user_keys
FROM gold.dim_users
WHERE user_id IS NULL;


SELECT
    COUNT(*) AS invalid_organization_keys
FROM gold.dim_organizations
WHERE organization_id IS NULL;


SELECT
    COUNT(*) AS invalid_repository_keys
FROM gold.dim_repositories
WHERE repository_id IS NULL;


SELECT
    COUNT(*) AS invalid_commit_keys
FROM gold.fact_commits
WHERE commit_id IS NULL;


SELECT
    COUNT(*) AS invalid_pr_keys
FROM gold.fact_pull_requests
WHERE pull_request_id IS NULL;


SELECT
    COUNT(*) AS invalid_issue_keys
FROM gold.fact_issues
WHERE issue_id IS NULL;


SELECT
    COUNT(*) AS invalid_release_keys
FROM gold.fact_releases
WHERE release_id IS NULL;


SELECT
    COUNT(*) AS invalid_star_keys
FROM gold.fact_stars
WHERE star_id IS NULL;


SELECT
    COUNT(*) AS invalid_fork_keys
FROM gold.fact_forks
WHERE fork_id IS NULL;



-- =============================================================================
-- SECTION 7: DIMENSION -> FACT REFERENTIAL INTEGRITY
-- =============================================================================

-- Commits -> Repository
SELECT
    COUNT(*) AS orphan_commits_repository
FROM gold.fact_commits fc
LEFT JOIN gold.dim_repositories dr
    ON dr.repository_id = fc.repository_id
WHERE dr.repository_id IS NULL;


-- Commits -> User
SELECT
    COUNT(*) AS orphan_commits_user
FROM gold.fact_commits fc
LEFT JOIN gold.dim_users du
    ON du.user_id = fc.user_id
WHERE du.user_id IS NULL;


-- Pull Requests -> Repository
SELECT
    COUNT(*) AS orphan_pr_repository
FROM gold.fact_pull_requests pr
LEFT JOIN gold.dim_repositories dr
    ON dr.repository_id = pr.repository_id
WHERE dr.repository_id IS NULL;


-- Pull Requests -> User
SELECT
    COUNT(*) AS orphan_pr_user
FROM gold.fact_pull_requests pr
LEFT JOIN gold.dim_users du
    ON du.user_id = pr.author_id
WHERE du.user_id IS NULL;


-- Pull Request Reviews -> Pull Request
SELECT
    COUNT(*) AS orphan_reviews_pr
FROM gold.fact_pull_request_reviews rv
LEFT JOIN gold.fact_pull_requests pr
    ON pr.pull_request_id = rv.pull_request_id
WHERE pr.pull_request_id IS NULL;


-- Pull Request Reviews -> Reviewer
SELECT
    COUNT(*) AS orphan_reviews_user
FROM gold.fact_pull_request_reviews rv
LEFT JOIN gold.dim_users du
    ON du.user_id = rv.reviewer_id
WHERE du.user_id IS NULL;


-- Issues -> Repository
SELECT
    COUNT(*) AS orphan_issues_repository
FROM gold.fact_issues fi
LEFT JOIN gold.dim_repositories dr
    ON dr.repository_id = fi.repository_id
WHERE dr.repository_id IS NULL;


-- Issues -> User
SELECT
    COUNT(*) AS orphan_issues_user
FROM gold.fact_issues fi
LEFT JOIN gold.dim_users du
    ON du.user_id = fi.user_id
WHERE du.user_id IS NULL;


-- Releases -> Repository
SELECT
    COUNT(*) AS orphan_releases_repository
FROM gold.fact_releases fr
LEFT JOIN gold.dim_repositories dr
    ON dr.repository_id = fr.repository_id
WHERE dr.repository_id IS NULL;


-- Releases -> Publisher
SELECT
    COUNT(*) AS orphan_releases_user
FROM gold.fact_releases fr
LEFT JOIN gold.dim_users du
    ON du.user_id = fr.published_by
WHERE du.user_id IS NULL;


-- Stars -> Repository
SELECT
    COUNT(*) AS orphan_stars_repository
FROM gold.fact_stars fs
LEFT JOIN gold.dim_repositories dr
    ON dr.repository_id = fs.repository_id
WHERE dr.repository_id IS NULL;


-- Stars -> User
SELECT
    COUNT(*) AS orphan_stars_user
FROM gold.fact_stars fs
LEFT JOIN gold.dim_users du
    ON du.user_id = fs.user_id
WHERE du.user_id IS NULL;


-- Forks -> Source Repository
SELECT
    COUNT(*) AS orphan_fork_source
FROM gold.fact_forks ff
LEFT JOIN gold.dim_repositories dr
    ON dr.repository_id = ff.source_repository_id
WHERE dr.repository_id IS NULL;


-- Forks -> User
SELECT
    COUNT(*) AS orphan_fork_user
FROM gold.fact_forks ff
LEFT JOIN gold.dim_users du
    ON du.user_id = ff.user_id
WHERE du.user_id IS NULL;



-- =============================================================================
-- SECTION 8: REPOSITORY DIMENSION VALIDATION
-- =============================================================================

-- Repository owner must exist
SELECT
    COUNT(*) AS invalid_repository_owners
FROM gold.dim_repositories dr
LEFT JOIN gold.dim_users du
    ON du.user_id = dr.owner_id
WHERE du.user_id IS NULL;


-- Organization must exist when organization_id is populated
SELECT
    COUNT(*) AS invalid_repository_organizations
FROM gold.dim_repositories dr
LEFT JOIN gold.dim_organizations do_
    ON do_.organization_id = dr.organization_id
WHERE dr.organization_id IS NOT NULL
    AND do_.organization_id IS NULL;


-- Primary programming language must exist
SELECT
    COUNT(*) AS invalid_primary_languages
FROM gold.dim_repositories dr
LEFT JOIN gold.dim_languages dl
    ON dl.language_id = dr.primary_language_id
WHERE dl.language_id IS NULL;


-- Repository names should not be blank
SELECT
    COUNT(*) AS blank_repository_names
FROM gold.dim_repositories
WHERE repository_name IS NULL
    OR TRIM(repository_name) = '';



-- =============================================================================
-- SECTION 9: FACT VALUE VALIDATION
-- =============================================================================

-- Commit lines cannot be negative
SELECT
    COUNT(*) AS invalid_lines_added
FROM gold.fact_commits
WHERE lines_added < 0;


SELECT
    COUNT(*) AS invalid_lines_deleted
FROM gold.fact_commits
WHERE lines_deleted < 0;


-- Pull Request files changed cannot be negative
SELECT
    COUNT(*) AS invalid_pr_files_changed
FROM gold.fact_pull_requests
WHERE files_changed < 0;


-- Issue status
SELECT
    COUNT(*) AS invalid_issue_status
FROM gold.fact_issues
WHERE status NOT IN ('Open', 'Closed');


-- Pull Request status
SELECT
    COUNT(*) AS invalid_pr_status
FROM gold.fact_pull_requests
WHERE status NOT IN ('Open', 'Closed', 'Merged');


-- Review state
SELECT
    COUNT(*) AS invalid_review_state
FROM gold.fact_pull_request_reviews
WHERE review_state NOT IN
    ('Approved', 'Changes Requested', 'Commented');



-- =============================================================================
-- SECTION 10: DATE/TIMESTAMP VALIDATION
-- =============================================================================

-- Repository dates
SELECT
    COUNT(*) AS invalid_repository_dates
FROM gold.dim_repositories
WHERE updated_at < created_at;


-- Commit timestamp should exist
SELECT
    COUNT(*) AS missing_commit_timestamp
FROM gold.fact_commits
WHERE commit_timestamp IS NULL;


-- PR merge date
SELECT
    COUNT(*) AS invalid_pr_merge_dates
FROM gold.fact_pull_requests
WHERE merged_at IS NOT NULL
    AND merged_at < created_at;


-- Issue resolution date
SELECT
    COUNT(*) AS invalid_issue_dates
FROM gold.fact_issues
WHERE closed_at IS NOT NULL
    AND closed_at < created_at;


-- Release date
SELECT
    COUNT(*) AS missing_release_dates
FROM gold.fact_releases
WHERE published_at IS NULL;


-- Star timestamp
SELECT
    COUNT(*) AS missing_star_dates
FROM gold.fact_stars
WHERE starred_at IS NULL;



-- =============================================================================
-- SECTION 11: CALCULATED METRIC VALIDATION
-- =============================================================================

-- ---------------------------------------------------------------------------
-- Test 11.1: total_lines_changed
-- ---------------------------------------------------------------------------
-- If total_lines_changed is calculated as:
-- lines_added + lines_deleted


SELECT
    COUNT(*) AS incorrect_total_lines_changed
FROM gold.fact_commits
WHERE total_lines_changed <> (lines_added + lines_deleted);


-- Expected:
-- 0



-- ---------------------------------------------------------------------------
-- Test 11.2: Pull Request hours_to_merge
-- ---------------------------------------------------------------------------

SELECT
    COUNT(*) AS incorrect_hours_to_merge
FROM gold.fact_pull_requests
WHERE merged_at IS NOT NULL
    AND hours_to_merge IS NOT NULL
    AND hours_to_merge <>
        ROUND(
            EXTRACT(
                EPOCH FROM (merged_at - created_at)
            ) / 3600.0,
            2
        );


-- ---------------------------------------------------------------------------
-- Test 11.3: Issue hours_to_resolve
-- ---------------------------------------------------------------------------

SELECT
    COUNT(*) AS incorrect_hours_to_resolve
FROM gold.fact_issues
WHERE closed_at IS NOT NULL
    AND hours_to_resolve IS NOT NULL
    AND hours_to_resolve <>
        ROUND(
            EXTRACT(
                EPOCH FROM (closed_at - created_at)
            ) / 3600.0,
            2
        );



-- =============================================================================
-- SECTION 12: RELEASE METRIC VALIDATION
-- =============================================================================

-- First release should not have a previous-release interval
SELECT
    COUNT(*) AS invalid_first_release_interval
FROM gold.fact_releases
WHERE days_since_previous_release IS NOT NULL
    AND days_since_previous_release < 0;


-- Release type should contain expected values
SELECT
    release_type,
    COUNT(*) AS release_count
FROM gold.fact_releases
GROUP BY release_type
ORDER BY release_type;


-- Check for unexpected release types
SELECT
    COUNT(*) AS invalid_release_types
FROM gold.fact_releases
WHERE release_type NOT IN ('Major', 'Minor', 'Patch');



-- =============================================================================
-- SECTION 13: STAR VALIDATION
-- =============================================================================

-- A user should not star the same repository more than once.
SELECT
    repository_id,
    user_id,
    COUNT(*) AS duplicate_star_count
FROM gold.fact_stars
GROUP BY repository_id, user_id
HAVING COUNT(*) > 1;


-- Expected:
-- 0 rows



-- =============================================================================
-- SECTION 14: FORK VALIDATION
-- =============================================================================

-- Source and forked repository must be different.
SELECT
    COUNT(*) AS invalid_forks
FROM gold.fact_forks
WHERE source_repository_id = forked_repository_id;


-- Expected:
-- 0



-- =============================================================================
-- SECTION 15: SILVER -> GOLD ROW RECONCILIATION
-- =============================================================================
-- Gold fact tables should normally reconcile with their corresponding
-- Silver tables after the Gold load.
--
-- These checks are especially useful for detecting accidental data loss
-- during Gold transformation.


SELECT
    'users' AS entity,
    (SELECT COUNT(*) FROM silver.users) AS silver_count,
    (SELECT COUNT(*) FROM gold.dim_users) AS gold_count,
    (SELECT COUNT(*) FROM silver.users)
        - (SELECT COUNT(*) FROM gold.dim_users) AS difference

UNION ALL

SELECT
    'organizations',
    (SELECT COUNT(*) FROM silver.organizations),
    (SELECT COUNT(*) FROM gold.dim_organizations),
    (SELECT COUNT(*) FROM silver.organizations)
        - (SELECT COUNT(*) FROM gold.dim_organizations)

UNION ALL

SELECT
    'repositories',
    (SELECT COUNT(*) FROM silver.repositories),
    (SELECT COUNT(*) FROM gold.dim_repositories),
    (SELECT COUNT(*) FROM silver.repositories)
        - (SELECT COUNT(*) FROM gold.dim_repositories)

UNION ALL

SELECT
    'commits',
    (SELECT COUNT(*) FROM silver.commits),
    (SELECT COUNT(*) FROM gold.fact_commits),
    (SELECT COUNT(*) FROM silver.commits)
        - (SELECT COUNT(*) FROM gold.fact_commits)

UNION ALL

SELECT
    'pull_requests',
    (SELECT COUNT(*) FROM silver.pull_requests),
    (SELECT COUNT(*) FROM gold.fact_pull_requests),
    (SELECT COUNT(*) FROM silver.pull_requests)
        - (SELECT COUNT(*) FROM gold.fact_pull_requests)

UNION ALL

SELECT
    'pull_request_reviews',
    (SELECT COUNT(*) FROM silver.pull_request_reviews),
    (SELECT COUNT(*) FROM gold.fact_pull_request_reviews),
    (SELECT COUNT(*) FROM silver.pull_request_reviews)
        - (SELECT COUNT(*) FROM gold.fact_pull_request_reviews)

UNION ALL

SELECT
    'issues',
    (SELECT COUNT(*) FROM silver.issues),
    (SELECT COUNT(*) FROM gold.fact_issues),
    (SELECT COUNT(*) FROM silver.issues)
        - (SELECT COUNT(*) FROM gold.fact_issues)

UNION ALL

SELECT
    'releases',
    (SELECT COUNT(*) FROM silver.releases),
    (SELECT COUNT(*) FROM gold.fact_releases),
    (SELECT COUNT(*) FROM silver.releases)
        - (SELECT COUNT(*) FROM gold.fact_releases)

UNION ALL

SELECT
    'stars',
    (SELECT COUNT(*) FROM silver.stars),
    (SELECT COUNT(*) FROM gold.fact_stars),
    (SELECT COUNT(*) FROM silver.stars)
        - (SELECT COUNT(*) FROM gold.fact_stars)

UNION ALL

SELECT
    'forks',
    (SELECT COUNT(*) FROM silver.forks),
    (SELECT COUNT(*) FROM gold.fact_forks),
    (SELECT COUNT(*) FROM silver.forks)
        - (SELECT COUNT(*) FROM gold.fact_forks)

ORDER BY entity;



-- =============================================================================
-- SECTION 16: REPOSITORY PERFORMANCE VIEW VALIDATION
-- =============================================================================

-- Check that every Gold repository appears in the performance summary.
SELECT
    COUNT(*) AS repositories_missing_from_performance_summary
FROM gold.dim_repositories dr
LEFT JOIN gold.repository_performance_summary rps
    ON rps.repository_id = dr.repository_id
WHERE rps.repository_id IS NULL;


-- Check for duplicate repository rows
SELECT
    repository_id,
    COUNT(*) AS duplicate_count
FROM gold.repository_performance_summary
GROUP BY repository_id
HAVING COUNT(*) > 1;



-- =============================================================================
-- SECTION 17: DEVELOPER PRODUCTIVITY VIEW VALIDATION
-- =============================================================================

-- Every developer should appear once.
SELECT
    user_id,
    COUNT(*) AS duplicate_count
FROM gold.developer_productivity_summary
GROUP BY user_id
HAVING COUNT(*) > 1;


-- Every Gold user should appear in the productivity summary.
SELECT
    COUNT(*) AS users_missing_from_productivity_summary
FROM gold.dim_users du
LEFT JOIN gold.developer_productivity_summary dps
    ON dps.user_id = du.user_id
WHERE dps.user_id IS NULL;



-- =============================================================================
-- SECTION 18: REPOSITORY MONTHLY ACTIVITY VALIDATION
-- =============================================================================

-- No negative activity counts.
SELECT
    COUNT(*) AS invalid_monthly_activity
FROM gold.repository_monthly_activity
WHERE commit_count < 0
    OR pull_request_count < 0
    OR issue_count < 0
    OR release_count < 0
    OR star_count < 0;


-- One repository/month should appear only once.
SELECT
    repository_id,
    activity_month,
    COUNT(*) AS duplicate_count
FROM gold.repository_monthly_activity
GROUP BY repository_id, activity_month
HAVING COUNT(*) > 1;



-- =============================================================================
-- SECTION 19: DEVELOPER MONTHLY ACTIVITY VALIDATION
-- =============================================================================

SELECT
    COUNT(*) AS invalid_developer_monthly_activity
FROM gold.developer_monthly_activity
WHERE commit_count < 0;


SELECT
    user_id,
    activity_month,
    COUNT(*) AS duplicate_count
FROM gold.developer_monthly_activity
GROUP BY user_id, activity_month
HAVING COUNT(*) > 1;



-- =============================================================================
-- SECTION 20: PULL REQUEST EFFICIENCY VALIDATION
-- =============================================================================

SELECT
    COUNT(*) AS invalid_merge_rate
FROM gold.pull_request_efficiency_summary
WHERE merge_rate_pct < 0
    OR merge_rate_pct > 100;


SELECT
    COUNT(*) AS invalid_change_request_rate
FROM gold.pull_request_efficiency_summary
WHERE pct_reviews_requesting_changes < 0
    OR pct_reviews_requesting_changes > 100;


SELECT
    COUNT(*) AS invalid_repository_pr_summary
FROM gold.pull_request_efficiency_summary
WHERE total_pull_requests < 0
    OR merged_pull_requests < 0
    OR open_pull_requests < 0
    OR closed_pull_requests < 0;



-- =============================================================================
-- SECTION 21: ISSUE RESOLUTION VIEW VALIDATION
-- =============================================================================

SELECT
    COUNT(*) AS invalid_closure_rate
FROM gold.issue_resolution_summary
WHERE closure_rate_pct < 0
    OR closure_rate_pct > 100;


SELECT
    COUNT(*) AS invalid_unresolved_rate
FROM gold.issue_resolution_summary
WHERE unresolved_rate_pct < 0
    OR unresolved_rate_pct > 100;


-- Open + Closed should equal Total
SELECT
    COUNT(*) AS inconsistent_issue_totals
FROM gold.issue_resolution_summary
WHERE open_issues + closed_issues <> total_issues;



-- =============================================================================
-- SECTION 22: LANGUAGE ADOPTION VALIDATION
-- =============================================================================

SELECT
    COUNT(*) AS invalid_language_usage
FROM gold.language_adoption_summary
WHERE repositories_using < 0
    OR repositories_primary < 0
    OR total_commits < 0
    OR total_stars < 0;


-- Primary repositories cannot exceed repositories using the language.
SELECT
    COUNT(*) AS invalid_primary_language_counts
FROM gold.language_adoption_summary
WHERE repositories_primary > repositories_using;



-- =============================================================================
-- SECTION 23: ORGANIZATION SUMMARY VALIDATION
-- =============================================================================

SELECT
    COUNT(*) AS invalid_commits_per_member
FROM gold.organization_summary
WHERE commits_per_member < 0;


SELECT
    COUNT(*) AS invalid_organization_metrics
FROM gold.organization_summary
WHERE total_repositories < 0
    OR total_members < 0
    OR total_commits < 0
    OR total_stars < 0
    OR issues_resolved < 0
    OR total_releases < 0;



-- =============================================================================
-- SECTION 24: RELEASE ANALYTICS VIEW VALIDATION
-- =============================================================================

SELECT
    COUNT(*) AS invalid_release_summary
FROM gold.release_analytics_summary
WHERE total_releases < 0
    OR avg_days_between_releases < 0;


-- Latest release cannot be earlier than first release.
SELECT
    COUNT(*) AS invalid_release_dates
FROM gold.release_analytics_summary
WHERE latest_release_at < first_release_at;



-- =============================================================================
-- SECTION 25: DATA QUALITY VIEW VALIDATION
-- =============================================================================

-- Silver rows should not normally exceed Bronze rows.
SELECT
    COUNT(*) AS invalid_row_retention
FROM gold.data_quality_summary
WHERE silver_rows > bronze_rows;


-- Retention percentage should be between 0 and 100.
SELECT
    COUNT(*) AS invalid_retention_percentage
FROM gold.data_quality_summary
WHERE pct_rows_retained < 0
    OR pct_rows_retained > 100;


-- Duplicate rows removed should not be negative.
SELECT
    COUNT(*) AS invalid_duplicate_count
FROM gold.data_quality_summary
WHERE duplicate_rows_removed < 0;



-- =============================================================================
-- SECTION 26: EXECUTIVE SUMMARY VALIDATION
-- =============================================================================

-- Executive summary should contain exactly one row.
SELECT
    COUNT(*) AS executive_summary_rows
FROM gold.executive_summary;


-- All KPI counts should be non-negative.
SELECT
    COUNT(*) AS invalid_executive_kpis
FROM gold.executive_summary
WHERE total_developers < 0
    OR total_repositories < 0
    OR total_commits < 0
    OR total_pull_requests < 0
    OR total_pull_requests_merged < 0
    OR total_issues < 0
    OR total_issues_resolved < 0
    OR total_releases < 0
    OR total_stars < 0
    OR total_forks < 0
    OR total_organizations < 0;


-- Merged PRs cannot exceed total PRs.
SELECT
    COUNT(*) AS invalid_merged_pr_kpi
FROM gold.executive_summary
WHERE total_pull_requests_merged > total_pull_requests;


-- Resolved issues cannot exceed total issues.
SELECT
    COUNT(*) AS invalid_resolved_issue_kpi
FROM gold.executive_summary
WHERE total_issues_resolved > total_issues;


-- PR merge rate must be between 0 and 100.
SELECT
    COUNT(*) AS invalid_overall_pr_merge_rate
FROM gold.executive_summary
WHERE overall_pr_merge_rate_pct < 0
    OR overall_pr_merge_rate_pct > 100;


-- Issue closure rate must be between 0 and 100.
SELECT
    COUNT(*) AS invalid_overall_issue_closure_rate
FROM gold.executive_summary
WHERE overall_issue_closure_rate_pct < 0
    OR overall_issue_closure_rate_pct > 100;



-- =============================================================================
-- SECTION 27: GOLD KPI CROSS-CHECK
-- =============================================================================
-- Validate executive KPIs directly against Gold tables.


SELECT
    es.total_developers,
    (SELECT COUNT(*) FROM gold.dim_users) AS actual_developers
FROM gold.executive_summary es;


SELECT
    es.total_repositories,
    (SELECT COUNT(*) FROM gold.dim_repositories) AS actual_repositories
FROM gold.executive_summary es;


SELECT
    es.total_commits,
    (SELECT COUNT(*) FROM gold.fact_commits) AS actual_commits
FROM gold.executive_summary es;


SELECT
    es.total_pull_requests,
    (SELECT COUNT(*) FROM gold.fact_pull_requests) AS actual_pull_requests
FROM gold.executive_summary es;


SELECT
    es.total_issues,
    (SELECT COUNT(*) FROM gold.fact_issues) AS actual_issues
FROM gold.executive_summary es;


SELECT
    es.total_releases,
    (SELECT COUNT(*) FROM gold.fact_releases) AS actual_releases
FROM gold.executive_summary es;


SELECT
    es.total_stars,
    (SELECT COUNT(*) FROM gold.fact_stars) AS actual_stars
FROM gold.executive_summary es;


SELECT
    es.total_forks,
    (SELECT COUNT(*) FROM gold.fact_forks) AS actual_forks
FROM gold.executive_summary es;



-- =============================================================================
-- SECTION 28: GOLD LAYER FINAL VALIDATION SUMMARY
-- =============================================================================
-- This provides a compact high-level health check.


SELECT
    'Dimension Users' AS test_name,
    CASE
        WHEN COUNT(*) = 0 THEN 'PASS'
        ELSE 'CHECK'
    END AS result
FROM gold.dim_users
WHERE user_id IS NULL

UNION ALL

SELECT
    'Dimension Repositories',
    CASE
        WHEN COUNT(*) = 0 THEN 'PASS'
        ELSE 'CHECK'
    END
FROM gold.dim_repositories
WHERE repository_id IS NULL

UNION ALL

SELECT
    'Fact Commits',
    CASE
        WHEN COUNT(*) = 0 THEN 'PASS'
        ELSE 'CHECK'
    END
FROM gold.fact_commits
WHERE commit_id IS NULL

UNION ALL

SELECT
    'Fact Pull Requests',
    CASE
        WHEN COUNT(*) = 0 THEN 'PASS'
        ELSE 'CHECK'
    END
FROM gold.fact_pull_requests
WHERE pull_request_id IS NULL

UNION ALL

SELECT
    'Fact Issues',
    CASE
        WHEN COUNT(*) = 0 THEN 'PASS'
        ELSE 'CHECK'
    END
FROM gold.fact_issues
WHERE issue_id IS NULL

UNION ALL

SELECT
    'Fact Releases',
    CASE
        WHEN COUNT(*) = 0 THEN 'PASS'
        ELSE 'CHECK'
    END
FROM gold.fact_releases
WHERE release_id IS NULL

UNION ALL

SELECT
    'Fact Stars',
    CASE
        WHEN COUNT(*) = 0 THEN 'PASS'
        ELSE 'CHECK'
    END
FROM gold.fact_stars
WHERE star_id IS NULL

UNION ALL

SELECT
    'Fact Forks',
    CASE
        WHEN COUNT(*) = 0 THEN 'PASS'
        ELSE 'CHECK'
    END
FROM gold.fact_forks
WHERE fork_id IS NULL;
