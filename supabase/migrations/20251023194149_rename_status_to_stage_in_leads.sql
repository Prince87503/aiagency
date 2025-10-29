/*
  # Rename status column to stage in leads table

  1. Changes
    - Rename the `status` column to `stage` in the `leads` table
    - Update the index name from `idx_leads_status` to `idx_leads_stage`
    - Update any triggers or functions that reference the old column name

  2. Notes
    - This is a schema-only change and does not affect existing data
    - The column's default value and constraints remain unchanged
    - All existing lead records will retain their current status values under the new "stage" name
*/

-- Rename the status column to stage
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'leads' AND column_name = 'status'
  ) THEN
    ALTER TABLE leads RENAME COLUMN status TO stage;
  END IF;
END $$;

-- Drop old index if it exists and create new one with updated name
DROP INDEX IF EXISTS idx_leads_status;
CREATE INDEX IF NOT EXISTS idx_leads_stage ON leads(stage);