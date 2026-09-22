-- =============================================================================
-- GitHub Analytics Database
-- Test Suite: Business Logic Validation
-- =============================================================================
-- Purpose:
--   Validate that the business metrics and analytical outputs produced by the
--   Gold layer follow the expected business rules and logical relationships.
--
-- Scope:
--   1. Repository metrics
--   2. Developer productivity
--   3. Pull request metrics
--   4. Issue metrics
--   5. Release metrics
--   6. Community engagement
--   7. Organization analytics
--   8. Programming language analytics
--   9. Executive KPIs
--
-- Expected Result:
--   Every test should return 0 failed records unless the underlying data
--   intentionally violates the business rule.
--
-- PostgreSQL
-- =============================================================================


-- =============================================================================
-- SECTION 1: REPOSITORY BUSINESS LOGIC
-- =============================================================================


-- -----------------------------------------------------------------------------
-- Test 1: Total commits cannot be negative
-- -----------------------------------------------------------------------------

SELECT
    COUNT(*) AS failed_records
FROM gold.repository_performance_summary
WHERE total_commits < 0;


-- -----------------------------------------------------------------------------
-- Test 2: Total contributors cannot be negative
-- -----------------------------------------------------------------------------

SELECT
    COUNT(*) AS failed_records
FROM gold.repository_performance_summary
WHERE total_contributors < 0;


-- -----------------------------------------------------------------------------
-- Test 3: Pull request status totals should reconcile
-- Total PRs = Open + Merged + Closed
-- -----------------------------------------------------------------------------

SELECT
    COUNT(*) AS failed_records
FROM gold.repository_performance_summary
WHERE total_pull_requests <>
    (
        open_pull_requests
        + merged_pull_requests
        + closed_pull_requests
    );


-- -----------------------------------------------------------------------------
-- Test 4: Issue status totals should reconcile
-- Total Issues = Open + Closed
-- -----------------------------------------------------------------------------

SELECT
    COUNT(*) AS failed_records
FROM gold.repository_performance_summary
WHERE total_issues <>
    (
        open_issues
        + closed_issues
    );


-- -----------------------------------------------------------------------------
-- Test 5: Repository stars cannot be negative
-- -----------------------------------------------------------------------------

SELECT
    COUNT(*) AS failed_records
FROM gold.repository_performance_summary
WHERE total_stars < 0;


-- -----------------------------------------------------------------------------
-- Test 6: Repository forks cannot be negative
-- -----------------------------------------------------------------------------

SELECT
    COUNT(*) AS failed_records
FROM gold.repository_performance_summary
WHERE total_forks < 0;


-- -----------------------------------------------------------------------------
-- Test 7: Days since last commit cannot be negative
-- A future commit should not exist relative to CURRENT_DATE.
-- -----------------------------------------------------------------------------

SELECT
    COUNT(*) AS failed_records
FROM gold.repository_performance_summary
WHERE days_since_last_commit < 0;


-- =============================================================================
-- SECTION 2: DEVELOPER PRODUCTIVITY BUSINESS LOGIC
-- =============================================================================


-- -----------------------------------------------------------------------------
-- Test 8: Developer commits cannot be negative
-- -----------------------------------------------------------------------------

SELECT
    COUNT(*) AS failed_records
FROM gold.developer_productivity_summary
WHERE commits_authored < 0;


-- -----------------------------------------------------------------------------
-- Test 9: Pull requests opened cannot be negative
-- -----------------------------------------------------------------------------

SELECT
    COUNT(*) AS failed_records
FROM gold.developer_productivity_summary
WHERE pull_requests_opened < 0;


-- -----------------------------------------------------------------------------
-- Test 10: Merged PRs cannot exceed opened PRs
-- -----------------------------------------------------------------------------

SELECT
    COUNT(*) AS failed_records
FROM gold.developer_productivity_summary
WHERE pull_requests_merged > pull_requests_opened;


-- -----------------------------------------------------------------------------
-- Test 11: Reviewed PRs cannot be negative
-- -----------------------------------------------------------------------------

