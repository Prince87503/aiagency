/*
  # Add HTTP method to webhooks table

  1. Changes
    - Add `method` column to `webhooks` table with default value 'POST'
    - Update existing 'Get Team Member' webhook to use 'GET' method
  
  2. Notes
    - This allows the UI to generate proper cURL commands for different HTTP methods
*/

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'webhooks' AND column_name = 'method'
  ) THEN
    ALTER TABLE webhooks ADD COLUMN method text DEFAULT 'POST';
  END IF;
END $$;

UPDATE webhooks 
SET method = 'GET' 
WHERE name = 'Get Team Member';