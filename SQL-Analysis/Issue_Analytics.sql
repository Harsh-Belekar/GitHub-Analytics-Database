-- =============================================================================
-- GitHub Analytics Database — SQL Analysis
-- Category: Issue Analytics  (Business_Questions.md, Section 6)
-- =============================================================================

-- Q1. How many issues are currently open?
SELECT 
    COUNT(*) AS open_issues
FROM gold.fact_issues
WHERE status = 'Open';


-- Q2. How many issues have been resolved?
SELECT 
    COUNT(*) AS resolved_issues
FROM gold.fact_issues
WHERE status = 'Closed';


-- Q3. What is the average issue resolution time?
SELECT 
    ROUND(AVG(hours_to_resolve), 2) AS avg_resolution_time_hours
FROM gold.fact_issues
WHERE status = 'Closed';


-- Q4. Which repositories have the most issues?
SELECT 
    repository_name, 
    total_issues
FROM gold.issue_resolution_summary
ORDER BY total_issues DESC
LIMIT 10;


-- Q5. Which developers resolve the most issues?
SELECT 
    username, 
    issues_resolved
FROM gold.developer_productivity_summary
ORDER BY issues_resolved DESC
LIMIT 10;


-- Q6. What percentage of issues remain unresolved?
SELECT
    ROUND(COUNT(*) FILTER (WHERE status = 'Open')::NUMERIC / NULLIF(COUNT(*), 0) * 100, 2) AS pct_unresolved
FROM gold.fact_issues;


-- Q7. Which issue priorities occur most frequently?
SELECT 
    priority, 
    COUNT(*) AS issue_count
FROM gold.fact_issues
GROUP BY priority
ORDER BY issue_count DESC;


-- Q8. Which repositories receive the most critical issues?
SELECT 
    repository_name, 
    critical_issues
FROM gold.issue_resolution_summary
ORDER BY critical_issues DESC
LIMIT 10;


-- Q9. What are the monthly issue trends?
SELECT 
    DATE_TRUNC('month', created_at)::DATE AS issue_month,
    COUNT(*) AS issue_count
FROM gold.fact_issues
GROUP BY 1
ORDER BY 1;


-- Q10. What is the issue closure rate by repository?
SELECT 
    repository_name, 
    total_issues, 
    closed_issues, 
    closure_rate_pct
FROM gold.issue_resolution_summary
WHERE total_issues > 0
ORDER BY closure_rate_pct DESC;
