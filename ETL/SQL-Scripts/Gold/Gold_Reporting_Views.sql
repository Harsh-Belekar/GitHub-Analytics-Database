-- =============================================================================
-- GitHub Analytics Database — Gold Layer: Reporting Views (PostgreSQL)
-- =============================================================================
-- These views now sit ON TOP of the physical gold.dim_*/gold.fact_* tables
-- (populated by gold.load_gold()) rather than querying silver.* directly —
-- a proper layered dependency: Silver -> Gold tables -> Gold views. The one
-- deliberate exception is the data-quality section, which still compares
-- bronze.* to silver.* directly, since that comparison is the whole point.

-- Prerequisite: Gold_Dimensions_Facts.sql + Load_Gold.sql, and
-- CALL gold.load_gold(); must have been run at least once.
-- =============================================================================


-- gold.repository_performance_summary
CREATE OR REPLACE VIEW gold.repository_performance_summary AS
SELECT
    dr.repository_id,
    dr.repository_name,
    dr.owner_username,
    dr.organization_name,
    dr.primary_language_name AS primary_language,
    dr.visibility,
    dr.created_at AS repository_created_at,
    COALESCE(c.total_commits, 0) AS total_commits,
    COALESCE(c.commits_last_30_days, 0) AS commits_last_30_days,
    c.last_commit_date,
    (CURRENT_DATE - c.last_commit_date::DATE) AS days_since_last_commit,
    COALESCE(ct.total_contributors, 0) AS total_contributors,
    COALESCE(pr.total_pull_requests, 0) AS total_pull_requests,
    COALESCE(pr.open_pull_requests, 0) AS open_pull_requests,
    COALESCE(pr.merged_pull_requests, 0) AS merged_pull_requests,
    COALESCE(pr.closed_pull_requests, 0) AS closed_pull_requests,
    COALESCE(i.total_issues, 0) AS total_issues,
    COALESCE(i.open_issues, 0) AS open_issues,
    COALESCE(i.closed_issues, 0) AS closed_issues,
    COALESCE(rel.total_releases, 0) AS total_releases,
    COALESCE(s.total_stars, 0) AS total_stars,
    COALESCE(f.total_forks, 0) AS total_forks
FROM gold.dim_repositories dr
LEFT JOIN (
    SELECT repository_id, COUNT(*) AS total_commits,
            MAX(commit_timestamp) AS last_commit_date,
            COUNT(*) FILTER (WHERE commit_timestamp >= CURRENT_DATE - INTERVAL '30 days') AS commits_last_30_days
    FROM gold.fact_commits GROUP BY repository_id
) c ON c.repository_id = dr.repository_id
LEFT JOIN (
    SELECT repository_id, COUNT(*) AS total_contributors
    FROM gold.fact_repository_contributors GROUP BY repository_id
) ct ON ct.repository_id = dr.repository_id
LEFT JOIN (
    SELECT repository_id,
            COUNT(*) AS total_pull_requests,
            COUNT(*) FILTER (WHERE status = 'Open') AS open_pull_requests,
            COUNT(*) FILTER (WHERE status = 'Merged') AS merged_pull_requests,
            COUNT(*) FILTER (WHERE status = 'Closed') AS closed_pull_requests
    FROM gold.fact_pull_requests GROUP BY repository_id
) pr ON pr.repository_id = dr.repository_id
LEFT JOIN (
    SELECT repository_id,
            COUNT(*) AS total_issues,
            COUNT(*) FILTER (WHERE status = 'Open') AS open_issues,
            COUNT(*) FILTER (WHERE status = 'Closed') AS closed_issues
    FROM gold.fact_issues GROUP BY repository_id
) i ON i.repository_id = dr.repository_id
LEFT JOIN (
    SELECT repository_id, COUNT(*) AS total_releases FROM gold.fact_releases GROUP BY repository_id
) rel ON rel.repository_id = dr.repository_id
LEFT JOIN (
    SELECT repository_id, COUNT(*) AS total_stars FROM gold.fact_stars GROUP BY repository_id
) s ON s.repository_id = dr.repository_id
LEFT JOIN (
    SELECT source_repository_id AS repository_id, COUNT(*) AS total_forks
    FROM gold.fact_forks GROUP BY source_repository_id
) f ON f.repository_id = dr.repository_id;


