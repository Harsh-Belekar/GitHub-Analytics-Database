-- =============================================================================
-- GitHub Analytics Database — SQL Analysis
-- Category: Pull Request Analytics  (Business_Questions.md, Section 5)
-- =============================================================================

-- Q1. How many pull requests were created?
SELECT
	COUNT(*) AS total_pull_requests
FROM gold.fact_pull_requests;


-- Q2. How many pull requests were merged?
SELECT 
	COUNT(*) AS merged_pull_requests
FROM gold.fact_pull_requests
WHERE status = 'Merged';


-- Q3. How many pull requests remain open?
SELECT 
	COUNT(*) AS open_pull_requests
FROM gold.fact_pull_requests
WHERE status = 'Open';


-- Q4. What is the average pull request review time?
SELECT 
	ROUND(AVG(EXTRACT(EPOCH FROM (rv.first_review_at - pr.created_at)) / 3600.0), 2) AS avg_review_time_hours
FROM gold.fact_pull_requests pr
JOIN (
    SELECT pull_request_id, MIN(reviewed_at) AS first_review_at
    FROM gold.fact_pull_request_reviews
    GROUP BY pull_request_id
) rv ON rv.pull_request_id = pr.pull_request_id;


-- Q5. Which repositories have the highest merge rate?
SELECT 
	repository_name, 
	total_pull_requests, 
	merge_rate_pct
FROM gold.pull_request_efficiency_summary
WHERE total_pull_requests > 0
ORDER BY merge_rate_pct DESC
LIMIT 10;


-- Q6. Which developers submit the most pull requests?
SELECT 
	username, 
	pull_requests_opened
FROM gold.developer_productivity_summary
ORDER BY pull_requests_opened DESC
LIMIT 10;


-- Q7. Which reviewers approve the most pull requests?
SELECT 
	username,
	pull_requests_approved
FROM gold.developer_productivity_summary
ORDER BY pull_requests_approved DESC
LIMIT 10;


-- Q8. What percentage of pull requests require changes?
SELECT
    ROUND(
        COUNT(*) FILTER (WHERE review_state = 'Changes Requested')::NUMERIC
        / NULLIF(COUNT(*), 0) * 100, 2
    ) AS pct_reviews_requesting_changes
FROM gold.fact_pull_request_reviews;


-- Q9. Which repositories have the highest pull request activity?
SELECT 
	repository_name, 
	total_pull_requests
FROM gold.pull_request_efficiency_summary
ORDER BY total_pull_requests DESC
LIMIT 10;


-- Q10. What is the monthly trend of pull request creation?
SELECT 
	DATE_TRUNC('month', created_at)::DATE AS pr_month, 
	COUNT(*) AS pull_request_count
FROM gold.fact_pull_requests
GROUP BY 1
ORDER BY 1;
