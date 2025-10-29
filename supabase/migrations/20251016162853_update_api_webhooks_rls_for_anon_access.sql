/*
  # Update API Webhooks RLS for Anon Access

  1. Changes
    - Add anon policies for api_webhooks table
    - Allow anon users to insert, update, and delete webhooks
    - This matches the pattern used in other admin tables

  2. Security
    - Enable full CRUD access for anon users
    - This is intended for admin dashboard usage
*/

-- Drop existing policies if they exist
DROP POLICY IF EXISTS "Allow anon to read api webhooks" ON api_webhooks;
DROP POLICY IF EXISTS "Allow authenticated to read api webhooks" ON api_webhooks;
DROP POLICY IF EXISTS "Allow authenticated to insert api webhooks" ON api_webhooks;
DROP POLICY IF EXISTS "Allow authenticated to update api webhooks" ON api_webhooks;
DROP POLICY IF EXISTS "Allow authenticated to delete api webhooks" ON api_webhooks;

-- Create policies for anon users (full access)
CREATE POLICY "Allow anon to read api webhooks"
  ON api_webhooks
  FOR SELECT
  TO anon
  USING (true);

CREATE POLICY "Allow anon to insert api webhooks"
  ON api_webhooks
  FOR INSERT
  TO anon
  WITH CHECK (true);

CREATE POLICY "Allow anon to update api webhooks"
  ON api_webhooks
  FOR UPDATE
  TO anon
  USING (true)
  WITH CHECK (true);

CREATE POLICY "Allow anon to delete api webhooks"
  ON api_webhooks
  FOR DELETE
  TO anon
  USING (true);

-- Create policies for authenticated users (full access)
CREATE POLICY "Allow authenticated to read api webhooks"
  ON api_webhooks
  FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Allow authenticated to insert api webhooks"
  ON api_webhooks
  FOR INSERT
  TO authenticated
  WITH CHECK (true);

CREATE POLICY "Allow authenticated to update api webhooks"
  ON api_webhooks
  FOR UPDATE
  TO authenticated
  USING (true)
  WITH CHECK (true);

CREATE POLICY "Allow authenticated to delete api webhooks"
  ON api_webhooks
  FOR DELETE
  TO authenticated
  USING (true);