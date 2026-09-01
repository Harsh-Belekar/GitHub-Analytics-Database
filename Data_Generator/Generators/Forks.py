"""
Generators/Forks.py
----------------------
Table: forks   (Fact — community engagement)
Grain: one row per repository fork.

Business rules honoured:
    - source_repository_id != forked_repository_id (a repo cannot be forked
    into itself).
    - Both reference existing rows in `repositories` (forked_repository_id
    is treated as the already-generated repository row that represents
    the forked copy).
    - user_id is the owner of the forked (destination) repository — i.e.
    the person who performed the fork now owns that copy.
"""

import numpy as np
import pandas as pd

import Config
import Utils


def generate(repositories_df, target_row_count=None):
    target_n = target_row_count or Config.ROW_COUNTS["forks"]

    repo_ids = repositories_df["repository_id"].to_numpy()
    repo_owner = dict(zip(repositories_df["repository_id"], repositories_df["owner_id"]))
    repo_created = dict(zip(repositories_df["repository_id"], repositories_df["created_at"]))

    if len(repo_ids) < 2:
        return pd.DataFrame(columns=[
            "fork_id", "source_repository_id", "forked_repository_id", "user_id", "forked_at",
        ])

    rows = []
    attempts = 0
    max_attempts = target_n * 5
    while len(rows) < target_n and attempts < max_attempts:
        attempts += 1
        source_id, forked_id = np.random.choice(repo_ids, size=2, replace=False)
        source_id, forked_id = int(source_id), int(forked_id)

        forked_at = Utils.random_datetime_after(repo_created[source_id], max_days_after=900)
        rows.append({
            "source_repository_id": source_id,
            "forked_repository_id": forked_id,
            "user_id": repo_owner[forked_id],
            "forked_at": forked_at,
        })

    ids = Utils.id_sequence("forks", len(rows))
    for row, fid in zip(rows, ids):
        row["fork_id"] = fid

    df = pd.DataFrame(rows)[[
        "fork_id", "source_repository_id", "forked_repository_id", "user_id", "forked_at",
    ]]

    df = Utils.inject_duplicate_rows(df)

    return df
