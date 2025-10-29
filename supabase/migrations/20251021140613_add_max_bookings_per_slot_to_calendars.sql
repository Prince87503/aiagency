/*
  # Add Max Bookings Per Slot to Calendars

  1. Changes
    - Add max_bookings_per_slot column to calendars table
    - Default value is 1 (one booking per slot)
    - Must be a positive integer

  2. Notes
    - This field controls how many appointments can be booked in the same time slot
    - Value of 1 = exclusive slots (default behavior)
    - Values > 1 = allow multiple bookings per slot (e.g., for group sessions)
*/

-- Add max_bookings_per_slot column to calendars table
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'calendars' AND column_name = 'max_bookings_per_slot'
  ) THEN
    ALTER TABLE calendars ADD COLUMN max_bookings_per_slot integer NOT NULL DEFAULT 1 CHECK (max_bookings_per_slot > 0);
  END IF;
END $$;
