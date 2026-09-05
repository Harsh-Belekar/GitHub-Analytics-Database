/*
===============================================================================
DDL Script: Create Gold Tables ( Dimensions & Facts )
===============================================================================
Script Purpose:
    This script creates Tables for the Gold layer in the GitHub data warehouse. 
    The Gold layer represents the final dimension and fact tables (Star Schema)
===============================================================================
*/

-- gold.dim_date  
DROP TABLE IF EXISTS gold.dim_date CASCADE;
CREATE TABLE gold.dim_date (
    date_key        INT PRIMARY KEY,      
    full_date       DATE NOT NULL,
    year            INT NOT NULL,
    quarter         INT NOT NULL,
    month           INT NOT NULL,
    month_name      VARCHAR(20) NOT NULL,
    day             INT NOT NULL,
    day_name        VARCHAR(20) NOT NULL,
    day_of_week     INT NOT NULL,
    week_of_year    INT NOT NULL,
    is_weekend      BOOLEAN NOT NULL
);

INSERT INTO gold.dim_date
SELECT
    TO_CHAR(d, 'YYYYMMDD')::INT,
    d,
    EXTRACT(YEAR FROM d)::INT,
    EXTRACT(QUARTER FROM d)::INT,
    EXTRACT(MONTH FROM d)::INT,
    TO_CHAR(d, 'Month'),
    EXTRACT(DAY FROM d)::INT,
    TO_CHAR(d, 'Day'),
    EXTRACT(ISODOW FROM d)::INT,
    EXTRACT(WEEK FROM d)::INT,
    EXTRACT(ISODOW FROM d) IN (6, 7)
FROM GENERATE_SERIES('2015-01-01'::DATE, '2027-12-31'::DATE, INTERVAL '1 day') AS d;


-- gold.dim_users
DROP TABLE IF EXISTS gold.dim_users CASCADE;
CREATE TABLE gold.dim_users (
    user_id               INT PRIMARY KEY,
    username              VARCHAR(100) NOT NULL,
    full_name             VARCHAR(200) NOT NULL,
    email                 VARCHAR(255) NOT NULL,
    country               VARCHAR(100) NOT NULL,
    city                  VARCHAR(100),
    company               VARCHAR(150),
    account_type          VARCHAR(30) NOT NULL,
    hireable              BOOLEAN,
    verified              BOOLEAN,
    followers             INT,
    following             INT,
    public_repos          INT,
    public_gists          INT,
    joined_platform_at    TIMESTAMP
);

-- gold.dim_organizations
DROP TABLE IF EXISTS gold.dim_organizations CASCADE;
CREATE TABLE gold.dim_organizations (
    organization_id           INT PRIMARY KEY,
    organization_name         VARCHAR(150) NOT NULL,
    organization_type         VARCHAR(50) NOT NULL,
    country                   VARCHAR(100) NOT NULL,
    city                      VARCHAR(100),
    industry                  VARCHAR(100) NOT NULL,
    verified                  BOOLEAN,
    total_repositories        INT,
    total_members             INT,
    organization_created_at   TIMESTAMP
);

-- gold.dim_languages
DROP TABLE IF EXISTS gold.dim_languages CASCADE;
CREATE TABLE gold.dim_languages (
    language_id           INT PRIMARY KEY,
    language_name         VARCHAR(100) NOT NULL,
    file_extension        VARCHAR(20) NOT NULL,
    language_type         VARCHAR(50) NOT NULL,
    first_release_year    INT NOT NULL,
    is_popular            BOOLEAN NOT NULL
);

