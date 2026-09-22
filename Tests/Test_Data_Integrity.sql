-- =============================================================================
-- GitHub Analytics Database — Data Integrity Tests
-- =============================================================================
-- Script Purpose:
--     Validates referential integrity, relationship consistency,
--     duplicate relationships, orphan records, and cross-layer
--     data consistency across Bronze, Silver, and Gold.
--
-- Expected Result:
--     Every test should return 0 violations unless explicitly stated.
--
-- Layers:
--     Bronze -> Raw loaded data
--     Silver -> Cleaned and validated data
--     Gold   -> Business-ready dimensions, facts, and reporting tables
-- =============================================================================


-- =============================================================================
-- SECTION 1: SILVER PRIMARY KEY INTEGRITY
-- =============================================================================

-- Test 1: Duplicate Programming Language IDs
SELECT
    'silver.programming_languages' AS table_name,
    'Duplicate language_id' AS test_name,
    COUNT(*) AS violation_count
FROM (
    SELECT language_id
    FROM silver.programming_languages
    GROUP BY language_id
    HAVING COUNT(*) > 1
) t;


-- Test 2: Duplicate User IDs
SELECT
    'silver.users',
    'Duplicate user_id',
    COUNT(*)
FROM (
    SELECT user_id
    FROM silver.users
    GROUP BY user_id
    HAVING COUNT(*) > 1
) t;


-- Test 3: Duplicate Organization IDs
SELECT
    'silver.organizations',
    'Duplicate organization_id',
    COUNT(*)
FROM (
    SELECT organization_id
    FROM silver.organizations
    GROUP BY organization_id
    HAVING COUNT(*) > 1
) t;


-- Test 4: Duplicate Repository IDs
SELECT
    'silver.repositories',
    'Duplicate repository_id',
    COUNT(*)
FROM (
    SELECT repository_id
    FROM silver.repositories
    GROUP BY repository_id
    HAVING COUNT(*) > 1
) t;


-- Test 5: Duplicate Commit IDs
SELECT
    'silver.commits',
    'Duplicate commit_id',
    COUNT(*)
FROM (
    SELECT commit_id
    FROM silver.commits
    GROUP BY commit_id
    HAVING COUNT(*) > 1
) t;


-- Test 6: Duplicate Pull Request IDs
SELECT
    'silver.pull_requests',
    'Duplicate pull_request_id',
    COUNT(*)
FROM (
    SELECT pull_request_id
    FROM silver.pull_requests
    GROUP BY pull_request_id
    HAVING COUNT(*) > 1
) t;


-- Test 7: Duplicate Issue IDs
SELECT
    'silver.issues',
    'Duplicate issue_id',
    COUNT(*)
FROM (
    SELECT issue_id
    FROM silver.issues
    GROUP BY issue_id
    HAVING COUNT(*) > 1
) t;


-- =============================================================================
-- SECTION 2: SILVER FOREIGN-KEY / ORPHAN RECORD TESTS
-- =============================================================================

-- Test 8: Organization members referencing missing organizations
SELECT
    'silver.organization_members' AS table_name,
    'Orphan organization_id' AS test_name,
    COUNT(*) AS violation_count
FROM silver.organization_members om
LEFT JOIN silver.organizations o
    ON o.organization_id = om.organization_id
WHERE o.organization_id IS NULL;


-- Test 9: Organization members referencing missing users
SELECT
    'silver.organization_members',
    'Orphan user_id',
    COUNT(*)
FROM silver.organization_members om
LEFT JOIN silver.users u
    ON u.user_id = om.user_id
WHERE u.user_id IS NULL;


-- Test 10: Repositories referencing missing owners
SELECT
    'silver.repositories',
    'Orphan owner_id',
    COUNT(*)
FROM silver.repositories r
LEFT JOIN silver.users u
    ON u.user_id = r.owner_id
WHERE u.user_id IS NULL;


-- Test 11: Repositories referencing missing organizations
SELECT
    'silver.repositories',
    'Orphan organization_id',
    COUNT(*)
FROM silver.repositories r
LEFT JOIN silver.organizations o
    ON o.organization_id = r.organization_id
