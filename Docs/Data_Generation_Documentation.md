# 🚀 GitHub Analytics Database — Data Generation Documentation

---

## 1. Introduction

This document explains how the synthetic dataset for the **GitHub Analytics Database** project is generated.

The generator is a Python program that produces 15 CSV files — one per table defined in `Entity_Identification.md`, `Relationship_Design.md`, and `Data_Catalog.md` — with correct foreign-key relationships, realistic business behaviour, and intentional data-quality issues to support the **Bronze layer** of the Medallion Architecture.

It is fully config-driven: the same codebase can generate a small sample (for fast testing) or the full ~2 million row dataset described in the Data Catalog, just by changing one number.

---

## 2. Folder Structure

```text
Data_Generator/
  ├── Config.py                  # All settings: volumes, ID ranges, dates, dirty-data rates
  ├── Master_data.py             # Static reference lists (languages, countries, templates...)
  ├── Utils.py                   # Shared helper functions used by every generator
  ├── Main.py                    # Orchestrator — runs everything in the correct order
  │
  └── Generators/
      ├── __init__.py
      ├── Programming_Languages.py
      ├── Users.py
      ├── Organizations.py
      ├── Organization_Members.py
      ├── Repositories.py
      ├── Repository_Languages.py
      ├── Repository_Contributors.py
      ├── Branches.py
      ├── Commits.py
      ├── Pull_Requests.py
      ├── Pull_Request_Reviews.py
      ├── Issues.py
      ├── Releases.py
      ├── Stars.py
      └── Forks.py
```

---

## 3. Design Principles

1. **Config-driven** — nothing is hardcoded inside a generator. Row counts, ID ranges, dates, and data-quality rates all live in `Config.py`.
2. **Foreign-key-safe generation order** — every table is generated only after its parent tables already exist, so a child row can never reference an ID that doesn't exist yet.
3. **Reproducibility** — a fixed random seed (`Config.RANDOM_SEED`) means running the generator twice produces identical output.
4. **Scalability** — a single `SCALE_FACTOR` setting shrinks or grows every table proportionally, from a quick ~100K-row sample up to the full ~2M-row catalog volume.
5. **Intentional data-quality issues** — the raw output deliberately contains nulls, duplicate rows, inconsistent formatting, and stray bad values, because Data_Catalog.md specifies that the Bronze layer should reflect real-world "messy" ingested data. These issues are meant to be cleaned in a later Silver-layer transformation step.

---

## 4. File-by-File Explanation

### 4.1 `Config.py` — The Control Panel

Central settings file. Every other file reads from here instead of hardcoding values.

| Section | Purpose |
|---|---|
| `RANDOM_SEED` | Fixes randomness so every run produces the same dataset. |
| `SCALE_FACTOR` | A single multiplier (e.g. `0.05` = 5%) applied to every table's row count. Set to `1.0` for the full catalog volume. |
| `FULL_ROW_COUNTS` | The exact row counts from Data_Catalog.md (e.g. 900,000 stars, 500,000 commits). |
| `MIN_ROW_COUNTS` | A floor so a small `SCALE_FACTOR` never shrinks a table down to an unusably small size. |
| `ROW_COUNTS` | The final, computed row count per table — this is what generators actually use. |
| `ID_START` | The starting primary-key number for each table (e.g. `users` start at 1001), aligned with the example IDs in Data_Catalog.md. |
| `PLATFORM_START_DATE` / `TODAY` / `DATASET_GENERATED_AT` | Date boundaries — nothing in the dataset is created before the platform start date or after "today". |
| `OUTPUT_DIR` | Where generated CSVs are saved (`Data_Generator/Output/`). |
| `ENABLE_DIRTY_DATA` | Master on/off switch for all data-quality issues. |
| `DIRTY_DATA_RATES` | How often each type of issue happens (e.g. `null_injection_rate: 0.03` = ~3% of eligible values). |

### 4.2 `Master_data.py` — Reference Lists

Holds static, reusable lists so generators don't duplicate the same data:

