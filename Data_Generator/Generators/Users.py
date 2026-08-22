"""
Generators/Users.py
--------------------
Table: users   (Master / Dimension, no foreign keys)
Grain: one row per GitHub user.
"""

import numpy as np
import pandas as pd

import Config 
import Master_data 
import Utils 
from Utils import fake


def generate():
    n = Config.ROW_COUNTS["users"]
    ids = Utils.id_sequence("users", n)

    first_names = [fake.first_name() for _ in range(n)]
    last_names = [fake.last_name() for _ in range(n)]
    usernames = Utils.make_unique_usernames(first_names, last_names)

    rows = []
    for i in range(n):
        country = np.random.choice(Master_data.COUNTRIES)
        city = np.random.choice(Master_data.COUNTRY_CITIES[country])
        account_type = Utils.weighted_choice(Master_data.ACCOUNT_TYPES, Master_data.ACCOUNT_TYPE_WEIGHTS)
        created_at = Utils.random_datetime_between(Config.PLATFORM_START_DATE, Config.TODAY)
        updated_at = Utils.random_datetime_after(created_at, max_days_after=600)

        rows.append({
            "user_id": ids[i],
            "first_name": first_names[i],
            "last_name": last_names[i],
            "username": usernames[i],
            "email": f"{usernames[i]}@{fake.free_email_domain()}",
            "country": country,
            "city": city if np.random.rand() > 0.05 else None,   # a few users skip city
            "bio": fake.sentence(nb_words=6) if np.random.rand() > 0.4 else None,
            "company": fake.company() if np.random.rand() > 0.6 else None,
            "hireable": bool(np.random.rand() > 0.6),
            "verified": bool(np.random.rand() > 0.85),
            "followers": int(np.random.exponential(scale=150)),
            "following": int(np.random.exponential(scale=80)),
            "public_repos": int(np.random.exponential(scale=15)),
            "public_gists": int(np.random.exponential(scale=4)),
            "account_type": account_type,
            "avatar_url": f"https://avatars.githubusercontent.com/u/{ids[i]}",
            "profile_url": f"https://github.com/{usernames[i]}",
            "created_at": created_at,
            "updated_at": updated_at,
        })

    df = pd.DataFrame(rows)

    df = Utils.inject_nulls(df, "bio")
    df = Utils.inject_nulls(df, "company")
    df = Utils.inject_bad_emails(df, "email")
    df = Utils.inject_whitespace_case_issues(df, "country")
    df = Utils.inject_negative_numeric(df, "followers")
    df = Utils.inject_duplicate_rows(df)

    return df
