/*
===============================================================================
DDL Script: Create Silver Tables
===============================================================================
Script Purpose:
    This script creates tables in the 'silver' schema, dropping existing tables 
    if they already exist.
	Run this script to re-define the DDL structure of 'bronze' Tables
===============================================================================
*/

-- 1. programming_languages
DROP TABLE IF EXISTS silver.programming_languages CASCADE;
CREATE TABLE silver.programming_languages (
    language_id          INT PRIMARY KEY,
    language_name        VARCHAR(100) NOT NULL,
    file_extension       VARCHAR(20)  NOT NULL,
    language_type        VARCHAR(50)  NOT NULL,
    first_release_year   INT          NOT NULL,
    is_popular           BOOLEAN      NOT NULL,
    created_at           TIMESTAMP    NOT NULL,
    CONSTRAINT uq_languages_name UNIQUE (language_name)
);

-- 2. users 
DROP TABLE IF EXISTS silver.users CASCADE;
CREATE TABLE silver.users (
    user_id         INT PRIMARY KEY,
    first_name      VARCHAR(100) NOT NULL,
    last_name       VARCHAR(100) NOT NULL,
    username        VARCHAR(100) NOT NULL,
    email           VARCHAR(255) NOT NULL,
    country         VARCHAR(100) NOT NULL,
    city            VARCHAR(100),
    bio             TEXT,
    company         VARCHAR(150),
    hireable        BOOLEAN NOT NULL,
    verified        BOOLEAN NOT NULL,
    followers       INT NOT NULL,
    following       INT NOT NULL,
    public_repos    INT NOT NULL,
    public_gists    INT NOT NULL,
    account_type    VARCHAR(30) NOT NULL,
    avatar_url      VARCHAR(500),
    profile_url     VARCHAR(500) NOT NULL,
    created_at      TIMESTAMP NOT NULL,
    updated_at      TIMESTAMP NOT NULL,
    CONSTRAINT uq_users_username UNIQUE (username),
    CONSTRAINT uq_users_email UNIQUE (email)
);

-- 3. organizations
DROP TABLE IF EXISTS silver.organizations CASCADE;
CREATE TABLE silver.organizations (
    organization_id       INT PRIMARY KEY,
    organization_name     VARCHAR(150) NOT NULL,
    organization_type     VARCHAR(50)  NOT NULL,
    country               VARCHAR(100) NOT NULL,
    city                  VARCHAR(100),
    website               VARCHAR(255),
    email                 VARCHAR(255),
    industry              VARCHAR(100) NOT NULL,
    total_repositories    INT NOT NULL DEFAULT 0,
    total_members         INT NOT NULL DEFAULT 0,
    verified              BOOLEAN NOT NULL,
    created_at            TIMESTAMP NOT NULL,
    CONSTRAINT uq_organizations_name UNIQUE (organization_name)
);

-- 4. organization_members
DROP TABLE IF EXISTS silver.organization_members CASCADE;
CREATE TABLE silver.organization_members (
    membership_id       INT PRIMARY KEY,
    organization_id     INT NOT NULL,
    user_id             INT NOT NULL,
    role                VARCHAR(30) NOT NULL,
    joined_at           TIMESTAMP NOT NULL,
    is_public           BOOLEAN NOT NULL,
    CONSTRAINT uq_org_members_user_org UNIQUE (organization_id, user_id)
);

-- 5. repositories
DROP TABLE IF EXISTS silver.repositories CASCADE;
CREATE TABLE silver.repositories (
    repository_id            INT PRIMARY KEY,
    owner_id                 INT NOT NULL,
    organization_id          INT,
    repository_name          VARCHAR(200) NOT NULL,
    description              TEXT,
    visibility               VARCHAR(20) NOT NULL,
    default_branch           VARCHAR(50) NOT NULL,
    primary_language_id      INT NOT NULL,
    license                  VARCHAR(100),
    repository_size_mb       DECIMAL(10, 2) NOT NULL,
    has_issues               BOOLEAN NOT NULL,
    has_wiki                 BOOLEAN NOT NULL,
    has_projects             BOOLEAN NOT NULL,
    archived                 BOOLEAN NOT NULL,
    created_at               TIMESTAMP NOT NULL,
    updated_at               TIMESTAMP NOT NULL,
    CONSTRAINT uq_repositories_owner_name UNIQUE (owner_id, repository_name),
    CONSTRAINT chk_repositories_visibility CHECK (visibility IN ('Public', 'Private'))
);

-- 6. repository_languages
DROP TABLE IF EXISTS silver.repository_languages CASCADE;
CREATE TABLE silver.repository_languages (
    repository_language_id      INT PRIMARY KEY,
    repository_id               INT NOT NULL,
    language_id                 INT NOT NULL,
    percentage_used             DECIMAL(5, 2) NOT NULL,
    CONSTRAINT uq_repo_languages_repo_lang UNIQUE (repository_id, language_id),
    CONSTRAINT chk_repo_languages_pct CHECK (percentage_used >= 0 AND percentage_used <= 100)
);

-- 7. repository_contributors
DROP TABLE IF EXISTS silver.repository_contributors CASCADE;
CREATE TABLE silver.repository_contributors (
    contributor_id           INT PRIMARY KEY,
    repository_id            INT NOT NULL,
    user_id                  INT NOT NULL,
    total_commits            INT NOT NULL,
    first_commit_date        TIMESTAMP NOT NULL,
    last_commit_date         TIMESTAMP NOT NULL,
    CONSTRAINT uq_repo_contributors_repo_user UNIQUE (repository_id, user_id),
    CONSTRAINT chk_repo_contributors_dates CHECK (last_commit_date >= first_commit_date)
);

