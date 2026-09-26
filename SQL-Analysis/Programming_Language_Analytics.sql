-- =============================================================================
-- GitHub Analytics Database — SQL Analysis
-- Category: Programming Language Analytics  (Business_Questions.md, Section 9)
-- =============================================================================

-- Q1. Which programming languages are used most frequently?
SELECT 
    language_name, 
    repositories_using
FROM gold.language_adoption_summary
ORDER BY repositories_using DESC
LIMIT 10;


-- Q2. Which repositories use multiple programming languages?
SELECT 
    dr.repository_name, 
    COUNT(*) AS language_count
FROM gold.fact_repository_languages frl
JOIN gold.dim_repositories dr ON dr.repository_id = frl.repository_id
GROUP BY dr.repository_name
HAVING COUNT(*) > 1
ORDER BY language_count DESC;


-- Q3. Which language has the highest number of repositories?
SELECT 
    language_name, 
    repositories_primary
FROM gold.language_adoption_summary
ORDER BY repositories_primary DESC
LIMIT 1;


-- Q4. Which language generates the most commits?
SELECT 
    language_name, 
    total_commits
FROM gold.language_adoption_summary
ORDER BY total_commits DESC
LIMIT 10;


-- Q5. Which language has the highest community engagement?
SELECT 
    language_name, 
    total_stars
FROM gold.language_adoption_summary
ORDER BY total_stars DESC
LIMIT 10;


-- Q6. Which languages are growing over time?
WITH lang_monthly AS (
    SELECT
        dr.primary_language_name AS language_name,
        DATE_TRUNC('month', fc.commit_timestamp)::DATE AS commit_month,
        COUNT(*) AS commit_count
    FROM gold.fact_commits fc
    JOIN gold.dim_repositories dr ON dr.repository_id = fc.repository_id
    GROUP BY 1, 2
)
SELECT
    language_name,
    commit_month,
    commit_count,
    LAG(commit_count) OVER (PARTITION BY language_name ORDER BY commit_month) AS prev_month_count,
    ROUND(
        (commit_count - LAG(commit_count) OVER (PARTITION BY language_name ORDER BY commit_month))::NUMERIC
        / NULLIF(LAG(commit_count) OVER (PARTITION BY language_name ORDER BY commit_month), 0) * 100, 2
    ) AS growth_pct
FROM lang_monthly
ORDER BY language_name, commit_month;


-- Q7. Which organizations primarily use Python?
SELECT 
    DISTINCT organization_name
FROM gold.dim_repositories
WHERE primary_language_name = 'Python' AND organization_name IS NOT NULL;


-- Q8. Which repositories use SQL?
SELECT 
    dr.repository_name
FROM gold.fact_repository_languages frl
JOIN gold.dim_languages dl ON dl.language_id = frl.language_id
JOIN gold.dim_repositories dr ON dr.repository_id = frl.repository_id
WHERE dl.language_name = 'SQL';
