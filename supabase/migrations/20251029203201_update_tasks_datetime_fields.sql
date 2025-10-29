/*
  # Update Tasks Table Date Fields to DateTime

  1. Changes
    - Change `start_date` column from DATE to TIMESTAMPTZ to support date and time
    - Change `due_date` column from DATE to TIMESTAMPTZ to support date and time
    - Existing date values will be preserved and converted to timestamps (midnight UTC)

  2. Notes
    - Using TIMESTAMPTZ (timestamp with timezone) for proper timezone handling
    - Existing data will be automatically converted during the ALTER
    - NULL values remain NULL
*/

-- Update start_date to support datetime
ALTER TABLE tasks 
ALTER COLUMN start_date TYPE timestamptz 
USING start_date::timestamptz;

-- Update due_date to support datetime
ALTER TABLE tasks 
ALTER COLUMN due_date TYPE timestamptz 
USING due_date::timestamptz;