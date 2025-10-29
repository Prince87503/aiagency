/*
  # Add Affiliate ID to Leads Table

  1. Changes
    - Add `affiliate_id` column to `leads` table to track which affiliate partner created the lead
    - Add foreign key constraint to `affiliates` table
    - Add index on `affiliate_id` for faster filtering
  
  2. Security
    - Existing RLS policies remain in place
*/

-- Add affiliate_id column to leads table
DO $$ 
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'leads' AND column_name = 'affiliate_id'
  ) THEN
    ALTER TABLE leads ADD COLUMN affiliate_id uuid REFERENCES affiliates(id) ON DELETE SET NULL;
  END IF;
END $$;

-- Create index for affiliate_id
CREATE INDEX IF NOT EXISTS idx_leads_affiliate_id ON leads(affiliate_id);