-- gold.dim_repositories
DROP TABLE IF EXISTS gold.dim_repositories CASCADE;
CREATE TABLE gold.dim_repositories (
    repository_id               INT PRIMARY KEY,
    repository_name             VARCHAR(200) NOT NULL,
    owner_id                    INT NOT NULL,
    owner_username              VARCHAR(100) NOT NULL,
    organization_id             INT,
    organization_name           VARCHAR(150),
    primary_language_id         INT NOT NULL,
    primary_language_name       VARCHAR(100) NOT NULL,
    visibility                  VARCHAR(20) NOT NULL,
    license                     VARCHAR(100),
    repository_size_mb          DECIMAL(10, 2),
    has_issues                  BOOLEAN,
    has_wiki                    BOOLEAN,
    has_projects                BOOLEAN,
    archived                    BOOLEAN,
    ownership_type              VARCHAR(20) NOT NULL,
    created_at                  TIMESTAMP,
    updated_at                  TIMESTAMP
);

-- gold.dim_branches
DROP TABLE IF EXISTS gold.dim_branches CASCADE;
CREATE TABLE gold.dim_branches (
    branch_id                INT PRIMARY KEY,
    repository_id            INT NOT NULL,
    repository_name          VARCHAR(200) NOT NULL,
    branch_name              VARCHAR(100) NOT NULL,
    created_by               INT NOT NULL,
    created_by_username      VARCHAR(100) NOT NULL,
    is_default               BOOLEAN NOT NULL,
    created_at               TIMESTAMP
);

-- gold.fact_commits
DROP TABLE IF EXISTS gold.fact_commits CASCADE;
CREATE TABLE gold.fact_commits (
    commit_id               BIGINT PRIMARY KEY,
    commit_hash             VARCHAR(40) NOT NULL,
    repository_id           INT NOT NULL,
    branch_id               INT NOT NULL,
    user_id                 INT NOT NULL,
    commit_message          VARCHAR(500),
    files_changed           INT,
    lines_added             INT,
    lines_deleted           INT,
    total_lines_changed     INT,
    commit_timestamp        TIMESTAMP,
    date_key                INT
);

-- gold.fact_pull_requests
DROP TABLE IF EXISTS gold.fact_pull_requests CASCADE;
CREATE TABLE gold.fact_pull_requests (
    pull_request_id         INT PRIMARY KEY,
    repository_id           INT NOT NULL,
    author_id               INT NOT NULL,
    source_branch_id        INT NOT NULL,
    target_branch_id        INT NOT NULL,
    title                   VARCHAR(300),
    status                  VARCHAR(20),
    files_changed           INT,
    created_at              TIMESTAMP,
    merged_at               TIMESTAMP,
    hours_to_merge          NUMERIC(12, 2),
    date_key                INT
);

-- gold.fact_pull_request_reviews
DROP TABLE IF EXISTS gold.fact_pull_request_reviews CASCADE;
CREATE TABLE gold.fact_pull_request_reviews (
    review_id           INT PRIMARY KEY,
    pull_request_id     INT NOT NULL,
    repository_id       INT NOT NULL,
    reviewer_id         INT NOT NULL,
    pr_author_id        INT NOT NULL,
    review_state        VARCHAR(30),
    reviewed_at         TIMESTAMP,
    date_key            INT
);

-- gold.fact_issues
DROP TABLE IF EXISTS gold.fact_issues CASCADE;
CREATE TABLE gold.fact_issues (
    issue_id            INT PRIMARY KEY,
    repository_id       INT NOT NULL,
    user_id             INT NOT NULL,
    title               VARCHAR(300),
    issue_type          VARCHAR(30),
    priority            VARCHAR(20),
    status              VARCHAR(20),
    created_at          TIMESTAMP,
    closed_at           TIMESTAMP,
    hours_to_resolve    NUMERIC(12, 2),
    date_key            INT
);

-- gold.fact_releases
DROP TABLE IF EXISTS gold.fact_releases CASCADE;
CREATE TABLE gold.fact_releases (
    release_id                      INT PRIMARY KEY,
    repository_id                   INT NOT NULL,
    tag_name                        VARCHAR(50),
    version                         VARCHAR(50),
    release_title                   VARCHAR(300),
    published_by                    INT NOT NULL,
    published_at                    TIMESTAMP,
    major_version                   INT,
    minor_version                   INT,
    patch_version                   INT,
    release_type                    VARCHAR(10),
    previous_release_at             TIMESTAMP,
    days_since_previous_release     NUMERIC(10, 1),
    date_key                        INT
);