-- gold.developer_productivity_summary
CREATE OR REPLACE VIEW gold.developer_productivity_summary AS
SELECT
    du.user_id,
    du.username,
    du.full_name,
    du.followers,
    du.country,
    COALESCE(own.repos_owned, 0) AS repos_owned,
    COALESCE(contrib.repos_contributed_to, 0) AS repos_contributed_to,
    COALESCE(cm.commits_authored, 0) AS commits_authored,
    COALESCE(prc.pull_requests_opened, 0) AS pull_requests_opened,
    COALESCE(prc.pull_requests_merged, 0) AS pull_requests_merged,
    COALESCE(rv.pull_requests_reviewed, 0) AS pull_requests_reviewed,
    COALESCE(rv.pull_requests_approved, 0) AS pull_requests_approved,
    COALESCE(iss.issues_resolved, 0) AS issues_resolved
FROM gold.dim_users du
LEFT JOIN (
    SELECT owner_id, COUNT(*) AS repos_owned FROM gold.dim_repositories GROUP BY owner_id
) own ON own.owner_id = du.user_id
LEFT JOIN (
    SELECT user_id, COUNT(DISTINCT repository_id) AS repos_contributed_to
    FROM gold.fact_repository_contributors GROUP BY user_id
) contrib ON contrib.user_id = du.user_id
LEFT JOIN (
    SELECT user_id, COUNT(*) AS commits_authored FROM gold.fact_commits GROUP BY user_id
) cm ON cm.user_id = du.user_id
LEFT JOIN (
    SELECT author_id,
            COUNT(*) AS pull_requests_opened,
            COUNT(*) FILTER (WHERE status = 'Merged') AS pull_requests_merged
    FROM gold.fact_pull_requests GROUP BY author_id
) prc ON prc.author_id = du.user_id
LEFT JOIN (
    SELECT reviewer_id,
            COUNT(*) AS pull_requests_reviewed,
            COUNT(*) FILTER (WHERE review_state = 'Approved') AS pull_requests_approved
    FROM gold.fact_pull_request_reviews GROUP BY reviewer_id
) rv ON rv.reviewer_id = du.user_id
LEFT JOIN (
    SELECT user_id, COUNT(*) AS issues_resolved
    FROM gold.fact_issues WHERE status = 'Closed' GROUP BY user_id
) iss ON iss.user_id = du.user_id;


-- gold.repository_monthly_activity
CREATE OR REPLACE VIEW gold.repository_monthly_activity AS
WITH months AS (
    SELECT DISTINCT repository_id, DATE_TRUNC('month', commit_timestamp)::DATE AS activity_month FROM gold.fact_commits
    UNION
    SELECT DISTINCT repository_id, DATE_TRUNC('month', created_at)::DATE FROM gold.fact_pull_requests
    UNION
    SELECT DISTINCT repository_id, DATE_TRUNC('month', created_at)::DATE FROM gold.fact_issues
    UNION
    SELECT DISTINCT repository_id, DATE_TRUNC('month', published_at)::DATE FROM gold.fact_releases
    UNION
    SELECT DISTINCT repository_id, DATE_TRUNC('month', starred_at)::DATE FROM gold.fact_stars
),
commit_counts AS (
    SELECT repository_id, DATE_TRUNC('month', commit_timestamp)::DATE AS activity_month, COUNT(*) AS commit_count
    FROM gold.fact_commits GROUP BY 1, 2
),
pr_counts AS (
    SELECT repository_id, DATE_TRUNC('month', created_at)::DATE AS activity_month, COUNT(*) AS pull_request_count
    FROM gold.fact_pull_requests GROUP BY 1, 2
),
issue_counts AS (
    SELECT repository_id, DATE_TRUNC('month', created_at)::DATE AS activity_month, COUNT(*) AS issue_count
    FROM gold.fact_issues GROUP BY 1, 2
),
release_counts AS (
    SELECT repository_id, DATE_TRUNC('month', published_at)::DATE AS activity_month, COUNT(*) AS release_count
    FROM gold.fact_releases GROUP BY 1, 2
),
star_counts AS (
    SELECT repository_id, DATE_TRUNC('month', starred_at)::DATE AS activity_month, COUNT(*) AS star_count
    FROM gold.fact_stars GROUP BY 1, 2
)
SELECT
    m.repository_id,
    dr.repository_name,
    m.activity_month,
    EXTRACT(YEAR FROM m.activity_month)::INT AS activity_year,
    TRIM(TO_CHAR(m.activity_month, 'Month')) AS month_name,
    COALESCE(cc.commit_count, 0) AS commit_count,
    COALESCE(pc.pull_request_count, 0) AS pull_request_count,
    COALESCE(ic.issue_count, 0) AS issue_count,
    COALESCE(rc.release_count, 0) AS release_count,
    COALESCE(sc.star_count, 0) AS star_count
