# 🚀 GitHub Analytics Database - 📚 Data Catalog

---

## Overview

The Data Catalog documents every dataset used in the GitHub Analytics Database project. It provides a centralized reference for table definitions, primary keys, foreign keys, descriptions, and relationships.

This document serves as the source of truth for:

* Python Data Generation
* PostgreSQL Database Design
* Bronze → Silver → Gold ETL Pipeline
* SQL Analysis
* Power BI Dashboards

---

## Database Summary

| Layer               | Tables |
| ------------------- | ------ |
| Master Tables       | 3      |
| Transaction Tables  | 9      |
| Relationship Tables | 3      |
| Total Tables        | **15** |

---

## Table List

| No. | Table Name              | Category     | Description                                 |
| --: | ----------------------- | ------------ | ------------------------------------------- |
|   1 | programming_languages   | Master       | Stores supported programming languages.     |
|   2 | users                   | Master       | Stores GitHub user information.             |
|   3 | organizations           | Master       | Stores GitHub organizations.                |
|   4 | organization_members    | Relationship | Maps users to organizations.                |
|   5 | repositories            | Master       | Stores repository information.              |
|   6 | repository_languages    | Relationship | Maps repositories to programming languages. |
|   7 | repository_contributors | Relationship | Maps contributors to repositories.          |
|   8 | branches                | Transaction  | Repository branches.                        |
|   9 | commits                 | Transaction  | Commit history.                             |
|  10 | pull_requests           | Transaction  | Pull Requests.                              |
|  11 | pull_request_reviews    | Transaction  | Pull Request reviews.                       |
|  12 | issues                  | Transaction  | Repository issues.                          |
|  13 | releases                | Transaction  | Repository releases.                        |
|  14 | stars                   | Transaction  | Repository stars.                           |
|  15 | forks                   | Transaction  | Repository forks.                           |

---

## Table Details

## 1. programming_languages

### Purpose

Stores the master list of programming languages used by repositories.

### Table Information

| Property | Value |
|----------|-------|
| Layer | Bronze / Silver |
| Category | Dimension |
| Primary Key | language_id |
| Foreign Keys | None |
| Estimated Rows | 20 |
| Grain | One row per programming language |

### Columns

| Column | Type | Nullable | Key | Description | Example |
|---------|------|----------|-----|-------------|---------|
| language_id | INT | No | PK | Unique language identifier | 1 |
| language_name | VARCHAR(100) | No | | Programming language | Python |
| file_extension | VARCHAR(20) | No | | Default extension | .py |
| language_type | VARCHAR(50) | No | | Language category | Interpreted |
| first_release_year | INT | No | | Initial release year | 1991 |
| is_popular | BOOLEAN | No | | Popular language flag | TRUE |
| created_at | TIMESTAMP | No | | Dataset creation timestamp | 2026-08-07 12:00:00 |

---

## 2. users

### Purpose

Stores GitHub user profile information.

### Table Information

| Property | Value |
|----------|-------|
| Layer | Bronze / Silver |
| Category | Dimension |
| Primary Key | user_id |
| Foreign Keys | None |
| Estimated Rows | 5,000 |
| Grain | One row per GitHub user |

### Columns

| Column | Type | Nullable | Key | Description | Example |
|---------|------|----------|-----|-------------|---------|
| user_id | INT | No | PK | Unique user identifier | 1001 |
| first_name | VARCHAR(100) | No | | First name | Harsh |
| last_name | VARCHAR(100) | No | | Last name | Belekar |
| username | VARCHAR(100) | No | | GitHub username | harsh_belekar |
| email | VARCHAR(255) | No | | Email address | harsh@gmail.com |
| country | VARCHAR(100) | No | | Country | India |
| city | VARCHAR(100) | Yes | | City | Mumbai |
| bio | TEXT | Yes | | User biography | Data Engineer |
| company | VARCHAR(150) | Yes | | Company name | OpenAI |
| hireable | BOOLEAN | No | | Hireable status | TRUE |
| verified | BOOLEAN | No | | Verified account | FALSE |
| followers | INT | No | | Followers count | 520 |
| following | INT | No | | Following count | 178 |
| public_repos | INT | No | | Public repositories | 32 |
| public_gists | INT | No | | Public gists | 8 |
| account_type | VARCHAR(30) | No | | User type | User |
| avatar_url | VARCHAR(500) | Yes | | Avatar URL | https://avatars.githubusercontent.com/u/1001 |
| profile_url | VARCHAR(500) | No | | GitHub profile URL | https://github.com/harsh_belekar |
| created_at | TIMESTAMP | No | | Account creation timestamp | 2024-03-14 10:20:00 |
| updated_at | TIMESTAMP | No | | Last profile update | 2026-07-22 18:40:00 |

