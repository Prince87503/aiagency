/*
  # Create Appointments Table for Sales Management

  1. New Tables
    - `appointments`
      - `id` (uuid, primary key)
      - `appointment_id` (text, unique, auto-generated)
      - `title` (text, required)
      - `contact_id` (uuid, foreign key to contacts_master)
      - `contact_name` (text, required)
      - `contact_phone` (text, required)
      - `contact_email` (text, optional)
      - `appointment_date` (date, required)
      - `appointment_time` (time, required)
      - `duration_minutes` (integer, default 30)
      - `location` (text, optional)
      - `meeting_type` (text, required) - In-Person, Video Call, Phone Call
      - `status` (text, required) - Scheduled, Confirmed, Completed, Cancelled, No-Show
      - `purpose` (text, required) - Sales Meeting, Product Demo, Follow-up, Consultation, Other
      - `notes` (text, optional)
      - `reminder_sent` (boolean, default false)
      - `assigned_to` (uuid, foreign key to admin_users, optional)
      - `created_at` (timestamptz, default now())
      - `updated_at` (timestamptz, default now())

  2. Security
    - Enable RLS on `appointments` table
    - Add policy for anonymous users to read/write appointments (for public booking)
    - Add policy for authenticated admin users to manage all appointments

  3. Indexes
    - Index on appointment_date for efficient date-based queries
    - Index on status for filtering
    - Index on contact_id for relationship queries
*/

-- Create appointments table
CREATE TABLE IF NOT EXISTS appointments (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  appointment_id text UNIQUE NOT NULL DEFAULT 'APT-' || LPAD(FLOOR(RANDOM() * 999999999)::text, 9, '0'),
  title text NOT NULL,
  contact_id uuid REFERENCES contacts_master(id) ON DELETE SET NULL,
  contact_name text NOT NULL,
  contact_phone text NOT NULL,
  contact_email text,
  appointment_date date NOT NULL,
  appointment_time time NOT NULL,
  duration_minutes integer DEFAULT 30,
  location text,
  meeting_type text NOT NULL CHECK (meeting_type IN ('In-Person', 'Video Call', 'Phone Call')),
  status text NOT NULL DEFAULT 'Scheduled' CHECK (status IN ('Scheduled', 'Confirmed', 'Completed', 'Cancelled', 'No-Show')),
  purpose text NOT NULL CHECK (purpose IN ('Sales Meeting', 'Product Demo', 'Follow-up', 'Consultation', 'Other')),
  notes text,
  reminder_sent boolean DEFAULT false,
  assigned_to uuid REFERENCES admin_users(id) ON DELETE SET NULL,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_appointments_date ON appointments(appointment_date);
CREATE INDEX IF NOT EXISTS idx_appointments_status ON appointments(status);
CREATE INDEX IF NOT EXISTS idx_appointments_contact_id ON appointments(contact_id);
CREATE INDEX IF NOT EXISTS idx_appointments_assigned_to ON appointments(assigned_to);

-- Enable RLS
ALTER TABLE appointments ENABLE ROW LEVEL SECURITY;

-- Policy for anonymous users to create and read appointments (for public booking)
CREATE POLICY "Anyone can create appointments"
  ON appointments
  FOR INSERT
  TO anon
  WITH CHECK (true);

CREATE POLICY "Anyone can read appointments"
  ON appointments
  FOR SELECT
  TO anon
  USING (true);

CREATE POLICY "Anyone can update appointments"
  ON appointments
  FOR UPDATE
  TO anon
  USING (true)
  WITH CHECK (true);

CREATE POLICY "Anyone can delete appointments"
  ON appointments
  FOR DELETE
  TO anon
  USING (true);

-- Policy for authenticated admin users to manage all appointments
CREATE POLICY "Authenticated users can read all appointments"
  ON appointments
  FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Authenticated users can create appointments"
  ON appointments
  FOR INSERT
  TO authenticated
  WITH CHECK (true);

CREATE POLICY "Authenticated users can update all appointments"
  ON appointments
  FOR UPDATE
  TO authenticated
  USING (true)
  WITH CHECK (true);

CREATE POLICY "Authenticated users can delete appointments"
  ON appointments
  FOR DELETE
  TO authenticated
  USING (true);

-- Create updated_at trigger
CREATE OR REPLACE FUNCTION update_appointments_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER appointments_updated_at
  BEFORE UPDATE ON appointments
  FOR EACH ROW
  EXECUTE FUNCTION update_appointments_updated_at();
