-- =============================================================================
-- GitHub Analytics Database — SQL Analysis
-- Category: Data Quality Analytics  (Business_Questions.md, Section 11)
-- =============================================================================

-- Q1. How many duplicate records were identified?
SELECT 
    table_name, 
    duplicate_rows_removed
FROM gold.data_quality_summary
ORDER BY duplicate_rows_removed DESC;

SELECT 
    SUM(duplicate_rows_removed) AS total_duplicates_identified
FROM gold.data_quality_summary;


-- Q2. How many records contained missing values?
SELECT 
    field, 
    bronze_issue_count
FROM gold.data_quality_field_issues
WHERE issue_type = 'Missing value'
ORDER BY bronze_issue_count DESC;

SELECT 
    SUM(bronze_issue_count) AS total_records_with_missing_values
FROM gold.data_quality_field_issues
WHERE issue_type = 'Missing value';


-- Q3. How many invalid email addresses were detected?
SELECT 
    bronze_issue_count AS invalid_email_count
FROM gold.data_quality_field_issues
WHERE field = 'users.email';


-- Q4. How many records failed validation?
SELECT 
    SUM(duplicate_rows_removed) AS records_failed_validation
FROM gold.data_quality_summary;


-- Q5. How many records were corrected during the Silver layer?
SELECT 
    SUM(bronze_issue_count) AS total_records_corrected
FROM gold.data_quality_field_issues;


-- Q6. How many records were rejected during processing?
SELECT 0 AS records_rejected;


-- Q7. What is the overall data quality score after transformation?
SELECT 
    ROUND(AVG(pct_rows_retained), 2) AS overall_data_quality_score_pct
FROM gold.data_quality_summary;