---

## 3. organizations

## Purpose

Stores GitHub organizations that own repositories and manage members.

## Table Information

| Property | Value |
|----------|-------|
| Layer | Bronze / Silver |
| Category | Dimension |
| Primary Key | organization_id |
| Foreign Keys | None |
| Estimated Rows | 300 |
| Grain | One row per organization |

### Columns

| Column | Type | Nullable | Key | Description | Example |
|---------|------|----------|-----|-------------|---------|
| organization_id | INT | No | PK | Unique organization identifier | 201 |
| organization_name | VARCHAR(150) | No | | Organization name | OpenAI |
| organization_type | VARCHAR(50) | No | | Organization category | Company |
| country | VARCHAR(100) | No | | Country | USA |
| city | VARCHAR(100) | Yes | | City | San Francisco |
| website | VARCHAR(255) | Yes | | Official website | https://openai.com |
| email | VARCHAR(255) | Yes | | Contact email | info@openai.com |
| industry | VARCHAR(100) | No | | Industry | Artificial Intelligence |
| total_repositories | INT | No | | Repository count | 128 |
| total_members | INT | No | | Member count | 640 |
| verified | BOOLEAN | No | | Verified organization | TRUE |
| created_at | TIMESTAMP | No | | Organization creation timestamp | 2021-05-01 09:15:00 |


---

## 4. organization_members

### Purpose

Stores the membership relationship between GitHub users and organizations.

A user can belong to multiple organizations, and an organization can have multiple users. This table resolves the many-to-many relationship.

### Table Information

| Property | Value |
|----------|-------|
| Layer | Bronze / Silver |
| Category | Bridge Table |
| Primary Key | membership_id |
| Foreign Keys | organization_id → organizations.organization_id<br>user_id → users.user_id |
| Estimated Rows | 8,000 |
| Grain | One row per organization membership |

### Business Rules

- Every membership must belong to one organization.
- Every membership must reference one user.
- A user cannot have duplicate memberships within the same organization.
- Organization owners are unique per organization.

### Columns

| Column | Type | Nullable | Key | Description | Example |
|---------|------|----------|-----|-------------|---------|
| membership_id | INT | No | PK | Membership identifier | 5001 |
| organization_id | INT | No | FK | Organization identifier | 25 |
| user_id | INT | No | FK | User identifier | 1045 |
| role | VARCHAR(30) | No | | Member role | Owner |
| joined_at | TIMESTAMP | No | | Membership creation date | 2025-02-18 14:22:11 |
| is_public | BOOLEAN | No | | Public organization membership | TRUE |

---

## 5. repositories

### Purpose

Stores GitHub repositories owned by either individual users or organizations.

Repositories represent the central entity of the GitHub Analytics Database. Nearly every transactional table references repositories.

### Table Information

| Property | Value |
|----------|-------|
| Layer | Bronze / Silver |
| Category | Dimension |
| Primary Key | repository_id |
| Foreign Keys | owner_id → users.user_id<br>organization_id → organizations.organization_id<br>primary_language_id → programming_languages.language_id |
| Estimated Rows | 12,000 |
| Grain | One row per repository |

### Business Rules

- Every repository has exactly one owner.
- A repository may optionally belong to an organization.
- Every repository has one primary programming language.
- Repository names are unique within the same owner.
- Repository visibility is either Public or Private.

### Columns

