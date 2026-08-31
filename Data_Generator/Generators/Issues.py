"""
Generators/Issues.py
-----------------------
Table: issues   (Fact)
Grain: one row per issue.

Business rules honoured:
    - Every issue belongs to one repository and is created by one user.
    - closed_at is only set when status == 'Closed', and is always
    after created_at.
"""

import random
import numpy as np
import pandas as pd

import Config 
import Master_data 
import Utils 


def generate(repositories_df, repository_contributors_df, target_row_count=None):
    target_n = target_row_count or Config.ROW_COUNTS["issues"]

    repo_created = dict(zip(repositories_df["repository_id"], repositories_df["created_at"]))
    repo_owner = dict(zip(repositories_df["repository_id"], repositories_df["owner_id"]))
    contributors_by_repo = repository_contributors_df.groupby("repository_id")["user_id"].apply(list).to_dict()

    repo_ids = repositories_df["repository_id"].tolist()
    chosen_repos = np.random.choice(repo_ids, size=target_n, replace=True)

    ids = Utils.id_sequence("issues", target_n)
    rows = []

    for issue_id, repo_id in zip(ids, chosen_repos):
        pool = contributors_by_repo.get(repo_id, [repo_owner[repo_id]])
        creator_id = int(np.random.choice(pool))

        created_at = Utils.random_datetime_after(repo_created[repo_id], max_days_after=800)
        status = Utils.weighted_choice(Master_data.ISSUE_STATUS_OPTIONS, Master_data.ISSUE_STATUS_WEIGHTS)
        closed_at = Utils.random_datetime_after(created_at, max_days_after=45) if status == "Closed" else None

        title_noun = random.choice(Master_data.COMMIT_MESSAGE_NOUNS)
        title_template = random.choice(Master_data.ISSUE_TITLE_TEMPLATES)
        title = title_template.format(noun=title_noun) if "{noun}" in title_template else title_template

        rows.append({
            "issue_id": issue_id,
            "repository_id": repo_id,
            "user_id": creator_id,
            "title": title,
            "issue_type": Utils.weighted_choice(Master_data.ISSUE_TYPES, Master_data.ISSUE_TYPE_WEIGHTS),
            "priority": Utils.weighted_choice(Master_data.PRIORITIES, Master_data.PRIORITY_WEIGHTS),
            "status": status,
            "created_at": created_at,
            "closed_at": closed_at,
        })

    df = pd.DataFrame(rows)

    df = Utils.inject_whitespace_case_issues(df, "priority")
    df = Utils.inject_nulls(df, "title")
    df = Utils.inject_duplicate_rows(df)

    return df
