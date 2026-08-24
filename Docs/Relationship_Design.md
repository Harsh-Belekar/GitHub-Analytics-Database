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