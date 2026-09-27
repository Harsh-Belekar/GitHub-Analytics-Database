-- =============================================================================
-- GitHub Analytics Database — SQL Analysis
-- Category: Repository Analytics  (Business_Questions.md, Section 2)
-- =============================================================================

-- Q1. How many repositories are currently available?
SELECT 
	COUNT(*) AS total_repositories
FROM gold.dim_repositories;


-- Q2. Which repositories have the highest number of commits?
SELECT 
	repository_name, 
	total_commits
FROM gold.repository_performance_summary
ORDER BY total_commits DESC
LIMIT 10;


-- Q3. Which repositories have the highest number of contributors?
SELECT 
	repository_name, 
	total_contributors
FROM gold.repository_performance_summary
ORDER BY total_contributors DESC
LIMIT 10;


-- Q4. Which repositories receive the most pull requests?
SELECT 
	repository_name, 
	total_pull_requests
FROM gold.repository_performance_summary
ORDER BY total_pull_requests DESC
LIMIT 10;


-- Q5. Which repositories have the highest number of open issues?
SELECT 
	repository_name, 
	open_issues
FROM gold.repository_performance_summary
ORDER BY open_issues DESC
LIMIT 10;


-- Q6. Which repositories have the highest number of closed issues?
SELECT 
	repository_name, 
	closed_issues
FROM gold.repository_performance_summary
ORDER BY closed_issues DESC
LIMIT 10;


-- Q7. Which repositories receive the most stars?
SELECT 
	repository_name, 
	total_stars
FROM gold.repository_performance_summary
ORDER BY total_stars DESC
LIMIT 10;


-- Q8. Which repositories have been forked the most?
SELECT 
	repository_name, 
	total_forks
FROM gold.repository_performance_summary
ORDER BY total_forks DESC
LIMIT 10;


-- Q9. Which repositories are growing the fastest over time?
WITH monthly AS (
    SELECT
        repository_id,
        repository_name,
        activity_month,
        commit_count,
        LAG(commit_count) OVER (PARTITION BY repository_id ORDER BY activity_month) AS prev_month_commits
    FROM gold.repository_monthly_activity
)
SELECT
    repository_name,
    activity_month,
    commit_count,
    prev_month_commits,
    ROUND(
        (commit_count - prev_month_commits)::NUMERIC / NULLIF(prev_month_commits, 0), 2
    ) AS commit_growth_pct
FROM monthly
WHERE prev_month_commits IS NOT NULL AND prev_month_commits > 0
ORDER BY commit_growth_pct DESC
LIMIT 10;


-- Q10. What is the activity trend of each repository by month?
SELECT
    repository_name,
    activity_month,
    commit_count,
    pull_request_count,
    issue_count,
    release_count,
    star_count
FROM gold.repository_monthly_activity
ORDER BY repository_name, activity_month;