WHERE r.organization_id IS NOT NULL
    AND o.organization_id IS NULL;


-- Test 12: Repositories referencing missing primary languages
SELECT
    'silver.repositories',
    'Orphan primary_language_id',
    COUNT(*)
FROM silver.repositories r
LEFT JOIN silver.programming_languages pl
    ON pl.language_id = r.primary_language_id
WHERE pl.language_id IS NULL;


-- Test 13: Repository languages referencing missing repositories
SELECT
    'silver.repository_languages',
    'Orphan repository_id',
    COUNT(*)
FROM silver.repository_languages rl
LEFT JOIN silver.repositories r
    ON r.repository_id = rl.repository_id
WHERE r.repository_id IS NULL;


-- Test 14: Repository languages referencing missing languages
SELECT
    'silver.repository_languages',
    'Orphan language_id',
    COUNT(*)
FROM silver.repository_languages rl
LEFT JOIN silver.programming_languages pl
    ON pl.language_id = rl.language_id
WHERE pl.language_id IS NULL;


-- Test 15: Repository contributors referencing missing repositories
SELECT
    'silver.repository_contributors',
    'Orphan repository_id',
    COUNT(*)
FROM silver.repository_contributors rc
LEFT JOIN silver.repositories r
    ON r.repository_id = rc.repository_id
WHERE r.repository_id IS NULL;


-- Test 16: Repository contributors referencing missing users
SELECT
    'silver.repository_contributors',
    'Orphan user_id',
    COUNT(*)
FROM silver.repository_contributors rc
LEFT JOIN silver.users u
    ON u.user_id = rc.user_id
WHERE u.user_id IS NULL;


-- Test 17: Branches referencing missing repositories
SELECT
    'silver.branches',
    'Orphan repository_id',
    COUNT(*)
FROM silver.branches b
LEFT JOIN silver.repositories r
    ON r.repository_id = b.repository_id
WHERE r.repository_id IS NULL;


-- Test 18: Branches referencing missing users
SELECT
    'silver.branches',
    'Orphan created_by',
    COUNT(*)
FROM silver.branches b
LEFT JOIN silver.users u
    ON u.user_id = b.created_by
WHERE u.user_id IS NULL;


-- Test 19: Commits referencing missing repositories
SELECT
    'silver.commits',
    'Orphan repository_id',
    COUNT(*)
FROM silver.commits c
LEFT JOIN silver.repositories r
    ON r.repository_id = c.repository_id
WHERE r.repository_id IS NULL;


-- Test 20: Commits referencing missing branches
SELECT
    'silver.commits',
    'Orphan branch_id',
    COUNT(*)
FROM silver.commits c
LEFT JOIN silver.branches b
    ON b.branch_id = c.branch_id
WHERE b.branch_id IS NULL;


-- Test 21: Commits referencing missing users
SELECT
    'silver.commits',
    'Orphan user_id',
    COUNT(*)
FROM silver.commits c
LEFT JOIN silver.users u
    ON u.user_id = c.user_id
WHERE u.user_id IS NULL;


-- =============================================================================
-- SECTION 3: PULL REQUEST RELATIONSHIP INTEGRITY
-- =============================================================================

-- Test 22: Pull requests referencing missing repositories
SELECT
    'silver.pull_requests',
    'Orphan repository_id',
    COUNT(*)
FROM silver.pull_requests pr
LEFT JOIN silver.repositories r
    ON r.repository_id = pr.repository_id
WHERE r.repository_id IS NULL;


-- Test 23: Pull requests referencing missing users
SELECT
    'silver.pull_requests',
    'Orphan user_id',
    COUNT(*)
FROM silver.pull_requests pr
LEFT JOIN silver.users u
    ON u.user_id = pr.user_id
WHERE u.user_id IS NULL;


-- Test 24: Pull requests referencing missing source branches
SELECT
    'silver.pull_requests',
    'Orphan source_branch_id',
    COUNT(*)
FROM silver.pull_requests pr
LEFT JOIN silver.branches b
    ON b.branch_id = pr.source_branch_id
WHERE b.branch_id IS NULL;


