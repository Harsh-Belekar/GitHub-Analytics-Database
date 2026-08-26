"""
Generators/Programming_Languages.py
------------------------------------
Table: programming_languages   (Master / Dimension, no foreign keys)
Grain: one row per programming language.
"""

import pandas as pd
import Config
import Master_data
import Utils


def generate():
    n = Config.ROW_COUNTS["programming_languages"]
    languages = Master_data.LANGUAGES[:n]
    ids = Utils.id_sequence("programming_languages", len(languages))

    rows = []
    for lang_id, (name, ext, ltype, year, popular) in zip(ids, languages):
        rows.append({
            "language_id": lang_id,
            "language_name": name,
            "file_extension": ext,
            "language_type": ltype,
            "first_release_year": year,
            "is_popular": popular,
            "created_at": Config.DATASET_GENERATED_AT,
        })

    df = pd.DataFrame(rows)
    return df
