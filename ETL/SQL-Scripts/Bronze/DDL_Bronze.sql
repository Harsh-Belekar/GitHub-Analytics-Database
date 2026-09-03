/*
===============================================================================
GITHUB ANALYTICS DATABASE
DDL Script: Create Bronze Tables
===============================================================================
Script Purpose:
    This script creates tables in the 'bronze' schema, dropping existing tables 
    if they already exist.
	Run this script to re-define the DDL structure of 'bronze' Tables

Author       : Harsh Belekar
Project      : GitHub Analytics Data Pipeline
Pipeline     : Raw → Bronze → Silver → Gold
===============================================================================
*/

-- 1. programming_languages
DROP TABLE IF EXISTS bronze.programming_languages CASCADE;
CREATE TABLE bronze.programming_languages (
    language_id          INT,
    language_name        VARCHAR(100),
    file_extension       VARCHAR(20),
    language_type        VARCHAR(50),
    first_release_year   INT,
    is_popular           BOOLEAN,
    created_at           TIMESTAMP
);

-- 2. users 
DROP TABLE IF EXISTS bronze.users CASCADE;
CREATE TABLE bronze.users (
    user_id         INT,
    first_name      VARCHAR(100),
    last_name       VARCHAR(100),
    username        VARCHAR(100),
    email           VARCHAR(255),
    country         VARCHAR(100),
    city            VARCHAR(100),
    bio             TEXT,
    company         VARCHAR(150),
    hireable        BOOLEAN,
    verified        BOOLEAN,
    followers       INT,
    following       INT,
    public_repos    INT,
    public_gists    INT,
    account_type    VARCHAR(30),
    avatar_url      VARCHAR(500),
    profile_url     VARCHAR(500),
    created_at      TIMESTAMP,
    updated_at      TIMESTAMP
);

-- 3. organizations
DROP TABLE IF EXISTS bronze.organizations CASCADE;
CREATE TABLE bronze.organizations (
    organization_id       INT,
    organization_name     VARCHAR(150),
    organization_type     VARCHAR(50),
    country               VARCHAR(100),
    city                  VARCHAR(100),
    website               VARCHAR(255),
    email                 VARCHAR(255),
    industry              VARCHAR(100),
    total_repositories    INT,
    total_members         INT,
    verified              BOOLEAN,
    created_at            TIMESTAMP
);

-- 4. organization_members
DROP TABLE IF EXISTS bronze.organization_members CASCADE;
CREATE TABLE bronze.organization_members (
    membership_id       INT,
    organization_id     INT,
    user_id             INT,
    role                VARCHAR(30),
    joined_at           TIMESTAMP,
    is_public           BOOLEAN
);

-- 5. repositories
DROP TABLE IF EXISTS bronze.repositories CASCADE;
CREATE TABLE bronze.repositories (
    repository_id          INT,
    owner_id               INT,
    organization_id        FLOAT,
    repository_name        VARCHAR(200),
    description            TEXT,
    visibility             VARCHAR(20),
    default_branch         VARCHAR(50),
    primary_language_id    INT,
    license                VARCHAR(100),
    repository_size_mb     DECIMAL(10, 2),
    has_issues             BOOLEAN,
    has_wiki               BOOLEAN,
    has_projects           BOOLEAN,
    archived               BOOLEAN,
    created_at             TIMESTAMP,
    updated_at             TIMESTAMP
);

-- 6. repository_languages
DROP TABLE IF EXISTS bronze.repository_languages CASCADE;
CREATE TABLE bronze.repository_languages (
    repository_language_id    INT,
    repository_id             INT,
    language_id               INT,
    percentage_used           DECIMAL(5, 2)
);

-- 7. repository_contributors
DROP TABLE IF EXISTS bronze.repository_contributors CASCADE;
CREATE TABLE bronze.repository_contributors (
    contributor_id       INT,
    repository_id        INT,
    user_id              INT,
    total_commits        INT,
    first_commit_date    TIMESTAMP,
    last_commit_date     TIMESTAMP
);

-- 8. branches
DROP TABLE IF EXISTS bronze.branches CASCADE;
CREATE TABLE bronze.branches (
    branch_id        INT,
    repository_id    INT,
    branch_name      VARCHAR(100),
    created_by       INT,
    is_default       BOOLEAN,
    created_at       TIMESTAMP
);

-- 9. commits
DROP TABLE IF EXISTS bronze.commits CASCADE;
CREATE TABLE bronze.commits (
    commit_id           BIGINT,
    commit_hash         VARCHAR(40),
    repository_id       INT,
    branch_id           INT,
    user_id             INT,
    commit_message      VARCHAR(500),
    files_changed       INT,
    lines_added         INT,
    lines_deleted       INT,
    commit_timestamp    TIMESTAMP
);

-- 10. pull_requests
DROP TABLE IF EXISTS bronze.pull_requests CASCADE;
CREATE TABLE bronze.pull_requests (
    pull_request_id      INT,
    repository_id        INT,
    user_id              INT,
    source_branch_id     INT,
    target_branch_id     INT,
    title                VARCHAR(300),
    status               VARCHAR(20),
    files_changed        INT,
    created_at           TIMESTAMP,
    merged_at            TIMESTAMP
);

-- 11. pull_request_reviews  
DROP TABLE IF EXISTS bronze.pull_request_reviews CASCADE;
CREATE TABLE bronze.pull_request_reviews (
    review_id          INT,
    pull_request_id    INT,
    reviewer_id        INT,
    review_state       VARCHAR(30),
    review_comment     TEXT,
    reviewed_at        TIMESTAMP
);

-- 12. issues
DROP TABLE IF EXISTS bronze.issues CASCADE;
CREATE TABLE bronze.issues (
    issue_id        INT,
    repository_id   INT,
    user_id         INT,
    title           VARCHAR(300),
    issue_type      VARCHAR(30),
    priority        VARCHAR(20),
    status          VARCHAR(20),
    created_at      TIMESTAMP,
    closed_at       TIMESTAMP
);

-- 13. releases
DROP TABLE IF EXISTS bronze.releases CASCADE;
CREATE TABLE bronze.releases (
    release_id        INT,
    repository_id     INT,
    tag_name          VARCHAR(50),
    version           VARCHAR(50),
    release_title     VARCHAR(300),
    release_notes     TEXT,
    published_by      INT,
    published_at      TIMESTAMP
);

-- 14. stars
DROP TABLE IF EXISTS bronze.stars CASCADE;
CREATE TABLE bronze.stars (
    star_id         BIGINT,
    repository_id   INT,
    user_id         INT,
    starred_at      TIMESTAMP
);

-- 15. forks
DROP TABLE IF EXISTS bronze.forks CASCADE;
CREATE TABLE bronze.forks (
    fork_id                 INT,
    source_repository_id    INT,
    forked_repository_id    INT,
    user_id                 INT,
    forked_at               TIMESTAMP
);