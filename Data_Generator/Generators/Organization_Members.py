"""
Generators/Organization_Members.py
------------------------------------
Table: organization_members   (Bridge: users <-> organizations)
Grain: one row per organization membership.

Business rules honoured:
    - Every membership references exactly one org and one user.
    - A user cannot have duplicate memberships within the same organization.
    - Organization owners are unique per organization (exactly one 'Owner').
"""

import numpy as np
import pandas as pd

import Config
import Master_data
import Utils


def generate(users_df, organizations_df):
    target_n = Config.ROW_COUNTS["organization_members"]
    user_ids = users_df["user_id"].tolist()
    org_ids = organizations_df["organization_id"].tolist()
    org_created = dict(zip(organizations_df["organization_id"], organizations_df["created_at"]))

    pairs = set()
    rows = []
    owners_assigned = set()

    for org_id in org_ids:
        owner_id = np.random.choice(user_ids)
        pairs.add((owner_id, org_id))
        owners_assigned.add(org_id)
        rows.append((owner_id, org_id, "Owner"))

    attempts = 0
    max_attempts = target_n * 20
    while len(rows) < target_n and attempts < max_attempts:
        attempts += 1
        user_id = np.random.choice(user_ids)
        org_id = np.random.choice(org_ids)
        if (user_id, org_id) in pairs:
            continue
        pairs.add((user_id, org_id))
        role = Utils.weighted_choice(
            [r for r in Master_data.MEMBER_ROLES if r != "Owner"],
            Master_data.MEMBER_ROLE_WEIGHTS[1:],
        )
        rows.append((user_id, org_id, role))

    ids = Utils.id_sequence("organization_members", len(rows))
    out_rows = []
    for mid, (user_id, org_id, role) in zip(ids, rows):
        base_date = org_created[org_id]
        joined_at = Utils.random_datetime_after(base_date, max_days_after=800)
        out_rows.append({
            "membership_id": mid,
            "organization_id": org_id,
            "user_id": user_id,
            "role": role,
            "joined_at": joined_at,
            "is_public": bool(np.random.rand() > 0.3),
        })

    df = pd.DataFrame(out_rows)

    df = Utils.inject_whitespace_case_issues(df, "role")
    df = Utils.inject_duplicate_rows(df)

    return df