FROM months m
JOIN gold.dim_repositories dr ON dr.repository_id = m.repository_id
LEFT JOIN commit_counts cc ON cc.repository_id = m.repository_id AND cc.activity_month = m.activity_month
LEFT JOIN pr_counts pc ON pc.repository_id = m.repository_id AND pc.activity_month = m.activity_month
LEFT JOIN issue_counts ic ON ic.repository_id = m.repository_id AND ic.activity_month = m.activity_month
LEFT JOIN release_counts rc ON rc.repository_id = m.repository_id AND rc.activity_month = m.activity_month
LEFT JOIN star_counts sc ON sc.repository_id = m.repository_id AND sc.activity_month = m.activity_month;


-- gold.developer_monthly_activity
CREATE OR REPLACE VIEW gold.developer_monthly_activity AS
SELECT
    c.user_id,
    du.username,
    DATE_TRUNC('month', c.commit_timestamp)::DATE AS activity_month,
    COUNT(*) AS commit_count
FROM gold.fact_commits c
JOIN gold.dim_users du ON du.user_id = c.user_id
GROUP BY c.user_id, du.username, DATE_TRUNC('month', c.commit_timestamp)::DATE;


-- gold.organization_summary
CREATE OR REPLACE VIEW gold.organization_summary AS
SELECT
    do_.organization_id,
    do_.organization_name,
    do_.organization_type,
    do_.industry,
    do_.total_repositories,
    do_.total_members,
    COALESCE(cm.total_commits, 0) AS total_commits,
    COALESCE(s.total_stars, 0) AS total_stars,
    COALESCE(iss.issues_resolved, 0) AS issues_resolved,
    COALESCE(rel.total_releases, 0) AS total_releases,
    CASE WHEN do_.total_members > 0
        THEN ROUND(COALESCE(cm.total_commits, 0)::NUMERIC / do_.total_members, 2)
        ELSE 0 END AS commits_per_member
FROM gold.dim_organizations do_
LEFT JOIN (
    SELECT dr.organization_id, COUNT(*) AS total_commits
    FROM gold.fact_commits c JOIN gold.dim_repositories dr ON dr.repository_id = c.repository_id
    WHERE dr.organization_id IS NOT NULL GROUP BY dr.organization_id
) cm ON cm.organization_id = do_.organization_id
LEFT JOIN (
    SELECT dr.organization_id, COUNT(*) AS total_stars
    FROM gold.fact_stars st JOIN gold.dim_repositories dr ON dr.repository_id = st.repository_id
    WHERE dr.organization_id IS NOT NULL GROUP BY dr.organization_id
) s ON s.organization_id = do_.organization_id
LEFT JOIN (
    SELECT dr.organization_id, COUNT(*) AS issues_resolved
    FROM gold.fact_issues i JOIN gold.dim_repositories dr ON dr.repository_id = i.repository_id
    WHERE dr.organization_id IS NOT NULL AND i.status = 'Closed' GROUP BY dr.organization_id
) iss ON iss.organization_id = do_.organization_id
LEFT JOIN (
    SELECT dr.organization_id, COUNT(*) AS total_releases
    FROM gold.fact_releases rl JOIN gold.dim_repositories dr ON dr.repository_id = rl.repository_id
    WHERE dr.organization_id IS NOT NULL GROUP BY dr.organization_id
) rel ON rel.organization_id = do_.organization_id;


