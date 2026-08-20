"""
Config.py
---------
Central configuration for the GitHub Analytics Database data generator.

Everything that controls VOLUME, RANDOMNESS, OUTPUT LOCATION, and
DATA-QUALITY behaviour lives here so the individual generator modules
never hardcode magic numbers.
"""

# import os

RANDOM_SEED = 42 # REPRODUCIBILITY

SCALE_FACTOR = 0.05 # SCALE CONTROL

FULL_ROW_COUNTS = {
    "programming_languages": 20,  
    "users": 5_000,
    "organizations": 300,
    "organization_members": 8_000,
    "repositories": 12_000,
    "repository_languages": 20_000,
    "repository_contributors": 60_000,
    "branches": 45_000,
    "commits": 500_000,
    "pull_requests": 80_000,
    "pull_request_reviews": 120_000,
    "issues": 100_000,
    "releases": 25_000,
    "stars": 900_000,
    "forks": 150_000,
}

MIN_ROW_COUNTS = {
    "programming_languages": 20,
    "users": 200,
    "organizations": 30,
    "organization_members": 300,
    "repositories": 300,
    "repository_languages": 400,
    "repository_contributors": 500,
    "branches": 500,
    "commits": 2_000,
    "pull_requests": 500,
    "pull_request_reviews": 500,
    "issues": 500,
    "releases": 200,
    "stars": 2_000,
    "forks": 300,
}


def _scaled_row_counts():
    counts = {}
    for table, full in FULL_ROW_COUNTS.items():
        if table == "programming_languages":
            counts[table] = full  
        else:
            scaled = round(full * SCALE_FACTOR)
            counts[table] = max(scaled, FULL_ROW_COUNTS[table])
    return counts


ROW_COUNTS = _scaled_row_counts()

# PRIMARY KEY STARTING OFFSETS
ID_START = {
    "programming_languages": 1,
    "users": 1001,
    "organizations": 201,
    "organization_members": 5001,
    "repositories": 10001,
    "repository_languages": 80001,
    "repository_contributors": 100001,
    "branches": 90001,
    "commits": 5_000_001,
    "pull_requests": 300001,
    "pull_request_reviews": 500001,
    "issues": 400001,
    "releases": 800001,
    "stars": 1_000_001,
    "forks": 700001,
}


# DATE RANGES
PLATFORM_START_DATE = "2015-01-01"   
DATASET_GENERATED_AT = "2026-08-07 12:00:00"
TODAY = "2026-08-08"

OUTPUT_DIR = "./Data/Raw"
# os.path.join(os.path.dirname(os.path.abspath(__file__)), "Output")

ENABLE_DIRTY_DATA = True

DIRTY_DATA_RATES = {
    "null_injection_rate": 0.03,       # blank out an eligible nullable field
    "duplicate_row_rate": 0.01,        # duplicate a small fraction of rows
    "whitespace_case_rate": 0.03,      # "  Python " / "PYTHON" / "python"
    "bad_email_rate": 0.02,            # malformed email addresses
    "inconsistent_date_format_rate": 0.02,  # timestamps stored as strings in odd formats
    "negative_numeric_rate": 0.01,     # stray negative values where business rules say >= 0
}
