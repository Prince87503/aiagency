/*
  # Add created_by field to appointments table

  1. Changes
    - Add `created_by` column to appointments table (references admin_users)
    - Set default to NULL to allow appointments created without authentication
    
  2. Purpose
    - Track which user created each appointment
    - Enable audit trail for appointment creation
    - Support webhook payloads with creator information
*/

-- Add created_by column to appointments table
ALTER TABLE appointments 
ADD COLUMN IF NOT EXISTS created_by uuid REFERENCES admin_users(id) ON DELETE SET NULL;

-- Create index for created_by lookups
CREATE INDEX IF NOT EXISTS idx_appointments_created_by ON appointments(created_by);
