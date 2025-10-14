-- SQL Server 2019 compatible solution to extract field names, old values, and new values
-- Input format: field_name:Old = "old_value",New ="new_value",field_name2:Old = "old_value2",New ="new_value2"

DECLARE @input_text NVARCHAR(MAX) = 'e_id:Old = "",New ="1006120",event_id:Old = "",New ="NoticeofIntentDt",parent_id:Old = "",New ="ICD455"';

WITH input_data AS (
    SELECT @input_text AS input_text
),
-- Split by comma to get individual field entries
field_entries AS (
    SELECT 
        LTRIM(RTRIM(value)) AS field_entry
    FROM input_data
    CROSS APPLY STRING_SPLIT(input_text, ',') AS value
    WHERE LTRIM(RTRIM(value)) != ''
),
-- Extract field name, old value, and new value from each entry
parsed_fields AS (
    SELECT 
        field_entry,
        -- Extract field name (everything before the first colon)
        LEFT(field_entry, CHARINDEX(':', field_entry) - 1) AS field_name,
        
        -- Extract old value (between 'Old = "' and '",New')
        CASE 
            WHEN field_entry LIKE '%Old = "%' AND field_entry LIKE '%,New%' THEN
                SUBSTRING(field_entry, 
                    CHARINDEX('Old = "', field_entry) + 7,
                    CHARINDEX('",New', field_entry) - CHARINDEX('Old = "', field_entry) - 7
                )
            ELSE ''
        END AS old_value,
        
        -- Extract new value (between 'New ="' and the end, removing trailing quote)
        CASE 
            WHEN field_entry LIKE '%New ="%' THEN
                LTRIM(RTRIM(SUBSTRING(field_entry, 
                    CHARINDEX('New =', field_entry) + 6,
                    LEN(field_entry) - CHARINDEX('New =', field_entry) - 5
                )))
            ELSE ''
        END AS new_value
    FROM field_entries
)
-- Final result
SELECT 
    field_name,
    old_value,
    new_value
FROM parsed_fields
ORDER BY field_name;

-- Alternative approach using a more robust parsing method
-- This handles edge cases better and is more readable
/*
DECLARE @input_text NVARCHAR(MAX) = 'e_id:Old = "",New ="1006120",event_id:Old = "",New ="NoticeofIntentDt",parent_id:Old = "",New ="ICD455"';

WITH input_data AS (
    SELECT @input_text AS input_text
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
        -- Field name: everything before the first colon
        LEFT(field_entry, CHARINDEX(':', field_entry) - 1) AS field_name,
        
        -- Old value: extract between quotes after "Old = "
        CASE 
            WHEN CHARINDEX('Old = "', field_entry) > 0 THEN
                SUBSTRING(field_entry,
                    CHARINDEX('Old = "', field_entry) + 7,
                    CHARINDEX('"', field_entry, CHARINDEX('Old = "', field_entry) + 7) - CHARINDEX('Old = "', field_entry) - 7
                )
            ELSE ''
        END AS old_value,
        
        -- New value: extract between quotes after "New ="
        CASE 
            WHEN CHARINDEX('New =', field_entry) > 0 THEN
                SUBSTRING(field_entry,
                    CHARINDEX('"', field_entry, CHARINDEX('New =', field_entry)) + 1,
                    LEN(field_entry) - CHARINDEX('"', field_entry, CHARINDEX('New =', field_entry)) - 1
                )
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
*/

-- Function-based approach (if you want to create a reusable function)
/*
CREATE OR ALTER FUNCTION dbo.ExtractFieldValues(@input_text NVARCHAR(MAX))
RETURNS TABLE
AS
RETURN
(
    WITH field_entries AS (
        SELECT 
            LTRIM(RTRIM(value)) AS field_entry
        FROM STRING_SPLIT(@input_text, ',') AS value
        WHERE LTRIM(RTRIM(value)) != ''
    ),
    parsed_fields AS (
        SELECT 
            field_entry,
            LEFT(field_entry, CHARINDEX(':', field_entry) - 1) AS field_name,
            CASE 
                WHEN field_entry LIKE '%Old = "%' AND field_entry LIKE '%,New%' THEN
                    SUBSTRING(field_entry, 
                        CHARINDEX('Old = "', field_entry) + 7,
                        CHARINDEX('",New', field_entry) - CHARINDEX('Old = "', field_entry) - 7
                    )
                ELSE ''
            END AS old_value,
            CASE 
                WHEN field_entry LIKE '%New ="%' THEN
                    LTRIM(RTRIM(SUBSTRING(field_entry, 
                        CHARINDEX('New =', field_entry) + 6,
                        LEN(field_entry) - CHARINDEX('New =', field_entry) - 5
                    )))
                ELSE ''
            END AS new_value
        FROM field_entries
    )
    SELECT 
        field_name,
        old_value,
        new_value
    FROM parsed_fields
);

-- Usage of the function:
-- SELECT * FROM dbo.ExtractFieldValues('e_id:Old = "",New ="1006120",event_id:Old = "",New ="NoticeofIntentDt",parent_id:Old = "",New ="ICD455"');
*/