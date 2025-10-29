/*
  # Add Attachment Fields to Support Tickets

  1. Changes
    - Add `attachment_1_url` column to store first file URL
    - Add `attachment_1_name` column to store first file name
    - Add `attachment_2_url` column to store second file URL
    - Add `attachment_2_name` column to store second file name
    - Add `attachment_3_url` column to store third file URL
    - Add `attachment_3_name` column to store third file name
  
  2. Purpose
    - Allow users to upload up to 3 files when creating support tickets
    - Store both the file URL (from storage) and original filename for display
*/

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'support_tickets' AND column_name = 'attachment_1_url'
  ) THEN
    ALTER TABLE support_tickets 
      ADD COLUMN attachment_1_url text,
      ADD COLUMN attachment_1_name text,
      ADD COLUMN attachment_2_url text,
      ADD COLUMN attachment_2_name text,
      ADD COLUMN attachment_3_url text,
      ADD COLUMN attachment_3_name text;
  END IF;
END $$;