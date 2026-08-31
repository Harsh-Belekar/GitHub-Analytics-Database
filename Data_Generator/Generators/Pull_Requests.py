"""
Generators/Pull_Requests.py
------------------------------
Table: pull_requests   (Fact)
Grain: one row per pull request.

Business rules honoured:
    Every PR belongs to one repository, has one creator, one source branch,
    and one target branch (source != target, both belong to the repo).
    - merged_at is only populated when status == 'Merged'.
    - A closed PR may or may not be merged (handled via status distribution).
"""

import random
import numpy as np
import pandas as pd

import Config
import Master_data
import Utils


def generate(repositories_df, branches_df, repository_contributors_df, target_row_count=None):
    target_n = target_row_count or Config.ROW_COUNTS["pull_requests"]

    repo_created = dict(zip(repositories_df["repository_id"], repositories_df["created_at"]))
    repo_owner = dict(zip(repositories_df["repository_id"], repositories_df["owner_id"]))
    branches_by_repo = branches_df.groupby("repository_id")["branch_id"].apply(list).to_dict()
    contributors_by_repo = repository_contributors_df.groupby("repository_id")["user_id"].apply(list).to_dict()

    eligible_repos = [r for r, b in branches_by_repo.items() if len(b) >= 2]
    if not eligible_repos:
        eligible_repos = list(branches_by_repo.keys())

    weights = np.array([len(contributors_by_repo.get(r, [1])) for r in eligible_repos], dtype=float)
    weights = weights / weights.sum()
    chosen_repos = np.random.choice(eligible_repos, size=target_n, p=weights)

    ids = Utils.id_sequence("pull_requests", target_n)
    rows = []

    for pr_id, repo_id in zip(ids, chosen_repos):
        branch_ids = branches_by_repo[repo_id]
        if len(branch_ids) >= 2:
            source_branch_id, target_branch_id = random.sample(branch_ids, 2)
        else:
            source_branch_id = target_branch_id = branch_ids[0]

        author_pool = contributors_by_repo.get(repo_id, [repo_owner[repo_id]])
        author_id = int(np.random.choice(author_pool))

        created_at = Utils.random_datetime_after(repo_created[repo_id], max_days_after=800)
        status = Utils.weighted_choice(Master_data.PR_STATUS_OPTIONS, Master_data.PR_STATUS_WEIGHTS)
        merged_at = Utils.random_datetime_after(created_at, max_days_after=30) if status == "Merged" else None

        title_noun = random.choice(Master_data.COMMIT_MESSAGE_NOUNS)
        rows.append({
            "pull_request_id": pr_id,
            "repository_id": repo_id,
            "user_id": author_id,
            "source_branch_id": source_branch_id,
            "target_branch_id": target_branch_id,
            "title": f"{random.choice(['Add', 'Fix', 'Update', 'Improve', 'Refactor'])} {title_noun}",
            "status": status,
            "files_changed": int(np.random.geometric(p=0.3)),
            "created_at": created_at,
            "merged_at": merged_at,
        })

    df = pd.DataFrame(rows)

    df = Utils.inject_whitespace_case_issues(df, "status")
    df = Utils.inject_negative_numeric(df, "files_changed")
    df = Utils.inject_duplicate_rows(df)

    return df
