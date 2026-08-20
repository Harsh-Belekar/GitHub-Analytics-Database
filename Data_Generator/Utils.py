"""
Utils.py
--------
Shared helper functions used by every module in Generators/:
    * a single seeded Faker instance
    * ID sequence helpers
    * random date/timestamp helpers
    * weighted-choice helper
    * controlled "dirty data" injection (nulls, dupes, bad formats, ...)
    * CSV writer
"""

import os
import random
import numpy as np
import pandas as pd
from datetime import datetime
from faker import Faker

import Config

# Seeding — keeps every run reproducible
random.seed(Config.RANDOM_SEED)
np.random.seed(Config.RANDOM_SEED)
fake = Faker()
Faker.seed(Config.RANDOM_SEED)


# ID sequences
def id_sequence(table_name, count):
    """Return a list of `count` sequential integer IDs for a table,
    starting at the offset configured in Config.ID_START."""
    start = Config.ID_START[table_name]
    return list(range(start, start + count))


# Random date / timestamp helpers
def random_datetime_between(start_date, end_date):
    """start_date / end_date: 'YYYY-MM-DD' strings or datetime objects."""
    if isinstance(start_date, str):
        start_date = datetime.strptime(start_date, "%Y-%m-%d")
    if isinstance(end_date, str):
        end_date = datetime.strptime(end_date, "%Y-%m-%d")
    return fake.date_time_between(start_date=start_date, end_date=end_date)


def random_datetime_after(start_dt, max_days_after=365):
    """A random datetime strictly after start_dt, up to max_days_after later,
    never later than Config.TODAY."""
    today = datetime.strptime(Config.TODAY, "%Y-%m-%d")
    if isinstance(start_dt, str):
        start_dt = pd.to_datetime(start_dt)
    upper_bound = min(start_dt + pd.Timedelta(days=max_days_after), today)
    if upper_bound <= start_dt:
        upper_bound = start_dt + pd.Timedelta(hours=1)
    return fake.date_time_between(start_date=start_dt, end_date=upper_bound)


def weighted_choice(options, weights):
    return random.choices(options, weights=weights, k=1)[0]


def weighted_choices(options, weights, k):
    return random.choices(options, weights=weights, k=k)


# Uniqueness helpers
def make_unique_usernames(first_names, last_names):
    """Given parallel lists of first/last names, build guaranteed-unique
    GitHub-style usernames."""
    seen = {}
    usernames = []
    for f, l in zip(first_names, last_names):
        base = f"{f}.{l}".lower().replace(" ", "")
        base = "".join(ch for ch in base if ch.isalnum() or ch == ".")
        if base not in seen:
            seen[base] = 0
            usernames.append(base)
        else:
            seen[base] += 1
            usernames.append(f"{base}{seen[base]}")
    return usernames


# Dirty-data injection
def inject_nulls(df, column, rate=None):
    """Randomly blank out values in a nullable column."""
    if not Config.ENABLE_DIRTY_DATA:
        return df
    rate = rate if rate is not None else Config.DIRTY_DATA_RATES["null_injection_rate"]
    mask = np.random.rand(len(df)) < rate
    df.loc[mask, column] = None
    return df


def inject_whitespace_case_issues(df, column, rate=None):
    """Randomly add stray whitespace / flip case on a text column
    (e.g. 'Python' -> ' python ' or 'PYTHON')."""
    if not Config.ENABLE_DIRTY_DATA:
        return df
    rate = rate if rate is not None else Config.DIRTY_DATA_RATES["whitespace_case_rate"]
    mask = np.random.rand(len(df)) < rate
    idx = df.index[mask]

    def mangle(val):
        if val is None or (isinstance(val, float) and pd.isna(val)):
            return val
        choice = random.choice(["upper", "lower", "pad"])
        if choice == "upper":
            return str(val).upper()
        if choice == "lower":
            return str(val).lower()
        return f"  {val}  "

    df.loc[idx, column] = df.loc[idx, column].apply(mangle)
    return df


def inject_bad_emails(df, column, rate=None):
    """Corrupt a fraction of emails (missing @, double domain, stray spaces)."""
    if not Config.ENABLE_DIRTY_DATA:
        return df
    rate = rate if rate is not None else Config.DIRTY_DATA_RATES["bad_email_rate"]
    mask = np.random.rand(len(df)) < rate
    idx = df.index[mask]

    def mangle(val):
        if val is None or (isinstance(val, float) and pd.isna(val)):
            return val
        choice = random.choice(["no_at", "double_dot", "space", "upper"])
        if choice == "no_at":
            return str(val).replace("@", "_at_")
        if choice == "double_dot":
            return str(val).replace(".", "..", 1)
        if choice == "space":
            return f" {val} "
        return str(val).upper()

    df.loc[idx, column] = df.loc[idx, column].apply(mangle)
    return df


def inject_duplicate_rows(df, rate=None):
    """Append duplicate copies of a random fraction of rows (simulates
    duplicate ingestion in a raw Bronze feed). NOTE: this intentionally
    breaks primary-key uniqueness in the raw file — that's the point of a
    Bronze-layer data quality issue and is expected to be cleaned in Silver."""
    if not Config.ENABLE_DIRTY_DATA:
        return df
    rate = rate if rate is not None else Config.DIRTY_DATA_RATES["duplicate_row_rate"]
    n_dupes = int(len(df) * rate)
    if n_dupes == 0:
        return df
    dupes = df.sample(n=n_dupes, random_state=Config.RANDOM_SEED)
    return pd.concat([df, dupes], ignore_index=True)


def inject_inconsistent_date_format(df, column, rate=None):
    """Store some timestamps as alternate string formats instead of
    the standard 'YYYY-MM-DD HH:MM:SS'."""
    if not Config.ENABLE_DIRTY_DATA:
        return df
    rate = rate if rate is not None else Config.DIRTY_DATA_RATES["inconsistent_date_format_rate"]
    mask = np.random.rand(len(df)) < rate
    idx = df.index[mask]

    alt_formats = ["%d/%m/%Y %H:%M", "%m-%d-%Y", "%d %b %Y %I:%M %p"]

    def mangle(val):
        if val is None or (isinstance(val, float) and pd.isna(val)):
            return val
        try:
            dt = pd.to_datetime(val)
        except Exception:
            return val
        return dt.strftime(random.choice(alt_formats))

    df.loc[idx, column] = df.loc[idx, column].apply(mangle)
    return df


def inject_negative_numeric(df, column, rate=None):
    """Flip the sign on a small fraction of a numeric column that should
    always be >= 0 (simulates a bad upstream extract)."""
    if not Config.ENABLE_DIRTY_DATA:
        return df
    rate = rate if rate is not None else Config.DIRTY_DATA_RATES["negative_numeric_rate"]
    mask = (np.random.rand(len(df)) < rate) & (df[column] > 0)
    df.loc[mask, column] = -df.loc[mask, column]
    return df


# Output
def save_csv(df, table_name):
    os.makedirs(Config.OUTPUT_DIR, exist_ok=True)
    path = os.path.join(Config.OUTPUT_DIR, f"{table_name}.csv")
    df.to_csv(path, index=False)
    print(f"  -> {table_name}.csv  ({len(df):,} rows)")
    return path
