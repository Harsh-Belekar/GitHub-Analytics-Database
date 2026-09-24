-- =============================================================================
-- GitHub Analytics Database — SQL Analysis
-- Category: Developer Productivity  (Business_Questions.md, Section 3)
-- =============================================================================

-- Q1. Which developers created the most commits?
SELECT 
	username, 
	commits_authored
FROM gold.developer_productivity_summary
ORDER BY commits_authored DESC
LIMIT 10;


-- Q2. Which developers opened the most pull requests?
SELECT 
	username, 
	pull_requests_opened
FROM gold.developer_productivity_summary
ORDER BY pull_requests_opened DESC
LIMIT 10;


-- Q3. Which developers merged the most pull requests?
SELECT 
	username, 
	pull_requests_merged
FROM gold.developer_productivity_summary
ORDER BY pull_requests_merged DESC
LIMIT 10;


-- Q4. Which developers reviewed the most pull requests?
SELECT 
	username, 
	pull_requests_reviewed
FROM gold.developer_productivity_summary
ORDER BY pull_requests_reviewed DESC
LIMIT 10;


-- Q5. Which developers resolved the most issues?
SELECT 
	username, 
	issues_resolved
FROM gold.developer_productivity_summary
ORDER BY issues_resolved DESC
LIMIT 10;


-- Q6. Which developers contribute to the highest number of repositories?
SELECT 
	username, 
	repos_contributed_to
FROM gold.developer_productivity_summary
ORDER BY repos_contributed_to DESC
LIMIT 10;


-- Q7. Which developers have the highest follower count?
SELECT 
	username, 
	followers
FROM gold.dim_users
ORDER BY followers DESC
LIMIT 10;


-- Q8. Which developers own the most repositories?
SELECT 
	username, 
	repos_owned
FROM gold.developer_productivity_summary
ORDER BY repos_owned DESC
LIMIT 10;


-- Q9. Which developers are the most active each month?
WITH ranked AS (
    SELECT
        username,
        activity_month,
        commit_count,
        ROW_NUMBER() OVER (PARTITION BY activity_month ORDER BY commit_count DESC) AS rnk
    FROM gold.developer_monthly_activity
)
SELECT activity_month, username, commit_count
FROM ranked
WHERE rnk = 1
ORDER BY activity_month;


-- Q10. What is the average number of commits per developer?
SELECT
    ROUND(AVG(commits_authored), 2) AS avg_commits_per_developer,
    ROUND(AVG(commits_authored) 
		FILTER (WHERE commits_authored > 0), 2) AS avg_commits_per_active_developer
FROM gold.developer_productivity_summary;
