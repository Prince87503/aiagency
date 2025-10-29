/*
  # Update Appearance Settings RLS for System Defaults

  1. Changes
    - Allow anonymous users to update system default settings (user_id IS NULL)
    - This allows admins using OTP login to customize appearance without Supabase auth
    
  2. Security
    - System default (user_id IS NULL) is the single source of appearance settings
    - All users can read it
    - All users can update it (since it's a single admin system)
*/

-- Drop existing policies
DROP POLICY IF EXISTS "Anyone can read system default appearance settings" ON appearance_settings;

-- Recreate with update permissions
CREATE POLICY "Anyone can read system default appearance settings"
  ON appearance_settings
  FOR SELECT
  TO public
  USING (user_id IS NULL);

CREATE POLICY "Anyone can update system default appearance settings"
  ON appearance_settings
  FOR UPDATE
  TO public
  USING (user_id IS NULL)
  WITH CHECK (user_id IS NULL);