SELECT
    COUNT(*) AS failed_records
FROM gold.developer_productivity_summary
WHERE pull_requests_reviewed < 0;


-- -----------------------------------------------------------------------------
-- Test 12: Approved reviews cannot exceed total reviews
-- -----------------------------------------------------------------------------

SELECT
    COUNT(*) AS failed_records
FROM gold.developer_productivity_summary
WHERE pull_requests_approved > pull_requests_reviewed;


-- -----------------------------------------------------------------------------
-- Test 13: Repositories contributed to cannot be negative
-- -----------------------------------------------------------------------------

SELECT
    COUNT(*) AS failed_records
FROM gold.developer_productivity_summary
WHERE repos_contributed_to < 0;


-- -----------------------------------------------------------------------------
-- Test 14: Repository ownership count cannot be negative
-- -----------------------------------------------------------------------------

SELECT
    COUNT(*) AS failed_records
FROM gold.developer_productivity_summary
WHERE repos_owned < 0;


-- =============================================================================
-- SECTION 3: PULL REQUEST BUSINESS LOGIC
-- =============================================================================


-- -----------------------------------------------------------------------------
-- Test 15: Merged PR must have a merge timestamp
-- -----------------------------------------------------------------------------

SELECT
    COUNT(*) AS failed_records
FROM gold.fact_pull_requests
WHERE status = 'Merged'
    AND merged_at IS NULL;


-- -----------------------------------------------------------------------------
-- Test 16: Open PR should not have a merge timestamp
-- -----------------------------------------------------------------------------

SELECT
    COUNT(*) AS failed_records
FROM gold.fact_pull_requests
WHERE status = 'Open'
    AND merged_at IS NOT NULL;


-- -----------------------------------------------------------------------------
-- Test 17: Merge timestamp cannot be earlier than PR creation
-- -----------------------------------------------------------------------------

SELECT
    COUNT(*) AS failed_records
FROM gold.fact_pull_requests
WHERE merged_at IS NOT NULL
    AND merged_at < created_at;


-- -----------------------------------------------------------------------------
-- Test 18: Pull request files changed cannot be negative
-- -----------------------------------------------------------------------------

SELECT
    COUNT(*) AS failed_records
FROM gold.fact_pull_requests
WHERE files_changed < 0;


-- -----------------------------------------------------------------------------
-- Test 19: Merge rate must be between 0 and 100
-- -----------------------------------------------------------------------------

SELECT
    COUNT(*) AS failed_records
FROM gold.pull_request_efficiency_summary
WHERE merge_rate_pct < 0
    OR merge_rate_pct > 100;


-- -----------------------------------------------------------------------------
-- Test 20: Average PR merge time cannot be negative
-- -----------------------------------------------------------------------------

SELECT
    COUNT(*) AS failed_records
FROM gold.pull_request_efficiency_summary
WHERE avg_hours_to_merge < 0;


-- =============================================================================
-- SECTION 4: ISSUE BUSINESS LOGIC
-- =============================================================================


-- -----------------------------------------------------------------------------
-- Test 21: Closed issue must have a closed timestamp
-- -----------------------------------------------------------------------------

SELECT
    COUNT(*) AS failed_records
FROM gold.fact_issues
WHERE status = 'Closed'
    AND closed_at IS NULL;


-- -----------------------------------------------------------------------------
-- Test 22: Open issue should not have a closed timestamp
-- -----------------------------------------------------------------------------

SELECT
    COUNT(*) AS failed_records
FROM gold.fact_issues
WHERE status = 'Open'
    AND closed_at IS NOT NULL;


-- -----------------------------------------------------------------------------
-- Test 23: Issue closed timestamp cannot be earlier than creation
-- -----------------------------------------------------------------------------

SELECT
    COUNT(*) AS failed_records
FROM gold.fact_issues
WHERE closed_at IS NOT NULL
    AND closed_at < created_at;


-- -----------------------------------------------------------------------------
-- Test 24: Issue resolution time cannot be negative
-- -----------------------------------------------------------------------------

