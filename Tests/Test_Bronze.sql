-- =============================================================================
-- GitHub Analytics Database
-- Bronze Layer Data Validation Tests
-- =============================================================================
-- Author      : Harsh Belekar
-- Layer       : Bronze
-- Purpose     : This script validates the raw data loaded into the Bronze layer.
--
-- Bronze is the raw ingestion layer, therefore data quality issues are
-- identified and reported here but are not necessarily treated as failures.
-- Data cleaning, validation, deduplication, and transformation are handled
-- in the Silver layer.
-- =============================================================================


-- =============================================================================
-- 1. TABLE ROW COUNT VALIDATION
-- =============================================================================
-- Verify that all Bronze tables contain data.

SELECT 
    'programming_languages' AS table_name,
    COUNT(*) AS row_count
FROM bronze.programming_languages

UNION ALL

SELECT 
    'users',
    COUNT(*)
FROM bronze.users

UNION ALL

SELECT 
    'organizations',
    COUNT(*)
FROM bronze.organizations

UNION ALL

SELECT 
    'organization_members',
    COUNT(*)
FROM bronze.organization_members

UNION ALL

SELECT 
    'repositories',
    COUNT(*)
FROM bronze.repositories

UNION ALL

SELECT 
    'repository_languages',
    COUNT(*)
FROM bronze.repository_languages

UNION ALL

SELECT 
    'repository_contributors',
    COUNT(*)
FROM bronze.repository_contributors

UNION ALL

SELECT 
    'branches',
    COUNT(*)
FROM bronze.branches

UNION ALL

SELECT
    'commits',
    COUNT(*)
FROM bronze.commits

UNION ALL

SELECT 
    'pull_requests',
    COUNT(*)
FROM bronze.pull_requests

UNION ALL

SELECT 
    'pull_request_reviews',
    COUNT(*)
FROM bronze.pull_request_reviews

UNION ALL

SELECT 
    'issues',
    COUNT(*)
FROM bronze.issues

UNION ALL

SELECT 
    'releases',
    COUNT(*)
FROM bronze.releases

UNION ALL

SELECT 
    'stars',
    COUNT(*)
FROM bronze.stars

UNION ALL

SELECT 
    'forks',
    COUNT(*)
FROM bronze.forks

ORDER BY table_name;


-- =============================================================================
-- 2. NULL PRIMARY KEY / IDENTIFIER CHECKS
-- =============================================================================
-- Identify records where important identifier columns are missing.

SELECT
    'programming_languages' AS table_name,
    COUNT(*) AS null_id_count
FROM bronze.programming_languages
WHERE language_id IS NULL

UNION ALL

SELECT
    'users',
    COUNT(*)
FROM bronze.users
WHERE user_id IS NULL

UNION ALL

SELECT
    'organizations',
    COUNT(*)
FROM bronze.organizations
WHERE organization_id IS NULL

UNION ALL

SELECT
    'organization_members',
    COUNT(*)
FROM bronze.organization_members
WHERE membership_id IS NULL

UNION ALL

SELECT
    'repositories',
    COUNT(*)
FROM bronze.repositories
WHERE repository_id IS NULL

UNION ALL

SELECT
    'repository_languages',
    COUNT(*)
FROM bronze.repository_languages
WHERE repository_language_id IS NULL

UNION ALL

SELECT
    'repository_contributors',
    COUNT(*)
FROM bronze.repository_contributors
WHERE contributor_id IS NULL

UNION ALL

SELECT
    'branches',
    COUNT(*)
FROM bronze.branches
WHERE branch_id IS NULL

UNION ALL

SELECT
    'commits',
    COUNT(*)
FROM bronze.commits
WHERE commit_id IS NULL

UNION ALL

SELECT
    'pull_requests',
    COUNT(*)
FROM bronze.pull_requests
WHERE pull_request_id IS NULL

UNION ALL

SELECT
    'pull_request_reviews',
    COUNT(*)
FROM bronze.pull_request_reviews
WHERE review_id IS NULL

UNION ALL

SELECT
    'issues',
    COUNT(*)
FROM bronze.issues
WHERE issue_id IS NULL

UNION ALL

SELECT
    'releases',
    COUNT(*)
FROM bronze.releases
WHERE release_id IS NULL

UNION ALL

SELECT
    'stars',
    COUNT(*)
FROM bronze.stars
WHERE star_id IS NULL

UNION ALL

SELECT
    'forks',
    COUNT(*)
FROM bronze.forks
WHERE fork_id IS NULL

