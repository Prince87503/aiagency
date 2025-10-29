/*
  # Update custom_lead_tabs RLS for Anonymous Access

  1. Changes
    - Update RLS policies on custom_lead_tabs table
    - Add policies allowing anonymous (anon) users to manage custom tabs
    
  2. Security
    - Allow anon users to SELECT, INSERT, UPDATE, DELETE from custom_lead_tabs
    - This enables custom tab management for admin users
*/

-- Drop existing policies
DROP POLICY IF EXISTS "Anyone can read active custom lead tabs" ON custom_lead_tabs;
DROP POLICY IF EXISTS "Authenticated users can insert custom lead tabs" ON custom_lead_tabs;
DROP POLICY IF EXISTS "Authenticated users can update custom lead tabs" ON custom_lead_tabs;
DROP POLICY IF EXISTS "Authenticated users can delete custom lead tabs" ON custom_lead_tabs;

-- Create new policies for anon and authenticated access
CREATE POLICY "Allow anon to read custom lead tabs"
  ON custom_lead_tabs
  FOR SELECT
  TO anon
  USING (true);

CREATE POLICY "Allow authenticated to read custom lead tabs"
  ON custom_lead_tabs
  FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Allow anon to insert custom lead tabs"
  ON custom_lead_tabs
  FOR INSERT
  TO anon
  WITH CHECK (true);

CREATE POLICY "Allow authenticated to insert custom lead tabs"
  ON custom_lead_tabs
  FOR INSERT
  TO authenticated
  WITH CHECK (true);

CREATE POLICY "Allow anon to update custom lead tabs"
  ON custom_lead_tabs
  FOR UPDATE
  TO anon
  USING (true)
  WITH CHECK (true);

CREATE POLICY "Allow authenticated to update custom lead tabs"
  ON custom_lead_tabs
  FOR UPDATE
  TO authenticated
  USING (true)
  WITH CHECK (true);

CREATE POLICY "Allow anon to delete custom lead tabs"
  ON custom_lead_tabs
  FOR DELETE
  TO anon
  USING (true);

CREATE POLICY "Allow authenticated to delete custom lead tabs"
  ON custom_lead_tabs
  FOR DELETE
  TO authenticated
  USING (true);