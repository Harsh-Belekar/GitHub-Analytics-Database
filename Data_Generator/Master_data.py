"""
Master_data.py
---------------
Static reference/lookup data shared across multiple generators.
Keeping this centralized avoids duplicating lists (countries, languages,
issue types, etc.) inside individual Generators/*.py modules.
"""

# Programming languages
LANGUAGES = [
    ("Python",     ".py",    "Interpreted", 1991, True),
    ("JavaScript", ".js",    "Interpreted", 1995, True),
    ("TypeScript", ".ts",    "Interpreted", 2012, True),
    ("Java",       ".java",  "Compiled",    1995, True),
    ("C",          ".c",     "Compiled",    1972, True),
    ("C++",        ".cpp",   "Compiled",    1985, True),
    ("C#",         ".cs",    "Compiled",    2000, True),
    ("Go",         ".go",    "Compiled",    2009, True),
    ("Rust",       ".rs",    "Compiled",    2010, True),
    ("Ruby",       ".rb",    "Interpreted", 1995, True),
    ("PHP",        ".php",   "Interpreted", 1995, True),
    ("Swift",      ".swift", "Compiled",    2014, True),
    ("Kotlin",     ".kt",    "Compiled",    2011, True),
    ("R",          ".r",     "Interpreted", 1993, False),
    ("Scala",      ".scala", "Compiled",    2004, False),
    ("Perl",       ".pl",    "Interpreted", 1987, False),
    ("Haskell",    ".hs",    "Compiled",    1990, False),
    ("Shell",      ".sh",    "Scripting",   1989, True),
    ("HTML",       ".html",  "Markup",      1993, True),
    ("CSS",        ".css",   "Stylesheet",  1996, True),
]

# Countries -> cities
COUNTRY_CITIES = {
    "India": ["Pune", "Mumbai", "Bengaluru", "Hyderabad", "Delhi", "Chennai"],
    "USA": ["San Francisco", "New York", "Seattle", "Austin", "Boston", "Chicago"],
    "UK": ["London", "Manchester", "Bristol", "Edinburgh"],
    "Germany": ["Berlin", "Munich", "Hamburg"],
    "Canada": ["Toronto", "Vancouver", "Montreal"],
    "Australia": ["Sydney", "Melbourne", "Brisbane"],
    "Japan": ["Tokyo", "Osaka"],
    "Singapore": ["Singapore"],
    "Netherlands": ["Amsterdam", "Rotterdam"],
    "Brazil": ["Sao Paulo", "Rio de Janeiro"],
    "France": ["Paris", "Lyon"],
    "Ireland": ["Dublin"],
}
COUNTRIES = list(COUNTRY_CITIES.keys())

# Organizations
ORG_TYPES = ["Company", "Non-Profit", "Educational", "Open Source Foundation", "Startup", "Government"]
INDUSTRIES = [
    "Artificial Intelligence", "Fintech", "E-commerce", "Healthcare", "Gaming",
    "Cybersecurity", "Cloud Computing", "EdTech", "Media & Entertainment",
    "Telecommunications", "Developer Tools", "Logistics",
]

# Users
ACCOUNT_TYPES = ["User", "Organization"]
ACCOUNT_TYPE_WEIGHTS = [0.97, 0.03]  # most GitHub accounts are individual users

# Organization Members
MEMBER_ROLES = ["Owner", "Admin", "Maintainer", "Member"]
MEMBER_ROLE_WEIGHTS = [0.05, 0.10, 0.15, 0.70]

# Repositories
VISIBILITY_OPTIONS = ["Public", "Private"]
VISIBILITY_WEIGHTS = [0.8, 0.2]
LICENSES = ["MIT", "Apache-2.0", "GPL-3.0", "BSD-3-Clause", "Mozilla-2.0", "Unlicense", None]
LICENSE_WEIGHTS = [0.35, 0.2, 0.1, 0.1, 0.05, 0.05, 0.15]

