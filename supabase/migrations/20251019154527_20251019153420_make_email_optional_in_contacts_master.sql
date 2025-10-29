/*
  # Make Email Optional in Contacts Master

  1. Changes
    - Remove NOT NULL constraint from email column
    - Remove UNIQUE constraint from email column
    - This allows contacts to be created without email addresses
    - Multiple contacts can have NULL emails

  2. Security
    - Existing RLS policies remain unchanged
*/

-- Remove NOT NULL constraint from email column
ALTER TABLE contacts_master 
  ALTER COLUMN email DROP NOT NULL;

-- Drop the unique constraint on email
-- First, we need to find and drop the unique constraint
DO $$
BEGIN
  -- Drop unique constraint if it exists
  IF EXISTS (
    SELECT 1 FROM pg_constraint 
    WHERE conname = 'contacts_master_email_key' 
    AND conrelid = 'contacts_master'::regclass
  ) THEN
    ALTER TABLE contacts_master DROP CONSTRAINT contacts_master_email_key;
  END IF;
END $$;

-- Add comment
COMMENT ON COLUMN contacts_master.email IS 'Contact email address (optional)';
