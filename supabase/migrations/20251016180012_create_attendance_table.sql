/*
  # Create Attendance Management Table

  1. New Tables
    - `attendance`
      - `id` (uuid, primary key)
      - `admin_user_id` (uuid, foreign key to admin_users)
      - `date` (date) - Attendance date
      - `check_in_time` (timestamptz) - Check-in timestamp
      - `check_out_time` (timestamptz) - Check-out timestamp (nullable)
      - `check_in_selfie_url` (text) - URL to selfie image
      - `check_in_location` (jsonb) - GPS coordinates {lat, lng, address}
      - `status` (text) - present, absent, late, half_day
      - `notes` (text) - Optional notes
      - `created_at` (timestamptz)
      - `updated_at` (timestamptz)

  2. Security
    - Enable RLS on `attendance` table
    - Add policies for authenticated users (admin role) to manage attendance
    - Add policy for users to view their own attendance
    - Add policy for anon users to mark attendance (for mobile app support)

  3. Indexes
    - Index on admin_user_id for faster lookups
    - Index on date for date-based queries
    - Composite index on admin_user_id and date for unique constraint
*/

-- Create attendance table
CREATE TABLE IF NOT EXISTS attendance (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  admin_user_id uuid NOT NULL REFERENCES admin_users(id) ON DELETE CASCADE,
  date date NOT NULL DEFAULT CURRENT_DATE,
  check_in_time timestamptz NOT NULL DEFAULT now(),
  check_out_time timestamptz,
  check_in_selfie_url text,
  check_in_location jsonb,
  status text DEFAULT 'present',
  notes text,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now(),
  CONSTRAINT unique_user_date UNIQUE (admin_user_id, date)
);

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_attendance_user_id ON attendance(admin_user_id);
CREATE INDEX IF NOT EXISTS idx_attendance_date ON attendance(date);
CREATE INDEX IF NOT EXISTS idx_attendance_status ON attendance(status);

-- Enable RLS
ALTER TABLE attendance ENABLE ROW LEVEL SECURITY;

-- Policy: Allow authenticated admin users to view all attendance
CREATE POLICY "Admins can view all attendance"
  ON attendance
  FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM admin_users
      WHERE admin_users.id = auth.uid()
      AND admin_users.role IN ('Admin', 'Super Admin')
    )
  );

-- Policy: Allow users to view their own attendance
CREATE POLICY "Users can view own attendance"
  ON attendance
  FOR SELECT
  TO authenticated
  USING (admin_user_id = auth.uid());

-- Policy: Allow anon users to insert attendance (for mark attendance)
CREATE POLICY "Anon can mark attendance"
  ON attendance
  FOR INSERT
  TO anon
  WITH CHECK (true);

-- Policy: Allow authenticated users to insert their own attendance
CREATE POLICY "Users can mark own attendance"
  ON attendance
  FOR INSERT
  TO authenticated
  WITH CHECK (admin_user_id = auth.uid());

-- Policy: Allow anon users to update attendance (for check out)
CREATE POLICY "Anon can update attendance"
  ON attendance
  FOR UPDATE
  TO anon
  USING (true)
  WITH CHECK (true);

-- Policy: Allow users to update their own attendance
CREATE POLICY "Users can update own attendance"
  ON attendance
  FOR UPDATE
  TO authenticated
  USING (admin_user_id = auth.uid())
  WITH CHECK (admin_user_id = auth.uid());

-- Policy: Allow admins to update any attendance
CREATE POLICY "Admins can update all attendance"
  ON attendance
  FOR UPDATE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM admin_users
      WHERE admin_users.id = auth.uid()
      AND admin_users.role IN ('Admin', 'Super Admin')
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM admin_users
      WHERE admin_users.id = auth.uid()
      AND admin_users.role IN ('Admin', 'Super Admin')
    )
  );

-- Policy: Allow admins to delete attendance
CREATE POLICY "Admins can delete attendance"
  ON attendance
  FOR DELETE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM admin_users
      WHERE admin_users.id = auth.uid()
      AND admin_users.role IN ('Admin', 'Super Admin')
    )
  );

-- Create function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_attendance_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger to automatically update updated_at
DROP TRIGGER IF EXISTS update_attendance_updated_at_trigger ON attendance;
CREATE TRIGGER update_attendance_updated_at_trigger
  BEFORE UPDATE ON attendance
  FOR EACH ROW
  EXECUTE FUNCTION update_attendance_updated_at();

-- Add comments
COMMENT ON TABLE attendance IS 'Stores employee attendance records with check-in/out times and selfies';
COMMENT ON COLUMN attendance.check_in_location IS 'GPS coordinates and address in JSON format: {lat, lng, address}';
COMMENT ON COLUMN attendance.status IS 'Attendance status: present, absent, late, half_day';
