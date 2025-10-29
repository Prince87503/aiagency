/*
  # Update admin_sessions RLS for Anonymous Access

  1. Changes
    - Update RLS policies on admin_sessions table
    - Add policies allowing anonymous (anon) users to manage sessions
    
  2. Security
    - Allow anon users to SELECT, INSERT, UPDATE, DELETE from admin_sessions
    - This enables session management for non-authenticated admin logins
*/

-- Drop existing policies if any
DROP POLICY IF EXISTS "Admins can manage their own sessions" ON admin_sessions;

-- Create new policies for anon and authenticated access
CREATE POLICY "Allow anon to read admin sessions"
  ON admin_sessions
  FOR SELECT
  TO anon
  USING (true);

CREATE POLICY "Allow authenticated to read admin sessions"
  ON admin_sessions
  FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Allow anon to insert admin sessions"
  ON admin_sessions
  FOR INSERT
  TO anon
  WITH CHECK (true);

CREATE POLICY "Allow authenticated to insert admin sessions"
  ON admin_sessions
  FOR INSERT
  TO authenticated
  WITH CHECK (true);

CREATE POLICY "Allow anon to update admin sessions"
  ON admin_sessions
  FOR UPDATE
  TO anon
  USING (true)
  WITH CHECK (true);

CREATE POLICY "Allow authenticated to update admin sessions"
  ON admin_sessions
  FOR UPDATE
  TO authenticated
  USING (true)
  WITH CHECK (true);

CREATE POLICY "Allow anon to delete admin sessions"
  ON admin_sessions
  FOR DELETE
  TO anon
  USING (true);

CREATE POLICY "Allow authenticated to delete admin sessions"
  ON admin_sessions
  FOR DELETE
  TO authenticated
  USING (true);
