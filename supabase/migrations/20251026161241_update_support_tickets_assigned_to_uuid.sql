/*
  # Update Support Tickets assigned_to to UUID
  
  1. Changes
    - Convert `assigned_to` column from text to uuid
    - Add foreign key constraint to reference admin_users table
    - This ensures assigned_to values are valid admin user IDs
  
  2. Security
    - Maintains existing RLS policies
    - Ensures data integrity with foreign key constraint
*/

DO $$
BEGIN
  -- Drop existing data in assigned_to if it's not a valid UUID
  UPDATE support_tickets
  SET assigned_to = NULL
  WHERE assigned_to IS NOT NULL 
    AND assigned_to !~ '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$';

  -- Drop the column if it's text type and recreate as UUID
  IF EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'support_tickets' 
      AND column_name = 'assigned_to'
      AND data_type = 'text'
  ) THEN
    ALTER TABLE support_tickets DROP COLUMN assigned_to;
    ALTER TABLE support_tickets ADD COLUMN assigned_to uuid REFERENCES admin_users(id) ON DELETE SET NULL;
  END IF;
END $$;
