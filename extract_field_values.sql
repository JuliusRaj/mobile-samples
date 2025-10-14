-- SQL to extract field names, old values, and new values from delimited text
-- Input format: field_name:Old = "old_value",New ="new_value",field_name2:Old = "old_value2",New ="new_value2"

WITH input_data AS (
    SELECT 'e_id:Old = "",New ="1006120",event_id:Old = "",New ="NoticeofIntentDt",parent_id:Old = "",New ="ICD455"' AS input_text
),

-- Split by comma to get individual field entries
field_entries AS (
    SELECT 
        TRIM(value) AS field_entry
    FROM input_data,
    LATERAL unnest(string_to_array(input_text, ',')) AS value
    WHERE TRIM(value) != ''
),

-- Extract field name, old value, and new value from each entry
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

-- Final result
SELECT 
    field_name,
    old_value,
    new_value
FROM parsed_fields
ORDER BY field_name;