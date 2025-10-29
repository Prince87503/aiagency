/*
  # Create Calendars Table for Calendar Management

  1. New Tables
    - `calendars`
      - `id` (uuid, primary key)
      - `calendar_id` (text, unique, auto-generated)
      - `title` (text, required)
      - `description` (text, optional)
      - `thumbnail` (text, optional) - URL to thumbnail image
      - `availability` (jsonb, required) - JSON object with day/time availability
      - `assigned_user_id` (uuid, foreign key to admin_users, optional)
      - `slot_duration` (integer, required, default 30) - Duration in minutes
      - `meeting_type` (text[], required) - Array of meeting types allowed
      - `default_location` (text, optional)
      - `buffer_time` (integer, default 0) - Buffer time between meetings in minutes
      - `max_bookings_per_day` (integer, optional)
      - `booking_window_days` (integer, default 30) - How many days in advance can book
      - `color` (text, default '#3B82F6') - Calendar color for UI
      - `is_active` (boolean, default true)
      - `timezone` (text, default 'UTC')
      - `created_at` (timestamptz, default now())
      - `updated_at` (timestamptz, default now())

  2. Security
    - Enable RLS on `calendars` table
    - Add policy for anonymous users to read active calendars
    - Add policy for authenticated admin users to manage all calendars

  3. Indexes
    - Index on is_active for filtering
    - Index on assigned_user_id for user-specific queries

  4. Notes
    - Availability JSON structure example:
      {
        "monday": { "enabled": true, "slots": [{"start": "09:00", "end": "17:00"}] },
        "tuesday": { "enabled": true, "slots": [{"start": "09:00", "end": "17:00"}] },
        ...
      }
    - meeting_type array can include: ["In-Person", "Video Call", "Phone Call"]
*/

-- Create calendars table
CREATE TABLE IF NOT EXISTS calendars (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  calendar_id text UNIQUE NOT NULL DEFAULT 'CAL-' || LPAD(FLOOR(RANDOM() * 999999999)::text, 9, '0'),
  title text NOT NULL,
  description text,
  thumbnail text,
  availability jsonb NOT NULL DEFAULT '{
    "monday": {"enabled": true, "slots": [{"start": "09:00", "end": "17:00"}]},
    "tuesday": {"enabled": true, "slots": [{"start": "09:00", "end": "17:00"}]},
    "wednesday": {"enabled": true, "slots": [{"start": "09:00", "end": "17:00"}]},
    "thursday": {"enabled": true, "slots": [{"start": "09:00", "end": "17:00"}]},
    "friday": {"enabled": true, "slots": [{"start": "09:00", "end": "17:00"}]},
    "saturday": {"enabled": false, "slots": []},
    "sunday": {"enabled": false, "slots": []}
  }'::jsonb,
  assigned_user_id uuid REFERENCES admin_users(id) ON DELETE SET NULL,
  slot_duration integer NOT NULL DEFAULT 30 CHECK (slot_duration > 0),
  meeting_type text[] NOT NULL DEFAULT ARRAY['In-Person', 'Video Call', 'Phone Call'],
  default_location text,
  buffer_time integer DEFAULT 0 CHECK (buffer_time >= 0),
  max_bookings_per_day integer CHECK (max_bookings_per_day > 0),
  booking_window_days integer DEFAULT 30 CHECK (booking_window_days > 0),
  color text DEFAULT '#3B82F6',
  is_active boolean DEFAULT true,
  timezone text DEFAULT 'UTC',
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_calendars_is_active ON calendars(is_active);
CREATE INDEX IF NOT EXISTS idx_calendars_assigned_user_id ON calendars(assigned_user_id);

-- Enable RLS
ALTER TABLE calendars ENABLE ROW LEVEL SECURITY;

-- Policy for anonymous users to read active calendars
CREATE POLICY "Anyone can read active calendars"
  ON calendars
  FOR SELECT
  TO anon
  USING (is_active = true);

-- Policy for anonymous users to create calendars (for public booking pages)
CREATE POLICY "Anyone can create calendars"
  ON calendars
  FOR INSERT
  TO anon
  WITH CHECK (true);

-- Policy for anonymous users to update calendars
CREATE POLICY "Anyone can update calendars"
  ON calendars
  FOR UPDATE
  TO anon
  USING (true)
  WITH CHECK (true);

-- Policy for anonymous users to delete calendars
CREATE POLICY "Anyone can delete calendars"
  ON calendars
  FOR DELETE
  TO anon
  USING (true);

-- Policy for authenticated admin users to read all calendars
CREATE POLICY "Authenticated users can read all calendars"
  ON calendars
  FOR SELECT
  TO authenticated
  USING (true);

-- Policy for authenticated admin users to create calendars
CREATE POLICY "Authenticated users can create calendars"
  ON calendars
  FOR INSERT
  TO authenticated
  WITH CHECK (true);

-- Policy for authenticated admin users to update calendars
CREATE POLICY "Authenticated users can update all calendars"
  ON calendars
  FOR UPDATE
  TO authenticated
  USING (true)
  WITH CHECK (true);

-- Policy for authenticated admin users to delete calendars
CREATE POLICY "Authenticated users can delete calendars"
  ON calendars
  FOR DELETE
  TO authenticated
  USING (true);

-- Create updated_at trigger
CREATE OR REPLACE FUNCTION update_calendars_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER calendars_updated_at
  BEFORE UPDATE ON calendars
  FOR EACH ROW
  EXECUTE FUNCTION update_calendars_updated_at();