ORDER BY table_name;


-- =============================================================================
-- 3. DUPLICATE IDENTIFIER CHECKS
-- =============================================================================
-- Identify duplicate IDs in the raw Bronze data.

SELECT
    'programming_languages' AS table_name,
    language_id AS duplicate_id,
    COUNT(*) AS duplicate_count
FROM bronze.programming_languages
GROUP BY language_id
HAVING COUNT(*) > 1

UNION ALL

SELECT
    'users',
    user_id,
    COUNT(*)
FROM bronze.users
GROUP BY user_id
HAVING COUNT(*) > 1

UNION ALL

SELECT
    'organizations',
    organization_id,
    COUNT(*)
FROM bronze.organizations
GROUP BY organization_id
HAVING COUNT(*) > 1

UNION ALL

SELECT
    'repositories',
    repository_id,
    COUNT(*)
FROM bronze.repositories
GROUP BY repository_id
HAVING COUNT(*) > 1

UNION ALL

SELECT
    'commits',
    commit_id,
    COUNT(*)
FROM bronze.commits
GROUP BY commit_id
HAVING COUNT(*) > 1

UNION ALL

SELECT
    'pull_requests',
    pull_request_id,
    COUNT(*)
FROM bronze.pull_requests
GROUP BY pull_request_id
HAVING COUNT(*) > 1

UNION ALL

SELECT
    'issues',
    issue_id,
    COUNT(*)
FROM bronze.issues
GROUP BY issue_id
HAVING COUNT(*) > 1

UNION ALL

SELECT
    'releases',
    release_id,
    COUNT(*)
FROM bronze.releases
GROUP BY release_id
HAVING COUNT(*) > 1

UNION ALL

SELECT
    'stars',
    star_id,
    COUNT(*)
FROM bronze.stars
GROUP BY star_id
HAVING COUNT(*) > 1

UNION ALL

SELECT
    'forks',
    fork_id,
    COUNT(*)
FROM bronze.forks
GROUP BY fork_id
HAVING COUNT(*) > 1

ORDER BY table_name, duplicate_count DESC;


-- =============================================================================
-- 4. DUPLICATE BUSINESS KEY CHECKS
-- =============================================================================

-- Duplicate usernames
SELECT
    username,
    COUNT(*) AS duplicate_count
FROM bronze.users
WHERE username IS NOT NULL
GROUP BY username
HAVING COUNT(*) > 1
ORDER BY duplicate_count DESC;


-- Duplicate emails
SELECT
    email,
    COUNT(*) AS duplicate_count
FROM bronze.users
WHERE email IS NOT NULL
GROUP BY email
HAVING COUNT(*) > 1
ORDER BY duplicate_count DESC;


-- Duplicate organization names
SELECT
    organization_name,
    COUNT(*) AS duplicate_count
FROM bronze.organizations
WHERE organization_name IS NOT NULL
GROUP BY organization_name
HAVING COUNT(*) > 1
ORDER BY duplicate_count DESC;


-- Duplicate repository names for the same owner
SELECT
    owner_id,
    repository_name,
    COUNT(*) AS duplicate_count
FROM bronze.repositories
WHERE owner_id IS NOT NULL
    AND repository_name IS NOT NULL
GROUP BY owner_id, repository_name
HAVING COUNT(*) > 1
ORDER BY duplicate_count DESC;


-- Duplicate repository-language combinations
SELECT
    repository_id,
    language_id,
    COUNT(*) AS duplicate_count
FROM bronze.repository_languages
WHERE repository_id IS NOT NULL
    AND language_id IS NOT NULL
GROUP BY repository_id, language_id
HAVING COUNT(*) > 1
ORDER BY duplicate_count DESC;


-- Duplicate repository-contributor combinations
SELECT
    repository_id,
    user_id,
    COUNT(*) AS duplicate_count
FROM bronze.repository_contributors
WHERE repository_id IS NOT NULL
    AND user_id IS NOT NULL
GROUP BY repository_id, user_id
HAVING COUNT(*) > 1
ORDER BY duplicate_count DESC;


-- =============================================================================
-- 5. REFERENTIAL INTEGRITY CHECKS
-- =============================================================================
-- Bronze does not enforce foreign keys, but these tests identify orphan records.


-- Repositories with invalid owners
SELECT r.*
FROM bronze.repositories r
LEFT JOIN bronze.users u
    ON r.owner_id = u.user_id
WHERE r.owner_id IS NOT NULL
    AND u.user_id IS NULL;


