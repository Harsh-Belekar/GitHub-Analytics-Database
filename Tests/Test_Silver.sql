-- =============================================================================
-- GitHub Analytics Database
-- Silver Layer Data Quality & Validation Tests
-- =============================================================================
-- Purpose:
--     Validate the structure, quality, integrity, and transformation of
--     Silver-layer tables after the Silver ETL process.
--
-- Layer:
--     Silver
--
-- Source:
--     Bronze -> Silver
--
-- Expected Result:
--     All validation queries should return 0 violations unless explicitly
--     documented otherwise.
-- =============================================================================


-- =============================================================================
-- SECTION 1: TABLE EXISTENCE TESTS
-- =============================================================================

-- Test 1.1: Check that all Silver tables exist
SELECT
    table_name
FROM information_schema.tables
WHERE table_schema = 'silver'
ORDER BY table_name;

-- Expected:
-- 15 Silver tables should exist.


-- Test 1.2: Count Silver tables
SELECT
    COUNT(*) AS silver_table_count
FROM information_schema.tables
WHERE table_schema = 'silver';

-- Expected:
-- silver_table_count = 15



-- =============================================================================
-- SECTION 2: ROW COUNT VALIDATION
-- =============================================================================
-- Silver should normally contain the same or fewer rows than Bronze because
-- duplicate/invalid records may be removed during transformation.


SELECT
    'programming_languages' AS table_name,
    (SELECT COUNT(*) FROM bronze.programming_languages) AS bronze_rows,
    (SELECT COUNT(*) FROM silver.programming_languages) AS silver_rows
UNION ALL
SELECT
    'users',
    (SELECT COUNT(*) FROM bronze.users),
    (SELECT COUNT(*) FROM silver.users)
UNION ALL
SELECT
    'organizations',
    (SELECT COUNT(*) FROM bronze.organizations),
    (SELECT COUNT(*) FROM silver.organizations)
UNION ALL
SELECT
    'organization_members',
    (SELECT COUNT(*) FROM bronze.organization_members),
    (SELECT COUNT(*) FROM silver.organization_members)
UNION ALL
SELECT
    'repositories',
    (SELECT COUNT(*) FROM bronze.repositories),
    (SELECT COUNT(*) FROM silver.repositories)
UNION ALL
SELECT
    'repository_languages',
    (SELECT COUNT(*) FROM bronze.repository_languages),
    (SELECT COUNT(*) FROM silver.repository_languages)
UNION ALL
SELECT
    'repository_contributors',
    (SELECT COUNT(*) FROM bronze.repository_contributors),
    (SELECT COUNT(*) FROM silver.repository_contributors)
UNION ALL
SELECT
    'branches',
    (SELECT COUNT(*) FROM bronze.branches),
    (SELECT COUNT(*) FROM silver.branches)
UNION ALL
SELECT
    'commits',
    (SELECT COUNT(*) FROM bronze.commits),
    (SELECT COUNT(*) FROM silver.commits)
UNION ALL
SELECT
    'pull_requests',
    (SELECT COUNT(*) FROM bronze.pull_requests),
    (SELECT COUNT(*) FROM silver.pull_requests)
UNION ALL
SELECT
    'pull_request_reviews',
    (SELECT COUNT(*) FROM bronze.pull_request_reviews),
    (SELECT COUNT(*) FROM silver.pull_request_reviews)
UNION ALL
SELECT
    'issues',
    (SELECT COUNT(*) FROM bronze.issues),
    (SELECT COUNT(*) FROM silver.issues)
UNION ALL
SELECT
    'releases',
    (SELECT COUNT(*) FROM bronze.releases),
    (SELECT COUNT(*) FROM silver.releases)
UNION ALL
SELECT
    'stars',
    (SELECT COUNT(*) FROM bronze.stars),
    (SELECT COUNT(*) FROM silver.stars)
UNION ALL
SELECT
    'forks',
    (SELECT COUNT(*) FROM bronze.forks),
    (SELECT COUNT(*) FROM silver.forks)
ORDER BY table_name;


-- Test 2.1: Check if Silver has more rows than Bronze
SELECT
    'programming_languages' AS table_name
WHERE
    (SELECT COUNT(*) FROM silver.programming_languages)
    >
    (SELECT COUNT(*) FROM bronze.programming_languages)

UNION ALL

SELECT
    'users'
WHERE
    (SELECT COUNT(*) FROM silver.users)
    >
    (SELECT COUNT(*) FROM bronze.users)

