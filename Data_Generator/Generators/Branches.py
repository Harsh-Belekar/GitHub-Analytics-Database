"""
Generators/Branches.py
------------------------
Table: branches   (Dimension)
Grain: one row per repository branch.

Business rules honoured:
    - Every repository has exactly one default branch ('main').
    - Branch names are unique within the same repository.
"""

import random
import numpy as np
import pandas as pd

import Config 
import Master_data 
import Utils 


def generate(repositories_df, repository_contributors_df, target_row_count=None):
    target_n = target_row_count or Config.ROW_COUNTS["branches"]

    repo_owner = dict(zip(repositories_df["repository_id"], repositories_df["owner_id"]))
    repo_created = dict(zip(repositories_df["repository_id"], repositories_df["created_at"]))

    contributors_by_repo = repository_contributors_df.groupby("repository_id")["user_id"].apply(list).to_dict()

    repo_ids = repositories_df["repository_id"].tolist()
    extra_branches_needed = max(0, target_n - len(repo_ids))
    avg_extra_per_repo = extra_branches_needed / max(len(repo_ids), 1)

    non_default_names = [b for b in Master_data.BRANCH_NAME_POOL if b != "main"]

    rows = []
    for repo_id in repo_ids:
        created_at = repo_created[repo_id]
        owner_id = repo_owner[repo_id]

        rows.append({
            "repository_id": repo_id,
            "branch_name": "main",
            "created_by": owner_id,
            "is_default": True,
            "created_at": created_at,
        })

        n_extra = min(np.random.poisson(lam=max(avg_extra_per_repo, 0.1)), len(non_default_names))
        chosen_names = random.sample(non_default_names, n_extra) if n_extra else []
        pool = contributors_by_repo.get(repo_id, [owner_id])

        for name in chosen_names:
            branch_created_at = Utils.random_datetime_after(created_at, max_days_after=700)
            rows.append({
                "repository_id": repo_id,
                "branch_name": name,
                "created_by": int(np.random.choice(pool)),
                "is_default": False,
                "created_at": branch_created_at,
            })

    ids = Utils.id_sequence("branches", len(rows))
    for row, bid in zip(rows, ids):
        row["branch_id"] = bid

    df = pd.DataFrame(rows)[[
        "branch_id", "repository_id", "branch_name", "created_by", "is_default", "created_at",
    ]]

    df = Utils.inject_whitespace_case_issues(df, "branch_name")
    df = Utils.inject_duplicate_rows(df)

    return df
