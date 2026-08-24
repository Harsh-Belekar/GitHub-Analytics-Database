# 🚀 GitHub Analytics Database - Relationship Design

---

# 1. Introduction

The purpose of this document is to define the relationships between the entities identified in the GitHub Analytics Database.

A well-designed relational model ensures:

* Data integrity
* Referential integrity
* Reduced data redundancy
* Efficient SQL querying
* Scalable ETL processing
* Accurate analytical reporting

The relationships defined in this document will serve as the foundation for the Entity Relationship (ER) Diagram, PostgreSQL schema, synthetic data generation, and Medallion Architecture implementation.

---

# 2. Relationship Design Principles

The database has been designed following standard relational database principles.

The design aims to:

* Normalize data up to Third Normal Form (3NF).
* Maintain Primary Key and Foreign Key integrity.
* Eliminate unnecessary duplication.
* Support one-to-many and many-to-many relationships.
* Enable efficient JOIN operations.
* Ensure scalability for future GitHub features.

---

# 3. Relationship Overview

The GitHub Analytics Database contains **15 business entities** connected through a combination of **One-to-One (1:1)**, **One-to-Many (1:N)**, and **Many-to-Many (M:N)** relationships.

Most business processes revolve around the **Repository** entity, making it the central hub of the data model.

---

# 4. Relationship Details

## 4.1 Users → Repositories

### Relationship

**One-to-Many (1:N)**

### Description

A single user can own multiple repositories, but each repository has only one owner.

### Foreign Key

```text
repositories.owner_user_id
        ↓
users.user_id
```

---

## 4.2 Organizations → Repositories

### Relationship

**One-to-Many (1:N)**

### Description

An organization can own multiple repositories.

Each repository belongs to only one organization.

### Foreign Key

```text
repositories.organization_id
        ↓
organizations.organization_id
```

---

## 4.3 Users ↔ Organizations

### Relationship

**Many-to-Many (M:N)**

### Bridge Entity

Organization Members

### Description

A developer may belong to multiple organizations.

An organization may have multiple developers.

### Foreign Keys

```text
organization_members.user_id
            ↓
users.user_id


organization_members.organization_id
            ↓
organizations.organization_id
```

---

## 4.4 Repositories ↔ Programming Languages

### Relationship

**Many-to-Many (M:N)**

### Bridge Entity

Repository Languages

### Description

A repository can use multiple programming languages.

A programming language can be used by many repositories.

### Foreign Keys

```text
repository_languages.repository_id
              ↓
repositories.repository_id


repository_languages.language_id
              ↓
programming_languages.language_id
```

---

## 4.5 Users ↔ Repositories

### Relationship

**Many-to-Many (M:N)**

### Bridge Entity

Repository Contributors

### Description

A developer may contribute to multiple repositories.

A repository may have multiple contributors.

### Foreign Keys

```text
repository_contributors.user_id
            ↓
users.user_id


repository_contributors.repository_id
            ↓
repositories.repository_id
```

---

## 4.6 Repositories → Branches

### Relationship

**One-to-Many (1:N)**

### Description

Each repository contains one or more branches.

Each branch belongs to one repository.

### Foreign Key

```text
branches.repository_id
        ↓
repositories.repository_id
```

---

## 4.7 Branches → Commits

### Relationship

**One-to-Many (1:N)**

### Description

A branch contains many commits.

Each commit belongs to exactly one branch.

### Foreign Key

```text
commits.branch_id
      ↓
branches.branch_id
```

---

## 4.8 Users → Commits

### Relationship

**One-to-Many (1:N)**

### Description

A user may create many commits.

Each commit has one author.

### Foreign Key

```text
commits.author_user_id
      ↓
users.user_id
```

---

## 4.9 Repositories → Commits

### Relationship

**One-to-Many (1:N)**

### Description

A repository contains many commits.

Each commit belongs to one repository.

### Foreign Key

```text
commits.repository_id
      ↓
repositories.repository_id
```

---

## 4.10 Repositories → Pull Requests

### Relationship

**One-to-Many (1:N)**

### Description

Each repository contains multiple pull requests.

Each pull request belongs to one repository.

### Foreign Key

```text
pull_requests.repository_id
          ↓
repositories.repository_id
```

---

## 4.11 Users → Pull Requests

### Relationship

**One-to-Many (1:N)**

### Description

A developer may create multiple pull requests.

Each pull request has one creator.

### Foreign Key

```text
pull_requests.created_by
         ↓
users.user_id
```

---

## 4.12 Pull Requests → Pull Request Reviews

### Relationship

**One-to-Many (1:N)**

