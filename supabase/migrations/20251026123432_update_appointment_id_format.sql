/*
  # Update Appointment ID Format to APT0001, APT0002, etc.

  1. Changes
    - Drop the default random ID generation for appointment_id
    - Create a sequence for auto-incrementing appointment numbers
    - Create a function to generate appointment IDs in APT0001 format
    - Create a trigger to auto-generate appointment IDs on insert
    - Update all existing appointments with the new ID format

  2. Migration Steps
    - Create sequence starting from 1
    - Update existing appointments with sequential IDs
    - Add trigger for new appointments
*/

-- Create sequence for appointment numbering
CREATE SEQUENCE IF NOT EXISTS appointments_id_seq START WITH 1;

-- Create function to generate appointment ID
CREATE OR REPLACE FUNCTION generate_appointment_id()
RETURNS TEXT AS $$
DECLARE
  next_id INTEGER;
BEGIN
  next_id := nextval('appointments_id_seq');
  RETURN 'APT' || LPAD(next_id::TEXT, 4, '0');
END;
$$ LANGUAGE plpgsql;

-- Update existing appointments with sequential IDs
DO $$
DECLARE
  appointment_record RECORD;
  counter INTEGER := 0;
BEGIN
  FOR appointment_record IN 
    SELECT id FROM appointments ORDER BY created_at
  LOOP
    counter := counter + 1;
    UPDATE appointments 
    SET appointment_id = 'APT' || LPAD(counter::TEXT, 4, '0')
    WHERE id = appointment_record.id;
  END LOOP;
  
  -- Set the sequence to continue from the last ID
  IF counter > 0 THEN
    PERFORM setval('appointments_id_seq', counter);
  END IF;
END $$;

-- Drop the old default constraint
ALTER TABLE appointments ALTER COLUMN appointment_id DROP DEFAULT;

-- Add new default using the function
ALTER TABLE appointments ALTER COLUMN appointment_id SET DEFAULT generate_appointment_id();

-- Create trigger to auto-generate appointment_id on insert
CREATE OR REPLACE FUNCTION set_appointment_id()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.appointment_id IS NULL OR NEW.appointment_id = '' THEN
    NEW.appointment_id := generate_appointment_id();
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_set_appointment_id ON appointments;

CREATE TRIGGER trigger_set_appointment_id
  BEFORE INSERT ON appointments
  FOR EACH ROW
  EXECUTE FUNCTION set_appointment_id();