UNION ALL

SELECT
    'organizations'
WHERE
    (SELECT COUNT(*) FROM silver.organizations)
    >
    (SELECT COUNT(*) FROM bronze.organizations)

UNION ALL

SELECT
    'repositories'
WHERE
    (SELECT COUNT(*) FROM silver.repositories)
    >
    (SELECT COUNT(*) FROM bronze.repositories);

-- Expected:
-- 0 rows



-- =============================================================================
-- SECTION 3: PRIMARY KEY VALIDATION
-- =============================================================================
-- Verify that no NULL or duplicate primary keys exist.


-- Programming Languages
SELECT
    'programming_languages' AS table_name,
    COUNT(*) AS invalid_primary_keys
FROM silver.programming_languages
WHERE language_id IS NULL;


SELECT
    language_id,
    COUNT(*) AS duplicate_count
FROM silver.programming_languages
GROUP BY language_id
HAVING COUNT(*) > 1;


-- Users
SELECT
    'users' AS table_name,
    COUNT(*) AS invalid_primary_keys
FROM silver.users
WHERE user_id IS NULL;


SELECT
    user_id,
    COUNT(*) AS duplicate_count
FROM silver.users
GROUP BY user_id
HAVING COUNT(*) > 1;


-- Organizations
SELECT
    organization_id,
    COUNT(*) AS duplicate_count
FROM silver.organizations
GROUP BY organization_id
HAVING COUNT(*) > 1;


-- Repositories
SELECT
    repository_id,
    COUNT(*) AS duplicate_count
FROM silver.repositories
GROUP BY repository_id
HAVING COUNT(*) > 1;


-- Commits
SELECT
    commit_id,
    COUNT(*) AS duplicate_count
FROM silver.commits
GROUP BY commit_id
HAVING COUNT(*) > 1;


-- Pull Requests
SELECT
    pull_request_id,
    COUNT(*) AS duplicate_count
FROM silver.pull_requests
GROUP BY pull_request_id
HAVING COUNT(*) > 1;


-- Issues
SELECT
    issue_id,
    COUNT(*) AS duplicate_count
FROM silver.issues
GROUP BY issue_id
HAVING COUNT(*) > 1;


-- Releases
SELECT
    release_id,
    COUNT(*) AS duplicate_count
FROM silver.releases
GROUP BY release_id
HAVING COUNT(*) > 1;


-- Stars
SELECT
    star_id,
    COUNT(*) AS duplicate_count
FROM silver.stars
GROUP BY star_id
HAVING COUNT(*) > 1;


-- Forks
SELECT
    fork_id,
    COUNT(*) AS duplicate_count
FROM silver.forks
GROUP BY fork_id
HAVING COUNT(*) > 1;



-- =============================================================================
-- SECTION 4: UNIQUE CONSTRAINT VALIDATION
-- =============================================================================

-- Users: username must be unique
SELECT
    username,
    COUNT(*) AS duplicate_count
FROM silver.users
GROUP BY username
HAVING COUNT(*) > 1;


-- Users: email must be unique
SELECT
    email,
    COUNT(*) AS duplicate_count
FROM silver.users
GROUP BY email
HAVING COUNT(*) > 1;


-- Organizations: organization name must be unique
SELECT
    organization_name,
    COUNT(*) AS duplicate_count
FROM silver.organizations
GROUP BY organization_name
HAVING COUNT(*) > 1;


-- Repository: owner + repository name must be unique
SELECT
    owner_id,
    repository_name,
    COUNT(*) AS duplicate_count
FROM silver.repositories
GROUP BY owner_id, repository_name
HAVING COUNT(*) > 1;


-- Organization membership
SELECT
    organization_id,
    user_id,
    COUNT(*) AS duplicate_count
FROM silver.organization_members
GROUP BY organization_id, user_id
HAVING COUNT(*) > 1;


-- Repository languages
SELECT
    repository_id,
    language_id,
    COUNT(*) AS duplicate_count
FROM silver.repository_languages
GROUP BY repository_id, language_id
HAVING COUNT(*) > 1;


-- Repository contributors
SELECT
    repository_id,
    user_id,
    COUNT(*) AS duplicate_count
FROM silver.repository_contributors
GROUP BY repository_id, user_id
HAVING COUNT(*) > 1;


-- Branches
SELECT
    repository_id,
    branch_name,
    COUNT(*) AS duplicate_count
FROM silver.branches
GROUP BY repository_id, branch_name
HAVING COUNT(*) > 1;