SELECT
    COUNT(*) AS failed_records
FROM gold.fact_issues
WHERE hours_to_resolve < 0;


-- -----------------------------------------------------------------------------
-- Test 25: Issue closure rate must be between 0 and 100
-- -----------------------------------------------------------------------------

SELECT
    COUNT(*) AS failed_records
FROM gold.issue_resolution_summary
WHERE closure_rate_pct < 0
    OR closure_rate_pct > 100;


-- -----------------------------------------------------------------------------
-- Test 26: Unresolved rate must be between 0 and 100
-- -----------------------------------------------------------------------------

SELECT
    COUNT(*) AS failed_records
FROM gold.issue_resolution_summary
WHERE unresolved_rate_pct < 0
    OR unresolved_rate_pct > 100;


-- -----------------------------------------------------------------------------
-- Test 27: Closure rate + unresolved rate should equal 100%
-- -----------------------------------------------------------------------------

SELECT
    COUNT(*) AS failed_records
FROM gold.issue_resolution_summary
WHERE total_issues > 0
    AND ROUND(
        closure_rate_pct + unresolved_rate_pct,
        2
        ) <> 100.00;


-- =============================================================================
-- SECTION 5: RELEASE BUSINESS LOGIC
-- =============================================================================


-- -----------------------------------------------------------------------------
-- Test 28: Release publication date cannot be in the future
-- -----------------------------------------------------------------------------

SELECT
    COUNT(*) AS failed_records
FROM gold.fact_releases
WHERE published_at > CURRENT_TIMESTAMP;


-- -----------------------------------------------------------------------------
-- Test 29: Days since previous release cannot be negative
-- -----------------------------------------------------------------------------

SELECT
    COUNT(*) AS failed_records
FROM gold.fact_releases
WHERE days_since_previous_release < 0;


-- -----------------------------------------------------------------------------
-- Test 30: Release interval must be positive
-- -----------------------------------------------------------------------------

SELECT
    COUNT(*) AS failed_records
FROM gold.fact_releases
WHERE days_since_previous_release IS NOT NULL
    AND days_since_previous_release <= 0;


-- -----------------------------------------------------------------------------
-- Test 31: Release analytics average interval cannot be negative
-- -----------------------------------------------------------------------------

SELECT
    COUNT(*) AS failed_records
FROM gold.release_analytics_summary
WHERE avg_days_between_releases < 0;


-- =============================================================================
-- SECTION 6: COMMUNITY ENGAGEMENT BUSINESS LOGIC
-- =============================================================================


-- -----------------------------------------------------------------------------
-- Test 32: Stars cannot have future timestamps
-- -----------------------------------------------------------------------------

SELECT
    COUNT(*) AS failed_records
FROM gold.fact_stars
WHERE starred_at > CURRENT_TIMESTAMP;


-- -----------------------------------------------------------------------------
-- Test 33: Fork timestamps cannot be in the future
-- -----------------------------------------------------------------------------

SELECT
    COUNT(*) AS failed_records
FROM gold.fact_forks
WHERE forked_at > CURRENT_TIMESTAMP;


-- -----------------------------------------------------------------------------
-- Test 34: Stars cannot be negative
-- -----------------------------------------------------------------------------

SELECT
    COUNT(*) AS failed_records
FROM gold.repository_performance_summary
WHERE total_stars < 0;


-- -----------------------------------------------------------------------------
-- Test 35: Forks cannot be negative
-- -----------------------------------------------------------------------------

SELECT
    COUNT(*) AS failed_records
FROM gold.repository_performance_summary
WHERE total_forks < 0;


-- -----------------------------------------------------------------------------
-- Test 36: Community engagement counts cannot be negative
-- -----------------------------------------------------------------------------

SELECT
    COUNT(*) AS failed_records
FROM gold.organization_summary
WHERE total_stars < 0
    OR total_releases < 0
    OR total_commits < 0
    OR issues_resolved < 0;


-- =============================================================================
-- SECTION 7: ORGANIZATION BUSINESS LOGIC
-- =============================================================================


