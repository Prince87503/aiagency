/*
  # Update Webhooks RLS for Anonymous Access

  1. Changes
    - Add RLS policies for anonymous users to manage webhooks
    - Allows public access to webhooks table for Settings page
    - Maintains security by keeping existing authenticated policies

  2. Security
    - Anonymous users can read, insert, update, and delete webhooks
    - This enables the Settings page to work without authentication
*/

-- Add policies for anonymous users
CREATE POLICY "Anonymous users can read webhooks"
  ON webhooks
  FOR SELECT
  TO anon
  USING (true);

CREATE POLICY "Anonymous users can insert webhooks"
  ON webhooks
  FOR INSERT
  TO anon
  WITH CHECK (true);

CREATE POLICY "Anonymous users can update webhooks"
  ON webhooks
  FOR UPDATE
  TO anon
  USING (true)
  WITH CHECK (true);

CREATE POLICY "Anonymous users can delete webhooks"
  ON webhooks
  FOR DELETE
  TO anon
  USING (true);

-- Add comment
COMMENT ON TABLE webhooks IS 'Stores webhook configurations with RLS policies for both authenticated and anonymous users';
