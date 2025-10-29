/*
  # Add Calendar Integration to Appointments

  1. Changes
    - Add calendar_id foreign key to appointments table
    - Add index on calendar_id for efficient queries

  2. Notes
    - calendar_id is optional to maintain backward compatibility
    - When a calendar is selected, appointment settings will auto-populate from calendar
*/

-- Add calendar_id column to appointments table
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'appointments' AND column_name = 'calendar_id'
  ) THEN
    ALTER TABLE appointments ADD COLUMN calendar_id uuid REFERENCES calendars(id) ON DELETE SET NULL;
  END IF;
END $$;

-- Create index on calendar_id for efficient queries
CREATE INDEX IF NOT EXISTS idx_appointments_calendar_id ON appointments(calendar_id);