-- -----------------------------------------------------------------------------
-- Test 37: Organization repository count cannot be negative
-- -----------------------------------------------------------------------------

SELECT
    COUNT(*) AS failed_records
FROM gold.organization_summary
WHERE total_repositories < 0;


-- -----------------------------------------------------------------------------
-- Test 38: Organization member count cannot be negative
-- -----------------------------------------------------------------------------

SELECT
    COUNT(*) AS failed_records
FROM gold.organization_summary
WHERE total_members < 0;


-- -----------------------------------------------------------------------------
-- Test 39: Commits per member cannot be negative
-- -----------------------------------------------------------------------------

SELECT
    COUNT(*) AS failed_records
FROM gold.organization_summary
WHERE commits_per_member < 0;


-- -----------------------------------------------------------------------------
-- Test 40: Commits per member should be zero when organization has no members
-- -----------------------------------------------------------------------------

SELECT
    COUNT(*) AS failed_records
FROM gold.organization_summary
WHERE total_members = 0
    AND commits_per_member <> 0;


-- =============================================================================
-- SECTION 8: PROGRAMMING LANGUAGE BUSINESS LOGIC
-- =============================================================================


-- -----------------------------------------------------------------------------
-- Test 41: Language usage percentage must be between 0 and 100
-- -----------------------------------------------------------------------------

SELECT
    COUNT(*) AS failed_records
FROM gold.fact_repository_languages
WHERE percentage_used < 0
    OR percentage_used > 100;


-- -----------------------------------------------------------------------------
-- Test 42: Repository language percentages should not exceed 100%
-- -----------------------------------------------------------------------------

SELECT
    repository_id,
    SUM(percentage_used) AS total_language_percentage
FROM gold.fact_repository_languages
GROUP BY repository_id
HAVING SUM(percentage_used) > 100.01;


-- -----------------------------------------------------------------------------
-- Test 43: Language repository counts cannot be negative
-- -----------------------------------------------------------------------------

SELECT
    COUNT(*) AS failed_records
FROM gold.language_adoption_summary
WHERE repositories_using < 0
    OR repositories_primary < 0;


-- -----------------------------------------------------------------------------
-- Test 44: Language commit counts cannot be negative
-- -----------------------------------------------------------------------------

SELECT
    COUNT(*) AS failed_records
FROM gold.language_adoption_summary
WHERE total_commits < 0;


-- -----------------------------------------------------------------------------
-- Test 45: Language star counts cannot be negative
-- -----------------------------------------------------------------------------

SELECT
    COUNT(*) AS failed_records
FROM gold.language_adoption_summary
WHERE total_stars < 0;


-- =============================================================================
-- SECTION 9: MONTHLY ACTIVITY BUSINESS LOGIC
-- =============================================================================


-- -----------------------------------------------------------------------------
-- Test 46: Monthly repository activity counts cannot be negative
-- -----------------------------------------------------------------------------

SELECT
    COUNT(*) AS failed_records
FROM gold.repository_monthly_activity
WHERE commit_count < 0
    OR pull_request_count < 0
    OR issue_count < 0
    OR release_count < 0
    OR star_count < 0;


-- -----------------------------------------------------------------------------
-- Test 47: Monthly developer commit counts cannot be negative
-- -----------------------------------------------------------------------------

SELECT
    COUNT(*) AS failed_records
FROM gold.developer_monthly_activity
WHERE commit_count < 0;


-- -----------------------------------------------------------------------------
-- Test 48: Activity month must not be in the future
-- -----------------------------------------------------------------------------

SELECT
    COUNT(*) AS failed_records
FROM gold.repository_monthly_activity
WHERE activity_month > CURRENT_DATE;


-- =============================================================================
-- SECTION 10: EXECUTIVE KPI VALIDATION
-- =============================================================================


-- -----------------------------------------------------------------------------
-- Test 49: Executive summary totals must match Gold tables
-- -----------------------------------------------------------------------------