-- Commits
SELECT
    commit_hash,
    COUNT(*) AS duplicate_count
FROM silver.commits
GROUP BY commit_hash
HAVING COUNT(*) > 1;


-- Releases
SELECT
    repository_id,
    version,
    COUNT(*) AS duplicate_count
FROM silver.releases
GROUP BY repository_id, version
HAVING COUNT(*) > 1;


-- Stars
SELECT
    repository_id,
    user_id,
    COUNT(*) AS duplicate_count
FROM silver.stars
GROUP BY repository_id, user_id
HAVING COUNT(*) > 1;



-- =============================================================================
-- SECTION 5: NULL VALIDATION
-- =============================================================================
-- Silver columns defined as NOT NULL should never contain NULL values.


-- Users
SELECT
    COUNT(*) AS invalid_users
FROM silver.users
WHERE
    user_id IS NULL
    OR first_name IS NULL
    OR last_name IS NULL
    OR username IS NULL
    OR email IS NULL
    OR country IS NULL
    OR hireable IS NULL
    OR verified IS NULL
    OR followers IS NULL
    OR following IS NULL
    OR public_repos IS NULL
    OR public_gists IS NULL
    OR account_type IS NULL
    OR profile_url IS NULL
    OR created_at IS NULL
    OR updated_at IS NULL;


-- Repositories
SELECT
    COUNT(*) AS invalid_repositories
FROM silver.repositories
WHERE
    repository_id IS NULL
    OR owner_id IS NULL
    OR repository_name IS NULL
    OR visibility IS NULL
    OR default_branch IS NULL
    OR primary_language_id IS NULL
    OR repository_size_mb IS NULL
    OR has_issues IS NULL
    OR has_wiki IS NULL
    OR has_projects IS NULL
    OR archived IS NULL
    OR created_at IS NULL
    OR updated_at IS NULL;


-- Commits
SELECT
    COUNT(*) AS invalid_commits
FROM silver.commits
WHERE
    commit_id IS NULL
    OR commit_hash IS NULL
    OR repository_id IS NULL
    OR branch_id IS NULL
    OR user_id IS NULL
    OR commit_message IS NULL
    OR files_changed IS NULL
    OR lines_added IS NULL
    OR lines_deleted IS NULL
    OR commit_timestamp IS NULL;


-- Pull Requests
SELECT
    COUNT(*) AS invalid_pull_requests
FROM silver.pull_requests
WHERE
    pull_request_id IS NULL
    OR repository_id IS NULL
    OR user_id IS NULL
    OR source_branch_id IS NULL
    OR target_branch_id IS NULL
    OR title IS NULL
    OR status IS NULL
    OR files_changed IS NULL
    OR created_at IS NULL;


-- Issues
SELECT
    COUNT(*) AS invalid_issues
FROM silver.issues
WHERE
    issue_id IS NULL
    OR repository_id IS NULL
    OR user_id IS NULL
    OR title IS NULL
    OR issue_type IS NULL
    OR priority IS NULL
    OR status IS NULL
    OR created_at IS NULL;


-- =============================================================================
-- SECTION 6: BUSINESS RULE VALIDATION
-- =============================================================================


-- Test 6.1: Repository visibility values
SELECT
    visibility,
    COUNT(*) AS record_count
FROM silver.repositories
GROUP BY visibility
ORDER BY visibility;

-- Expected:
-- Only Public / Private


-- Test 6.2: Invalid repository visibility
SELECT
    COUNT(*) AS invalid_visibility
FROM silver.repositories
WHERE visibility NOT IN ('Public', 'Private');

-- Expected:
-- 0


-- Test 6.3: Invalid pull request statuses
SELECT
    COUNT(*) AS invalid_pr_status
FROM silver.pull_requests
WHERE status NOT IN ('Open', 'Closed', 'Merged');

-- Expected:
-- 0


-- Test 6.4: Invalid issue types
SELECT
    COUNT(*) AS invalid_issue_types
FROM silver.issues
WHERE issue_type NOT IN
    ('Bug', 'Feature', 'Documentation', 'Enhancement');

-- Expected:
-- 0


-- Test 6.5: Invalid issue priorities
SELECT
    COUNT(*) AS invalid_issue_priorities
FROM silver.issues
WHERE priority NOT IN
    ('Low', 'Medium', 'High', 'Critical');

-- Expected:
-- 0


-- Test 6.6: Invalid issue statuses
SELECT
    COUNT(*) AS invalid_issue_status