-- Test 25: Pull requests referencing missing target branches
SELECT
    'silver.pull_requests',
    'Orphan target_branch_id',
    COUNT(*)
FROM silver.pull_requests pr
LEFT JOIN silver.branches b
    ON b.branch_id = pr.target_branch_id
WHERE b.branch_id IS NULL;


-- Test 26: Reviews referencing missing pull requests
SELECT
    'silver.pull_request_reviews',
    'Orphan pull_request_id',
    COUNT(*)
FROM silver.pull_request_reviews rv
LEFT JOIN silver.pull_requests pr
    ON pr.pull_request_id = rv.pull_request_id
WHERE pr.pull_request_id IS NULL;


-- Test 27: Reviews referencing missing reviewers
SELECT
    'silver.pull_request_reviews',
    'Orphan reviewer_id',
    COUNT(*)
FROM silver.pull_request_reviews rv
LEFT JOIN silver.users u
    ON u.user_id = rv.reviewer_id
WHERE u.user_id IS NULL;


-- =============================================================================
-- SECTION 4: ISSUE AND RELEASE INTEGRITY
-- =============================================================================

-- Test 28: Issues referencing missing repositories
SELECT
    'silver.issues',
    'Orphan repository_id',
    COUNT(*)
FROM silver.issues i
LEFT JOIN silver.repositories r
    ON r.repository_id = i.repository_id
WHERE r.repository_id IS NULL;


-- Test 29: Issues referencing missing users
SELECT
    'silver.issues',
    'Orphan user_id',
    COUNT(*)
FROM silver.issues i
LEFT JOIN silver.users u
    ON u.user_id = i.user_id
WHERE u.user_id IS NULL;


-- Test 30: Releases referencing missing repositories
SELECT
    'silver.releases',
    'Orphan repository_id',
    COUNT(*)
FROM silver.releases rel
LEFT JOIN silver.repositories r
    ON r.repository_id = rel.repository_id
WHERE r.repository_id IS NULL;


-- Test 31: Releases referencing missing publishing users
SELECT
    'silver.releases',
    'Orphan published_by',
    COUNT(*)
FROM silver.releases rel
LEFT JOIN silver.users u
    ON u.user_id = rel.published_by
WHERE u.user_id IS NULL;


-- =============================================================================
-- SECTION 5: STAR AND FORK INTEGRITY
-- =============================================================================

-- Test 32: Stars referencing missing repositories
SELECT
    'silver.stars',
    'Orphan repository_id',
    COUNT(*)
FROM silver.stars s
LEFT JOIN silver.repositories r
    ON r.repository_id = s.repository_id
WHERE r.repository_id IS NULL;


-- Test 33: Stars referencing missing users
SELECT
    'silver.stars',
    'Orphan user_id',
    COUNT(*)
FROM silver.stars s
LEFT JOIN silver.users u
    ON u.user_id = s.user_id
WHERE u.user_id IS NULL;


-- Test 34: Forks referencing missing source repositories
SELECT
    'silver.forks',
    'Orphan source_repository_id',
    COUNT(*)
FROM silver.forks f
LEFT JOIN silver.repositories r
    ON r.repository_id = f.source_repository_id
WHERE r.repository_id IS NULL;


-- Test 35: Forks referencing missing forked repositories
SELECT
    'silver.forks',
    'Orphan forked_repository_id',
    COUNT(*)
FROM silver.forks f
LEFT JOIN silver.repositories r
    ON r.repository_id = f.forked_repository_id
WHERE r.repository_id IS NULL;


-- Test 36: Forks referencing missing users
SELECT
    'silver.forks',
    'Orphan user_id',
    COUNT(*)
FROM silver.forks f
LEFT JOIN silver.users u
    ON u.user_id = f.user_id
WHERE u.user_id IS NULL;


-- =============================================================================
-- SECTION 6: CROSS-RELATIONSHIP BUSINESS RULE TESTS
-- =============================================================================

-- Test 37: Repository default branch consistency
-- Every repository marked with a default branch should have
-- exactly one branch marked as default.
SELECT
    'silver.repositories',
    'Repositories without exactly one default branch',
    COUNT(*)
