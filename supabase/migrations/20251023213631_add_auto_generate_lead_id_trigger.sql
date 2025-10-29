/*
  # Add Auto-Generate Lead ID Trigger

  1. Changes
    - Create a BEFORE INSERT trigger to automatically generate lead_id
    - Lead ID format: L001, L002, L003, etc.
    - Finds the highest existing lead_id and increments

  2. Logic
    - Runs BEFORE INSERT to generate lead_id if not provided
    - Extracts numeric part from last lead_id (e.g., "L005" → 5)
    - Increments by 1
    - Formats back with leading zeros (e.g., 6 → "L006")
    - Defaults to "L001" if no leads exist

  3. Notes
    - This fixes the "Failed to create lead" error
    - Users no longer need to manually provide lead_id
*/

-- Create function to auto-generate lead_id
CREATE OR REPLACE FUNCTION generate_lead_id()
RETURNS TRIGGER AS $$
DECLARE
  new_lead_id TEXT;
  last_lead_id TEXT;
  last_number INTEGER;
BEGIN
  -- Only generate if lead_id is not provided or is empty
  IF NEW.lead_id IS NULL OR NEW.lead_id = '' THEN
    -- Get the last lead_id
    SELECT lead_id INTO last_lead_id
    FROM leads
    ORDER BY created_at DESC
    LIMIT 1;
    
    IF last_lead_id IS NULL THEN
      new_lead_id := 'L001';
    ELSE
      -- Extract number from last lead_id (e.g., 'L005' -> 5)
      last_number := CAST(SUBSTRING(last_lead_id FROM 2) AS INTEGER);
      -- Increment and format with leading zeros
      new_lead_id := 'L' || LPAD((last_number + 1)::TEXT, 3, '0');
    END IF;
    
    NEW.lead_id := new_lead_id;
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Drop existing trigger if it exists
DROP TRIGGER IF EXISTS trigger_generate_lead_id ON leads;

-- Create BEFORE INSERT trigger
CREATE TRIGGER trigger_generate_lead_id
  BEFORE INSERT ON leads
  FOR EACH ROW
  EXECUTE FUNCTION generate_lead_id();
