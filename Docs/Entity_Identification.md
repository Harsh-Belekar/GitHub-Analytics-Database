# 🚀 GitHub Analytics Database - Entity Identification

---

# 1. Introduction

The purpose of this document is to identify the business entities required for the **GitHub Analytics Database**.

Entity identification is the first step in relational database design. Each entity represents a real-world object or concept involved in GitHub software development activities.

These entities will later be transformed into relational database tables and will form the foundation of the Bronze, Silver, and Gold layers within the Medallion Architecture.

---

# 2. Entity Identification Process

The entities were identified by analyzing GitHub workflows and the business questions defined for this project.

The identification process focused on:

* Users and organizations
* Repository management
* Source code development
* Collaboration and code review
* Issue tracking
* Release management
* Community engagement
* Programming language usage

Each entity represents a distinct business object with its own attributes and relationships.

---

# 3. Core Business Entities

## 3.1 Users

### Description

Represents GitHub users who own repositories, contribute code, review pull requests, create issues, and participate in software development.

### Purpose

Provides developer-related information for productivity and contribution analysis.

### Primary Key

**user_id**

---

## 3.2 Organizations

### Description

Represents GitHub organizations that own repositories and manage groups of developers.

### Purpose

Supports organizational reporting and team-level analytics.

### Primary Key

**organization_id**

---

## 3.3 Organization Members

### Description

Represents the many-to-many relationship between users and organizations.

A single user may belong to multiple organizations, and an organization can have multiple members.

### Purpose

Tracks organization membership and collaboration.

### Primary Key

**membership_id**

---

## 3.4 Repositories

### Description

Represents software repositories hosted on GitHub.

Repositories contain source code, branches, commits, issues, pull requests, releases, and community activity.

### Purpose

Acts as the central entity for software development analytics.

### Primary Key

**repository_id**

---

## 3.5 Programming Languages

### Description

Represents programming languages used in repositories.

### Purpose

Supports technology adoption and language usage analysis.

### Primary Key

**language_id**

---

## 3.6 Repository Languages

### Description

Represents the many-to-many relationship between repositories and programming languages.

A repository may use multiple languages, and a language may be used by many repositories.

### Purpose

Enables language distribution and repository technology analysis.

### Primary Key

**repository_language_id**

---

## 3.7 Repository Contributors

### Description

Represents contributors assigned to repositories.

A contributor may contribute to multiple repositories, and each repository may have multiple contributors.

### Purpose

Measures collaboration and developer participation.

### Primary Key

**contributor_id**

---

## 3.8 Branches

### Description

Represents Git branches created within repositories.

### Purpose

Tracks development branches used for commits and pull requests.

### Primary Key

**branch_id**

---

## 3.9 Commits

### Description

Represents source code commits performed by developers.

Each commit belongs to one repository, one branch, and one author.

### Purpose

Supports developer productivity and repository activity analysis.

### Primary Key

**commit_id**

---

## 3.10 Pull Requests

### Description

Represents pull requests created to merge code changes into repositories.

### Purpose

Measures collaboration, review processes, and software delivery efficiency.

### Primary Key

**pull_request_id**

---

## 3.11 Pull Request Reviews

### Description

Represents code reviews performed on pull requests.

Each review is completed by a reviewer and references a specific pull request.

### Purpose

Analyzes review quality and collaboration performance.

### Primary Key

**review_id**

---

## 3.12 Issues

### Description

Represents bugs, feature requests, documentation tasks, and enhancements reported within repositories.

### Purpose

Supports issue tracking and project maintenance analytics.

### Primary Key

**issue_id**

---

## 3.13 Releases

### Description

Represents software releases published for repositories.

### Purpose

Measures release frequency and software delivery trends.

### Primary Key

**release_id**

---

## 3.14 Stars

### Description

Represents users starring repositories.

A user may star multiple repositories, and a repository may receive stars from many users.

### Purpose

Measures repository popularity and community engagement.

### Primary Key

**star_id**

---

## 3.15 Forks

### Description

Represents repository forks created by users.

### Purpose

Measures repository adoption and community participation.

### Primary Key

**fork_id**

---

# 4. Entity Summary

| Entity                  | Primary Key            | Business Purpose                     |
| ----------------------- | ---------------------- | ------------------------------------ |
| Users                   | user_id                | Stores GitHub user information       |
| Organizations           | organization_id        | Stores organization information      |
| Organization Members    | membership_id          | Links users with organizations       |
| Repositories            | repository_id          | Stores repository details            |
| Programming Languages   | language_id            | Stores programming languages         |
| Repository Languages    | repository_language_id | Links repositories with languages    |
| Repository Contributors | contributor_id         | Links contributors with repositories |
| Branches                | branch_id              | Stores repository branches           |
| Commits                 | commit_id              | Stores commit history                |
| Pull Requests           | pull_request_id        | Stores pull requests                 |
| Pull Request Reviews    | review_id              | Stores code reviews                  |
| Issues                  | issue_id               | Stores issue tracking data           |
| Releases                | release_id             | Stores release information           |
| Stars                   | star_id                | Stores repository stars              |
| Forks                   | fork_id                | Stores repository forks              |

---

# 5. Entity Classification

The entities can be grouped into logical categories.

## Master Entities

* Users
* Organizations
* Programming Languages

These provide reference data used by other entities.

---

## Transactional Entities

* Repositories
* Branches
* Commits
* Pull Requests
* Pull Request Reviews
* Issues
* Releases

These record day-to-day software development activities.

---

## Bridge (Junction) Entities

* Organization Members
* Repository Languages
* Repository Contributors

These resolve many-to-many relationships between core entities.

---

## Community Entities

* Stars
* Forks

These capture user engagement and repository popularity.

---

# 6. Design Considerations

The entity model has been designed to:

* Follow Third Normal Form (3NF).
* Eliminate unnecessary data redundancy.
* Maintain referential integrity.
* Support scalable ETL pipelines.
* Enable efficient SQL queries.
* Simplify analytical reporting.
* Support Medallion Architecture.
* Allow future expansion with additional GitHub features such as Discussions, Projects, Packages, Security Alerts, GitHub Actions, and Milestones.

---

# 7. Expected Outcome

The identified entities provide a complete representation of the GitHub software development ecosystem.

Together, they enable analysis of:

* Developer productivity
* Repository performance
* Collaboration
* Code review processes
* Issue management
* Release management
* Programming language adoption
* Community engagement

These entities will be transformed into relational database tables and connected through well-defined primary key and foreign key relationships.

---

# 8. Conclusion

The entity identification process establishes the structural foundation of the GitHub Analytics Database. These fifteen entities accurately model the core components of GitHub and provide the basis for database schema design, ER diagrams, ETL pipelines, advanced SQL analysis, and business intelligence reporting.

The next phase of the project is **Relationship Design**, where the relationships, cardinalities, and foreign key dependencies between these entities will be formally defined.