FROM silver.repositories r
LEFT JOIN (
    SELECT
        repository_id,
        COUNT(*) FILTER (WHERE is_default = TRUE) AS default_branch_count
    FROM silver.branches
    GROUP BY repository_id
) b
    ON b.repository_id = r.repository_id
WHERE COALESCE(b.default_branch_count, 0) <> 1;


-- Test 38: Default branch name must exist
SELECT
    'silver.repositories',
    'Default branch name mismatch',
    COUNT(*)
FROM silver.repositories r
WHERE NOT EXISTS (
    SELECT 1
    FROM silver.branches b
    WHERE b.repository_id = r.repository_id
        AND b.branch_name = r.default_branch
);


-- Test 39: Commit branch must belong to the same repository
SELECT
    'silver.commits',
    'Commit branch belongs to another repository',
    COUNT(*)
FROM silver.commits c
JOIN silver.branches b
    ON b.branch_id = c.branch_id
WHERE b.repository_id <> c.repository_id;


-- Test 40: Pull request source branch must belong to repository
SELECT
    'silver.pull_requests',
    'Source branch belongs to another repository',
    COUNT(*)
FROM silver.pull_requests pr
JOIN silver.branches b
    ON b.branch_id = pr.source_branch_id
WHERE b.repository_id <> pr.repository_id;


-- Test 41: Pull request target branch must belong to repository
SELECT
    'silver.pull_requests',
    'Target branch belongs to another repository',
    COUNT(*)
FROM silver.pull_requests pr
JOIN silver.branches b
    ON b.branch_id = pr.target_branch_id
WHERE b.repository_id <> pr.repository_id;


-- =============================================================================
-- SECTION 7: REPOSITORY LANGUAGE INTEGRITY
-- =============================================================================

-- Test 42: Repository language percentages above 100%
SELECT
    'silver.repository_languages',
    'Repository language percentage exceeds 100',
    COUNT(*)
FROM (
    SELECT
        repository_id,
        SUM(percentage_used) AS total_percentage
    FROM silver.repository_languages
    GROUP BY repository_id
    HAVING SUM(percentage_used) > 100.01
) t;


-- Test 43: Repository language percentages below zero
SELECT
    'silver.repository_languages',
    'Negative language percentage',
    COUNT(*)
FROM silver.repository_languages
WHERE percentage_used < 0;


-- =============================================================================
-- SECTION 8: DATE / TEMPORAL INTEGRITY
-- =============================================================================

-- Test 44: Repository updated_at before created_at
SELECT
    'silver.repositories',
    'updated_at before created_at',
    COUNT(*)
FROM silver.repositories
WHERE updated_at < created_at;


-- Test 45: User updated_at before created_at
SELECT
    'silver.users',
    'updated_at before created_at',
    COUNT(*)
FROM silver.users
WHERE updated_at < created_at;


-- Test 46: Commit timestamp before repository creation
SELECT
    'silver.commits',
    'Commit before repository creation',
    COUNT(*)
FROM silver.commits c
JOIN silver.repositories r
    ON r.repository_id = c.repository_id
WHERE c.commit_timestamp < r.created_at;


-- Test 47: Star timestamp before repository creation
SELECT
    'silver.stars',
    'Star before repository creation',
    COUNT(*)
FROM silver.stars s
JOIN silver.repositories r
    ON r.repository_id = s.repository_id
WHERE s.starred_at < r.created_at;


-- Test 48: Release timestamp before repository creation
SELECT
    'silver.releases',
    'Release before repository creation',
    COUNT(*)
FROM silver.releases rel
JOIN silver.repositories r
    ON r.repository_id = rel.repository_id
WHERE rel.published_at < r.created_at;


-- =============================================================================
-- SECTION 9: GOLD DIMENSION / FACT INTEGRITY
-- =============================================================================

-- Test 49: Gold commits with missing repository dimension
SELECT
    'gold.fact_commits',
    'Fact commit without repository dimension',
    COUNT(*)
FROM gold.fact_commits fc
LEFT JOIN gold.dim_repositories dr
    ON dr.repository_id = fc.repository_id