-- Repositories with invalid organizations
SELECT r.*
FROM bronze.repositories r
LEFT JOIN bronze.organizations o
    ON r.organization_id = o.organization_id
WHERE r.organization_id IS NOT NULL
    AND o.organization_id IS NULL;


-- Repository languages with invalid repositories
SELECT rl.*
FROM bronze.repository_languages rl
LEFT JOIN bronze.repositories r
    ON rl.repository_id = r.repository_id
WHERE r.repository_id IS NULL;


-- Repository languages with invalid languages
SELECT rl.*
FROM bronze.repository_languages rl
LEFT JOIN bronze.programming_languages pl
    ON rl.language_id = pl.language_id
WHERE pl.language_id IS NULL;


-- Contributors with invalid repositories
SELECT rc.*
FROM bronze.repository_contributors rc
LEFT JOIN bronze.repositories r
    ON rc.repository_id = r.repository_id
WHERE r.repository_id IS NULL;


-- Contributors with invalid users
SELECT rc.*
FROM bronze.repository_contributors rc
LEFT JOIN bronze.users u
    ON rc.user_id = u.user_id
WHERE u.user_id IS NULL;


-- Branches with invalid repositories
SELECT b.*
FROM bronze.branches b
LEFT JOIN bronze.repositories r
    ON b.repository_id = r.repository_id
WHERE r.repository_id IS NULL;


-- Commits with invalid repositories
SELECT c.*
FROM bronze.commits c
LEFT JOIN bronze.repositories r
    ON c.repository_id = r.repository_id
WHERE r.repository_id IS NULL;


-- Commits with invalid branches
SELECT c.*
FROM bronze.commits c
LEFT JOIN bronze.branches b
    ON c.branch_id = b.branch_id
WHERE b.branch_id IS NULL;


-- Commits with invalid users
SELECT c.*
FROM bronze.commits c
LEFT JOIN bronze.users u
    ON c.user_id = u.user_id
WHERE u.user_id IS NULL;


-- Pull requests with invalid repositories
SELECT pr.*
FROM bronze.pull_requests pr
LEFT JOIN bronze.repositories r
    ON pr.repository_id = r.repository_id
WHERE r.repository_id IS NULL;


-- Pull request reviews with invalid pull requests
SELECT prr.*
FROM bronze.pull_request_reviews prr
LEFT JOIN bronze.pull_requests pr
    ON prr.pull_request_id = pr.pull_request_id
WHERE pr.pull_request_id IS NULL;


-- Pull request reviews with invalid reviewers
SELECT prr.*
FROM bronze.pull_request_reviews prr
LEFT JOIN bronze.users u
    ON prr.reviewer_id = u.user_id
WHERE u.user_id IS NULL;


-- Issues with invalid repositories
SELECT i.*
FROM bronze.issues i
LEFT JOIN bronze.repositories r
    ON i.repository_id = r.repository_id
WHERE r.repository_id IS NULL;


-- Issues with invalid users
SELECT i.*
FROM bronze.issues i
LEFT JOIN bronze.users u
    ON i.user_id = u.user_id
WHERE u.user_id IS NULL;


-- Releases with invalid repositories
SELECT rel.*
FROM bronze.releases rel
LEFT JOIN bronze.repositories r
    ON rel.repository_id = r.repository_id
WHERE r.repository_id IS NULL;


-- Releases with invalid publishers
SELECT rel.*
FROM bronze.releases rel
LEFT JOIN bronze.users u
    ON rel.published_by = u.user_id
WHERE u.user_id IS NULL;


-- Stars with invalid repositories
SELECT s.*
FROM bronze.stars s
LEFT JOIN bronze.repositories r
    ON s.repository_id = r.repository_id
WHERE r.repository_id IS NULL;


-- Stars with invalid users
SELECT s.*
FROM bronze.stars s
LEFT JOIN bronze.users u
    ON s.user_id = u.user_id
WHERE u.user_id IS NULL;


-- Forks with invalid source repositories
SELECT f.*
FROM bronze.forks f
LEFT JOIN bronze.repositories r
    ON f.source_repository_id = r.repository_id
WHERE r.repository_id IS NULL;


-- Forks with invalid forked repositories
SELECT f.*
FROM bronze.forks f
LEFT JOIN bronze.repositories r
    ON f.forked_repository_id = r.repository_id
WHERE r.repository_id IS NULL;


-- =============================================================================
-- 6. NUMERIC DATA VALIDATION
-- =============================================================================

-- Negative repository sizes
SELECT *
FROM bronze.repositories
WHERE repository_size_mb < 0;


