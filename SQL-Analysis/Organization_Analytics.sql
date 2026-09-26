-- =============================================================================
-- GitHub Analytics Database — SQL Analysis
-- Category: Organization Analytics  (Business_Questions.md, Section 8)
-- =============================================================================

-- Q1. How many organizations exist?
SELECT 
    COUNT(*) AS total_organizations
FROM gold.dim_organizations;


-- Q2. Which organizations own the most repositories?
SELECT 
    organization_name, 
    total_repositories
FROM gold.organization_summary
ORDER BY total_repositories DESC
LIMIT 10;


-- Q3. Which organizations have the most developers?
SELECT 
    organization_name, 
    total_members
FROM gold.organization_summary
ORDER BY total_members DESC
LIMIT 10;


-- Q4. Which organizations generate the most commits?
SELECT 
    organization_name, 
    total_commits
FROM gold.organization_summary
ORDER BY total_commits DESC
LIMIT 10;


-- Q5. Which organizations receive the most stars?
SELECT 
    organization_name, 
    total_stars
FROM gold.organization_summary
ORDER BY total_stars DESC
LIMIT 10;


-- Q6. Which organizations resolve the most issues?
SELECT 
    organization_name, 
    issues_resolved
FROM gold.organization_summary
ORDER BY issues_resolved DESC
LIMIT 10;


-- Q7. Which organizations publish the most releases?
SELECT 
    organization_name, 
    total_releases
FROM gold.organization_summary
ORDER BY total_releases DESC
LIMIT 10;


-- Q8. Which organizations have the highest developer productivity?
SELECT 
    organization_name,
    total_members, 
    total_commits, 
    commits_per_member
FROM gold.organization_summary
WHERE total_members > 0
ORDER BY commits_per_member DESC
LIMIT 10;
