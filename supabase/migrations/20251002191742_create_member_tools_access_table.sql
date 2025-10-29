/*
  # Create Member Tools Access Table

  1. New Tables
    - `member_tools_access`
      - `id` (uuid, primary key) - Unique identifier for each access record
      - `enrolled_member_id` (uuid, foreign key) - References enrolled_members table
      - `tools_access` (jsonb) - Array of tools the member has access to
      - `created_at` (timestamptz) - When the access was granted
      - `updated_at` (timestamptz) - When the access was last modified
  
  2. Security
    - Enable RLS on `member_tools_access` table
    - Add policies for anon and authenticated users to read, insert, update, and delete records
    - This enables the Tools Access page to manage member tool permissions
  
  3. Indexes
    - Add index on enrolled_member_id for fast lookups
*/

-- Create member_tools_access table
CREATE TABLE IF NOT EXISTS member_tools_access (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  enrolled_member_id uuid NOT NULL REFERENCES enrolled_members(id) ON DELETE CASCADE,
  tools_access jsonb DEFAULT '[]'::jsonb,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now(),
  UNIQUE(enrolled_member_id)
);

-- Create index for faster lookups
CREATE INDEX IF NOT EXISTS idx_member_tools_access_enrolled_member_id 
  ON member_tools_access(enrolled_member_id);

-- Enable RLS
ALTER TABLE member_tools_access ENABLE ROW LEVEL SECURITY;

-- Create policies for anon access
CREATE POLICY "Allow anon to read member tools access"
  ON member_tools_access
  FOR SELECT
  TO anon
  USING (true);

CREATE POLICY "Allow authenticated to read member tools access"
  ON member_tools_access
  FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Allow anon to insert member tools access"
  ON member_tools_access
  FOR INSERT
  TO anon
  WITH CHECK (true);

CREATE POLICY "Allow authenticated to insert member tools access"
  ON member_tools_access
  FOR INSERT
  TO authenticated
  WITH CHECK (true);

CREATE POLICY "Allow anon to update member tools access"
  ON member_tools_access
  FOR UPDATE
  TO anon
  USING (true)
  WITH CHECK (true);

CREATE POLICY "Allow authenticated to update member tools access"
  ON member_tools_access
  FOR UPDATE
  TO authenticated
  USING (true)
  WITH CHECK (true);

CREATE POLICY "Allow anon to delete member tools access"
  ON member_tools_access
  FOR DELETE
  TO anon
  USING (true);

CREATE POLICY "Allow authenticated to delete member tools access"
  ON member_tools_access
  FOR DELETE
  TO authenticated
  USING (true);

-- Create trigger to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_member_tools_access_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_member_tools_access_updated_at_trigger
  BEFORE UPDATE ON member_tools_access
  FOR EACH ROW
  EXECUTE FUNCTION update_member_tools_access_updated_at();
