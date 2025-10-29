/*
  # Remove Duplicate Contacts and Add Unique Constraint

  1. Changes
    - Remove duplicate contacts keeping only the oldest entry for each phone number
    - Add unique constraint to `phone` column in `contacts_master` table
  
  2. Security
    - Maintains data integrity by preventing duplicate phone numbers
    - Keeps the oldest contact record for each duplicate phone number
  
  3. Notes
    - Phone number is the primary identifier for contacts
    - This ensures data integrity and prevents duplicate contact entries in the future
*/

DO $$
BEGIN
  DELETE FROM contacts_master
  WHERE id IN (
    SELECT id
    FROM (
      SELECT id, 
             ROW_NUMBER() OVER (PARTITION BY phone ORDER BY created_at ASC) AS rn
      FROM contacts_master
    ) t
    WHERE t.rn > 1
  );

  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint 
    WHERE conname = 'contacts_master_phone_key'
  ) THEN
    ALTER TABLE contacts_master 
    ADD CONSTRAINT contacts_master_phone_key UNIQUE (phone);
  END IF;
END $$;
