-- SQL Server 2019 solution to extract field names, old values, and new values
-- from the 'details' column of Table1
-- Input format: field_name:Old = "old_value",New ="new_value",field_name2:Old = "old_value2",New ="new_value2"

WITH field_entries AS (
    SELECT 
        t.id,  -- Assuming Table1 has an id column, adjust as needed
        LTRIM(RTRIM(value)) AS field_entry
    FROM Table1 t
    CROSS APPLY STRING_SPLIT(t.details, ',') AS value
    WHERE LTRIM(RTRIM(value)) != ''
),
parsed_fields AS (
    SELECT 
        id,
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
    id,
    field_name,
    old_value,
    new_value
FROM parsed_fields
ORDER BY id, field_name;