- **`LANGUAGES`** — 20 real programming languages with extension, type, and release year (feeds the `programming_languages` table).
- **`COUNTRY_CITIES`** — countries mapped to realistic cities, used for user/organization locations.
- **`ORG_TYPES`, `INDUSTRIES`** — used when generating organizations.
- **`MEMBER_ROLES`** — Owner / Admin / Maintainer / Member, with realistic weighting (most members are plain "Member").
- **`VISIBILITY_OPTIONS`, `LICENSES`, repo name word lists** — used to build realistic-looking repositories.
- **`BRANCH_NAME_POOL`** — realistic branch names like `feature/auth`, `bugfix/login-error`.
- **`COMMIT_MESSAGE_TEMPLATES` / `NOUNS`** — combined to build varied, realistic commit messages ("Fix login bug", "Add API support", etc.).
- **`PR_STATUS_OPTIONS`, `REVIEW_STATES`, `REVIEW_COMMENTS`** — pull request and review vocabulary.
- **`ISSUE_TYPES`, `PRIORITIES`, `ISSUE_TITLE_TEMPLATES`** — issue tracking vocabulary.
- **`RELEASE_TITLE_TEMPLATES`, `RELEASE_NOTES_POOL`** — release vocabulary.

Every list also has a matching **weights** list (e.g. `PR_STATUS_WEIGHTS`) so choices aren't perfectly uniform — for example, most pull requests end up "Merged" rather than an even 33/33/33 split, which mirrors real GitHub behaviour.

### 4.3 `Utils.py` — The Shared Toolbox

Helper functions every generator imports rather than rewriting:

| Function | What it does |
|---|---|
| `id_sequence(table, count)` | Returns the next N sequential IDs for a table, starting from `Config.ID_START`. |
| `random_datetime_between(start, end)` | A random timestamp between two dates. |
| `random_datetime_after(start, max_days_after)` | A random timestamp *after* a given date — used to guarantee children happen after their parent (e.g. a commit after its repo was created). |
| `weighted_choice(options, weights)` | Picks one option, respecting realistic probabilities instead of pure randomness. |
| `make_unique_usernames(...)` | Builds GitHub-style usernames and guarantees no two users get the same one. |
| `inject_nulls`, `inject_whitespace_case_issues`, `inject_bad_emails`, `inject_duplicate_rows`, `inject_inconsistent_date_format`, `inject_negative_numeric` | The "dirty data" functions — each corrupts a controlled, configurable percentage of a column or table, only when `Config.ENABLE_DIRTY_DATA` is `True`. |
| `save_csv(df, table_name)` | Writes a table to `Output/<table_name>.csv` and prints how many rows were saved. |

### 4.4 `Main.py` — The Orchestrator

This is the file you actually run (`python Main.py`). It doesn't generate any data itself — it just calls every generator **in the correct dependency order**, passing each one the parent data it needs:

```text
programming_languages, users, organizations   (no dependencies — generated first)
    -> repositories
    -> organization_members
    -> repository_languages
    -> repository_contributors
        -> branches
            -> commits
            -> pull_requests
                -> pull_request_reviews
        -> issues
        -> releases
        -> stars
        -> forks
```

After every table is generated, `Main.py` writes all 15 to CSV and prints a summary (row counts + total time taken).

One extra step worth noting: `organizations` is generated *before* `repositories` and `organization_members` exist, so its `total_repositories` / `total_members` counters start at 0. Once those child tables exist, `Organizations.backfill_counts()` recalculates the real totals and updates the organizations table — this keeps those denormalized counter columns accurate.

### 4.5 `Generators/*.py` — One File Per Table

Every generator follows the same pattern: build a list of realistic rows (respecting the business rules from your design docs), turn it into a table, optionally apply dirty-data injection, and return it. A few notable design decisions:

