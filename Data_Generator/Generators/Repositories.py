"""
Generators/Repositories.py
----------------------------
Table: repositories   (Dimension — the central hub of the model)
Grain: one row per repository.

FKs: owner_id -> users.user_id
    organization_id -> organizations.organization_id (nullable)
    primary_language_id -> programming_languages.language_id
"""

import random
import numpy as np
import pandas as pd

import Config
import Master_data
import Utils


def _random_repo_name():
    prefix = random.choice(Master_data.REPO_NAME_PREFIXES)
    suffix = random.choice(Master_data.REPO_NAME_SUFFIXES)
    return f"{prefix}-{suffix}-{random.randint(1, 999)}"


def generate(users_df, organizations_df, languages_df):
    n = Config.ROW_COUNTS["repositories"]
    ids = Utils.id_sequence("repositories", n)

    user_ids = users_df["user_id"].tolist()
    user_created = dict(zip(users_df["user_id"], users_df["created_at"]))
    org_ids = organizations_df["organization_id"].tolist()
    language_ids = languages_df["language_id"].tolist()

    rows = []
    for i in range(n):
        owner_id = np.random.choice(user_ids)
        organization_id = np.random.choice(org_ids) if np.random.rand() < 0.35 else None
        primary_language_id = np.random.choice(language_ids)

        owner_created = user_created[owner_id]
        created_at = Utils.random_datetime_after(owner_created, max_days_after=1200)
        updated_at = Utils.random_datetime_after(created_at, max_days_after=500)

        rows.append({
            "repository_id": ids[i],
            "owner_id": owner_id,
            "organization_id": organization_id,
            "repository_name": _random_repo_name(),
            "description": f"A {np.random.choice(Master_data.INDUSTRIES).lower()} related project." if np.random.rand() > 0.15 else None,
            "visibility": Utils.weighted_choice(Master_data.VISIBILITY_OPTIONS, Master_data.VISIBILITY_WEIGHTS),
            "default_branch": "main",
            "primary_language_id": primary_language_id,
            "license": Utils.weighted_choice(Master_data.LICENSES, Master_data.LICENSE_WEIGHTS),
            "repository_size_mb": round(float(np.random.exponential(scale=120)), 2),
            "has_issues": bool(np.random.rand() > 0.1),
            "has_wiki": bool(np.random.rand() > 0.4),
            "has_projects": bool(np.random.rand() > 0.6),
            "archived": bool(np.random.rand() > 0.92),
            "created_at": created_at,
            "updated_at": updated_at,
        })

    df = pd.DataFrame(rows)

    df = Utils.inject_nulls(df, "description")
    df = Utils.inject_whitespace_case_issues(df, "visibility")
    df = Utils.inject_negative_numeric(df, "repository_size_mb")

    return df