-- gold.language_adoption_summary
CREATE OR REPLACE VIEW gold.language_adoption_summary AS
SELECT
    dl.language_id,
    dl.language_name,
    dl.language_type,
    dl.is_popular,
    COUNT(DISTINCT frl.repository_id) AS repositories_using,
    COUNT(DISTINCT CASE WHEN dr.primary_language_id = dl.language_id THEN dr.repository_id END) AS repositories_primary,
    COALESCE(cm.total_commits, 0) AS total_commits,
    COALESCE(st.total_stars, 0) AS total_stars
FROM gold.dim_languages dl
LEFT JOIN gold.fact_repository_languages frl ON frl.language_id = dl.language_id
LEFT JOIN gold.dim_repositories dr ON dr.repository_id = frl.repository_id
LEFT JOIN (
    SELECT dr2.primary_language_id AS language_id, COUNT(*) AS total_commits
    FROM gold.fact_commits c JOIN gold.dim_repositories dr2 ON dr2.repository_id = c.repository_id
    GROUP BY dr2.primary_language_id
) cm ON cm.language_id = dl.language_id
LEFT JOIN (
    SELECT dr3.primary_language_id AS language_id, COUNT(*) AS total_stars
    FROM gold.fact_stars s JOIN gold.dim_repositories dr3 ON dr3.repository_id = s.repository_id
    GROUP BY dr3.primary_language_id
) st ON st.language_id = dl.language_id
GROUP BY dl.language_id, dl.language_name, dl.language_type, dl.is_popular, cm.total_commits, st.total_stars;


-- gold.pull_request_efficiency_summary
CREATE OR REPLACE VIEW gold.pull_request_efficiency_summary AS
WITH review_stats AS (
    SELECT
        pull_request_id,
        MIN(reviewed_at) AS first_review_at,
        COUNT(*) FILTER (WHERE review_state = 'Changes Requested') AS changes_requested_count,
        COUNT(*) AS review_count
    FROM gold.fact_pull_request_reviews
    GROUP BY pull_request_id
)
SELECT
    dr.repository_id,
    dr.repository_name,
    COUNT(pb.pull_request_id) AS total_pull_requests,
    COUNT(pb.pull_request_id) FILTER (WHERE pb.status = 'Merged') AS merged_pull_requests,
    COUNT(pb.pull_request_id) FILTER (WHERE pb.status = 'Open') AS open_pull_requests,
    COUNT(pb.pull_request_id) FILTER (WHERE pb.status = 'Closed') AS closed_pull_requests,
    ROUND(
        COUNT(pb.pull_request_id) FILTER (WHERE pb.status = 'Merged')::NUMERIC
        / NULLIF(COUNT(pb.pull_request_id), 0) * 100, 2
    ) AS merge_rate_pct,
    ROUND(AVG(pb.hours_to_merge) FILTER (WHERE pb.status = 'Merged'), 2) AS avg_hours_to_merge,
    ROUND(AVG(EXTRACT(EPOCH FROM (rs.first_review_at - pb.created_at)) / 3600.0), 2) AS avg_hours_to_first_review,
    ROUND(
        SUM(rs.changes_requested_count)::NUMERIC / NULLIF(SUM(rs.review_count), 0) * 100, 2
    ) AS pct_reviews_requesting_changes
FROM gold.dim_repositories dr
LEFT JOIN gold.fact_pull_requests pb ON pb.repository_id = dr.repository_id
LEFT JOIN review_stats rs ON rs.pull_request_id = pb.pull_request_id
GROUP BY dr.repository_id, dr.repository_name;


-- gold.issue_resolution_summary
CREATE OR REPLACE VIEW gold.issue_resolution_summary AS
SELECT
    dr.repository_id,
    dr.repository_name,
    COUNT(i.issue_id) AS total_issues,
    COUNT(i.issue_id) FILTER (WHERE i.status = 'Open') AS open_issues,
    COUNT(i.issue_id) FILTER (WHERE i.status = 'Closed') AS closed_issues,
    ROUND(
        COUNT(i.issue_id) FILTER (WHERE i.status = 'Closed')::NUMERIC
        / NULLIF(COUNT(i.issue_id), 0) * 100, 2
    ) AS closure_rate_pct,
    ROUND(
        COUNT(i.issue_id) FILTER (WHERE i.status = 'Open')::NUMERIC
        / NULLIF(COUNT(i.issue_id), 0) * 100, 2
    ) AS unresolved_rate_pct,
    ROUND(AVG(i.hours_to_resolve) FILTER (WHERE i.status = 'Closed'), 2) AS avg_hours_to_resolve,
    COUNT(i.issue_id) FILTER (WHERE i.priority = 'Critical') AS critical_issues,
    COUNT(i.issue_id) FILTER (WHERE i.priority = 'High') AS high_priority_issues