FROM silver.issues
WHERE status NOT IN ('Open', 'Closed');

-- Expected:
-- 0


-- Test 6.7: Invalid review states
SELECT
    COUNT(*) AS invalid_review_states
FROM silver.pull_request_reviews
WHERE review_state NOT IN
    ('Approved', 'Changes Requested', 'Commented');

-- Expected:
-- 0



-- =============================================================================
-- SECTION 7: NUMERIC RANGE VALIDATION
-- =============================================================================


-- Repository size cannot be negative
SELECT
    COUNT(*) AS invalid_repository_size
FROM silver.repositories
WHERE repository_size_mb < 0;


-- Language percentage must be between 0 and 100
SELECT
    COUNT(*) AS invalid_language_percentage
FROM silver.repository_languages
WHERE percentage_used < 0
    OR percentage_used > 100;


-- Commit lines added cannot be negative
SELECT
    COUNT(*) AS invalid_lines_added
FROM silver.commits
WHERE lines_added < 0;


-- Commit lines deleted cannot be negative
SELECT
    COUNT(*) AS invalid_lines_deleted
FROM silver.commits
WHERE lines_deleted < 0;


-- Contributor commit count cannot be negative
SELECT
    COUNT(*) AS invalid_contributor_commits
FROM silver.repository_contributors
WHERE total_commits < 0;


-- User follower count cannot be negative
SELECT
    COUNT(*) AS invalid_followers
FROM silver.users
WHERE followers < 0;


-- User following count cannot be negative
SELECT
    COUNT(*) AS invalid_following
FROM silver.users
WHERE following < 0;


-- Public repositories cannot be negative
SELECT
    COUNT(*) AS invalid_public_repos
FROM silver.users
WHERE public_repos < 0;


-- Public gists cannot be negative
SELECT
    COUNT(*) AS invalid_public_gists
FROM silver.users
WHERE public_gists < 0;



-- =============================================================================
-- SECTION 8: DATE VALIDATION
-- =============================================================================


-- Repository updated date cannot be before creation date
SELECT
    COUNT(*) AS invalid_repository_dates
FROM silver.repositories
WHERE updated_at < created_at;


-- User updated date cannot be before creation date
SELECT
    COUNT(*) AS invalid_user_dates
FROM silver.users
WHERE updated_at < created_at;


-- Contributor last commit cannot be before first commit
SELECT
    COUNT(*) AS invalid_contributor_dates
FROM silver.repository_contributors
WHERE last_commit_date < first_commit_date;


-- Pull request merge cannot occur before creation
SELECT
    COUNT(*) AS invalid_pr_dates
FROM silver.pull_requests
WHERE merged_at IS NOT NULL
    AND merged_at < created_at;


-- Issue closure cannot occur before creation
SELECT
    COUNT(*) AS invalid_issue_dates
FROM silver.issues
WHERE closed_at IS NOT NULL
    AND closed_at < created_at;



-- =============================================================================
-- SECTION 9: REFERENTIAL INTEGRITY VALIDATION
-- =============================================================================
-- Silver DDL does not currently define FOREIGN KEY constraints, so these
-- queries explicitly validate the relationships.


-- Organization members -> Organizations
SELECT
    COUNT(*) AS orphan_organization_members
FROM silver.organization_members om
LEFT JOIN silver.organizations o
    ON o.organization_id = om.organization_id
WHERE o.organization_id IS NULL;


-- Organization members -> Users
SELECT
    COUNT(*) AS orphan_members_users
FROM silver.organization_members om
LEFT JOIN silver.users u
    ON u.user_id = om.user_id
WHERE u.user_id IS NULL;


-- Repository -> Owner
SELECT
    COUNT(*) AS orphan_repository_owners
FROM silver.repositories r
LEFT JOIN silver.users u
    ON u.user_id = r.owner_id
WHERE u.user_id IS NULL;


-- Repository -> Organization
SELECT
    COUNT(*) AS orphan_repository_organizations
FROM silver.repositories r
LEFT JOIN silver.organizations o
    ON o.organization_id = r.organization_id
WHERE r.organization_id IS NOT NULL
    AND o.organization_id IS NULL;


-- Repository -> Primary Language
SELECT
    COUNT(*) AS orphan_repository_languages
FROM silver.repositories r
LEFT JOIN silver.programming_languages l
    ON l.language_id = r.primary_language_id
WHERE l.language_id IS NULL;


-- Repository Languages -> Repository
SELECT
    COUNT(*) AS orphan_repository_language_repositories