REPO_NAME_PREFIXES = [
    "data", "api", "web", "mobile", "cli", "core", "auth", "ml", "analytics",
    "dashboard", "engine", "sdk", "toolkit", "service", "platform", "app",
    "pipeline", "infra", "client", "server",
]
REPO_NAME_SUFFIXES = [
    "hub", "kit", "flow", "base", "gen", "sync", "lab", "box", "stack",
    "gateway", "manager", "builder", "tracker", "connect", "suite",
]

# Branches
BRANCH_NAME_POOL = [
    "main", "develop", "staging",
    "feature/dashboard", "feature/auth", "feature/api-v2", "feature/ui-refresh",
    "feature/payments", "feature/notifications", "feature/search",
    "bugfix/login-error", "bugfix/null-pointer", "bugfix/memory-leak",
    "hotfix/security-patch", "release/v1.0", "release/v2.0",
]

# Commits
COMMIT_MESSAGE_TEMPLATES = [
    "Fix {noun} bug", "Add {noun} support", "Update {noun} logic",
    "Refactor {noun} module", "Improve {noun} performance",
    "Remove deprecated {noun} code", "Fix typo in {noun}",
    "Add unit tests for {noun}", "Update dependencies for {noun}",
    "Fix authentication bug", "Optimize {noun} query", "Clean up {noun} formatting",
    "Merge branch into {noun}", "Bump version for {noun}",
    "Add documentation for {noun}", "Fix crash in {noun}",
]
COMMIT_MESSAGE_NOUNS = [
    "dashboard", "login", "API", "database", "UI", "cache", "export",
    "auth", "search", "payments", "notifications", "config", "logging",
    "pipeline", "scheduler", "parser",
]

# Pull Requests / Reviews
PR_STATUS_OPTIONS = ["Open", "Closed", "Merged"]
PR_STATUS_WEIGHTS = [0.15, 0.15, 0.70]
REVIEW_STATES = ["Approved", "Changes Requested", "Commented"]
REVIEW_STATE_WEIGHTS = [0.55, 0.25, 0.20]
REVIEW_COMMENTS = [
    "Looks good. Ready to merge.",
    "Please add test coverage for this change.",
    "Can you rename this variable for clarity?",
    "LGTM after the last round of fixes.",
    "Requesting changes on the error handling.",
    "Nice work, just a couple of nits.",
    "This needs a rebase before merging.",
    "Approved — nice cleanup.",
]

# Issues
ISSUE_TYPES = ["Bug", "Feature", "Documentation", "Enhancement"]
ISSUE_TYPE_WEIGHTS = [0.45, 0.25, 0.10, 0.20]
PRIORITIES = ["Low", "Medium", "High", "Critical"]
PRIORITY_WEIGHTS = [0.35, 0.35, 0.20, 0.10]
ISSUE_STATUS_OPTIONS = ["Open", "Closed"]
ISSUE_STATUS_WEIGHTS = [0.4, 0.6]
ISSUE_TITLE_TEMPLATES = [
    "{noun} export not working", "Crash when loading {noun}",
    "Add support for {noun}", "Improve {noun} performance",
    "Update documentation for {noun}", "{noun} throws null reference error",
    "Feature request: {noun} filters", "{noun} fails on large datasets",
    "UI glitch in {noun} view", "Memory leak in {noun}",
]

# Releases
RELEASE_TITLE_TEMPLATES = [
    "Stable Release {version}", "Bug Fix Release {version}",
    "Feature Release {version}", "Security Patch {version}",
    "Performance Release {version}", "Beta Release {version}",
]
RELEASE_NOTES_POOL = [
    "Performance improvements and bug fixes.",
    "Added new API endpoints and improved documentation.",
    "Fixed critical security vulnerability.",
    "Minor bug fixes and dependency updates.",
    "Improved UI responsiveness and fixed edge cases.",
    "Breaking changes: see migration guide.",
    "Initial public release.",
]
