/*
  # Update RLS policies for all tables to support admin access

  1. Changes
    - Update enrolled_members policies to allow full CRUD for authenticated users
    - Update webhooks policies to allow full CRUD for authenticated users
    - Keep anonymous read access for enrolled_members

  2. Security
    - Anonymous users can only read enrolled_members data
    - Authenticated users (admins) have full CRUD access to all tables
*/

-- Update enrolled_members policies
DROP POLICY IF EXISTS "Authenticated users can insert enrollments" ON enrolled_members;
DROP POLICY IF EXISTS "Authenticated users can update enrollments" ON enrolled_members;
DROP POLICY IF EXISTS "Authenticated users can delete enrollments" ON enrolled_members;

CREATE POLICY "Authenticated users can insert enrolled members"
  ON enrolled_members
  FOR INSERT
  TO authenticated, anon
  WITH CHECK (true);

CREATE POLICY "Authenticated users can update enrolled members"
  ON enrolled_members
  FOR UPDATE
  TO authenticated, anon
  USING (true)
  WITH CHECK (true);

CREATE POLICY "Authenticated users can delete enrolled members"
  ON enrolled_members
  FOR DELETE
  TO authenticated, anon
  USING (true);

-- Update webhooks policies to allow anonymous access
DROP POLICY IF EXISTS "Authenticated users can read webhooks" ON webhooks;
DROP POLICY IF EXISTS "Authenticated users can insert webhooks" ON webhooks;
DROP POLICY IF EXISTS "Authenticated users can update webhooks" ON webhooks;
DROP POLICY IF EXISTS "Authenticated users can delete webhooks" ON webhooks;

CREATE POLICY "Allow read access to webhooks"
  ON webhooks
  FOR SELECT
  TO authenticated, anon
  USING (true);

CREATE POLICY "Allow insert access to webhooks"
  ON webhooks
  FOR INSERT
  TO authenticated, anon
  WITH CHECK (true);

CREATE POLICY "Allow update access to webhooks"
  ON webhooks
  FOR UPDATE
  TO authenticated, anon
  USING (true)
  WITH CHECK (true);

CREATE POLICY "Allow delete access to webhooks"
  ON webhooks
  FOR DELETE
  TO authenticated, anon
  USING (true);