SELECT
    CASE
        WHEN es.total_developers =
            (SELECT COUNT(*) FROM gold.dim_users)
        THEN 0
        ELSE 1
    END AS developer_count_failure,

    CASE
        WHEN es.total_repositories =
            (SELECT COUNT(*) FROM gold.dim_repositories)
        THEN 0
        ELSE 1
    END AS repository_count_failure,

    CASE
        WHEN es.total_commits =
            (SELECT COUNT(*) FROM gold.fact_commits)
        THEN 0
        ELSE 1
    END AS commit_count_failure,

    CASE
        WHEN es.total_pull_requests =
            (SELECT COUNT(*) FROM gold.fact_pull_requests)
        THEN 0
        ELSE 1
    END AS pull_request_count_failure,

    CASE
        WHEN es.total_issues =
            (SELECT COUNT(*) FROM gold.fact_issues)
        THEN 0
        ELSE 1
    END AS issue_count_failure,

    CASE
        WHEN es.total_releases =
            (SELECT COUNT(*) FROM gold.fact_releases)
        THEN 0
        ELSE 1
    END AS release_count_failure,

    CASE
        WHEN es.total_stars =
            (SELECT COUNT(*) FROM gold.fact_stars)
        THEN 0
        ELSE 1
    END AS star_count_failure,

    CASE
        WHEN es.total_forks =
            (SELECT COUNT(*) FROM gold.fact_forks)
        THEN 0
        ELSE 1
    END AS fork_count_failure,

    CASE
        WHEN es.total_organizations =
            (SELECT COUNT(*) FROM gold.dim_organizations)
        THEN 0
        ELSE 1
    END AS organization_count_failure

FROM gold.executive_summary es;


-- =============================================================================
-- SECTION 11: EXECUTIVE KPI RANGE VALIDATION
-- =============================================================================


-- -----------------------------------------------------------------------------
-- Test 50: Executive PR merge rate must be between 0 and 100
-- -----------------------------------------------------------------------------

SELECT
    COUNT(*) AS failed_records
FROM gold.executive_summary
WHERE overall_pr_merge_rate_pct < 0
    OR overall_pr_merge_rate_pct > 100;


-- -----------------------------------------------------------------------------
-- Test 51: Executive issue closure rate must be between 0 and 100
-- -----------------------------------------------------------------------------

SELECT
    COUNT(*) AS failed_records
FROM gold.executive_summary
WHERE overall_issue_closure_rate_pct < 0
    OR overall_issue_closure_rate_pct > 100;


-- -----------------------------------------------------------------------------
-- Test 52: Average commits per active developer cannot be negative
-- -----------------------------------------------------------------------------

SELECT
    COUNT(*) AS failed_records
FROM gold.executive_summary
WHERE avg_commits_per_active_developer < 0;


-- =============================================================================
-- SECTION 12: CROSS-METRIC BUSINESS VALIDATION
-- =============================================================================


-- -----------------------------------------------------------------------------
-- Test 53: Repository performance metrics must agree with fact tables
-- -----------------------------------------------------------------------------

SELECT
    r.repository_id,
    r.total_commits AS summary_commits,
    COUNT(c.commit_id) AS fact_commits
FROM gold.repository_performance_summary r
LEFT JOIN gold.fact_commits c
    ON c.repository_id = r.repository_id
GROUP BY
    r.repository_id,
    r.total_commits
HAVING r.total_commits <> COUNT(c.commit_id);


-- -----------------------------------------------------------------------------
-- Test 54: Repository PR metrics must agree with fact table
-- -----------------------------------------------------------------------------

SELECT
    r.repository_id,
    r.total_pull_requests AS summary_prs,
    COUNT(pr.pull_request_id) AS fact_prs
FROM gold.repository_performance_summary r
LEFT JOIN gold.fact_pull_requests pr
    ON pr.repository_id = r.repository_id
GROUP BY
    r.repository_id,
    r.total_pull_requests
HAVING r.total_pull_requests <> COUNT(pr.pull_request_id);


