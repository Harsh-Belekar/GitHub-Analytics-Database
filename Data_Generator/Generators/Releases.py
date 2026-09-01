"""
Generators/Releases.py
-------------------------
Table: releases   (Fact)
Grain: one row per repository release.

Business rules honoured:
    - Every release belongs to one repository, published by one user.
    - Release version is unique within a repository (sequential major.minor.patch).
"""

import random
import numpy as np
import pandas as pd

import Config
import Master_data
import Utils


def _sequential_versions(n):
    """Produce n unique, increasing semantic versions e.g. 1.0.0, 1.1.0 ..."""
    versions = []
    major, minor, patch = 1, 0, 0
    for _ in range(n):
        versions.append(f"{major}.{minor}.{patch}")
        patch += 1
        if patch > 4:
            patch = 0
            minor += 1
            if minor > 9:
                minor = 0
                major += 1
    return versions


def generate(repositories_df, repository_contributors_df, target_row_count=None):
    target_n = target_row_count or Config.ROW_COUNTS["releases"]

    repo_created = dict(zip(repositories_df["repository_id"], repositories_df["created_at"]))
    repo_owner = dict(zip(repositories_df["repository_id"], repositories_df["owner_id"]))
    contributors_by_repo = repository_contributors_df.groupby("repository_id")["user_id"].apply(list).to_dict()

    repo_ids = repositories_df["repository_id"].tolist()
    avg_releases = max(1, round(target_n / max(len(repo_ids), 1)))

    rows = []
    for repo_id in repo_ids:
        n_releases = max(0, np.random.poisson(lam=avg_releases))
        if n_releases == 0:
            continue
        versions = _sequential_versions(n_releases)
        pool = contributors_by_repo.get(repo_id, [repo_owner[repo_id]])

        last_date = repo_created[repo_id]
        for version in versions:
            published_at = Utils.random_datetime_after(last_date, max_days_after=200)
            last_date = published_at
            publisher_id = int(np.random.choice(pool))
            rows.append({
                "repository_id": repo_id,
                "tag_name": f"v{version}",
                "version": version,
                "release_title": random.choice(Master_data.RELEASE_TITLE_TEMPLATES).format(version=version),
                "release_notes": random.choice(Master_data.RELEASE_NOTES_POOL) if np.random.rand() > 0.1 else None,
                "published_by": publisher_id,
                "published_at": published_at,
            })

    if len(rows) > target_n:
        rows = random.sample(rows, target_n)

    ids = Utils.id_sequence("releases", len(rows))
    for row, rid in zip(rows, ids):
        row["release_id"] = rid

    df = pd.DataFrame(rows)[[
        "release_id", "repository_id", "tag_name", "version", "release_title",
        "release_notes", "published_by", "published_at",
    ]]

    df = Utils.inject_nulls(df, "release_notes")
    df = Utils.inject_duplicate_rows(df)

    return df
