/*
  # Add pipeline support to leads table

  1. Changes
    - Add `pipeline_id` column to leads table (foreign key to pipelines)
    - Set default pipeline for existing leads
    - Update indexes

  2. Notes
    - Existing leads will be assigned to the default Sales Pipeline
    - The pipeline_id is optional to support backwards compatibility
*/

-- Add pipeline_id column to leads table
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'leads' AND column_name = 'pipeline_id'
  ) THEN
    ALTER TABLE leads ADD COLUMN pipeline_id uuid REFERENCES pipelines(id) ON DELETE SET NULL;
  END IF;
END $$;

-- Set default pipeline for existing leads
UPDATE leads
SET pipeline_id = (SELECT id FROM pipelines WHERE pipeline_id = 'P001' AND entity_type = 'lead' LIMIT 1)
WHERE pipeline_id IS NULL;

-- Create index for faster lookups
CREATE INDEX IF NOT EXISTS idx_leads_pipeline_id ON leads(pipeline_id);