-- -----------------------------------------------------------------------------
-- Test 55: Repository issue metrics must agree with fact table
-- -----------------------------------------------------------------------------

SELECT
    r.repository_id,
    r.total_issues AS summary_issues,
    COUNT(i.issue_id) AS fact_issues
FROM gold.repository_performance_summary r
LEFT JOIN gold.fact_issues i
    ON i.repository_id = r.repository_id
GROUP BY
    r.repository_id,
    r.total_issues
HAVING r.total_issues <> COUNT(i.issue_id);


-- -----------------------------------------------------------------------------
-- Test 56: Repository release metrics must agree with fact table
-- -----------------------------------------------------------------------------

SELECT
    r.repository_id,
    r.total_releases AS summary_releases,
    COUNT(rel.release_id) AS fact_releases
FROM gold.repository_performance_summary r
LEFT JOIN gold.fact_releases rel
    ON rel.repository_id = r.repository_id
GROUP BY
    r.repository_id,
    r.total_releases
HAVING r.total_releases <> COUNT(rel.release_id);


-- -----------------------------------------------------------------------------
-- Test 57: Repository star metrics must agree with fact table
-- -----------------------------------------------------------------------------

SELECT
    r.repository_id,
    r.total_stars AS summary_stars,
    COUNT(s.star_id) AS fact_stars
FROM gold.repository_performance_summary r
LEFT JOIN gold.fact_stars s
    ON s.repository_id = r.repository_id
GROUP BY
    r.repository_id,
    r.total_stars
HAVING r.total_stars <> COUNT(s.star_id);


-- -----------------------------------------------------------------------------
-- Test 58: Repository contributor metrics must agree with fact table
-- -----------------------------------------------------------------------------

SELECT
    r.repository_id,
    r.total_contributors AS summary_contributors,
    COUNT(rc.contributor_id) AS fact_contributors
FROM gold.repository_performance_summary r
LEFT JOIN gold.fact_repository_contributors rc
    ON rc.repository_id = r.repository_id
GROUP BY
    r.repository_id,
    r.total_contributors
HAVING r.total_contributors <> COUNT(rc.contributor_id);


-- =============================================================================
-- SECTION 13: BUSINESS LOGIC TEST SUMMARY
-- =============================================================================
-- This final query gives a simple overall status for the business logic test
-- suite. It does not replace the individual tests above; it provides a quick
-- health indicator after all tests have been executed.
-- =============================================================================

WITH test_results AS (

    SELECT
        'Repository PR status reconciliation' AS test_name,
        COUNT(*) AS failed_records
    FROM gold.repository_performance_summary
    WHERE total_pull_requests <>
        open_pull_requests
        + merged_pull_requests
        + closed_pull_requests

    UNION ALL

    SELECT
        'Repository issue status reconciliation',
        COUNT(*)
    FROM gold.repository_performance_summary
    WHERE total_issues <>
        open_issues
        + closed_issues

    UNION ALL

    SELECT
        'Merged PR requires merge timestamp',
        COUNT(*)
    FROM gold.fact_pull_requests
    WHERE status = 'Merged'
        AND merged_at IS NULL

    UNION ALL

    SELECT
        'Closed issue requires close timestamp',
        COUNT(*)
    FROM gold.fact_issues
    WHERE status = 'Closed'
        AND closed_at IS NULL

    UNION ALL

    SELECT
        'Executive repository count',
        COUNT(*)
    FROM gold.executive_summary
    WHERE total_repositories <>
        (SELECT COUNT(*) FROM gold.dim_repositories)

    UNION ALL

    SELECT
        'Executive commit count',
        COUNT(*)
    FROM gold.executive_summary
    WHERE total_commits <>
        (SELECT COUNT(*) FROM gold.fact_commits)

)

SELECT
    test_name,
    failed_records,
    CASE
        WHEN failed_records = 0 THEN 'PASS'
        ELSE 'FAIL'
    END AS test_status
FROM test_results
ORDER BY
    CASE
        WHEN failed_records > 0 THEN 0
        ELSE 1
    END,
    test_name;