| Column | Type | Nullable | Key | Description | Example |
|---------|------|----------|-----|-------------|---------|
| repository_id | INT | No | PK | Repository identifier | 12045 |
| owner_id | INT | No | FK | Repository owner | 1050 |
| organization_id | INT | Yes | FK | Owning organization | 31 |
| repository_name | VARCHAR(200) | No | | Repository name | github-analytics |
| description | TEXT | Yes | | Repository description | GitHub Analytics Data Warehouse |
| visibility | VARCHAR(20) | No | | Repository visibility | Public |
| default_branch | VARCHAR(50) | No | | Default branch | main |
| primary_language_id | INT | No | FK | Primary language | 1 |
| license | VARCHAR(100) | Yes | | Repository license | MIT |
| repository_size_mb | DECIMAL(10,2) | No | | Repository size | 425.50 |
| has_issues | BOOLEAN | No | | Issues enabled | TRUE |
| has_wiki | BOOLEAN | No | | Wiki enabled | TRUE |
| has_projects | BOOLEAN | No | | Projects enabled | FALSE |
| archived | BOOLEAN | No | | Archived repository | FALSE |
| created_at | TIMESTAMP | No | | Repository creation date | 2024-06-10 15:18:33 |
| updated_at | TIMESTAMP | No | | Last update | 2026-07-19 11:52:07 |


---

## 6. repository_languages

### Purpose

Stores the programming language distribution of each repository.

GitHub repositories frequently contain multiple programming languages. This table resolves the many-to-many relationship between repositories and programming languages.

### Table Information

| Property | Value |
|----------|-------|
| Layer | Bronze / Silver |
| Category | Bridge Table |
| Primary Key | repository_language_id |
| Foreign Keys | repository_id → repositories.repository_id<br>language_id → programming_languages.language_id |
| Estimated Rows | 20,000 |
| Grain | One row per repository-language combination |

### Business Rules

- Every record references one repository.
- Every record references one programming language.
- A repository cannot contain duplicate language records.
- Percentages for one repository should total approximately 100%.

### Columns

| Column | Type | Nullable | Key | Description | Example |
|---------|------|----------|-----|-------------|---------|
| repository_language_id | INT | No | PK | Repository language identifier | 80025 |
| repository_id | INT | No | FK | Repository identifier | 12045 |
| language_id | INT | No | FK | Programming language identifier | 1 |
| percentage_used | DECIMAL(5,2) | No | | Percentage of repository code | 76.40 |

---

## 7. repository_contributors

### Purpose

Stores contributor information for each repository.

A repository can have multiple contributors, and a user can contribute to multiple repositories. This bridge table tracks contribution statistics.

### Table Information

| Property | Value |
|----------|-------|
| Layer | Bronze / Silver |
| Category | Bridge Table |
| Primary Key | contributor_id |
| Foreign Keys | repository_id → repositories.repository_id<br>user_id → users.user_id |
| Estimated Rows | 60,000 |
| Grain | One row per repository contributor |

### Business Rules

- Every contributor belongs to one repository.
- Every contributor references one GitHub user.
- A repository cannot contain duplicate contributors.
- Last commit date must be greater than or equal to first commit date.

### Columns

| Column | Type | Nullable | Key | Description | Example |
|---------|------|----------|-----|-------------|---------|
| contributor_id | INT | No | PK | Unique contributor record | 100501 |
| repository_id | INT | No | FK | Repository identifier | 12045 |
| user_id | INT | No | FK | Contributor identifier | 2045 |
| total_commits | INT | No | | Total commits made | 342 |
| first_commit_date | TIMESTAMP | No | | First contribution date | 2024-02-15 09:20:00 |
| last_commit_date | TIMESTAMP | No | | Most recent contribution | 2026-07-20 16:42:10 |

---

## 8. branches

### Purpose

Stores repository branches used for software development.

Each repository contains one or more branches. Commits and pull requests are linked to branches.

### Table Information

| Property | Value |
|----------|-------|
| Layer | Bronze / Silver |
| Category | Dimension |
| Primary Key | branch_id |
| Foreign Keys | repository_id → repositories.repository_id<br>created_by → users.user_id |
| Estimated Rows | 45,000 |
| Grain | One row per repository branch |

### Business Rules

- Every branch belongs to one repository.
- Every repository has exactly one default branch.
- Branch names are unique within the same repository.

