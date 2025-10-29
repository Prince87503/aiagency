/*
  # Fix Lead ID Generation in Contact-to-Lead Sync

  1. Changes
    - Update sync_contact_to_lead function to generate lead_id automatically
    - Lead ID format: L001, L002, L003, etc.
    - Finds the highest existing lead_id and increments

  2. Logic
    - Extracts numeric part from last lead_id (e.g., "L005" → 5)
    - Increments by 1
    - Formats back with leading zeros (e.g., 6 → "L006")
    - Defaults to "L001" if no leads exist
*/

-- Update function to auto-create lead when contact with type "Lead" is added
CREATE OR REPLACE FUNCTION sync_contact_to_lead()
RETURNS TRIGGER AS $$
DECLARE
  new_lead_id TEXT;
  last_lead_id TEXT;
  last_number INTEGER;
BEGIN
  -- Only create lead if contact_type is "Lead" and phone number is provided
  IF NEW.contact_type = 'Lead' AND NEW.phone IS NOT NULL AND NEW.phone != '' THEN
    -- Check if lead with this phone number already exists
    IF NOT EXISTS (
      SELECT 1 FROM leads 
      WHERE phone = NEW.phone
    ) THEN
      -- Generate new lead_id
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
      
      -- Create new lead with generated lead_id
      INSERT INTO leads (
        lead_id,
        name,
        email,
        phone,
        source,
        interest,
        status,
        company,
        address,
        notes
      ) VALUES (
        new_lead_id,
        NEW.full_name,
        NEW.email,
        NEW.phone,
        'Contact Master',
        'Warm',
        'New',
        NEW.business_name,
        NEW.address,
        'Auto-created from Contact Master'
      );
    END IF;
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
