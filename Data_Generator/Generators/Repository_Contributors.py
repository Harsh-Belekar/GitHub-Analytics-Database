"""
Generators/Repository_Contributors.py
----------------------------------------
Table: repository_contributors   (Bridge: repositories <-> users)
Grain: one row per repository contributor.

Business rules honoured:
    - No duplicate contributor within the same repository.
    - last_commit_date >= first_commit_date.
    - The repository owner is always included as a contributor.
"""

import numpy as np
import pandas as pd

import Config 
import Utils 


def generate(repositories_df, users_df, target_row_count=None):
    target_n = target_row_count or Config.ROW_COUNTS["repository_contributors"]
    user_ids = users_df["user_id"].tolist()

    repo_records = repositories_df[["repository_id", "owner_id", "created_at"]].to_dict("records")
    avg_contributors = max(1, round(target_n / max(len(repo_records), 1)))
    avg_contributors = min(avg_contributors, 15)

    rows = []
    for rec in repo_records:
        repo_id = rec["repository_id"]
        owner_id = rec["owner_id"]
        repo_created = rec["created_at"]

        k = max(1, np.random.randint(1, avg_contributors + 2))
        contributors = {owner_id}
        attempts = 0
        while len(contributors) < k and attempts < k * 10:
            contributors.add(int(np.random.choice(user_ids)))
            attempts += 1

        for user_id in contributors:
            first_commit = Utils.random_datetime_after(repo_created, max_days_after=900)
            last_commit = Utils.random_datetime_after(first_commit, max_days_after=400)
            rows.append({
                "repository_id": repo_id,
                "user_id": user_id,
                "total_commits": int(np.random.exponential(scale=60)) + 1,
                "first_commit_date": first_commit,
                "last_commit_date": last_commit,
            })

    ids = Utils.id_sequence("repository_contributors", len(rows))
    for row, cid in zip(rows, ids):
        row["contributor_id"] = cid

    df = pd.DataFrame(rows)[[
        "contributor_id", "repository_id", "user_id",
        "total_commits", "first_commit_date", "last_commit_date",
    ]]

    df = Utils.inject_negative_numeric(df, "total_commits")
    df = Utils.inject_duplicate_rows(df)

    return df
