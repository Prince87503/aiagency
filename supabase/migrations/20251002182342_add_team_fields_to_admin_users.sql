/*
  # Add team management fields to admin_users table

  1. Changes
    - Add phone column for contact information
    - Add department column for team organization
    - Add status column to track active/inactive members
    - Update permissions JSONB to include all modules (automations, affiliates, support)
    - Add member_id column for easier reference

  2. Security
    - Maintain existing RLS policies
    - All new columns allow NULL for backward compatibility

  3. Notes
    - Existing admin users will have NULL values for new fields
    - Department field is flexible text for custom departments
    - Status field uses CHECK constraint for valid values
*/

-- Add new columns for team management
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'admin_users' AND column_name = 'phone'
  ) THEN
    ALTER TABLE admin_users ADD COLUMN phone text;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'admin_users' AND column_name = 'department'
  ) THEN
    ALTER TABLE admin_users ADD COLUMN department text;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'admin_users' AND column_name = 'status'
  ) THEN
    ALTER TABLE admin_users ADD COLUMN status text DEFAULT 'Active';
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'admin_users' AND column_name = 'member_id'
  ) THEN
    ALTER TABLE admin_users ADD COLUMN member_id text UNIQUE;
  END IF;
END $$;

-- Add check constraint for status field
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname = 'admin_users_status_check'
  ) THEN
    ALTER TABLE admin_users
    ADD CONSTRAINT admin_users_status_check
    CHECK (status IN ('Active', 'Inactive', 'Suspended'));
  END IF;
END $$;

-- Update default permissions to include all modules
ALTER TABLE admin_users
ALTER COLUMN permissions SET DEFAULT '{
  "enrolled_members": {"read": true, "insert": true, "update": true, "delete": true},
  "webhooks": {"read": true, "insert": true, "update": true, "delete": true},
  "leads": {"read": true, "insert": true, "update": true, "delete": true},
  "courses": {"read": true, "insert": true, "update": true, "delete": true},
  "billing": {"read": true, "insert": true, "update": true, "delete": true},
  "team": {"read": true, "insert": true, "update": true, "delete": true},
  "settings": {"read": true, "insert": true, "update": true, "delete": true},
  "automations": {"read": true, "insert": true, "update": true, "delete": true},
  "affiliates": {"read": true, "insert": true, "update": true, "delete": true},
  "support": {"read": true, "insert": true, "update": true, "delete": true}
}'::jsonb;

-- Update existing admin user with full permissions
UPDATE admin_users
SET permissions = '{
  "enrolled_members": {"read": true, "insert": true, "update": true, "delete": true},
  "webhooks": {"read": true, "insert": true, "update": true, "delete": true},
  "leads": {"read": true, "insert": true, "update": true, "delete": true},
  "courses": {"read": true, "insert": true, "update": true, "delete": true},
  "billing": {"read": true, "insert": true, "update": true, "delete": true},
  "team": {"read": true, "insert": true, "update": true, "delete": true},
  "settings": {"read": true, "insert": true, "update": true, "delete": true},
  "automations": {"read": true, "insert": true, "update": true, "delete": true},
  "affiliates": {"read": true, "insert": true, "update": true, "delete": true},
  "support": {"read": true, "insert": true, "update": true, "delete": true}
}'::jsonb,
department = 'Management',
status = 'Active'
WHERE email = 'admin@aiacademy.com';

-- Create index for member_id for faster lookups
CREATE INDEX IF NOT EXISTS idx_admin_users_member_id ON admin_users(member_id);
CREATE INDEX IF NOT EXISTS idx_admin_users_department ON admin_users(department);
CREATE INDEX IF NOT EXISTS idx_admin_users_status ON admin_users(status);