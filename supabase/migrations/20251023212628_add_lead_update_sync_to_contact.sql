/*
  # Add Lead Update Sync to Contact

  1. Changes
    - Create trigger to sync lead updates to contacts_master table
    - When a lead is updated, update the corresponding contact record
    - Match contacts by phone number
    - Update all relevant fields from lead to contact

  2. Fields Synced
    - name → full_name
    - email → email
    - phone → phone
    - company → business_name
    - address → address

  3. Notes
    - Only updates if a matching contact exists
    - Uses phone number as the primary lookup key
    - Handles phone number changes by looking up the old phone first
*/

-- Create function to sync lead updates to contact
CREATE OR REPLACE FUNCTION sync_lead_update_to_contact()
RETURNS TRIGGER AS $$
BEGIN
  -- Update contact if it exists (match by OLD phone number first, then NEW phone number)
  UPDATE contacts_master
  SET
    full_name = NEW.name,
    email = NEW.email,
    phone = NEW.phone,
    business_name = NEW.company,
    address = NEW.address,
    updated_at = NOW()
  WHERE phone = OLD.phone OR phone = NEW.phone;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Drop existing trigger if it exists
DROP TRIGGER IF EXISTS trigger_sync_lead_update_to_contact ON leads;

-- Create trigger for lead updates
CREATE TRIGGER trigger_sync_lead_update_to_contact
  AFTER UPDATE ON leads
  FOR EACH ROW
  EXECUTE FUNCTION sync_lead_update_to_contact();