### Columns

| Column | Type | Nullable | Key | Description | Example |
|---------|------|----------|-----|-------------|---------|
| branch_id | INT | No | PK | Branch identifier | 90001 |
| repository_id | INT | No | FK | Repository identifier | 12045 |
| branch_name | VARCHAR(100) | No | | Branch name | feature/dashboard |
| created_by | INT | No | FK | User who created branch | 1025 |
| is_default | BOOLEAN | No | | Default branch flag | FALSE |
| created_at | TIMESTAMP | No | | Branch creation timestamp | 2025-04-10 11:30:42 |

---

## 9. commits

### Purpose

Stores every commit made within repositories.

This is the largest transactional table in the database and records all code changes made by contributors.

### Table Information

| Property | Value |
|----------|-------|
| Layer | Bronze / Silver |
| Category | Fact Table |
| Primary Key | commit_id |
| Foreign Keys | repository_id → repositories.repository_id<br>branch_id → branches.branch_id<br>user_id → users.user_id |
| Estimated Rows | 500,000 |
| Grain | One row per commit |

### Business Rules

- Every commit belongs to one repository.
- Every commit belongs to one branch.
- Every commit is authored by one user.
- Commit hash must be unique.
- Lines added and deleted cannot be negative.

### Columns

| Column | Type | Nullable | Key | Description | Example |
|---------|------|----------|-----|-------------|---------|
| commit_id | BIGINT | No | PK | Commit identifier | 5000001 |
| commit_hash | VARCHAR(40) | No | | SHA-1 commit hash | 8f3d92a8e9f1bc7e3d2c... |
| repository_id | INT | No | FK | Repository identifier | 12045 |
| branch_id | INT | No | FK | Branch identifier | 90001 |
| user_id | INT | No | FK | Commit author | 2045 |
| commit_message | VARCHAR(500) | No | | Commit message | Fix authentication bug |
| files_changed | INT | No | | Number of modified files | 8 |
| lines_added | INT | No | | Total lines added | 145 |
| lines_deleted | INT | No | | Total lines deleted | 38 |
| commit_timestamp | TIMESTAMP | No | | Commit date and time | 2026-07-15 14:18:25 |

---

## 10. pull_requests

### Purpose

Stores pull requests created by users to propose changes from one branch to another.

Pull requests are central to collaborative software development and track the lifecycle of code changes from creation to merge or closure.

### Table Information

| Property | Value |
|----------|-------|
| Layer | Bronze / Silver |
| Category | Fact Table |
| Primary Key | pull_request_id |
| Foreign Keys | repository_id → repositories.repository_id<br>user_id → users.user_id<br>source_branch_id → branches.branch_id<br>target_branch_id → branches.branch_id |
| Estimated Rows | 80,000 |
| Grain | One row per pull request |

### Business Rules

- Every pull request belongs to one repository.
- Every pull request is created by one user.
- Every pull request has one source branch.
- Every pull request has one target branch.
- A pull request can only be merged once.
- A closed pull request may or may not be merged.

### Columns

| Column | Type | Nullable | Key | Description | Example |
|---------|------|----------|-----|-------------|---------|
| pull_request_id | INT | No | PK | Pull request identifier | 300001 |
| repository_id | INT | No | FK | Repository identifier | 12045 |
| user_id | INT | No | FK | Pull request creator | 2045 |
| source_branch_id | INT | No | FK | Source branch | 90008 |
| target_branch_id | INT | No | FK | Target branch | 90001 |
| title | VARCHAR(300) | No | | Pull request title | Add dashboard filters |
| status | VARCHAR(20) | No | | Open / Closed / Merged | Merged |
| files_changed | INT | No | | Files modified | 12 |
| created_at | TIMESTAMP | No | | PR creation timestamp | 2026-05-10 11:45:21 |
| merged_at | TIMESTAMP | Yes | | Merge timestamp | 2026-05-11 09:20:44 |

---

## 11. pull_request_reviews

### Purpose

Stores review activities performed on pull requests.

Each review represents feedback provided by a reviewer before a pull request is merged or closed.

### Table Information

