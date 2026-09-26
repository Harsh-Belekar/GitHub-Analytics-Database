-- =============================================================================
-- GitHub Analytics Database — SQL Analysis
-- Category: Release Analytics  (Business_Questions.md, Section 7)
-- =============================================================================

-- Q1. How many releases were published?
SELECT 
    COUNT(*) AS total_releases
FROM gold.fact_releases;


-- Q2. Which repositories publish releases most frequently?
SELECT 
    repository_name, 
    total_releases
FROM gold.release_analytics_summary
ORDER BY total_releases DESC
LIMIT 10;


-- Q3. What is the average time between releases?
SELECT 
    ROUND(AVG(days_since_previous_release), 1) AS avg_days_between_releases
FROM gold.fact_releases
WHERE days_since_previous_release IS NOT NULL;


-- Q4. How many major, minor, and patch releases were created?
SELECT 
    release_type, COUNT(*) AS release_count
FROM gold.fact_releases
GROUP BY release_type
ORDER BY release_count DESC;


-- Q5. Which repositories have the fastest release cycle?
SELECT 
    repository_name, 
    total_releases, 
    avg_days_between_releases
FROM gold.release_analytics_summary
WHERE total_releases > 1
ORDER BY avg_days_between_releases ASC
LIMIT 10;


-- Q6. Which repositories have the slowest release cycle?
SELECT 
    repository_name, 
    total_releases, 
    avg_days_between_releases
FROM gold.release_analytics_summary
WHERE total_releases > 1
ORDER BY avg_days_between_releases DESC
LIMIT 10;


-- Q7. What is the monthly release trend?
SELECT 
    DATE_TRUNC('month', published_at)::DATE AS release_month, 
    COUNT(*) AS release_count
FROM gold.fact_releases
GROUP BY 1
ORDER BY 1;


-- Q8. How many releases occur each year?
SELECT 
    EXTRACT(YEAR FROM published_at)::INT AS release_year, 
    COUNT(*) AS release_count
FROM gold.fact_releases
GROUP BY 1
ORDER BY 1;