FROM gold.dim_repositories dr
LEFT JOIN gold.fact_issues i ON i.repository_id = dr.repository_id
GROUP BY dr.repository_id, dr.repository_name;


-- gold.release_analytics_summary
CREATE OR REPLACE VIEW gold.release_analytics_summary AS
SELECT
    dr.repository_id,
    dr.repository_name,
    COUNT(fr.release_id) AS total_releases,
    MIN(fr.published_at) AS first_release_at,
    MAX(fr.published_at) AS latest_release_at,
    ROUND(AVG(fr.days_since_previous_release), 1) AS avg_days_between_releases
FROM gold.dim_repositories dr
LEFT JOIN gold.fact_releases fr ON fr.repository_id = dr.repository_id
GROUP BY dr.repository_id, dr.repository_name;

-- gold.data_quality_row_counts / gold.data_quality_summary
CREATE OR REPLACE VIEW gold.data_quality_row_counts AS
SELECT 'programming_languages' AS table_name,
        (SELECT COUNT(*) FROM bronze.programming_languages) AS bronze_rows,
        (SELECT COUNT(*) FROM silver.programming_languages) AS silver_rows
UNION ALL SELECT 'users', (SELECT COUNT(*) FROM bronze.users), (SELECT COUNT(*) FROM silver.users)
UNION ALL SELECT 'organizations', (SELECT COUNT(*) FROM bronze.organizations), (SELECT COUNT(*) FROM silver.organizations)
UNION ALL SELECT 'organization_members', (SELECT COUNT(*) FROM bronze.organization_members), (SELECT COUNT(*) FROM silver.organization_members)
UNION ALL SELECT 'repositories', (SELECT COUNT(*) FROM bronze.repositories), (SELECT COUNT(*) FROM silver.repositories)
UNION ALL SELECT 'repository_languages', (SELECT COUNT(*) FROM bronze.repository_languages), (SELECT COUNT(*) FROM silver.repository_languages)
UNION ALL SELECT 'repository_contributors', (SELECT COUNT(*) FROM bronze.repository_contributors), (SELECT COUNT(*) FROM silver.repository_contributors)
UNION ALL SELECT 'branches', (SELECT COUNT(*) FROM bronze.branches), (SELECT COUNT(*) FROM silver.branches)
UNION ALL SELECT 'commits', (SELECT COUNT(*) FROM bronze.commits), (SELECT COUNT(*) FROM silver.commits)
UNION ALL SELECT 'pull_requests', (SELECT COUNT(*) FROM bronze.pull_requests), (SELECT COUNT(*) FROM silver.pull_requests)
UNION ALL SELECT 'pull_request_reviews', (SELECT COUNT(*) FROM bronze.pull_request_reviews), (SELECT COUNT(*) FROM silver.pull_request_reviews)
UNION ALL SELECT 'issues', (SELECT COUNT(*) FROM bronze.issues), (SELECT COUNT(*) FROM silver.issues)
UNION ALL SELECT 'releases', (SELECT COUNT(*) FROM bronze.releases), (SELECT COUNT(*) FROM silver.releases)
UNION ALL SELECT 'stars', (SELECT COUNT(*) FROM bronze.stars), (SELECT COUNT(*) FROM silver.stars)
UNION ALL SELECT 'forks', (SELECT COUNT(*) FROM bronze.forks), (SELECT COUNT(*) FROM silver.forks);

CREATE OR REPLACE VIEW gold.data_quality_summary AS
SELECT
    table_name,
    bronze_rows,
    silver_rows,
    bronze_rows - silver_rows AS duplicate_rows_removed,
    ROUND(silver_rows::NUMERIC / NULLIF(bronze_rows, 0) * 100, 2) AS pct_rows_retained
FROM gold.data_quality_row_counts
ORDER BY duplicate_rows_removed DESC;


