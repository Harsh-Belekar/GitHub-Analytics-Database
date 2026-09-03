/*
===============================================================================
Stored Procedure: Load Bronze Layer (Source -> Bronze)
===============================================================================
Script Purpose:
    This stored procedure loads data into the 'bronze' schema from external CSV files. 
    It performs the following actions:
    - Truncates the bronze tables before loading data.
    - Uses the `COPY FROM` command to load data from csv Files to bronze tables.

Database:
    PostgreSQL

Parameters:
    None. 
	This stored procedure does not accept any parameters or return any values.

Usage Example:
    CALL bronze.load_bronze();
===============================================================================
*/

CREATE OR REPLACE PROCEDURE bronze.load_bronze()
LANGUAGE PLPGSQL
AS $$
DECLARE 
    start_time TIMESTAMP; 
    end_time TIMESTAMP; 
    batch_start_time TIMESTAMP;
    batch_end_time TIMESTAMP;
    duration_seconds NUMERIC;
BEGIN
	batch_start_time := clock_timestamp(); -- Record start time
	RAISE NOTICE '================================================';
	RAISE NOTICE 'Loading Bronze Layer — GitHub Analytics Database';
	RAISE NOTICE '================================================';

    start_time := clock_timestamp(); -- Record start time
	RAISE NOTICE '>> Truncating Table: bronze.programming_languages';
	TRUNCATE TABLE bronze.programming_languages;
	RAISE NOTICE '>> Inserting Data Into: bronze.programming_languages';
	COPY bronze.programming_languages (language_id,language_name,file_extension,language_type,
                                        first_release_year,is_popular,created_at)
	FROM 'D:\Github_Data\programming_languages.csv'
	DELIMITER ','
	CSV
	HEADER;
	end_time := clock_timestamp(); -- Record end time
	duration_seconds := EXTRACT(EPOCH FROM (end_time - start_time));
	RAISE NOTICE '>> Load Duration: % seconds', duration_seconds;
    RAISE NOTICE '>> -------------';


	start_time := clock_timestamp(); -- Record start time
	RAISE NOTICE '>> Truncating Table: bronze.users';
	TRUNCATE TABLE bronze.users;
	RAISE NOTICE '>> Inserting Data Into: bronze.users';
	COPY bronze.users (user_id,first_name,last_name,username,email,country,
                        city,bio,company,hireable,verified,followers,following,
                        public_repos,public_gists,account_type,avatar_url,profile_url,
                        created_at,updated_at)
	FROM 'D:\Github_Data\users.csv'
	DELIMITER ','
	CSV
	HEADER;
	end_time := clock_timestamp(); -- Record end time
	duration_seconds := EXTRACT(EPOCH FROM (end_time - start_time));
	RAISE NOTICE '>> Load Duration: % seconds', duration_seconds;
    RAISE NOTICE '>> -------------';


	start_time := clock_timestamp(); -- Record start time
	RAISE NOTICE '>> Truncating Table: bronze.organizations';
	TRUNCATE TABLE bronze.organizations;
	RAISE NOTICE '>> Inserting Data Into: bronze.organizations';
	COPY bronze.organizations (organization_id,organization_name,organization_type,
                                country,city,website,email,industry,total_repositories,
                                total_members,verified,created_at)
	FROM 'D:\Github_Data\organizations.csv'
	DELIMITER ','
	CSV
	HEADER;
	end_time := clock_timestamp(); -- Record end time
	duration_seconds := EXTRACT(EPOCH FROM (end_time - start_time));
	RAISE NOTICE '>> Load Duration: % seconds', duration_seconds;
    RAISE NOTICE '>> -------------';


	start_time := clock_timestamp(); -- Record start time
	RAISE NOTICE '>> Truncating Table: bronze.organization_members';
	TRUNCATE TABLE bronze.organization_members;
	RAISE NOTICE '>> Inserting Data Into: bronze.organization_members';
	COPY bronze.organization_members (membership_id,organization_id,user_id,
										role,joined_at,is_public)
	FROM 'D:\Github_Data\organization_members.csv'
	DELIMITER ','
	CSV
	HEADER;
	end_time := clock_timestamp(); -- Record end time
	duration_seconds := EXTRACT(EPOCH FROM (end_time - start_time));
	RAISE NOTICE '>> Load Duration: % seconds', duration_seconds;
    RAISE NOTICE '>> -------------';


	start_time := clock_timestamp(); -- Record start time
	RAISE NOTICE '>> Truncating Table: bronze.repositories';
	TRUNCATE TABLE bronze.repositories;
	RAISE NOTICE '>> Inserting Data Into: bronze.repositories';
	COPY bronze.repositories (repository_id,owner_id,organization_id,repository_name,
								description,visibility,default_branch,primary_language_id,
								license,repository_size_mb,has_issues,has_wiki,
								has_projects,archived,created_at,updated_at)
	FROM 'D:\Github_Data\repositories.csv'
	DELIMITER ','
	CSV
	HEADER;
	end_time := clock_timestamp(); -- Record end time
	duration_seconds := EXTRACT(EPOCH FROM (end_time - start_time));
	RAISE NOTICE '>> Load Duration: % seconds', duration_seconds;
    RAISE NOTICE '>> -------------';


	start_time := clock_timestamp(); -- Record start time
	RAISE NOTICE '>> Truncating Table: bronze.repository_languages';
	TRUNCATE TABLE bronze.repository_languages;
	RAISE NOTICE '>> Inserting Data Into: bronze.repository_languages';
	COPY bronze.repository_languages (repository_language_id,repository_id,
										language_id,percentage_used)
	FROM 'D:\Github_Data\repository_languages.csv'
	DELIMITER ','
	CSV
	HEADER;
	end_time := clock_timestamp(); -- Record end time
	duration_seconds := EXTRACT(EPOCH FROM (end_time - start_time));
	RAISE NOTICE '>> Load Duration: % seconds', duration_seconds;
    RAISE NOTICE '>> -------------';


	start_time := clock_timestamp(); -- Record start time
	RAISE NOTICE '>> Truncating Table: bronze.repository_contributors';
	TRUNCATE TABLE bronze.repository_contributors;
	RAISE NOTICE '>> Inserting Data Into: bronze.repository_contributors';
	COPY bronze.repository_contributors (contributor_id,repository_id,user_id,total_commits,
											first_commit_date,last_commit_date)
	FROM 'D:\Github_Data\repository_contributors.csv'
	DELIMITER ','
	CSV
	HEADER;
	end_time := clock_timestamp(); -- Record end time
	duration_seconds := EXTRACT(EPOCH FROM (end_time - start_time));
	RAISE NOTICE '>> Load Duration: % seconds', duration_seconds;
    RAISE NOTICE '>> -------------';


	start_time := clock_timestamp(); -- Record start time
	RAISE NOTICE '>> Truncating Table: bronze.branches';
	TRUNCATE TABLE bronze.branches;
	RAISE NOTICE '>> Inserting Data Into: bronze.branches';
	COPY bronze.branches (branch_id,repository_id,branch_name,created_by,is_default,created_at)
	FROM 'D:\Github_Data\branches.csv'
	DELIMITER ','
	CSV
	HEADER;
	end_time := clock_timestamp(); -- Record end time
	duration_seconds := EXTRACT(EPOCH FROM (end_time - start_time));
	RAISE NOTICE '>> Load Duration: % seconds', duration_seconds;
    RAISE NOTICE '>> -------------';


	start_time := clock_timestamp(); -- Record start time
	RAISE NOTICE '>> Truncating Table: bronze.commits';
	TRUNCATE TABLE bronze.commits;
	RAISE NOTICE '>> Inserting Data Into: bronze.commits';
	COPY bronze.commits (commit_id,commit_hash,repository_id,branch_id,user_id,
							commit_message,files_changed,lines_added,
							lines_deleted,commit_timestamp)
	FROM 'D:\Github_Data\commits.csv'
	DELIMITER ','
	CSV
	HEADER;
	end_time := clock_timestamp(); -- Record end time
	duration_seconds := EXTRACT(EPOCH FROM (end_time - start_time));
	RAISE NOTICE '>> Load Duration: % seconds', duration_seconds;
    RAISE NOTICE '>> -------------';


	start_time := clock_timestamp(); -- Record start time
	RAISE NOTICE '>> Truncating Table: bronze.pull_requests';
	TRUNCATE TABLE bronze.pull_requests;
	RAISE NOTICE '>> Inserting Data Into: bronze.pull_requests';
	COPY bronze.pull_requests (pull_request_id,repository_id,user_id,source_branch_id,
								target_branch_id,title,status,files_changed,
								created_at,merged_at)
	FROM 'D:\Github_Data\pull_requests.csv'
	DELIMITER ','
	CSV
	HEADER;
	end_time := clock_timestamp(); -- Record end time
	duration_seconds := EXTRACT(EPOCH FROM (end_time - start_time));
	RAISE NOTICE '>> Load Duration: % seconds', duration_seconds;
    RAISE NOTICE '>> -------------';


	start_time := clock_timestamp(); -- Record start time
	RAISE NOTICE '>> Truncating Table: bronze.pull_request_reviews';
	TRUNCATE TABLE bronze.pull_request_reviews;
	RAISE NOTICE '>> Inserting Data Into: bronze.pull_request_reviews';
	COPY bronze.pull_request_reviews (review_id,pull_request_id,reviewer_id,
										review_state,review_comment,reviewed_at)
	FROM 'D:\Github_Data\pull_request_reviews.csv'
	DELIMITER ','
	CSV
	HEADER;
	end_time := clock_timestamp(); -- Record end time
	duration_seconds := EXTRACT(EPOCH FROM (end_time - start_time));
	RAISE NOTICE '>> Load Duration: % seconds', duration_seconds;
    RAISE NOTICE '>> -------------';


	start_time := clock_timestamp(); -- Record start time
	RAISE NOTICE '>> Truncating Table: bronze.issues';
	TRUNCATE TABLE bronze.issues;
	RAISE NOTICE '>> Inserting Data Into: bronze.issues';
	COPY bronze.issues (issue_id,repository_id,user_id,title,issue_type,
							priority,status,created_at,closed_at)
	FROM 'D:\Github_Data\issues.csv'
	DELIMITER ','
	CSV
	HEADER;
	end_time := clock_timestamp(); -- Record end time
	duration_seconds := EXTRACT(EPOCH FROM (end_time - start_time));
	RAISE NOTICE '>> Load Duration: % seconds', duration_seconds;
    RAISE NOTICE '>> -------------';


	start_time := clock_timestamp(); -- Record start time
	RAISE NOTICE '>> Truncating Table: bronze.releases';
	TRUNCATE TABLE bronze.releases;
	RAISE NOTICE '>> Inserting Data Into: bronze.releases';
	COPY bronze.releases (release_id,repository_id,tag_name,version,release_title,
							release_notes,published_by,published_at)
	FROM 'D:\Github_Data\releases.csv'
	DELIMITER ','
	CSV
	HEADER;
	end_time := clock_timestamp(); -- Record end time
	duration_seconds := EXTRACT(EPOCH FROM (end_time - start_time));
	RAISE NOTICE '>> Load Duration: % seconds', duration_seconds;
    RAISE NOTICE '>> -------------';


	start_time := clock_timestamp(); -- Record start time
	RAISE NOTICE '>> Truncating Table: bronze.stars';
	TRUNCATE TABLE bronze.stars;
	RAISE NOTICE '>> Inserting Data Into: bronze.stars';
	COPY bronze.stars (star_id,repository_id,user_id,starred_at)
	FROM 'D:\Github_Data\stars.csv'
	DELIMITER ','
	CSV
	HEADER;
	end_time := clock_timestamp(); -- Record end time
	duration_seconds := EXTRACT(EPOCH FROM (end_time - start_time));
	RAISE NOTICE '>> Load Duration: % seconds', duration_seconds;
    RAISE NOTICE '>> -------------';


	start_time := clock_timestamp(); -- Record start time
	RAISE NOTICE '>> Truncating Table: bronze.forks';
	TRUNCATE TABLE bronze.forks;
	RAISE NOTICE '>> Inserting Data Into: bronze.forks';
	COPY bronze.forks (fork_id,source_repository_id,forked_repository_id,user_id,forked_at)
	FROM 'D:\Github_Data\forks.csv'
	DELIMITER ','
	CSV
	HEADER;
	end_time := clock_timestamp(); -- Record end time
	duration_seconds := EXTRACT(EPOCH FROM (end_time - start_time));
	RAISE NOTICE '>> Load Duration: % seconds', duration_seconds;
    RAISE NOTICE '>> -------------';


    batch_end_time := clock_timestamp(); -- Record end time
	duration_seconds := EXTRACT(EPOCH FROM (batch_end_time - batch_start_time));
	RAISE NOTICE '==========================================';
	RAISE NOTICE '>> Loading Bronze Layer is Completed';
    RAISE NOTICE '>> Total Load Duration: % seconds ', duration_seconds;
	RAISE NOTICE '==========================================';

EXCEPTION
	WHEN others THEN
		RAISE NOTICE '==========================================';
		RAISE NOTICE '❌ ERROR OCCURED DURING LOADING BRONZE LAYER';
		RAISE NOTICE 'Error Message %', SQLERRM;
		RAISE NOTICE 'Error SQL State Code: %' , SQLSTATE;
		RAISE NOTICE '==========================================';
END
$$;