FROM silver.repository_languages rl
LEFT JOIN silver.repositories r
    ON r.repository_id = rl.repository_id
WHERE r.repository_id IS NULL;


-- Repository Languages -> Programming Language
SELECT
    COUNT(*) AS orphan_repository_language_languages
FROM silver.repository_languages rl
LEFT JOIN silver.programming_languages l
    ON l.language_id = rl.language_id
WHERE l.language_id IS NULL;


-- Repository Contributors -> Repository
SELECT
    COUNT(*) AS orphan_contributor_repositories
FROM silver.repository_contributors rc
LEFT JOIN silver.repositories r
    ON r.repository_id = rc.repository_id
WHERE r.repository_id IS NULL;


-- Repository Contributors -> User
SELECT
    COUNT(*) AS orphan_contributor_users
FROM silver.repository_contributors rc
LEFT JOIN silver.users u
    ON u.user_id = rc.user_id
WHERE u.user_id IS NULL;


-- Branch -> Repository
SELECT
    COUNT(*) AS orphan_branches
FROM silver.branches b
LEFT JOIN silver.repositories r
    ON r.repository_id = b.repository_id
WHERE r.repository_id IS NULL;


-- Commit -> Repository
SELECT
    COUNT(*) AS orphan_commit_repositories
FROM silver.commits c
LEFT JOIN silver.repositories r
    ON r.repository_id = c.repository_id
WHERE r.repository_id IS NULL;


-- Commit -> Branch
SELECT
    COUNT(*) AS orphan_commit_branches
FROM silver.commits c
LEFT JOIN silver.branches b
    ON b.branch_id = c.branch_id
WHERE b.branch_id IS NULL;


-- Commit -> User
SELECT
    COUNT(*) AS orphan_commit_users
FROM silver.commits c
LEFT JOIN silver.users u
    ON u.user_id = c.user_id
WHERE u.user_id IS NULL;


-- Pull Request -> Repository
SELECT
    COUNT(*) AS orphan_pr_repositories
FROM silver.pull_requests pr
LEFT JOIN silver.repositories r
    ON r.repository_id = pr.repository_id
WHERE r.repository_id IS NULL;


-- Pull Request -> User
SELECT
    COUNT(*) AS orphan_pr_users
FROM silver.pull_requests pr
LEFT JOIN silver.users u
    ON u.user_id = pr.user_id
WHERE u.user_id IS NULL;


-- Pull Request Reviews -> Pull Request
SELECT
    COUNT(*) AS orphan_reviews_pr
FROM silver.pull_request_reviews rv
LEFT JOIN silver.pull_requests pr
    ON pr.pull_request_id = rv.pull_request_id
WHERE pr.pull_request_id IS NULL;


-- Pull Request Reviews -> Reviewer
SELECT
    COUNT(*) AS orphan_reviewers
FROM silver.pull_request_reviews rv
LEFT JOIN silver.users u
    ON u.user_id = rv.reviewer_id
WHERE u.user_id IS NULL;


-- Issues -> Repository
SELECT
    COUNT(*) AS orphan_issue_repositories
FROM silver.issues i
LEFT JOIN silver.repositories r
    ON r.repository_id = i.repository_id
WHERE r.repository_id IS NULL;


-- Issues -> User
SELECT
    COUNT(*) AS orphan_issue_users
FROM silver.issues i
LEFT JOIN silver.users u
    ON u.user_id = i.user_id
WHERE u.user_id IS NULL;


-- Releases -> Repository
SELECT
    COUNT(*) AS orphan_release_repositories
FROM silver.releases rel
LEFT JOIN silver.repositories r
    ON r.repository_id = rel.repository_id
WHERE r.repository_id IS NULL;


-- Releases -> Publisher
SELECT
    COUNT(*) AS orphan_release_publishers
FROM silver.releases rel
LEFT JOIN silver.users u
    ON u.user_id = rel.published_by
WHERE u.user_id IS NULL;


-- Stars -> Repository
SELECT
    COUNT(*) AS orphan_star_repositories
FROM silver.stars s
LEFT JOIN silver.repositories r
    ON r.repository_id = s.repository_id
WHERE r.repository_id IS NULL;


-- Stars -> User
SELECT
    COUNT(*) AS orphan_star_users
FROM silver.stars s
LEFT JOIN silver.users u
    ON u.user_id = s.user_id
WHERE u.user_id IS NULL;


-- Forks -> Source Repository
SELECT
    COUNT(*) AS orphan_fork_sources
