/*
  # Rename enrolled_member_id to contact_id in support_tickets

  1. Changes
    - Rename `enrolled_member_id` column to `contact_id` in support_tickets table
    - This reflects the new relationship with contacts_master instead of enrolled_members
  
  2. Notes
    - The column still references the same UUID values
    - Now points to contacts_master.id instead of enrolled_members.id
    - All existing data is preserved
*/

DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'support_tickets' AND column_name = 'enrolled_member_id'
  ) THEN
    ALTER TABLE support_tickets 
      RENAME COLUMN enrolled_member_id TO contact_id;
  END IF;
END $$;