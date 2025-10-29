/*
  # Add trigger to populate denormalized fields in tasks table

  1. Changes
    - Creates a trigger function to automatically populate assigned_to_name, assigned_by_name, contact_name, and contact_phone
    - Triggers on INSERT and UPDATE operations
    - Fetches data from admin_users and contacts_master tables based on UUIDs
    
  2. Purpose
    - Maintains denormalized data for performance and easier querying
    - Ensures data consistency when tasks are created or updated via webhooks or UI
*/

-- Create function to populate denormalized fields
CREATE OR REPLACE FUNCTION populate_task_denormalized_fields()
RETURNS TRIGGER AS $$
BEGIN
  -- Populate assigned_to_name
  IF NEW.assigned_to IS NOT NULL THEN
    SELECT full_name INTO NEW.assigned_to_name
    FROM admin_users
    WHERE id = NEW.assigned_to;
  ELSE
    NEW.assigned_to_name := NULL;
  END IF;

  -- Populate assigned_by_name
  IF NEW.assigned_by IS NOT NULL THEN
    SELECT full_name INTO NEW.assigned_by_name
    FROM admin_users
    WHERE id = NEW.assigned_by;
  ELSE
    NEW.assigned_by_name := NULL;
  END IF;

  -- Populate contact_name and contact_phone
  IF NEW.contact_id IS NOT NULL THEN
    SELECT full_name, phone INTO NEW.contact_name, NEW.contact_phone
    FROM contacts_master
    WHERE id = NEW.contact_id;
  ELSE
    NEW.contact_name := NULL;
    NEW.contact_phone := NULL;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Drop existing trigger if it exists
DROP TRIGGER IF EXISTS trigger_populate_task_denormalized_fields ON tasks;

-- Create trigger that runs before insert or update
CREATE TRIGGER trigger_populate_task_denormalized_fields
  BEFORE INSERT OR UPDATE ON tasks
  FOR EACH ROW
  EXECUTE FUNCTION populate_task_denormalized_fields();
