"""
Generators/Pull_Request_Reviews.py
--------------------------------------
Table: pull_request_reviews   (Fact)
Grain: one row per pull request review.

Business rules honoured:
    - Every review belongs to one PR and is submitted by one reviewer.
    - reviewed_at is always after the PR's created_at.
    - Reviewer is (where possible) a different user than the PR's creator.
"""

import random
import numpy as np
import pandas as pd

import Config 
import Master_data 
import Utils 


def generate(pull_requests_df, repository_contributors_df, target_row_count=None):
    target_n = target_row_count or Config.ROW_COUNTS["pull_request_reviews"]

    contributors_by_repo = repository_contributors_df.groupby("repository_id")["user_id"].apply(list).to_dict()

    pr_records = pull_requests_df[["pull_request_id", "repository_id", "user_id", "created_at"]].to_dict("records")

    n_prs = len(pr_records)
    chosen_idx = np.random.choice(n_prs, size=target_n, replace=True)

    ids = Utils.id_sequence("pull_request_reviews", target_n)
    rows = []

    for review_id, idx in zip(ids, chosen_idx):
        pr = pr_records[idx]
        pool = contributors_by_repo.get(pr["repository_id"], [pr["user_id"]])
        reviewer_candidates = [u for u in pool if u != pr["user_id"]] or pool
        reviewer_id = int(np.random.choice(reviewer_candidates))

        reviewed_at = Utils.random_datetime_after(pr["created_at"], max_days_after=20)
        review_state = Utils.weighted_choice(Master_data.REVIEW_STATES, Master_data.REVIEW_STATE_WEIGHTS)

        rows.append({
            "review_id": review_id,
            "pull_request_id": pr["pull_request_id"],
            "reviewer_id": reviewer_id,
            "review_state": review_state,
            "review_comment": random.choice(Master_data.REVIEW_COMMENTS) if np.random.rand() > 0.15 else None,
            "reviewed_at": reviewed_at,
        })

    df = pd.DataFrame(rows)
    
    df = Utils.inject_whitespace_case_issues(df, "review_state")
    df = Utils.inject_duplicate_rows(df)

    return df