### Description

A pull request may receive multiple reviews.

Each review belongs to one pull request.

### Foreign Key

```text
pull_request_reviews.pull_request_id
               ↓
pull_requests.pull_request_id
```

---

## 4.13 Users → Pull Request Reviews

### Relationship

**One-to-Many (1:N)**

### Description

A developer may review many pull requests.

Each review is performed by one reviewer.

### Foreign Key

```text
pull_request_reviews.reviewer_user_id
               ↓
users.user_id
```

---

## 4.14 Repositories → Issues

### Relationship

**One-to-Many (1:N)**

### Description

A repository contains multiple issues.

Each issue belongs to one repository.

### Foreign Key

```text
issues.repository_id
      ↓
repositories.repository_id
```

---

## 4.15 Users → Issues

### Relationship

**One-to-Many (1:N)**

### Description

Each issue is created by one user.

A user may create multiple issues.

### Foreign Key

```text
issues.created_by
      ↓
users.user_id
```

---

## 4.16 Repositories → Releases

### Relationship

**One-to-Many (1:N)**

### Description

Each repository may publish multiple releases.

Each release belongs to one repository.

### Foreign Key

```text
releases.repository_id
        ↓
repositories.repository_id
```

---

## 4.17 Users → Stars

### Relationship

**One-to-Many (1:N)**

### Description

A user may star multiple repositories.

### Foreign Keys

```text
stars.user_id
     ↓
users.user_id

stars.repository_id
     ↓
repositories.repository_id
```

---

## 4.18 Users → Forks

### Relationship

**One-to-Many (1:N)**

### Description

A user may fork multiple repositories.

### Foreign Keys

```text
forks.user_id
      ↓
users.user_id

forks.repository_id
      ↓
repositories.repository_id
```

---

# 5. Cardinality Summary

| Parent Entity | Child Entity         | Relationship |
| ------------- | -------------------- | ------------ |
| Users         | Repositories         | 1 : N        |
| Organizations | Repositories         | 1 : N        |
| Users         | Organization Members | 1 : N        |
| Organizations | Organization Members | 1 : N        |
| Repositories  | Branches             | 1 : N        |
| Branches      | Commits              | 1 : N        |
| Users         | Commits              | 1 : N        |
| Repositories  | Commits              | 1 : N        |
| Repositories  | Pull Requests        | 1 : N        |
| Pull Requests | Pull Request Reviews | 1 : N        |
| Repositories  | Issues               | 1 : N        |
| Repositories  | Releases             | 1 : N        |
| Users         | Stars                | 1 : N        |
| Users         | Forks                | 1 : N        |

---

# 6. Many-to-Many Relationships

The following relationships are resolved using bridge tables.

| Relationship                         | Bridge Table            |
| ------------------------------------ | ----------------------- |
| Users ↔ Organizations                | organization_members    |
| Repositories ↔ Programming Languages | repository_languages    |
| Users ↔ Repositories                 | repository_contributors |

---

# 7. Database Integrity Rules

The following integrity rules will be enforced:

* Every table must have a Primary Key.
* Foreign Keys must reference valid parent records.
* Child records cannot exist without corresponding parent records.
* Duplicate primary keys are not allowed.
* Referential integrity must be maintained throughout the ETL pipeline.
* Null values are permitted only where business rules allow.

---

# 8. Relationship Hierarchy

```text
Users
│
├── Repositories
│      ├── Branches
│      │      └── Commits
│      │
│      ├── Pull Requests
│      │      └── Pull Request Reviews
│      │
│      ├── Issues
│      ├── Releases
│      ├── Stars
│      └── Forks
│
├── Organization Members
│
└── Repository Contributors

Organizations
│
├── Repositories
└── Organization Members

Programming Languages
│
└── Repository Languages
```

---

# 9. Expected Outcome

The relationship model provides a robust and scalable relational foundation for the GitHub Analytics Database.

It ensures:

* Accurate entity relationships
* Reliable ETL processing
* Efficient SQL JOIN operations
* High data integrity
* Scalable database design
* Optimized analytical reporting

This relationship structure directly supports the Medallion Architecture and enables meaningful business insights through advanced SQL queries and Power BI dashboards.

---

# 10. Conclusion

The Relationship Design establishes how all business entities interact within the GitHub Analytics Database. By defining clear cardinalities, bridge tables, and referential integrity rules, this document provides the blueprint for the ER Diagram, database schema, synthetic data generation, and ETL implementation.

The next phase is **ER Diagram Design**, where these relationships will be visualized into a complete Entity Relationship Diagram before implementing the PostgreSQL database.