-- Negative follower/following counts
SELECT *
FROM bronze.users
WHERE followers < 0
    OR following < 0
    OR public_repos < 0
    OR public_gists < 0;


-- Invalid language usage percentage
SELECT *
FROM bronze.repository_languages
WHERE percentage_used < 0
    OR percentage_used > 100;


-- Negative contributor commit counts
SELECT *
FROM bronze.repository_contributors
WHERE total_commits < 0;


-- Negative commit statistics
SELECT *
FROM bronze.commits
WHERE files_changed < 0
    OR lines_added < 0
    OR lines_deleted < 0;


-- Negative pull request file counts
SELECT *
FROM bronze.pull_requests
WHERE files_changed < 0;


-- =============================================================================
-- 7. DATE VALIDATION
-- =============================================================================

-- Users updated before account creation
SELECT *
FROM bronze.users
WHERE updated_at < created_at;


-- Repository updated before creation
SELECT *
FROM bronze.repositories
WHERE updated_at < created_at;


-- Contributor last commit before first commit
SELECT *
FROM bronze.repository_contributors
WHERE last_commit_date < first_commit_date;


-- Pull requests merged before creation
SELECT *
FROM bronze.pull_requests
WHERE merged_at < created_at;


-- Issues closed before creation
SELECT *
FROM bronze.issues
WHERE closed_at < created_at;


-- =============================================================================
-- 8. DOMAIN VALUE VALIDATION
-- =============================================================================

-- Invalid repository visibility values
SELECT *
FROM bronze.repositories
WHERE visibility IS NOT NULL
    AND visibility NOT IN ('Public', 'Private');


-- Invalid pull request status values
SELECT *
FROM bronze.pull_requests
WHERE status IS NOT NULL
    AND status NOT IN ('Open', 'Closed', 'Merged');


-- Invalid issue types
SELECT *
FROM bronze.issues
WHERE issue_type IS NOT NULL
    AND issue_type NOT IN
    ('Bug', 'Feature', 'Documentation', 'Enhancement');


-- Invalid issue priorities
SELECT *
FROM bronze.issues
WHERE priority IS NOT NULL
    AND priority NOT IN
    ('Low', 'Medium', 'High', 'Critical');


-- Invalid issue status
SELECT *
FROM bronze.issues
WHERE status IS NOT NULL
    AND status NOT IN ('Open', 'Closed');


-- Invalid pull request review states
SELECT *
FROM bronze.pull_request_reviews
WHERE review_state IS NOT NULL
    AND review_state NOT IN
    ('Approved', 'Changes Requested', 'Commented');


-- =============================================================================
-- 9. EMAIL FORMAT VALIDATION
-- =============================================================================

SELECT *
FROM bronze.users
WHERE email IS NOT NULL
    AND email !~ '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$';


-- =============================================================================
-- 10. BRONZE LAYER VALIDATION SUMMARY
-- =============================================================================
-- Quick summary of the main data quality checks.

SELECT
    'NULL User IDs' AS validation_test,
    COUNT(*) AS issue_count
FROM bronze.users
WHERE user_id IS NULL

UNION ALL

SELECT
    'Duplicate User IDs',
    COUNT(*)
FROM (
    SELECT user_id
    FROM bronze.users
    GROUP BY user_id
    HAVING COUNT(*) > 1
) duplicates

UNION ALL

SELECT
    'Invalid Emails',
    COUNT(*)
FROM bronze.users
WHERE email IS NOT NULL
    AND email !~ '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$'

UNION ALL

SELECT
    'Negative Repository Size',
    COUNT(*)
FROM bronze.repositories
WHERE repository_size_mb < 0

UNION ALL

SELECT
    'Invalid Language Percentage',
    COUNT(*)
FROM bronze.repository_languages
WHERE percentage_used < 0
    OR percentage_used > 100

UNION ALL

SELECT
    'Invalid Repository Visibility',
    COUNT(*)
FROM bronze.repositories
WHERE visibility IS NOT NULL
    AND visibility NOT IN ('Public', 'Private')

UNION ALL

SELECT
    'Invalid Pull Request Status',
    COUNT(*)
FROM bronze.pull_requests
WHERE status IS NOT NULL
    AND status NOT IN ('Open', 'Closed', 'Merged')

UNION ALL

SELECT
    'Invalid Issue Status',
    COUNT(*)
FROM bronze.issues
WHERE status IS NOT NULL
    AND status NOT IN ('Open', 'Closed')

ORDER BY issue_count DESC;