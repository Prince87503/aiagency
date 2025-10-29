/*
  # Fix Sync Triggers Between Leads and Contacts

  1. Changes
    - Fix sync_lead_to_contact function to use correct column name (business_name instead of company)
    - Fix sync_contact_to_lead function to properly map business_name to company
    - Ensure both triggers work correctly with proper column mappings

  2. Column Mappings
    - leads.company → contacts_master.business_name
    - contacts_master.business_name → leads.company
*/

-- Fix function to auto-create contact when lead is added
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
        business_name,
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

-- The sync_contact_to_lead function is already correct, but recreating for consistency
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
