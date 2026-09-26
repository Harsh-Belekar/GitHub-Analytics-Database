-- =============================================================================
-- GitHub Analytics Database — SQL Analysis
-- Category: Community Engagement Analytics  (Business_Questions.md, Section 10)
-- =============================================================================

-- Q1. Which repositories have the highest number of stars?
SELECT 
    repository_name, 
    total_stars
FROM gold.repository_performance_summary
ORDER BY total_stars DESC
LIMIT 10;


-- Q2. Which repositories have the highest number of forks?
SELECT 
    repository_name, 
    total_forks
FROM gold.repository_performance_summary
ORDER BY total_forks DESC
LIMIT 10;


-- Q3. Which developers receive the most followers?
SELECT 
    username, 
    followers
FROM gold.dim_users
ORDER BY followers DESC
LIMIT 10;


-- Q4. Which repositories attract the largest contributor communities?
SELECT 
    repository_name, 
    total_contributors
FROM gold.repository_performance_summary
ORDER BY total_contributors DESC
LIMIT 10;


-- Q5. What is the relationship between stars and forks?
SELECT 
    CORR(total_stars, total_forks) AS stars_forks_correlation
FROM gold.repository_performance_summary;

-- Scatter-ready detail for the same relationship:
SELECT 
    repository_name, 
    total_stars, 
    total_forks
FROM gold.repository_performance_summary
ORDER BY total_stars DESC;


-- Q6. Which repositories experience the fastest community growth?
SELECT 
    dr.repository_name, 
    COUNT(*) AS stars_last_30_days
FROM gold.fact_stars fs
JOIN gold.dim_repositories dr 
    ON dr.repository_id = fs.repository_id
WHERE fs.starred_at >= CURRENT_DATE - INTERVAL '30 days'
GROUP BY dr.repository_name
ORDER BY stars_last_30_days DESC
LIMIT 10;


-- Q7. Which organizations receive the highest community engagement?
SELECT
    do_.organization_name,
    COALESCE(s.total_stars, 0) AS total_stars,
    COALESCE(f.total_forks, 0) AS total_forks,
    COALESCE(s.total_stars, 0) + COALESCE(f.total_forks, 0) AS total_engagement
FROM gold.dim_organizations do_
LEFT JOIN (
    SELECT dr.organization_id, COUNT(*) AS total_stars
    FROM gold.fact_stars fs JOIN gold.dim_repositories dr ON dr.repository_id = fs.repository_id
    WHERE dr.organization_id IS NOT NULL GROUP BY dr.organization_id
) s ON s.organization_id = do_.organization_id
LEFT JOIN (
    SELECT dr.organization_id, COUNT(*) AS total_forks
    FROM gold.fact_forks ff JOIN gold.dim_repositories dr ON dr.repository_id = ff.source_repository_id
    WHERE dr.organization_id IS NOT NULL GROUP BY dr.organization_id
) f ON f.organization_id = do_.organization_id
ORDER BY total_engagement DESC
LIMIT 10;
