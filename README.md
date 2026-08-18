# 🚀 GitHub Analytics Database

An End-to-End **GitHub Analytics Database and Data Warehouse project** built with **Python, PostgreSQL, Advanced SQL, and Medallion Architecture**.

The project simulates **GitHub's interconnected Software-Development Data and Transforms** it through a structured **Bronze → Silver → Gold** data warehouse pipeline. The final **Gold layer** provides **Business-ready** **Fact tables**, **Dimension tables**, **Analytical Views**, and **SQL-based** insights for **Repository**, **Developer**, **Commit**, **Pull Request**, **Issue**, **Release**, **Organization**, **Programming Language**, **Community**, and **Data-Quality Analysis.**

> **Project Scope:** This project is focused on **Data Engineering, Data Warehousing, ETL, Advanced SQL, Data Quality, and Analytical Reporting through SQL**. Dashboard development is intentionally outside the final project scope.

---

## 📌 Table of Contents

-   [Project Structure](#-project-structure)
-   [Project Overview](#-project-overview)
-   [Business Problem](#-business-problem)
-   [Project Objectives](#-project-objectives)
-   [Key Business Questions](#-key-business-questions)
-   [Data Warehouse Architecture](#️-data-warehouse-architecture)
-   [Database Schema](#-database-schema)
-   [Data Warehouse Layers](#-data-warehouse-layers)
-   [Technology Stack](#-technology-stack)
-   [Data Generation](#-data-generation)
-   [ETL Pipeline](#-etl-pipeline)
-   [Gold Layer](#-gold-layer)
-   [SQL Analysis](#-sql-analysis)
-   [Data Quality](#-data-quality)
-   [Testing](#-testing)
-   [Setup and Installation](#-setup-and-installation)
-   [Execution Workflow](#-execution-workflow)
-   [Documentation](#-documentation)
-   [Key Outcomes](#-key-outcomes)
-   [Future Enhancements](#-future-enhancements)
-   [Dataset Disclaimer ](#️-dataset-disclaimer)
-   [Author](#-author)

---

# 📁 Project Structure

``` text
GitHub-Analytics-Database/
│
├── README.md
├── requirements.txt
├── LICENSE
│
├── Docs/
│   ├── Business_Problem.md
│   ├── Objectives.md
│   ├── Business_Questions.md
│   ├── Entity_Identification.md
│   ├── Relationship_Design.md
│   ├── Data_Generation_Documentation.md
│   └── Data_Catalog.md
│
├── Data/
│   ├── Raw/
│   │   └── Raw_GitHub_Data.zip
│   └── Processed/
│       └── Processed_GitHub_Data.zip
│
├── Data_Generator/
│   ├── Config.py
│   ├── Master_data.py
│   ├── Utils.py
│   ├── Main.py
│   └── Generators/
│       ├── __init__.py
│       ├── Users.py
│       ├── Organizations.py
│       ├── Organization_Members.py
│       ├── Programming_Languages.py
│       ├── Repositories.py
│       ├── Repository_Languages.py
│       ├── Repository_Contributors.py
│       ├── Branches.py
│       ├── Commits.py
│       ├── Pull_Requests.py
│       ├── Pull_Request_Reviews.py
│       ├── Issues.py
│       ├── Releases.py
│       ├── Stars.py
│       └── Forks.py
│
├── ETL/
│   ├── Python-Scripts/
│   │   ├── Init_database.py
│   │   ├── Bronze/
│   │   │   ├── DDL_Bronze.py
│   │   │   └── Load_Bronze.py
│   │   ├── Silver/
│   │   │   ├── DDL_Silver.py
│   │   │   ├── Cleaning_Functions.py
│   │   │   └── Load_Silver.py
│   │   └── Gold/
│   │       ├── DDL_Gold.py
│   │       ├── Load_Gold.py
│   │       └── Gold_Reporting_Views.py
│   │
│   └── SQL-Scripts/
│       ├── Init_database.sql
│       ├── Bronze/
│       │   ├── DDL_Bronze.sql
│       │   └── Proc_Load_Bronze.sql
│       ├── Silver/
│       │   ├── DDL_Silver.sql
│       │   ├── Cleaning_Functions.sql
│       │   └── Proc_Load_Silver.sql
│       └── Gold/
│           ├── DDL_Gold.sql
│           ├── Proc_Load_Gold.sql
│           └── Gold_Reporting_Views.sql
│
├── Logs/
│   ├── Init_database.log
│   ├── DDL_Bronze.log
│   ├── Load_Bronze.log
│   ├── DDL_Silver.log
│   ├── Cleaning_Functions.log
│   ├── Load_Silver.log
│   ├── DDL_Gold.log
│   ├── Load_Gold.log
│   └── Gold_Reporting_Views.log
│
├── SQL-Analysis/
│   ├── Developer_Productivity.sql
│   ├── Commit_Analytics.sql
│   ├── Pull_Request_Analytics.sql
│   ├── Issue_Analytics.sql
│   ├── Release_Analytics.sql
│   ├── Organization_Analytics.sql
│   ├── Programming_Language_Analytics.sql
│   ├── Community_Engagement_Analytics.sql
│   ├── Data_Quality_Analytics.sql
│   └── Executive_Analytics.sql
│
├── Tests/
│   ├── Test_Bronze.sql
│   ├── Test_Silver.sql
│   ├── Test_Gold.sql
│   ├── Test_Data_Integrity.sql
│   └── Test_Business_Logic.sql
│
└── Images/
    ├── Database_Schema.png
    └── Data_Warehouse_Architecture.png
```

---

# 📖 Project Overview

GitHub generates a large volume of interconnected software-development
data involving:

-   Users
-   Organizations
-   Repositories
-   Programming languages
-   Repository contributors
-   Branches
-   Commits
-   Pull requests
-   Pull request reviews
-   Issues
-   Releases
-   Stars
-   Forks

Although these entities are highly valuable for analysis, their
relationships and operational structure make analytical querying more
complex.

This project solves that problem by building a centralized
PostgreSQL-based analytical database that:

1.  Generates realistic synthetic GitHub data.
2.  Loads raw data into a Bronze layer.
3.  Cleans and standardizes data in the Silver layer.
4.  Builds business-ready Gold dimensions and fact tables.
5.  Creates analytical reporting views.
6.  Uses Advanced SQL to answer business questions.
7.  Applies data-quality and integrity testing throughout the pipeline.

The project follows an industry-inspired **Medallion Architecture** to
separate raw ingestion, transformation, and analytical consumption
layers.

---

# 🎯 Business Problem

Software engineering teams need reliable visibility into development
activity to understand repository performance, developer contribution,
collaboration, issue management, release activity, and community
engagement.

However, GitHub-style operational data introduces several challenges:

-   Data is distributed across multiple interconnected entities.
-   Relationships between developers, repositories, commits, issues, and
    pull requests are complex.
-   Raw data is not optimized for analytical queries.
-   Missing values, duplicates, malformed values, and inconsistent data
    can affect analytical accuracy.
-   Repeated analytical queries can become complex without a
    well-designed warehouse layer.

The GitHub Analytics Database addresses these challenges by creating a
centralized analytical data warehouse with controlled data generation,
automated ETL, data-quality processing, dimensional modeling, and
business-ready SQL views.

---

# 🎯 Project Objectives

## Primary Objective

Build a production-inspired GitHub Analytics Database that transforms
synthetic operational GitHub data into reliable, business-ready
analytical datasets using PostgreSQL, Python, ETL, Medallion
Architecture, and Advanced SQL.

## Technical Objectives

-   Design a relational PostgreSQL data warehouse.
-   Generate realistic synthetic GitHub datasets.
-   Maintain relationships between interconnected GitHub entities.
-   Simulate real-world data-quality problems.
-   Implement Bronze, Silver, and Gold layers.
-   Develop modular Python ETL scripts.
-   Develop equivalent SQL-based ETL scripts.
-   Apply data cleaning and standardization.
-   Maintain primary-key and foreign-key integrity.
-   Create Gold-layer fact and dimension tables.
-   Create analytical reporting views.
-   Develop SQL analysis for business questions.
-   Implement automated logging and error handling.
-   Validate the data warehouse through SQL tests.

---

# ❓ Key Business Questions

The analytical layer is designed to answer questions across the
following areas.

### Repository Analytics

-   Which repositories have the highest number of commits?
-   Which repositories have the highest number of contributors?
-   Which repositories receive the most pull requests?
-   Which repositories have the highest number of issues?
-   Which repositories receive the most stars?
-   Which repositories have been forked the most?
-   How does repository activity change over time?

### Developer Productivity

-   Which developers create the most commits?
-   Which developers open the most pull requests?
-   Which developers merge the most pull requests?
-   Which developers review the most pull requests?
-   Which developers resolve the most issues?
-   Which developers contribute to the highest number of repositories?
-   Which developers own the most repositories?
-   What is the average number of commits per active developer?

### Commit Analytics

-   How many commits are created over time?
-   What are the peak development periods?
-   Which repositories receive commits most frequently?
-   Which branches contain the highest number of commits?
-   What is the average number of lines added per commit?
-   What is the average number of lines deleted per commit?
-   Which developers make the largest code contributions?

### Pull Request Analytics

-   How many pull requests are created, merged, open, and closed?
-   What is the average pull request review time?
-   Which repositories have the highest merge rate?
-   Which developers submit the most pull requests?
-   Which reviewers approve the most pull requests?
-   What percentage of pull requests require changes?

### Issue Analytics

-   How many issues are open and resolved?
-   What is the average issue resolution time?
-   Which repositories have the most issues?
-   Which developers resolve the most issues?
-   What percentage of issues remain unresolved?
-   Which repositories receive the most critical issues?

### Release Analytics

-   How many releases are published?
-   Which repositories publish releases most frequently?
-   What is the average time between releases?
-   Which repositories have the fastest release cycle?
-   What is the monthly release trend?

### Organization Analytics

-   How many organizations exist?
-   Which organizations own the most repositories?
-   Which organizations have the most developers?
-   Which organizations generate the most commits?
-   Which organizations receive the most stars?
-   Which organizations resolve the most issues?
-   Which organizations publish the most releases?

### Programming Language Analytics

-   Which programming languages are used most frequently?
-   Which repositories use multiple programming languages?
-   Which language has the highest number of repositories?
-   Which language generates the most commits?
-   Which language has the highest community engagement?
-   Which organizations primarily use Python?
-   Which repositories use SQL?

### Community Engagement

-   Which repositories have the highest number of stars?
-   Which repositories have the highest number of forks?
-   Which developers receive the most followers?
-   Which repositories attract the largest contributor communities?
-   What is the relationship between stars and forks?
-   Which organizations receive the highest community engagement?

### Data Quality Analytics

-   How many duplicate records were identified?
-   How many records contain missing values?
-   How many malformed email addresses were detected?
-   How many records failed validation?
-   How many records were retained after transformation?
-   How many records were rejected or excluded during processing?
-   What is the overall quality of the transformed datasets?

---

# 🏗️ Data Warehouse Architecture

The project follows the **Medallion Architecture**:

![Data Warehouse Architecture](Images/Data_Warehouse_Architecture.png)

### Data Flow
``` text
                    ┌───────────────────────┐
                    │   Synthetic Raw Data  │
                    │        CSV Files      │
                    └───────────┬───────────┘
                                │
                                ▼
                    ┌───────────────────────┐
                    │     BRONZE LAYER      │
                    │      Raw Data          │
                    │  Minimal Transformation│
                    └───────────┬───────────┘
                                │
                                ▼
                    ┌───────────────────────┐
                    │      SILVER LAYER     │
                    │ Cleaned & Standardized│
                    │     Data              │
                    └───────────┬───────────┘
                                │
                                ▼
                    ┌───────────────────────┐
                    │       GOLD LAYER      │
                    │ Business-Ready Facts  │
                    │ Dimensions & Views    │
                    └───────────┬───────────┘
                                │
                                ▼
                    ┌───────────────────────┐
                    │    Advanced SQL       │
                    │ Analysis & Reporting  │
                    └───────────────────────┘
```

The PostgreSQL database acts as the central data warehouse, while Python
and SQL scripts automate the ingestion and transformation processes.



---

# 🗄️ Database Schema

The Gold layer uses a dimensional data warehouse design consisting of
**dimension tables** and **fact tables**.

### Dimension Tables

-   `dim_users`
-   `dim_organizations`
-   `dim_repositories`
-   `dim_branches`
-   `dim_languages`

### Fact Tables

-   `fact_organization_members`
-   `fact_repository_languages`
-   `fact_repository_contributors`
-   `fact_commits`
-   `fact_pull_requests`
-   `fact_pull_request_reviews`
-   `fact_issues`
-   `fact_releases`
-   `fact_stars`
-   `fact_forks`

The dimensional model connects users, organizations, repositories,
branches, and programming languages with GitHub activity facts.

### Database Schema 

![Schema](Images/Database_Schema.png)

---

# 🥉 Data Warehouse Layers

## Bronze Layer

The Bronze layer stores the generated raw datasets with minimal
transformation.

### Responsibilities

-   Raw data ingestion
-   Initial storage
-   Batch loading
-   Full-load processing
-   Truncate-and-insert loading
-   Preservation of source-level data

### Characteristics

-   Raw data
-   Minimal transformation
-   Source-oriented structure
-   PostgreSQL tables

---

## 🥈 Silver Layer

The Silver layer converts raw data into clean, standardized, and
validated datasets.

### Transformations

-   Duplicate handling
-   Missing-value treatment
-   Data type standardization
-   Value normalization
-   Invalid-data handling
-   Data validation
-   Referential integrity checks
-   Data enrichment

The Silver layer provides a trusted foundation for downstream analytical
modeling.

---

## 🥇 Gold Layer

The Gold layer contains business-ready analytical structures.

### Components

-   Dimension tables
-   Fact tables
-   Reporting views
-   Aggregated metrics
-   Business logic
-   Analytical summaries

The Gold layer is designed to simplify complex analytical queries and
provide consistent datasets for SQL-based reporting.

---

# 🐍 Data Generation

Synthetic GitHub data is generated using Python.

The generator creates interconnected datasets for:

1.  Programming Languages
2.  Users
3.  Organizations
4.  Organization Members
5.  Repositories
6.  Repository Languages
7.  Repository Contributors
8.  Branches
9.  Commits
10. Pull Requests
11. Pull Request Reviews
12. Issues
13. Releases
14. Stars
15. Forks

The generation process maintains relationships between entities so that
downstream ETL processing can simulate realistic GitHub data.

The generator also supports the creation of controlled data-quality
issues such as missing values, duplicate records, malformed values, and
invalid data.

---

# 🔄 ETL Pipeline

The ETL process is implemented using both **Python scripts** and
**PostgreSQL SQL scripts**.

## ETL Flow

``` text
Synthetic Data
      │
      ▼
Raw CSV Files
      │
      ▼
Bronze Loading
      │
      ▼
Bronze Tables
      │
      ▼
Cleaning & Validation
      │
      ▼
Silver Tables
      │
      ▼
Business Transformations
      │
      ▼
Gold Fact & Dimension Tables
      │
      ▼
Gold Reporting Views
      │
      ▼
Advanced SQL Analysis
```

## Python ETL Components

### Database Initialization

`Init_database.py`

Creates and initializes the required PostgreSQL database structures.

### Bronze Layer

-   `DDL_Bronze.py`
-   `Load_Bronze.py`

Responsible for creating Bronze tables and loading raw datasets.

### Silver Layer

-   `DDL_Silver.py`
-   `Cleaning_Functions.py`
-   `Load_Silver.py`

Responsible for data cleaning, standardization, validation, and loading
into Silver tables.

### Gold Layer

-   `DDL_Gold.py`
-   `Load_Gold.py`
-   `Gold_Reporting_Views.py`

Responsible for creating Gold dimensions/facts, loading business-ready
data, and creating analytical reporting views.

---

# 🥇 Gold Layer

The Gold layer is the analytical core of the project.

## Repository Performance

`gold.repository_performance_summary`

Provides repository-level metrics including:

-   Total commits
-   Recent commit activity
-   Contributors
-   Pull requests
-   Issues
-   Releases
-   Stars
-   Forks
-   Repository metadata

## Developer Productivity

`gold.developer_productivity_summary`

Provides developer-level metrics including:

-   Repositories owned
-   Repositories contributed to
-   Commits authored
-   Pull requests opened
-   Pull requests merged
-   Pull requests reviewed
-   Pull requests approved
-   Issues resolved

## Repository Monthly Activity

`gold.repository_monthly_activity`

Combines monthly repository activity across:

-   Commits
-   Pull requests
-   Issues
-   Releases
-   Stars

## Developer Monthly Activity

`gold.developer_monthly_activity`

Tracks developer commit activity by month.

## Organization Summary

`gold.organization_summary`

Provides organization-level metrics such as:

-   Repository count
-   Member count
-   Commits
-   Stars
-   Resolved issues
-   Releases
-   Commits per member

## Language Adoption

`gold.language_adoption_summary`

Analyzes programming language adoption based on:

-   Repositories using the language
-   Repositories where the language is primary
-   Commit activity
-   Stars

## Pull Request Efficiency

`gold.pull_request_efficiency_summary`

Provides:

-   Pull request counts
-   Merge rate
-   Average time to merge
-   Average time to first review
-   Change-request percentage

## Issue Resolution

`gold.issue_resolution_summary`

Provides:

-   Total issues
-   Open issues
-   Closed issues
-   Closure rate
-   Unresolved rate
-   Average resolution time
-   Critical issues
-   High-priority issues

## Release Analytics

`gold.release_analytics_summary`

Provides:

-   Total releases
-   First release
-   Latest release
-   Average days between releases

## Data Quality Reporting

The Gold layer also contains data-quality views:

-   `gold.data_quality_row_counts`
-   `gold.data_quality_summary`
-   `gold.data_quality_field_issues`

These views help monitor data retention, duplicate reduction, and
field-level data-quality problems.

## Executive Summary

`gold.executive_summary`

Provides high-level warehouse KPIs including:

-   Total developers
-   Total repositories
-   Total commits
-   Total pull requests
-   Merged pull requests
-   Total issues
-   Resolved issues
-   Total releases
-   Total stars
-   Total forks
-   Total organizations
-   Average commits per active developer
-   Overall pull request merge rate
-   Overall issue closure rate

---

# 📊 SQL Analysis

The `SQL-Analysis/` directory contains analytical SQL scripts organized
by business area.

| Analysis | Purpose |
|---|---|
| **Developer Productivity** | Developer contribution and productivity analysis |
| **Commit Analytics** | Commit activity and code contribution analysis |
| **Pull Request Analytics** | Pull request and review performance |
| **Issue Analytics** | Issue resolution and project maintenance |
| **Release Analytics** | Release frequency and release-cycle analysis |
| **Organization Analytics** | Organization-level activity |
| **Programming Language Analytics** | Technology adoption |
| **Community Engagement** | Stars, forks, followers, and contributor activity |
| **Data Quality Analytics** | Data validation and quality analysis |
| **Executive Summary Analysis** | High-level GitHub engineering KPIs |

These queries use PostgreSQL features such as:

-   `JOIN`
-   `GROUP BY`
-   `HAVING`
-   `CASE`
-   `FILTER`
-   `CTE`
-   `Window Functions`
-   `Ranking Functions`
-   `Subqueries`
-   `Aggregations`
-   `Views`
-   `Date and time functions`

---

# 🧪 Data Quality

Data quality is treated as an important part of the ETL process.

The project intentionally simulates issues such as:

-   Missing values
-   Duplicate records
-   Invalid email addresses
-   Negative numeric values
-   Invalid relationships
-   Inconsistent values
-   Invalid foreign-key references

The Silver layer applies cleaning and validation rules before the data
reaches the Gold layer.

Examples of validation include:

-   Email format validation
-   Missing-value detection
-   Negative-value detection
-   Duplicate detection
-   Referential integrity validation
-   Standardization of values
-   Data retention measurement

---

# ✅ Testing

The `Tests/` directory contains SQL-based validation scripts.

### Bronze Tests

`Test_Bronze.sql`

Validates raw Bronze-layer tables.

### Silver Tests

`Test_Silver.sql`

Validates cleaned and standardized Silver data.

### Gold Tests

`Test_Gold.sql`

Validates Gold-layer dimensions, facts, and analytical structures.

### Data Integrity Tests

`Test_Data_Integrity.sql`

Validates:

-   Primary keys
-   Foreign keys
-   Referential integrity
-   Relationships between entities

### Business Logic Tests

`Test_Business_Logic.sql`

Validates analytical rules and expected business calculations.

---

# 🛠️ Technology Stack

| Category | Technology |
|---|---|
| **Programming Language** | Python |
| **Database** | PostgreSQL |
| **SQL** | Advanced PostgreSQL SQL |
| **Data Processing** | Pandas / Python |
| **Data Generation** | Python |
| **ETL** | Python + PostgreSQL |
| **Data Warehouse Architecture** | Medallion Architecture |
| **Data Modeling** | Dimensional Modeling |
| **Database Connectivity** | psycopg2 |
| **Version Control** | Git / GitHub |
| **Testing** | SQL-based validation |
| **Documentation** | Markdown |

---

# ⚙️ Setup and Installation

## 1. Clone the Repository

``` bash
git clone https://github.com/Harsh-Belekar/GitHub-Analytics-Database.git
cd GitHub-Analytics-Database
```

## 2. Create a Virtual Environment

### Windows

``` bash
python -m venv venv
venv\Scripts\activate
```

### Linux / macOS

``` bash
python3 -m venv venv
source venv/bin/activate
```

## 3. Install Dependencies

``` bash
pip install -r requirements.txt
```

## 4. Configure PostgreSQL

Update the database configuration in the Python scripts with your
PostgreSQL credentials.

Example:

``` python
DB_NAME = "GitHub-Data-Warehouse"
DB_USER = "postgres"
DB_PASSWORD = "your_password"
DB_HOST = "localhost"
DB_PORT = "5432"
```

---

# ▶️ Execution Workflow

A typical end-to-end execution sequence is:

### Step 1 --- Generate Synthetic Data

Run:

``` bash
python Data_Generator/Main.py
```

This generates the raw GitHub datasets.

### Step 2 --- Initialize the Database

Run:

``` bash
python ETL/Python-Scripts/Init_database.py
```

### Step 3 --- Create and Load Bronze Layer

Create Bronze tables:

``` bash
python ETL/Python-Scripts/Bronze/DDL_Bronze.py
```

Load raw data:

``` bash
python ETL/Python-Scripts/Bronze/Load_Bronze.py
```

### Step 4 --- Create and Load Silver Layer

Create Silver tables:

``` bash
python ETL/Python-Scripts/Silver/DDL_Silver.py
```

Apply cleaning and transformations:

``` bash
python ETL/Python-Scripts/Silver/Cleaning_Functions.py
```

Load Silver data:

``` bash
python ETL/Python-Scripts/Silver/Load_Silver.py
```

### Step 5 --- Create and Load Gold Layer

Create Gold tables:

``` bash
python ETL/Python-Scripts/Gold/DDL_Gold.py
```

Load Gold data:

``` bash
python ETL/Python-Scripts/Gold/Load_Gold.py
```

Create reporting views:

``` bash
python ETL/Python-Scripts/Gold/Gold_Reporting_Views.py
```

### Step 6 --- Run Data Tests

Execute the SQL scripts inside:

``` text
Tests/
```

### Step 7 --- Run Analytical SQL

Execute the required analysis scripts from:

``` text
SQL-Analysis/
```

---

# 📝 SQL-Based Alternative

The project also contains SQL equivalents of the ETL operations.

The SQL workflow is:

``` text
Init_database.sql
        │
        ▼
DDL_Bronze.sql
        │
        ▼
Proc_Load_Bronze.sql
        │
        ▼
DDL_Silver.sql
        │
        ▼
Cleaning_Functions.sql
        │
        ▼
Proc_Load_Silver.sql
        │
        ▼
DDL_Gold.sql
        │
        ▼
Proc_Load_Gold.sql
        │
        ▼
Gold_Reporting_Views.sql
        │
        ▼
SQL Analysis
```

This provides two implementation approaches:

-   Python-driven ETL
-   PostgreSQL SQL-driven ETL

---

# 📚 Documentation

The `Docs/` directory contains the project's technical and business
documentation.

| Document | Description |
|---|---|
| **Business_Problem.md** | Defines the business problem, scope, users, benefits, and success criteria |
| **Objectives.md** | Defines technical, analytical, learning, and portfolio objectives |
| **Business_Questions.md** | Defines the analytical questions the warehouse should answer |
| **Entity_Identification.md** | Identifies the major GitHub entities |
| **Relationship_Design.md** | Defines relationships between entities |
| **Data_Generation_Documentation.md** | Documents synthetic data-generation methodology |
| **Data_Catalog.md** | Documents tables, columns, and data definitions |

---

# 📈 Key Outcomes

The completed project demonstrates the ability to:

-   Build a PostgreSQL analytical database from the ground up.
-   Design interconnected relational and dimensional data models.
-   Generate realistic synthetic datasets.
-   Implement an end-to-end Medallion Architecture.
-   Develop reusable Python ETL components.
-   Develop PostgreSQL SQL-based ETL processes.
-   Perform data cleaning and standardization.
-   Implement data-quality validation.
-   Build fact and dimension tables.
-   Create business-ready analytical views.
-   Apply advanced SQL techniques to real-world analytical problems.
-   Validate data integrity and business logic.
-   Organize a production-inspired data engineering repository.
-   Document the complete data warehouse lifecycle.

---

# 🔮 Future Enhancements

Possible future improvements include:

-   Incremental ETL processing.
-   Slowly Changing Dimensions (SCD).
-   Query-performance benchmarking.
-   Index optimization.
-   Partitioning for large fact tables.
-   Automated ETL scheduling.
-   CI/CD-based data-quality testing.
-   Real GitHub API ingestion.
-   Cloud data warehouse deployment.
-   Additional GitHub entities and metrics.

These are potential extensions and are **not part of the current project
scope**.

---

# ⚠️ Dataset Disclaimer  

All datasets used in this project are **dummy, synthetic, or public** — generated programmatically using Python for learning and portfolio demonstration purposes only.

**No real customer data, restaurant data, or proprietary Samsung information has been used.**
This project is not affiliated with, endorsed by, or connected to Samsung in any way.

---

## 🧑‍💻 Author

**👤 Harsh Belekar**  
📍 Data Analyst | Python Developer | SQL | Power BI | Excel | Data Visualization  
📬 [LinkedIn](https://www.linkedin.com/in/harshbelekar) | 🔗[GitHub](https://github.com/Harsh-Belekar)

📧 [harshbelekar74@gmail.com](mailto:harshbelekar74@gmail.com)

---

⭐ *If you found this project helpful, feel free to star the repo and connect with me for collaboration!*

***Made with ❤️ and a lot of ☕ by Harsh Belekar***