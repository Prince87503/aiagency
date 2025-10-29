/*
  # Update RLS policies for enrolled_members to allow anonymous access

  1. Changes
    - Drop existing authenticated-only SELECT policy
    - Add new policy allowing anonymous users to read enrolled members data
    - Keep other policies for authenticated users only (insert, update, delete)

  2. Security
    - Anonymous users can only read data (SELECT)
    - Only authenticated users can modify data (INSERT, UPDATE, DELETE)
*/

-- Drop the existing authenticated-only SELECT policy
DROP POLICY IF EXISTS "Authenticated users can view enrolled members" ON enrolled_members;

-- Create new policy allowing anonymous access for SELECT
CREATE POLICY "Allow anonymous read access to enrolled members"
  ON enrolled_members
  FOR SELECT
  TO anon, authenticated
  USING (true);
