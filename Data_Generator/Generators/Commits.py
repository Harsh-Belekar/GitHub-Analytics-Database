"""
Generators/Commits.py
-----------------------
Table: commits   (Fact — largest table in the database)
Grain: one row per commit.

Business rules honoured:
    - Every commit belongs to one repository AND one branch that belongs to
    that same repository.
    - Every commit has one author, drawn from that repository's contributors.
    - commit_hash is unique.
    - lines_added / lines_deleted are non-negative (before dirty-data injection).
"""

import random
import numpy as np
import pandas as pd

import Config 
import Master_data 
import Utils 
from Utils import fake


def generate(repositories_df, branches_df, repository_contributors_df, target_row_count=None):
    target_n = target_row_count or Config.ROW_COUNTS["commits"]

    repo_created = dict(zip(repositories_df["repository_id"], repositories_df["created_at"]))
    repo_owner = dict(zip(repositories_df["repository_id"], repositories_df["owner_id"]))

    branches_by_repo = branches_df.groupby("repository_id").apply(
        lambda g: list(zip(g["branch_id"], g["created_at"]))
    ).to_dict()
    contributors_by_repo = repository_contributors_df.groupby("repository_id")["user_id"].apply(list).to_dict()

    repo_ids = repositories_df["repository_id"].tolist()
    weights = np.array([len(contributors_by_repo.get(r, [1])) for r in repo_ids], dtype=float)
    weights = weights / weights.sum()

    chosen_repos = np.random.choice(repo_ids, size=target_n, p=weights)

    ids = Utils.id_sequence("commits", target_n)
    hashes_seen = set()
    rows = []

    for commit_id, repo_id in zip(ids, chosen_repos):
        branch_options = branches_by_repo.get(repo_id)
        if not branch_options:
            continue
        branch_id, branch_created_at = random.choice(branch_options)

        author_pool = contributors_by_repo.get(repo_id, [repo_owner[repo_id]])
        author_id = int(np.random.choice(author_pool))

        commit_ts = Utils.random_datetime_after(branch_created_at, max_days_after=600)

        h = fake.sha1()
        while h in hashes_seen:
            h = fake.sha1()
        hashes_seen.add(h)

        template = random.choice(Master_data.COMMIT_MESSAGE_TEMPLATES)
        noun = random.choice(Master_data.COMMIT_MESSAGE_NOUNS)
        message = template.format(noun=noun) if "{noun}" in template else template

        rows.append({
            "commit_id": commit_id,
            "commit_hash": h,
            "repository_id": repo_id,
            "branch_id": branch_id,
            "user_id": author_id,
            "commit_message": message,
            "files_changed": int(np.random.geometric(p=0.35)),
            "lines_added": int(np.random.exponential(scale=40)),
            "lines_deleted": int(np.random.exponential(scale=15)),
            "commit_timestamp": commit_ts,
        })

    df = pd.DataFrame(rows)

    df = Utils.inject_negative_numeric(df, "lines_added")
    df = Utils.inject_negative_numeric(df, "lines_deleted")
    df = Utils.inject_nulls(df, "commit_message")
    df = Utils.inject_duplicate_rows(df)

    return df
