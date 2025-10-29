/*
  # Make Email Optional in Leads and Sync with Contacts

  1. Changes
    - Remove NOT NULL constraint from email column in leads table
    - Create trigger to auto-create contact when lead is added (if not exists by phone)
    - Create trigger to auto-create lead when contact with type "Lead" is added (if not exists by phone)
    - Bidirectional sync based on phone number (one-to-one relation)

  2. Trigger Logic
    - When new lead is added: Create contact with type "Lead" if phone number doesn't exist
    - When contact with type "Lead" is added: Create lead if phone number doesn't exist in leads
    - Phone number is the unique identifier for the relationship

  3. Security
    - Existing RLS policies remain unchanged
*/

-- Remove NOT NULL constraint from email column in leads table
ALTER TABLE leads 
  ALTER COLUMN email DROP NOT NULL;

-- Add comment
COMMENT ON COLUMN leads.email IS 'Lead email address (optional)';

-- Create function to auto-create contact when lead is added
CREATE OR REPLACE FUNCTION sync_lead_to_contact()
RETURNS TRIGGER AS $$
BEGIN
  -- Only create contact if phone number is provided and doesn't exist in contacts
  IF NEW.phone IS NOT NULL AND NEW.phone != '' THEN
    -- Check if contact with this phone number already exists
    IF NOT EXISTS (
      SELECT 1 FROM contacts_master 
      WHERE phone = NEW.phone
    ) THEN
      -- Create new contact
      INSERT INTO contacts_master (
        full_name,
        email,
        phone,
        contact_type,
        status,
        notes,
        company,
        address
      ) VALUES (
        NEW.name,
        NEW.email,
        NEW.phone,
        'Lead',
        'Active',
        'Auto-created from Lead CRM',
        NEW.company,
        NEW.address
      );
    END IF;
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create trigger on leads table for inserts
DROP TRIGGER IF EXISTS trigger_sync_lead_to_contact ON leads;
CREATE TRIGGER trigger_sync_lead_to_contact
  AFTER INSERT ON leads
  FOR EACH ROW
  EXECUTE FUNCTION sync_lead_to_contact();

-- Create function to auto-create lead when contact with type "Lead" is added
CREATE OR REPLACE FUNCTION sync_contact_to_lead()
RETURNS TRIGGER AS $$
BEGIN
  -- Only create lead if contact_type is "Lead" and phone number is provided
  IF NEW.contact_type = 'Lead' AND NEW.phone IS NOT NULL AND NEW.phone != '' THEN
    -- Check if lead with this phone number already exists
    IF NOT EXISTS (
      SELECT 1 FROM leads 
      WHERE phone = NEW.phone
    ) THEN
      -- Create new lead
      INSERT INTO leads (
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

-- Create trigger on contacts_master table for inserts
DROP TRIGGER IF EXISTS trigger_sync_contact_to_lead ON contacts_master;
CREATE TRIGGER trigger_sync_contact_to_lead
  AFTER INSERT ON contacts_master
  FOR EACH ROW
  EXECUTE FUNCTION sync_contact_to_lead();

-- Add comments
COMMENT ON FUNCTION sync_lead_to_contact() IS 'Auto-creates contact with type "Lead" when new lead is added (if phone number does not exist in contacts)';
COMMENT ON FUNCTION sync_contact_to_lead() IS 'Auto-creates lead when contact with type "Lead" is added (if phone number does not exist in leads)';
