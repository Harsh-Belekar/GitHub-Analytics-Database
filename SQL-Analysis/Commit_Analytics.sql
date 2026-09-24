-- =============================================================================
-- GitHub Analytics Database — SQL Analysis
-- Category: Commit Analytics  (Business_Questions.md, Section 4)
-- =============================================================================

-- Q1. How many commits were created each day?
SELECT 
	commit_timestamp::DATE AS commit_date, 
	COUNT(*) AS commit_count
FROM gold.fact_commits
GROUP BY commit_timestamp::DATE
ORDER BY commit_date;


-- Q2. How many commits were created each month?
SELECT 
	DATE_TRUNC('month', commit_timestamp)::DATE AS commit_month, 
	COUNT(*) AS commit_count
FROM gold.fact_commits
GROUP BY 1
ORDER BY 1;


-- Q3. What are the peak development periods?
-- Two angles: busiest day-of-week / hour-of-day combos, and busiest months.
SELECT
    TO_CHAR(commit_timestamp, 'Day') AS day_of_week,
    EXTRACT(HOUR FROM commit_timestamp)::INT AS hour_of_day,
    COUNT(*) AS commit_count
FROM gold.fact_commits
GROUP BY 1, 2
ORDER BY commit_count DESC
LIMIT 10;

SELECT 
	DATE_TRUNC('month', commit_timestamp)::DATE AS commit_month, 
	COUNT(*) AS commit_count
FROM gold.fact_commits
GROUP BY 1
ORDER BY commit_count DESC
LIMIT 5;


-- Q4. Which repositories receive commits most frequently?
SELECT 
	repository_name, 
	total_commits
FROM gold.repository_performance_summary
ORDER BY total_commits DESC
LIMIT 10;


-- Q5. Which branches contain the highest number of commits?
SELECT 
	repository_name,
	branch_name, 
	is_default, 
	commit_count
FROM gold.branch_activity_summary
ORDER BY commit_count DESC
LIMIT 10;


-- Q6. What is the average number of lines added per commit?
SELECT 
	ROUND(AVG(lines_added), 2) AS avg_lines_added_per_commit
FROM gold.fact_commits;


-- Q7. What is the average number of lines deleted per commit?
SELECT 
	ROUND(AVG(lines_deleted), 2) AS avg_lines_deleted_per_commit
FROM gold.fact_commits;


-- Q8. Which developers make the largest code contributions?
SELECT
    du.username,
    SUM(fc.total_lines_changed) AS total_lines_changed,
    COUNT(*) AS commit_count
FROM gold.fact_commits fc
JOIN gold.dim_users du ON du.user_id = fc.user_id
GROUP BY du.username
ORDER BY total_lines_changed DESC
LIMIT 10;


-- Q9. What is the monthly commit growth trend?
WITH monthly AS (
    SELECT 
		DATE_TRUNC('month', commit_timestamp)::DATE AS commit_month, 
		COUNT(*) AS commit_count
    FROM gold.fact_commits
    GROUP BY 1
)
SELECT
    commit_month,
    commit_count,
    LAG(commit_count) OVER (ORDER BY commit_month) AS prev_month_count,
    ROUND(
        (commit_count - LAG(commit_count) OVER (ORDER BY commit_month))::NUMERIC
        / NULLIF(LAG(commit_count) OVER (ORDER BY commit_month), 0) * 100, 2
    ) AS growth_pct
FROM monthly
ORDER BY commit_month;


-- Q10. What is the distribution of commit activity across repositories?
SELECT
    repository_name,
    total_commits,
    ROUND(total_commits::NUMERIC / NULLIF(SUM(total_commits) OVER (), 0) * 100, 2) AS pct_of_all_commits
FROM gold.repository_performance_summary
ORDER BY total_commits DESC;