WHERE dr.repository_id IS NULL;


-- Test 50: Gold commits with missing user dimension
SELECT
    'gold.fact_commits',
    'Fact commit without user dimension',
    COUNT(*)
FROM gold.fact_commits fc
LEFT JOIN gold.dim_users du
    ON du.user_id = fc.user_id
WHERE du.user_id IS NULL;


-- Test 51: Gold pull requests with missing repository
SELECT
    'gold.fact_pull_requests',
    'Fact PR without repository dimension',
    COUNT(*)
FROM gold.fact_pull_requests pr
LEFT JOIN gold.dim_repositories dr
    ON dr.repository_id = pr.repository_id
WHERE dr.repository_id IS NULL;


-- Test 52: Gold issues with missing repository
SELECT
    'gold.fact_issues',
    'Fact issue without repository dimension',
    COUNT(*)
FROM gold.fact_issues i
LEFT JOIN gold.dim_repositories dr
    ON dr.repository_id = i.repository_id
WHERE dr.repository_id IS NULL;


-- Test 53: Gold stars with missing repository
SELECT
    'gold.fact_stars',
    'Fact star without repository dimension',
    COUNT(*)
FROM gold.fact_stars s
LEFT JOIN gold.dim_repositories dr
    ON dr.repository_id = s.repository_id
WHERE dr.repository_id IS NULL;


-- Test 54: Gold releases with missing repository
SELECT
    'gold.fact_releases',
    'Fact release without repository dimension',
    COUNT(*)
FROM gold.fact_releases fr
LEFT JOIN gold.dim_repositories dr
    ON dr.repository_id = fr.repository_id
WHERE dr.repository_id IS NULL;


-- =============================================================================
-- SECTION 10: GOLD FACT DUPLICATE TESTS
-- =============================================================================

-- Test 55: Duplicate Gold commits
SELECT
    'gold.fact_commits',
    'Duplicate commit_id',
    COUNT(*)
FROM (
    SELECT commit_id
    FROM gold.fact_commits
    GROUP BY commit_id
    HAVING COUNT(*) > 1
) t;


-- Test 56: Duplicate Gold pull requests
SELECT
    'gold.fact_pull_requests',
    'Duplicate pull_request_id',
    COUNT(*)
FROM (
    SELECT pull_request_id
    FROM gold.fact_pull_requests
    GROUP BY pull_request_id
    HAVING COUNT(*) > 1
) t;


-- Test 57: Duplicate Gold issues
SELECT
    'gold.fact_issues',
    'Duplicate issue_id',
    COUNT(*)
FROM (
    SELECT issue_id
    FROM gold.fact_issues
    GROUP BY issue_id
    HAVING COUNT(*) > 1
) t;


-- Test 58: Duplicate Gold stars
SELECT
    'gold.fact_stars',
    'Duplicate star_id',
    COUNT(*)
FROM (
    SELECT star_id
    FROM gold.fact_stars
    GROUP BY star_id
    HAVING COUNT(*) > 1
) t;


-- =============================================================================
-- SECTION 11: CROSS-LAYER ROW CONSISTENCY
-- =============================================================================

-- Test 59: Silver users should not exceed Bronze users
SELECT
    'users' AS table_name,
    'Silver rows greater than Bronze rows' AS test_name,
    CASE
        WHEN (SELECT COUNT(*) FROM silver.users)
            > (SELECT COUNT(*) FROM bronze.users)
        THEN 1
        ELSE 0
    END AS violation_count;


-- Test 60: Silver repositories should not exceed Bronze repositories
SELECT
    'repositories',
    'Silver rows greater than Bronze rows',
    CASE
        WHEN (SELECT COUNT(*) FROM silver.repositories)
            > (SELECT COUNT(*) FROM bronze.repositories)
        THEN 1
        ELSE 0
    END;


-- Test 61: Silver commits should not exceed Bronze commits
SELECT
    'commits',
    'Silver rows greater than Bronze rows',
    CASE
        WHEN (SELECT COUNT(*) FROM silver.commits)
            > (SELECT COUNT(*) FROM bronze.commits)
        THEN 1
        ELSE 0
    END;


