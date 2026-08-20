"""
Main.py
-------
Orchestrates dataset generation for the GitHub Analytics Database project.

Generation order strictly follows foreign-key dependency order so every
child table only ever references IDs that already exist in its parent
table(s):

    programming_languages, users, organizations  (no dependencies)
        -> repositories
        -> organization_members
        -> repository_languages
        -> repository_contributors
            -> branches
                -> commits
                -> pull_requests
                    -> pull_request_reviews
            -> issues
            -> releases
            -> stars
            -> forks

Run with:  python Main.py
"""

import time

import Config as Config
import Utils as Utils
from Generators import Branches, Commits, Forks, Issues, Organization_Members
from Generators import Programming_Languages, Pull_Request_Reviews, Pull_Requests
from Generators import Repositories, Repository_Languages, Stars, Repository_Contributors
from Generators import Organizations, Releases ,Users


def main():
    start = time.time()
    print(f"GitHub Analytics Database — Data Generation")
    print(f"SCALE_FACTOR = {Config.SCALE_FACTOR}  |  ENABLE_DIRTY_DATA = {Config.ENABLE_DIRTY_DATA}")
    print(f"Output directory: {Config.OUTPUT_DIR}\n")

    # Master / Dimension tables (no FK dependencies)
    print("Generating master tables...")
    languages_df = Programming_Languages.generate()
    users_df = Users.generate()
    organizations_df = Organizations.generate()

    # Repositories (the central hub) 
    print("Generating repositories...")
    Repository_Languages.set_language_pool(languages_df["language_id"].tolist())
    repositories_df = Repositories.generate(users_df, organizations_df, languages_df)

    # Organization membership (bridge) 
    print("Generating organization memberships...")
    organization_members_df = Organization_Members.generate(users_df, organizations_df)
    organizations_df = Organizations.backfill_counts(organizations_df, repositories_df, organization_members_df)

    # Repository-level bridges 
    print("Generating repository languages and contributors...")
    repository_languages_df = Repository_Languages.generate(repositories_df)
    repository_contributors_df = Repository_Contributors.generate(repositories_df, users_df)

    # Branches 
    print("Generating branches...")
    branches_df = Branches.generate(repositories_df, repository_contributors_df)

    # Commits / Pull Requests / Reviews 
    print("Generating commits...")
    commits_df = Commits.generate(repositories_df, branches_df, repository_contributors_df)

    print("Generating pull requests...")
    pull_requests_df = Pull_Requests.generate(repositories_df, branches_df, repository_contributors_df)

    print("Generating pull request reviews...")
    pull_request_reviews_df = Pull_Request_Reviews.generate(pull_requests_df, repository_contributors_df)

    # Issues / Releases / Stars / Forks 
    print("Generating issues...")
    issues_df = Issues.generate(repositories_df, repository_contributors_df)

    print("Generating releases...")
    releases_df = Releases.generate(repositories_df, repository_contributors_df)

    print("Generating stars...")
    stars_df = Stars.generate(repositories_df, users_df)

    print("Generating forks...")
    forks_df = Forks.generate(repositories_df)

    # Save everything 
    print("\nWriting CSV files...")
    tables = {
        "programming_languages": languages_df,
        "users": users_df,
        "organizations": organizations_df,
        "organization_members": organization_members_df,
        "repositories": repositories_df,
        "repository_languages": repository_languages_df,
        "repository_contributors": repository_contributors_df,
        "branches": branches_df,
        "commits": commits_df,
        "pull_requests": pull_requests_df,
        "pull_request_reviews": pull_request_reviews_df,
        "issues": issues_df,
        "releases": releases_df,
        "stars": stars_df,
        "forks": forks_df,
    }

    for name, df in tables.items():
        Utils.save_csv(df, name)

    elapsed = time.time() - start
    total_rows = sum(len(df) for df in tables.values())
    print(f"\nDone. {len(tables)} tables, {total_rows:,} total rows written in {elapsed:.1f}s.")

    return tables


if __name__ == "__main__":
    main()
