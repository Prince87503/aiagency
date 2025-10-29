/*
  # Update Attendance RLS for Anon Access

  1. Changes
    - Add policy to allow anon users to read all attendance records
    - This enables the attendance records table to display data

  2. Security
    - Read-only access for anon users
    - Write operations still controlled by existing policies
*/

-- Policy: Allow anon users to view all attendance
CREATE POLICY "Anon can view all attendance"
  ON attendance
  FOR SELECT
  TO anon
  USING (true);
