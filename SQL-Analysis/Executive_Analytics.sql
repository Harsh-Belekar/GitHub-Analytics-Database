-- =============================================================================
-- GitHub Analytics Database — SQL Analysis
-- Category: Executive Dashboard Questions  (Business_Questions.md, Section 12)
-- =============================================================================

-- Q1. What is the total number of developers?
SELECT 
    total_developers 
FROM gold.executive_summary;


-- Q2. What is the total number of repositories?
SELECT 
    total_repositories 
FROM gold.executive_summary;


-- Q3. What is the total number of commits?
SELECT 
    total_commits 
FROM gold.executive_summary;


-- Q4. What is the total number of pull requests?
SELECT 
    total_pull_requests 
FROM gold.executive_summary;


-- Q5. What is the total number of issues?
SELECT 
    total_issues 
FROM gold.executive_summary;


-- Q6. What is the repository growth trend?
SELECT
    DATE_TRUNC('month', created_at)::DATE AS month,
    COUNT(*) AS new_repositories,
    SUM(COUNT(*)) OVER (ORDER BY DATE_TRUNC('month', created_at)::DATE) AS cumulative_repositories
FROM gold.dim_repositories
GROUP BY 1
ORDER BY 1;


-- Q7. What is the developer productivity trend?
SELECT
    activity_month,
    COUNT(DISTINCT user_id) AS active_developers,
    SUM(commit_count) AS total_commits,
    ROUND(SUM(commit_count)::NUMERIC / NULLIF(COUNT(DISTINCT user_id), 0), 2) AS avg_commits_per_active_developer
FROM gold.developer_monthly_activity
GROUP BY activity_month
ORDER BY activity_month;


-- Q8. Which repositories are the top performers?
SELECT repository_name, total_commits, total_stars, total_pull_requests, total_issues
FROM gold.repository_performance_summary
ORDER BY total_commits DESC, total_stars DESC
LIMIT 10;


-- Q9. Which organizations contribute the most?
SELECT organization_name, total_commits, total_stars, total_releases
FROM gold.organization_summary
ORDER BY total_commits DESC
LIMIT 10;


-- Q10. What are the overall software engineering KPIs?
SELECT * FROM gold.executive_summary;