-- Test 62: Gold repositories should not exceed Silver repositories
SELECT
    'repositories',
    'Gold rows greater than Silver rows',
    CASE
        WHEN (SELECT COUNT(*) FROM gold.dim_repositories)
            > (SELECT COUNT(*) FROM silver.repositories)
        THEN 1
        ELSE 0
    END;


-- Test 63: Gold users should not exceed Silver users
SELECT
    'users',
    'Gold rows greater than Silver rows',
    CASE
        WHEN (SELECT COUNT(*) FROM gold.dim_users)
            > (SELECT COUNT(*) FROM silver.users)
        THEN 1
        ELSE 0
    END;


-- =============================================================================
-- SECTION 12: BUSINESS RELATIONSHIP CONSISTENCY
-- =============================================================================

-- Test 64: Organization repository count consistency
SELECT
    'gold.dim_organizations',
    'Organization repository count mismatch',
    COUNT(*)
FROM gold.dim_organizations o
LEFT JOIN (
    SELECT
        organization_id,
        COUNT(*) AS actual_repository_count
    FROM gold.dim_repositories
    WHERE organization_id IS NOT NULL
    GROUP BY organization_id
) r
    ON r.organization_id = o.organization_id
WHERE COALESCE(o.total_repositories, 0)
        <> COALESCE(r.actual_repository_count, 0);


-- Test 65: Organization member count consistency
SELECT
    'gold.dim_organizations',
    'Organization member count mismatch',
    COUNT(*)
FROM gold.dim_organizations o
LEFT JOIN (
    SELECT
        organization_id,
        COUNT(*) AS actual_member_count
    FROM silver.organization_members
    GROUP BY organization_id
) m
    ON m.organization_id = o.organization_id
WHERE COALESCE(o.total_members, 0)
        <> COALESCE(m.actual_member_count, 0);


-- =============================================================================
-- SECTION 13: FINAL INTEGRITY SUMMARY
-- =============================================================================

-- Overall orphan-record summary
SELECT
    'Organization Members' AS relationship,
    COUNT(*) AS orphan_count
FROM silver.organization_members om
LEFT JOIN silver.organizations o
    ON o.organization_id = om.organization_id
WHERE o.organization_id IS NULL

UNION ALL

SELECT
    'Repository Owners',
    COUNT(*)
FROM silver.repositories r
LEFT JOIN silver.users u
    ON u.user_id = r.owner_id
WHERE u.user_id IS NULL

UNION ALL

SELECT
    'Repository Languages',
    COUNT(*)
FROM silver.repository_languages rl
LEFT JOIN silver.repositories r
    ON r.repository_id = rl.repository_id
WHERE r.repository_id IS NULL

UNION ALL

SELECT
    'Commits',
    COUNT(*)
FROM silver.commits c
LEFT JOIN silver.repositories r
    ON r.repository_id = c.repository_id
WHERE r.repository_id IS NULL

UNION ALL

SELECT
    'Pull Requests',
    COUNT(*)
FROM silver.pull_requests pr
LEFT JOIN silver.repositories r
    ON r.repository_id = pr.repository_id
WHERE r.repository_id IS NULL

UNION ALL

SELECT
    'Issues',
    COUNT(*)
FROM silver.issues i
LEFT JOIN silver.repositories r
    ON r.repository_id = i.repository_id
WHERE r.repository_id IS NULL

UNION ALL

SELECT
    'Releases',
    COUNT(*)
FROM silver.releases rel
LEFT JOIN silver.repositories r
    ON r.repository_id = rel.repository_id
WHERE r.repository_id IS NULL

UNION ALL

SELECT
    'Stars',
    COUNT(*)
FROM silver.stars s
LEFT JOIN silver.repositories r
    ON r.repository_id = s.repository_id
WHERE r.repository_id IS NULL

UNION ALL

SELECT
    'Forks',
    COUNT(*)
FROM silver.forks f
LEFT JOIN silver.repositories r
    ON r.repository_id = f.source_repository_id
WHERE r.repository_id IS NULL;