| Table | Key business rule enforced |
|---|---|
| `organization_members` | Exactly one "Owner" per organization; no duplicate user+org pairs. |
| `repository_languages` | Percentages for a repository sum to ~100%, and the primary language always gets the largest share. |
| `repository_contributors` | No duplicate contributor within the same repository; the repo owner is always included. |
| `branches` | Every repository gets exactly one `main` branch marked `is_default = True`. |
| `commits` | Every commit's branch actually belongs to that commit's repository; commit hashes are unique. |
| `pull_requests` | Source and target branches are different and both belong to the same repository; `merged_at` is only set when status is "Merged". |
| `pull_request_reviews` | The reviewer is (where possible) a different person than the PR's author. |
| `releases` | Release versions are unique and increasing within a repository (`1.0.0`, `1.0.1`, ...). |
| `stars` | A user can star a given repository only once, and can't star their own repository. |
| `forks` | A repository can never be forked into itself (`source_repository_id != forked_repository_id`). |

**Important note on dirty data placement:** duplicate-row injection is deliberately applied only to "leaf" tables that nothing else depends on (commits, stars, forks, issues, releases, etc.) and **not** to `organizations` or `repositories`. Those two are looped over directly by several child generators to guarantee rules like "exactly one default branch" — duplicating them would cause child generators to create conflicting structural data (e.g. two different "default" branches for one repository). Every other type of messiness (nulls, bad formatting, negative numbers) is still applied safely to those tables.

---

## 5. Data Quality Strategy (Bronze Layer)

| Issue type | Example | Typical rate |
|---|---|---|
| Missing values | Blank `bio`, `company`, `description`, `release_notes` | ~3% |
| Duplicate rows | Same primary key appears twice (simulates duplicate ingestion) | ~1% (leaf tables only) |
| Inconsistent formatting | `" python "`, `PYTHON`, `Python` all appearing for the same value | ~3% |
| Malformed emails | Missing `@`, doubled dots, stray spaces | ~2% |
| Inconsistent date formats | Timestamps stored in alternate string formats | ~2% |
| Stray negative numbers | A `followers` or `lines_added` value that's negative when it should never be | ~1% |

All rates are configurable in `Config.DIRTY_DATA_RATES`, and the whole system can be disabled with `Config.ENABLE_DIRTY_DATA = False` to produce perfectly clean data instead.

---

## 6. Validation Performed

Before delivery, the generated dataset was checked programmatically:

- **Referential integrity:** 0 orphaned foreign keys across all 15 tables (every child ID resolves to a real parent row).
- **One default branch per repository:** confirmed for all repositories.
- **Repository language percentages:** sum to ~100% for the vast majority of repositories (a small number are intentionally off due to the negative-numeric dirty-data injection — this is expected).
- **No duplicate contributor pairs**, **no duplicate release versions per repo**, **no duplicate star pairs**, **no owner starring their own repo**, **no self-forks** — all confirmed at 0 violations.
- **Dirty data present as expected:** duplicate primary keys, null values, and malformed emails all appear at approximately their configured rates.

---

## 7. How to Run

```bash
cd Data_Generator
python Main.py
```

Output CSVs are written to `Data/Raw/`.

### Changing the dataset size

Open `Config.py` and change:

```python
SCALE_FACTOR = 1.0   # generates the full ~2,025,320-row catalog volume
```

The default (`0.05`) generates roughly 100K rows in about 10 seconds; the full volume takes a few minutes.

### Turning off dirty data

```python
ENABLE_DIRTY_DATA = False
```

---

## 8. Output Tables

| Table | File |
|---|---|
| Programming Languages | `programming_languages.csv` |
| Users | `users.csv` |
| Organizations | `organizations.csv` |
| Organization Members | `organization_members.csv` |
| Repositories | `repositories.csv` |
| Repository Languages | `repository_languages.csv` |
| Repository Contributors | `repository_contributors.csv` |
| Branches | `branches.csv` |
| Commits | `commits.csv` |
| Pull Requests | `pull_requests.csv` |
| Pull Request Reviews | `pull_request_reviews.csv` |
| Issues | `issues.csv` |
| Releases | `releases.csv` |
| Stars | `stars.csv` |
| Forks | `forks.csv` |

---

## 9. Conclusion

This generator turns the entity, relationship, and catalog design documents into an actual, referentially-correct, appropriately messy dataset — ready to be loaded into PostgreSQL as the Bronze layer, cleaned into a Silver layer, and modeled into a Gold layer for SQL analysis and Power BI reporting.