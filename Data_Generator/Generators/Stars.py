"""
Generators/Stars.py
----------------------
Table: stars   (Fact — community engagement)
Grain: one row per repository star.

Business rules honoured:
    - A user can star a repository only once (deduplicated pairs).
    - A repository owner cannot star their own repository.
"""

import numpy as np
import pandas as pd

import Config 
import Utils 


def generate(repositories_df, users_df, target_row_count=None):
    target_n = target_row_count or Config.ROW_COUNTS["stars"]

    repo_ids = repositories_df["repository_id"].to_numpy()
    repo_owner = dict(zip(repositories_df["repository_id"], repositories_df["owner_id"]))
    repo_created = dict(zip(repositories_df["repository_id"], repositories_df["created_at"]))
    user_ids = users_df["user_id"].to_numpy()

    pairs = set()
    rows = []
    max_attempts = target_n * 5
    attempts = 0

    while len(rows) < target_n and attempts < max_attempts:
        attempts += 1
        repo_id = int(np.random.choice(repo_ids))
        user_id = int(np.random.choice(user_ids))
        if user_id == repo_owner[repo_id]:
            continue
        if (user_id, repo_id) in pairs:
            continue
        pairs.add((user_id, repo_id))

        starred_at = Utils.random_datetime_after(repo_created[repo_id], max_days_after=900)
        rows.append({
            "repository_id": repo_id,
            "user_id": user_id,
            "starred_at": starred_at,
        })

    ids = Utils.id_sequence("stars", len(rows))
    for row, sid in zip(rows, ids):
        row["star_id"] = sid

    df = pd.DataFrame(rows)[["star_id", "repository_id", "user_id", "starred_at"]]

    df = Utils.inject_duplicate_rows(df)

    return df