| Property | Value |
|----------|-------|
| Layer | Bronze / Silver |
| Category | Fact Table |
| Primary Key | review_id |
| Foreign Keys | pull_request_id → pull_requests.pull_request_id<br>reviewer_id → users.user_id |
| Estimated Rows | 120,000 |
| Grain | One row per pull request review |

### Business Rules

- Every review belongs to one pull request.
- Every review is submitted by one reviewer.
- A pull request can receive multiple reviews.
- Review timestamps must be after pull request creation.

### Columns

| Column | Type | Nullable | Key | Description | Example |
|---------|------|----------|-----|-------------|---------|
| review_id | INT | No | PK | Review identifier | 500120 |
| pull_request_id | INT | No | FK | Pull request identifier | 300001 |
| reviewer_id | INT | No | FK | Reviewer identifier | 1024 |
| review_state | VARCHAR(30) | No | | Approved / Changes Requested / Commented | Approved |
| review_comment | TEXT | Yes | | Review feedback | Looks good. Ready to merge. |
| reviewed_at | TIMESTAMP | No | | Review timestamp | 2026-05-10 16:25:32 |

---

## 12. issues

### Purpose

Stores repository issues used to track bugs, feature requests, documentation tasks, and enhancements.

Issues represent work items created by users and managed throughout the development lifecycle.

### Table Information

| Property | Value |
|----------|-------|
| Layer | Bronze / Silver |
| Category | Fact Table |
| Primary Key | issue_id |
| Foreign Keys | repository_id → repositories.repository_id<br>user_id → users.user_id |
| Estimated Rows | 100,000 |
| Grain | One row per issue |

### Business Rules

- Every issue belongs to one repository.
- Every issue is created by one user.
- Closed date cannot occur before created date.
- Issue status must match the issue lifecycle.

### Columns

| Column | Type | Nullable | Key | Description | Example |
|---------|------|----------|-----|-------------|---------|
| issue_id | INT | No | PK | Issue identifier | 400105 |
| repository_id | INT | No | FK | Repository identifier | 12045 |
| user_id | INT | No | FK | Issue creator | 2045 |
| title | VARCHAR(300) | No | | Issue title | Dashboard export not working |
| issue_type | VARCHAR(30) | No | | Bug / Feature / Documentation / Enhancement | Bug |
| priority | VARCHAR(20) | No | | Low / Medium / High / Critical | High |
| status | VARCHAR(20) | No | | Open / Closed | Closed |
| created_at | TIMESTAMP | No | | Issue creation timestamp | 2026-06-01 10:30:14 |
| closed_at | TIMESTAMP | Yes | | Issue closing timestamp | 2026-06-03 15:42:55 |

---

## 13. releases

### Purpose

Stores software releases published for repositories.

A release represents a stable software version associated with a Git tag and contains release notes describing new features, bug fixes, and improvements.

### Table Information

| Property | Value |
|----------|-------|
| Layer | Bronze / Silver |
| Category | Fact Table |
| Primary Key | release_id |
| Foreign Keys | repository_id → repositories.repository_id<br>published_by → users.user_id |
| Estimated Rows | 25,000 |
| Grain | One row per repository release |

### Business Rules

- Every release belongs to one repository.
- Every release is published by one user.
- Every repository can have multiple releases.
- Release version should be unique within a repository.

### Columns

| Column | Type | Nullable | Key | Description | Example |
|---------|------|----------|-----|-------------|---------|
| release_id | INT | No | PK | Release identifier | 80001 |
| repository_id | INT | No | FK | Repository identifier | 12045 |
| tag_name | VARCHAR(50) | No | | Git tag | v2.1.0 |
| version | VARCHAR(50) | No | | Release version | 2.1.0 |
| release_title | VARCHAR(300) | No | | Release title | Stable Release 2.1 |
| release_notes | TEXT | Yes | | Release notes | Performance improvements and bug fixes |
| published_by | INT | No | FK | Publisher | 1045 |
| published_at | TIMESTAMP | No | | Publication timestamp | 2026-07-12 10:18:42 |

---

## 14. stars

### Purpose

Stores repository stars given by GitHub users.

Stars represent community appreciation and repository popularity.

### Table Information

