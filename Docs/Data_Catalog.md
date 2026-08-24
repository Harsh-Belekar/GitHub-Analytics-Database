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
