-- Universal SQL to extract field names, old values, and new values from delimited text
-- Input format: field_name:Old = "old_value",New ="new_value",field_name2:Old = "old_value2",New ="new_value2"

-- Method 1: PostgreSQL/MySQL approach
WITH input_data AS (
    SELECT 'e_id:Old = "",New ="1006120",event_id:Old = "",New ="NoticeofIntentDt",parent_id:Old = "",New ="ICD455"' AS input_text
),
field_entries AS (
    SELECT 
        TRIM(value) AS field_entry
    FROM input_data,
    LATERAL unnest(string_to_array(input_text, ',')) AS value
    WHERE TRIM(value) != ''
),
parsed_fields AS (
    SELECT 
        field_entry,
        -- Extract field name (everything before the first colon)
        SPLIT_PART(field_entry, ':', 1) AS field_name,
        
        -- Extract old value (between 'Old = "' and '",New')
        CASE 
            WHEN field_entry LIKE '%Old = "%' AND field_entry LIKE '%,New%' THEN
                SUBSTRING(field_entry, 
                    POSITION('Old = "' IN field_entry) + 7,
                    POSITION('",New' IN field_entry) - POSITION('Old = "' IN field_entry) - 7
                )
            ELSE ''
        END AS old_value,
        
        -- Extract new value (between 'New ="' and the end, removing trailing quote)
        CASE 
            WHEN field_entry LIKE '%New ="%' THEN
                TRIM(BOTH '"' FROM SUBSTRING(field_entry, POSITION('New ="' IN field_entry) + 6))
            ELSE ''
        END AS new_value
    FROM field_entries
)
SELECT 
    field_name,
    old_value,
    new_value
FROM parsed_fields
ORDER BY field_name;

-- Method 2: Alternative approach using REGEXP for databases that support it
-- (PostgreSQL, MySQL 8.0+, Oracle, etc.)
/*
WITH input_data AS (
    SELECT 'e_id:Old = "",New ="1006120",event_id:Old = "",New ="NoticeofIntentDt",parent_id:Old = "",New ="ICD455"' AS input_text
),
field_entries AS (
    SELECT 
        TRIM(value) AS field_entry
    FROM input_data,
    LATERAL unnest(string_to_array(input_text, ',')) AS value
    WHERE TRIM(value) != ''
),
parsed_fields AS (
    SELECT 
        field_entry,
        REGEXP_REPLACE(field_entry, ':.*', '') AS field_name,
        REGEXP_REPLACE(field_entry, '.*Old = "([^"]*)".*', '\1') AS old_value,
        REGEXP_REPLACE(field_entry, '.*New ="([^"]*)".*', '\1') AS new_value
    FROM field_entries
)
SELECT 
    field_name,
    old_value,
    new_value
FROM parsed_fields
ORDER BY field_name;
*/

-- Method 3: For SQL Server
/*
WITH input_data AS (
    SELECT 'e_id:Old = "",New ="1006120",event_id:Old = "",New ="NoticeofIntentDt",parent_id:Old = "",New ="ICD455"' AS input_text
),
field_entries AS (
    SELECT 
        LTRIM(RTRIM(value)) AS field_entry
    FROM input_data
    CROSS APPLY STRING_SPLIT(input_text, ',') AS value
    WHERE LTRIM(RTRIM(value)) != ''
),
parsed_fields AS (
    SELECT 
        field_entry,
        LEFT(field_entry, CHARINDEX(':', field_entry) - 1) AS field_name,
        SUBSTRING(field_entry, 
            CHARINDEX('Old = "', field_entry) + 7,
            CHARINDEX('",New', field_entry) - CHARINDEX('Old = "', field_entry) - 7
        ) AS old_value,
        SUBSTRING(field_entry, 
            CHARINDEX('New ="', field_entry) + 6,
            LEN(field_entry) - CHARINDEX('New ="', field_entry) - 5
        ) AS new_value
    FROM field_entries
)
SELECT 
    field_name,
    old_value,
    new_value
FROM parsed_fields
ORDER BY field_name;
*/