-- gold.fact_stars
DROP TABLE IF EXISTS gold.fact_stars CASCADE;
CREATE TABLE gold.fact_stars (
    star_id             BIGINT PRIMARY KEY,
    repository_id       INT NOT NULL,
    user_id             INT NOT NULL,
    starred_at          TIMESTAMP,
    date_key            INT
);

-- gold.fact_forks
DROP TABLE IF EXISTS gold.fact_forks CASCADE;
CREATE TABLE gold.fact_forks (
    fork_id                 BIGINT PRIMARY KEY,
    source_repository_id    INT NOT NULL,
    forked_repository_id    INT NOT NULL,
    user_id                 INT NOT NULL,
    forked_at               TIMESTAMP,
    date_key                INT
);

-- gold.fact_repository_contributors
DROP TABLE IF EXISTS gold.fact_repository_contributors CASCADE;
CREATE TABLE gold.fact_repository_contributors (
    contributor_id          INT PRIMARY KEY,
    repository_id           INT NOT NULL,
    user_id                 INT NOT NULL,
    total_commits           INT,
    first_commit_date       TIMESTAMP,
    last_commit_date        TIMESTAMP
);

-- gold.fact_repository_languages
DROP TABLE IF EXISTS gold.fact_repository_languages CASCADE;
CREATE TABLE gold.fact_repository_languages (
    repository_language_id      INT PRIMARY KEY,
    repository_id               INT NOT NULL,
    language_id                 INT NOT NULL,
    percentage_used             NUMERIC(5, 2)
);

-- gold.fact_organization_members
DROP TABLE IF EXISTS gold.fact_organization_members CASCADE;
CREATE TABLE gold.fact_organization_members (
    membership_id       INT PRIMARY KEY,
    organization_id     INT NOT NULL,
    user_id             INT NOT NULL,
    role                VARCHAR(30),
    joined_at           TIMESTAMP,
    is_public           BOOLEAN
);


-- Indexes
CREATE INDEX idx_gold_commits_repo         ON gold.fact_commits (repository_id);
CREATE INDEX idx_gold_commits_user         ON gold.fact_commits (user_id);
CREATE INDEX idx_gold_commits_date         ON gold.fact_commits (date_key);
CREATE INDEX idx_gold_prs_repo             ON gold.fact_pull_requests (repository_id);
CREATE INDEX idx_gold_prs_author           ON gold.fact_pull_requests (author_id);
CREATE INDEX idx_gold_prs_date             ON gold.fact_pull_requests (date_key);
CREATE INDEX idx_gold_reviews_repo         ON gold.fact_pull_request_reviews (repository_id);
CREATE INDEX idx_gold_reviews_reviewer     ON gold.fact_pull_request_reviews (reviewer_id);
CREATE INDEX idx_gold_issues_repo          ON gold.fact_issues (repository_id);
CREATE INDEX idx_gold_issues_user          ON gold.fact_issues (user_id);
CREATE INDEX idx_gold_issues_date          ON gold.fact_issues (date_key);
CREATE INDEX idx_gold_releases_repo        ON gold.fact_releases (repository_id);
CREATE INDEX idx_gold_stars_repo           ON gold.fact_stars (repository_id);
CREATE INDEX idx_gold_forks_source_repo    ON gold.fact_forks (source_repository_id);
CREATE INDEX idx_gold_contributors_repo    ON gold.fact_repository_contributors (repository_id);
CREATE INDEX idx_gold_repo_languages_repo  ON gold.fact_repository_languages (repository_id);
CREATE INDEX idx_gold_org_members_org      ON gold.fact_organization_members (organization_id);
CREATE INDEX idx_gold_dim_repos_org        ON gold.dim_repositories (organization_id);
CREATE INDEX idx_gold_dim_repos_owner      ON gold.dim_repositories (owner_id);
CREATE INDEX idx_gold_dim_branches_repo    ON gold.dim_branches (repository_id);