-- gold.data_quality_field_issues
CREATE OR REPLACE VIEW gold.data_quality_field_issues AS
SELECT 'users.email' AS field, 'Malformed email address' AS issue_type,
        (SELECT COUNT(*) FROM bronze.users
            WHERE email !~ '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$') AS bronze_issue_count
UNION ALL
SELECT 'users.bio', 'Missing value',
        (SELECT COUNT(*) FROM bronze.users WHERE bio IS NULL OR TRIM(bio) = '')
UNION ALL
SELECT 'users.followers', 'Negative value',
        (SELECT COUNT(*) FROM bronze.users WHERE TRIM(followers::TEXT) ~ '^-')
UNION ALL
SELECT 'organizations.website', 'Missing value',
        (SELECT COUNT(*) FROM bronze.organizations WHERE website IS NULL OR TRIM(website) = '')
UNION ALL
SELECT 'repositories.description', 'Missing value',
        (SELECT COUNT(*) FROM bronze.repositories WHERE description IS NULL OR TRIM(description) = '')
UNION ALL
SELECT 'repositories.repository_size_mb', 'Negative value',
        (SELECT COUNT(*) FROM bronze.repositories WHERE TRIM(repository_size_mb::TEXT) ~ '^-')
UNION ALL
SELECT 'commits.commit_message', 'Missing value',
        (SELECT COUNT(*) FROM bronze.commits WHERE commit_message IS NULL OR TRIM(commit_message) = '')
UNION ALL
SELECT 'commits.lines_added', 'Negative value',
        (SELECT COUNT(*) FROM bronze.commits WHERE TRIM(lines_added::TEXT) ~ '^-')
UNION ALL
SELECT 'commits.lines_deleted', 'Negative value',
        (SELECT COUNT(*) FROM bronze.commits WHERE TRIM(lines_deleted::TEXT) ~ '^-')
UNION ALL
SELECT 'issues.title', 'Missing value',
        (SELECT COUNT(*) FROM bronze.issues WHERE title IS NULL OR TRIM(title) = '')
UNION ALL
SELECT 'releases.release_notes', 'Missing value',
        (SELECT COUNT(*) FROM bronze.releases WHERE release_notes IS NULL OR TRIM(release_notes) = '')
UNION ALL
SELECT 'repository_languages.percentage_used', 'Negative value',
        (SELECT COUNT(*) FROM bronze.repository_languages WHERE TRIM(percentage_used::TEXT) ~ '^-');


-- gold.executive_summary
CREATE OR REPLACE VIEW gold.executive_summary AS
SELECT
    (SELECT COUNT(*) FROM gold.dim_users) AS total_developers,
    (SELECT COUNT(*) FROM gold.dim_repositories) AS total_repositories,
    (SELECT COUNT(*) FROM gold.fact_commits) AS total_commits,
    (SELECT COUNT(*) FROM gold.fact_pull_requests) AS total_pull_requests,
    (SELECT COUNT(*) FROM gold.fact_pull_requests WHERE status = 'Merged') AS total_pull_requests_merged,
    (SELECT COUNT(*) FROM gold.fact_issues) AS total_issues,
    (SELECT COUNT(*) FROM gold.fact_issues WHERE status = 'Closed') AS total_issues_resolved,
    (SELECT COUNT(*) FROM gold.fact_releases) AS total_releases,
    (SELECT COUNT(*) FROM gold.fact_stars) AS total_stars,
    (SELECT COUNT(*) FROM gold.fact_forks) AS total_forks,
    (SELECT COUNT(*) FROM gold.dim_organizations) AS total_organizations,
    (SELECT ROUND(AVG(commits_authored), 2) FROM gold.developer_productivity_summary
    WHERE commits_authored > 0) AS avg_commits_per_active_developer,
    (SELECT ROUND(COUNT(*) FILTER (WHERE status = 'Merged')::NUMERIC / NULLIF(COUNT(*), 0) * 100, 2)
        FROM gold.fact_pull_requests) AS overall_pr_merge_rate_pct,
    (SELECT ROUND(COUNT(*) FILTER (WHERE status = 'Closed')::NUMERIC / NULLIF(COUNT(*), 0) * 100, 2)
        FROM gold.fact_issues) AS overall_issue_closure_rate_pct;