| Property | Value |
|----------|-------|
| Layer | Bronze / Silver |
| Category | Fact Table |
| Primary Key | star_id |
| Foreign Keys | repository_id → repositories.repository_id<br>user_id → users.user_id |
| Estimated Rows | 900,000 |
| Grain | One row per repository star |

### Business Rules

- Every star belongs to one repository.
- Every star is given by one user.
- A user can star a repository only once.
- Repository owner cannot star their own repository.

### Columns

| Column | Type | Nullable | Key | Description | Example |
|---------|------|----------|-----|-------------|---------|
| star_id | BIGINT | No | PK | Star identifier | 1000001 |
| repository_id | INT | No | FK | Repository identifier | 12045 |
| user_id | INT | No | FK | User who starred repository | 2301 |
| starred_at | TIMESTAMP | No | | Star timestamp | 2026-06-18 18:45:12 |

---

## 15. forks

### Purpose

Stores repository fork events.

Forks represent copies of repositories created by users for independent development.

### Table Information

| Property | Value |
|----------|-------|
| Layer | Bronze / Silver |
| Category | Fact Table |
| Primary Key | fork_id |
| Foreign Keys | source_repository_id → repositories.repository_id<br>forked_repository_id → repositories.repository_id<br>user_id → users.user_id |
| Estimated Rows | 150,000 |
| Grain | One row per repository fork |

### Business Rules

- Every fork references one source repository.
- Every fork creates one new repository.
- Every fork belongs to one user.
- A repository cannot be forked into itself.

### Columns

| Column | Type | Nullable | Key | Description | Example |
|---------|------|----------|-----|-------------|---------|
| fork_id | BIGINT | No | PK | Fork identifier | 700001 |
| source_repository_id | INT | No | FK | Original repository | 12045 |
| forked_repository_id | INT | No | FK | Newly created repository | 22045 |
| user_id | INT | No | FK | User performing the fork | 3302 |
| forked_at | TIMESTAMP | No | | Fork timestamp | 2026-03-20 14:32:51 |

---

# Entity Relationship Summary

| Parent Table          | Child Table             | Relationship |
| --------------------- | ----------------------- | ------------ |
| programming_languages | repository_languages    | One-to-Many  |
| users                 | repositories            | One-to-Many  |
| users                 | commits                 | One-to-Many  |
| users                 | pull_requests           | One-to-Many  |
| users                 | issues                  | One-to-Many  |
| users                 | stars                   | One-to-Many  |
| users                 | forks                   | One-to-Many  |
| users                 | organization_members    | One-to-Many  |
| organizations         | organization_members    | One-to-Many  |
| organizations         | repositories            | One-to-Many  |
| repositories          | branches                | One-to-Many  |
| repositories          | commits                 | One-to-Many  |
| repositories          | pull_requests           | One-to-Many  |
| repositories          | issues                  | One-to-Many  |
| repositories          | releases                | One-to-Many  |
| repositories          | stars                   | One-to-Many  |
| repositories          | forks                   | One-to-Many  |
| repositories          | repository_languages    | One-to-Many  |
| repositories          | repository_contributors | One-to-Many  |
| pull_requests         | pull_request_reviews    | One-to-Many  |

---

# Planned Data Volume

| Table                   | Estimated Rows |
| ----------------------- | -------------: |
| programming_languages   |             20 |
| users                   |          5,000 |
| organizations           |            300 |
| organization_members    |          8,000 |
| repositories            |         12,000 |
| repository_languages    |         20,000 |
| repository_contributors |         60,000 |
| branches                |         45,000 |
| commits                 |        500,000 |
| pull_requests           |         80,000 |
| pull_request_reviews    |        120,000 |
| issues                  |        100,000 |
| releases                |         25,000 |
| stars                   |        900,000 |
| forks                   |        150,000 |

**Total Estimated Records:** **≈ 2,025,320**

---

# Notes

* All datasets will be generated using Python.
* Raw datasets may intentionally contain controlled data quality issues to support the Bronze layer of the Medallion Architecture.
* The Silver layer will standardize and clean the data.
* The Gold layer will contain analytics-ready tables optimized for SQL reporting and Power BI dashboards.