-- 8. branches
DROP TABLE IF EXISTS silver.branches CASCADE;
CREATE TABLE silver.branches (
    branch_id          INT PRIMARY KEY,
    repository_id      INT NOT NULL,
    branch_name        VARCHAR(100) NOT NULL,
    created_by         INT NOT NULL,
    is_default         BOOLEAN NOT NULL,
    created_at         TIMESTAMP NOT NULL,
    CONSTRAINT uq_branches_repo_name UNIQUE (repository_id, branch_name)
);

-- 9. commits
DROP TABLE IF EXISTS silver.commits CASCADE;
CREATE TABLE silver.commits (
    commit_id             BIGINT PRIMARY KEY,
    commit_hash           VARCHAR(40) NOT NULL,
    repository_id         INT NOT NULL,
    branch_id             INT NOT NULL,
    user_id               INT NOT NULL,
    commit_message        VARCHAR(500) NOT NULL,
    files_changed         INT NOT NULL,
    lines_added           INT NOT NULL,
    lines_deleted         INT NOT NULL,
    commit_timestamp      TIMESTAMP NOT NULL,
    CONSTRAINT uq_commits_hash UNIQUE (commit_hash),
    CONSTRAINT chk_commits_lines_added CHECK (lines_added >= 0),
    CONSTRAINT chk_commits_lines_deleted CHECK (lines_deleted >= 0)
);

-- 10. pull_requests
DROP TABLE IF EXISTS silver.pull_requests CASCADE;
CREATE TABLE silver.pull_requests (
    pull_request_id        INT PRIMARY KEY,
    repository_id          INT NOT NULL,
    user_id                INT NOT NULL,
    source_branch_id       INT NOT NULL,
    target_branch_id       INT NOT NULL,
    title                  VARCHAR(300) NOT NULL,
    status                 VARCHAR(20) NOT NULL,
    files_changed          INT NOT NULL,
    created_at             TIMESTAMP NOT NULL,
    merged_at              TIMESTAMP,
    CONSTRAINT chk_pr_status CHECK (status IN ('Open', 'Closed', 'Merged')),
    CONSTRAINT chk_pr_merged_after_created CHECK (merged_at IS NULL OR merged_at >= created_at)
);

-- 11. pull_request_reviews  
DROP TABLE IF EXISTS silver.pull_request_reviews CASCADE;
CREATE TABLE silver.pull_request_reviews (
    review_id            INT PRIMARY KEY,
    pull_request_id      INT NOT NULL,
    reviewer_id          INT NOT NULL,
    review_state         VARCHAR(30) NOT NULL,
    review_comment       TEXT,
    reviewed_at          TIMESTAMP NOT NULL,
    CONSTRAINT chk_review_state CHECK (review_state IN ('Approved', 'Changes Requested', 'Commented'))
);

-- 12. issues
DROP TABLE IF EXISTS silver.issues CASCADE;
CREATE TABLE silver.issues (
    issue_id            INT PRIMARY KEY,
    repository_id       INT NOT NULL,
    user_id             INT NOT NULL,
    title               VARCHAR(300) NOT NULL,
    issue_type          VARCHAR(30) NOT NULL,
    priority            VARCHAR(20) NOT NULL,
    status              VARCHAR(20) NOT NULL,
    created_at          TIMESTAMP NOT NULL,
    closed_at           TIMESTAMP,
    CONSTRAINT chk_issues_type CHECK (issue_type IN ('Bug', 'Feature', 'Documentation', 'Enhancement')),
    CONSTRAINT chk_issues_priority CHECK (priority IN ('Low', 'Medium', 'High', 'Critical')),
    CONSTRAINT chk_issues_status CHECK (status IN ('Open', 'Closed')),
    CONSTRAINT chk_issues_closed_after_created CHECK (closed_at IS NULL OR closed_at >= created_at)
);

-- 13. releases
DROP TABLE IF EXISTS silver.releases CASCADE;
CREATE TABLE silver.releases (
    release_id          INT PRIMARY KEY,
    repository_id       INT NOT NULL,
    tag_name            VARCHAR(50) NOT NULL,
    version             VARCHAR(50) NOT NULL,
    release_title       VARCHAR(300) NOT NULL,
    release_notes       TEXT,
    published_by        INT NOT NULL,
    published_at        TIMESTAMP NOT NULL,
    CONSTRAINT uq_releases_repo_version UNIQUE (repository_id, version)
);

-- 14. stars
DROP TABLE IF EXISTS silver.stars CASCADE;
CREATE TABLE silver.stars (
    star_id           BIGINT PRIMARY KEY,
    repository_id     INT NOT NULL,
    user_id           INT NOT NULL,
    starred_at        TIMESTAMP NOT NULL,
    CONSTRAINT uq_stars_repo_user UNIQUE (repository_id, user_id)
);

-- 15. forks
DROP TABLE IF EXISTS silver.forks CASCADE;
CREATE TABLE silver.forks (
    fork_id                  INT PRIMARY KEY,
    source_repository_id     INT NOT NULL,
    forked_repository_id     INT NOT NULL,
    user_id                  INT NOT NULL,
    forked_at                TIMESTAMP NOT NULL,
    CONSTRAINT chk_forks_source_ne_forked CHECK (source_repository_id <> forked_repository_id)
);