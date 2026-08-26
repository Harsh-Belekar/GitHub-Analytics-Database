"""
Generators/Repository_Languages.py
------------------------------------
Table: repository_languages   (Bridge: repositories <-> programming_languages)
Grain: one row per repository-language combination.

Business rules honoured:
    - No duplicate language per repository.
    - percentage_used values for a given repository sum to ~100%.
    - The repository's primary_language_id is always included and gets the
    largest share.
"""

import numpy as np
import pandas as pd

import Config 
import Utils 


def generate(repositories_df, target_row_count=None):
    target_n = target_row_count or Config.ROW_COUNTS["repository_languages"]
    repo_records = repositories_df[["repository_id", "primary_language_id"]].to_dict("records")

    rows = []
    avg_langs_per_repo = max(1, round(target_n / max(len(repo_records), 1)))
    avg_langs_per_repo = min(avg_langs_per_repo, 4)

    for rec in repo_records:
        repo_id = rec["repository_id"]
        primary_lang = rec["primary_language_id"]
        k = np.random.randint(1, avg_langs_per_repo + 2)
        k = max(1, min(k, 5))

        chosen = {primary_lang}
        while len(chosen) < k:
            chosen.add(int(np.random.choice(_language_pool())))
        chosen = list(chosen)

        raw = np.random.dirichlet(np.ones(len(chosen)))
        raw = np.sort(raw)[::-1]
        percentages = np.round(raw * 100, 2)
        diff = round(100 - percentages.sum(), 2)
        percentages[0] = round(percentages[0] + diff, 2)

        for lang_id, pct in zip(chosen, percentages):
            rows.append({
                "repository_id": repo_id,
                "language_id": lang_id,
                "percentage_used": pct,
            })

    ids = Utils.id_sequence("repository_languages", len(rows))
    for row, rid in zip(rows, ids):
        row["repository_language_id"] = rid

    df = pd.DataFrame(rows)[["repository_language_id", "repository_id", "language_id", "percentage_used"]]

    df = Utils.inject_negative_numeric(df, "percentage_used")
    df = Utils.inject_duplicate_rows(df)

    return df


_LANGUAGE_ID_CACHE = None


def _language_pool():
    global _LANGUAGE_ID_CACHE
    if _LANGUAGE_ID_CACHE is None:
        raise RuntimeError("Language pool not initialised — call set_language_pool() first.")
    return _LANGUAGE_ID_CACHE


def set_language_pool(language_ids):
    global _LANGUAGE_ID_CACHE
    _LANGUAGE_ID_CACHE = list(language_ids)
