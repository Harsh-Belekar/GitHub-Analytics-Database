/*
===============================================================================
Cleaning Helper Functions
===============================================================================
Script Purpose:
    Shared functions used by silver.load_silver() to standardize raw Bronze
    text values into proper types. Kept generic and reusable across tables,
    mirroring the same helper-function pattern used elsewhere in this
    project's ETL (e.g. fn_parse_date, fn_to_boolean).
===============================================================================
*/

CREATE SCHEMA IF NOT EXISTS cleaning;

-- -----------------------------------------------------------------------------
-- cleaning.fn_parse_date
-- Parses a raw text timestamp into TIMESTAMP. Tries the standard format
-- produced by the generator first, then a couple of common alternates.
-- Returns NULL for blank or unparseable input rather than raising an error,
-- so a single bad value never aborts the whole load.
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION cleaning.fn_parse_date(raw_value TEXT)
RETURNS TIMESTAMP
LANGUAGE PLPGSQL
AS $$
DECLARE
    cleaned TEXT := TRIM(raw_value);
BEGIN
    IF cleaned IS NULL OR cleaned = '' THEN
        RETURN NULL;
    END IF;

    BEGIN
        RETURN cleaned::TIMESTAMP;                          -- YYYY-MM-DD HH24:MI:SS[.US]
    EXCEPTION WHEN others THEN
        NULL; -- fall through to next attempt
    END;

    BEGIN
        RETURN TO_TIMESTAMP(cleaned, 'DD/MM/YYYY HH24:MI');
    EXCEPTION WHEN others THEN
        NULL;
    END;

    BEGIN
        RETURN TO_TIMESTAMP(cleaned, 'MM-DD-YYYY');
    EXCEPTION WHEN others THEN
        NULL;
    END;

    BEGIN
        RETURN TO_TIMESTAMP(cleaned, 'DD Mon YYYY HH12:MI AM');
    EXCEPTION WHEN others THEN
        NULL;
    END;

    RETURN NULL; -- genuinely unparseable
END;
$$;

-- -----------------------------------------------------------------------------
-- cleaning.fn_to_boolean
-- Normalizes common truthy/falsy text representations into BOOLEAN.
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION cleaning.fn_to_boolean(raw_value TEXT)
RETURNS BOOLEAN
LANGUAGE PLPGSQL
AS $$
DECLARE
    cleaned TEXT := LOWER(TRIM(raw_value));
BEGIN
    IF cleaned IS NULL OR cleaned = '' THEN
        RETURN NULL;
    ELSIF cleaned IN ('true', 't', '1', 'yes', 'y') THEN
        RETURN TRUE;
    ELSIF cleaned IN ('false', 'f', '0', 'no', 'n') THEN
        RETURN FALSE;
    ELSE
        RETURN NULL;
    END IF;
END;
$$;

-- -----------------------------------------------------------------------------
-- cleaning.fn_clean_email
-- Best-effort email cleanup: lowercases, trims, strips stray internal
-- spaces, undoes the "@" -> "_at_" substitution and collapsed doubled dots
-- (the specific corruption patterns this project's Bronze generator uses).
-- Does not drop or null out unrecoverable values — email is NOT NULL in
-- Silver, so a best-effort cleaned string is kept even if still imperfect.
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION cleaning.fn_clean_email(raw_value TEXT)
RETURNS TEXT
LANGUAGE PLPGSQL
AS $$
DECLARE
    cleaned TEXT;
BEGIN
    IF raw_value IS NULL THEN
        RETURN NULL;
    END IF;

    cleaned := LOWER(TRIM(raw_value));
    cleaned := REPLACE(cleaned, ' ', '');
    cleaned := REPLACE(cleaned, '_at_', '@');
    cleaned := REGEXP_REPLACE(cleaned, '\.{2,}', '.', 'g');

    RETURN cleaned;
END;
$$;