FROM silver.forks f
LEFT JOIN silver.repositories r
    ON r.repository_id = f.source_repository_id
WHERE r.repository_id IS NULL;


-- Forks -> Forked Repository
SELECT
    COUNT(*) AS orphan_fork_targets
FROM silver.forks f
LEFT JOIN silver.repositories r
    ON r.repository_id = f.forked_repository_id
WHERE r.repository_id IS NULL;


-- Forks -> User
SELECT
    COUNT(*) AS orphan_fork_users
FROM silver.forks f
LEFT JOIN silver.users u
    ON u.user_id = f.user_id
WHERE u.user_id IS NULL;



-- =============================================================================
-- SECTION 10: EMAIL VALIDATION
-- =============================================================================

SELECT
    COUNT(*) AS invalid_emails
FROM silver.users
WHERE email !~ '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$';

-- Expected:
-- 0



-- =============================================================================
-- SECTION 11: TEXT CLEANING VALIDATION
-- =============================================================================


-- Usernames should not contain leading/trailing spaces
SELECT
    COUNT(*) AS usernames_with_spaces
FROM silver.users
WHERE username <> TRIM(username);


-- Emails should not contain spaces
SELECT
    COUNT(*) AS emails_with_spaces
FROM silver.users
WHERE email LIKE '% %';


-- Repository names should not contain leading/trailing spaces
SELECT
    COUNT(*) AS repository_names_with_spaces
FROM silver.repositories
WHERE repository_name <> TRIM(repository_name);


-- =============================================================================
-- SECTION 12: SILVER TRANSFORMATION VALIDATION
-- =============================================================================
-- Verify that important Bronze -> Silver transformations have occurred.


-- Email normalization check
SELECT
    COUNT(*) AS unnormalized_emails
FROM silver.users
WHERE email <> LOWER(email);


-- Boolean normalization
SELECT
    COUNT(*) AS invalid_boolean_users
FROM silver.users
WHERE hireable NOT IN (TRUE, FALSE)
    OR verified NOT IN (TRUE, FALSE);


-- Repository visibility normalization
SELECT
    visibility,
    COUNT(*) AS record_count
FROM silver.repositories
GROUP BY visibility
ORDER BY visibility;



-- =============================================================================
-- SECTION 13: BUSINESS LOGIC CROSS-CHECKS
-- =============================================================================


-- A repository marked as archived should not have an impossible state
-- such as a NULL creation timestamp.
SELECT
    COUNT(*) AS invalid_archived_repositories
FROM silver.repositories
WHERE archived = TRUE
    AND created_at IS NULL;


-- A merged pull request should have a merge timestamp
SELECT
    COUNT(*) AS merged_pr_without_merge_date
FROM silver.pull_requests
WHERE status = 'Merged'
    AND merged_at IS NULL;


-- A closed issue should have a closure timestamp
SELECT
    COUNT(*) AS closed_issue_without_close_date
FROM silver.issues
WHERE status = 'Closed'
    AND closed_at IS NULL;


-- =============================================================================
-- SECTION 14: SILVER LAYER SUMMARY
-- =============================================================================

SELECT
    'programming_languages' AS table_name,
    COUNT(*) AS row_count
FROM silver.programming_languages

UNION ALL
SELECT 'users', COUNT(*) FROM silver.users
UNION ALL
SELECT 'organizations', COUNT(*) FROM silver.organizations
UNION ALL
SELECT 'organization_members', COUNT(*) FROM silver.organization_members
UNION ALL
SELECT 'repositories', COUNT(*) FROM silver.repositories
UNION ALL
SELECT 'repository_languages', COUNT(*) FROM silver.repository_languages
UNION ALL
SELECT 'repository_contributors', COUNT(*) FROM silver.repository_contributors
UNION ALL
SELECT 'branches', COUNT(*) FROM silver.branches
UNION ALL
SELECT 'commits', COUNT(*) FROM silver.commits
UNION ALL
SELECT 'pull_requests', COUNT(*) FROM silver.pull_requests
UNION ALL
SELECT 'pull_request_reviews', COUNT(*) FROM silver.pull_request_reviews
UNION ALL
SELECT 'issues', COUNT(*) FROM silver.issues
UNION ALL
SELECT 'releases', COUNT(*) FROM silver.releases
UNION ALL
SELECT 'stars', COUNT(*) FROM silver.stars
UNION ALL
SELECT 'forks', COUNT(*) FROM silver.forks

ORDER BY table_name;
