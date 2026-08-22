"""
Generators/Organizations.py
-----------------------------
Table: organizations   (Master / Dimension, no foreign keys)
Grain: one row per organization.

NOTE: total_repositories / total_members are denormalized "as-of-generation"
counters (as specified in the catalog). They are recomputed AFTER
repositories and organization_members are generated — see Main.py, which
calls `backfill_counts()` once those tables exist.
"""

import numpy as np
import pandas as pd

import Config 
import Master_data 
import Utils 
from Utils import fake


def generate():
    n = Config.ROW_COUNTS["organizations"]
    ids = Utils.id_sequence("organizations", n)

    rows = []
    for i in range(n):
        name = fake.company()
        country = np.random.choice(Master_data.COUNTRIES)
        city = np.random.choice(Master_data.COUNTRY_CITIES[country])
        created_at = Utils.random_datetime_between(Config.PLATFORM_START_DATE, Config.TODAY)

        rows.append({
            "organization_id": ids[i],
            "organization_name": name,
            "organization_type": np.random.choice(Master_data.ORG_TYPES),
            "country": country,
            "city": city if np.random.rand() > 0.05 else None,
            "website": f"https://{name.lower().replace(' ', '').replace(',', '')}.com",
            "email": f"info@{name.lower().replace(' ', '').replace(',', '')}.com" if np.random.rand() > 0.1 else None,
            "industry": np.random.choice(Master_data.INDUSTRIES),
            "total_repositories": 0,
            "total_members": 0,
            "verified": bool(np.random.rand() > 0.7),
            "created_at": created_at,
        })

    df = pd.DataFrame(rows)

    df = Utils.inject_nulls(df, "website")
    df = Utils.inject_whitespace_case_issues(df, "organization_name")

    return df


def backfill_counts(org_df, repositories_df, org_members_df):
    """Recompute total_repositories / total_members from the actual
    generated child tables so the denormalized counters are consistent."""
    repo_counts = repositories_df.dropna(subset=["organization_id"]).groupby("organization_id").size()
    member_counts = org_members_df.groupby("organization_id").size()

    org_df["total_repositories"] = org_df["organization_id"].map(repo_counts).fillna(0).astype(int)
    org_df["total_members"] = org_df["organization_id"].map(member_counts).fillna(0).astype(int)
    return org_df
