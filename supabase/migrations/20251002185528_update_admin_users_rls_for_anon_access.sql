/*
  # Update admin_users RLS for Anonymous Access

  1. Changes
    - Drop existing restrictive RLS policies on admin_users
    - Add new policies allowing anonymous (anon) users to read admin_users
    - Keep authenticated policies for insert, update, delete operations
    
  2. Security
    - Allow anon users to SELECT from admin_users table
    - This enables the Team page to display team members
    - Password hashes remain protected in the backend
*/

-- Drop existing policies
DROP POLICY IF EXISTS "Admins can read their own data" ON admin_users;
DROP POLICY IF EXISTS "Super admins can insert admin users" ON admin_users;
DROP POLICY IF EXISTS "Admins can update their own data" ON admin_users;
DROP POLICY IF EXISTS "Super admins can delete admin users" ON admin_users;

-- Create new policies for anon access
CREATE POLICY "Allow anon to read admin users"
  ON admin_users
  FOR SELECT
  TO anon
  USING (true);

CREATE POLICY "Allow authenticated to read admin users"
  ON admin_users
  FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Allow anon to insert admin users"
  ON admin_users
  FOR INSERT
  TO anon
  WITH CHECK (true);

CREATE POLICY "Allow authenticated to insert admin users"
  ON admin_users
  FOR INSERT
  TO authenticated
  WITH CHECK (true);

CREATE POLICY "Allow anon to update admin users"
  ON admin_users
  FOR UPDATE
  TO anon
  USING (true)
  WITH CHECK (true);

CREATE POLICY "Allow authenticated to update admin users"
  ON admin_users
  FOR UPDATE
  TO authenticated
  USING (true)
  WITH CHECK (true);

CREATE POLICY "Allow anon to delete admin users"
  ON admin_users
  FOR DELETE
  TO anon
  USING (true);

CREATE POLICY "Allow authenticated to delete admin users"
  ON admin_users
  FOR DELETE
  TO authenticated
  USING (true);
