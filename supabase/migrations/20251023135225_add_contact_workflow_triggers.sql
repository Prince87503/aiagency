/*
  # Add Contact Workflow Triggers

  1. Changes
    - Add CONTACT_ADDED trigger event to workflow_triggers table
    - Add CONTACT_UPDATED trigger event to workflow_triggers table
    - Add CONTACT_DELETED trigger event to workflow_triggers table

  2. Event Schemas
    - CONTACT_ADDED: Includes all contact fields when a new contact is created
    - CONTACT_UPDATED: Includes all contact fields + previous values when a contact is updated
    - CONTACT_DELETED: Includes all contact fields + deleted_at timestamp when a contact is deleted

  3. Categories
    - All contact triggers are categorized under "Contact Management"
*/

-- Insert CONTACT_ADDED trigger
INSERT INTO workflow_triggers (
  name,
  display_name,
  description,
  event_name,
  event_schema,
  category,
  icon
) VALUES (
  'CONTACT_ADDED',
  'Contact Added',
  'Trigger when a new contact is added to the system',
  'CONTACT_ADDED',
  '[
    {"field": "id", "type": "uuid", "description": "Unique identifier for the contact"},
    {"field": "contact_id", "type": "text", "description": "Human-readable contact ID (e.g., CONT0001)"},
    {"field": "full_name", "type": "text", "description": "Contact full name"},
    {"field": "email", "type": "text", "description": "Contact email address"},
    {"field": "phone", "type": "text", "description": "Contact phone number"},
    {"field": "date_of_birth", "type": "date", "description": "Contact date of birth"},
    {"field": "gender", "type": "text", "description": "Contact gender"},
    {"field": "education_level", "type": "text", "description": "Contact education level"},
    {"field": "profession", "type": "text", "description": "Contact profession"},
    {"field": "experience", "type": "text", "description": "Contact work experience"},
    {"field": "business_name", "type": "text", "description": "Business name"},
    {"field": "address", "type": "text", "description": "Contact address"},
    {"field": "city", "type": "text", "description": "Contact city"},
    {"field": "state", "type": "text", "description": "Contact state"},
    {"field": "pincode", "type": "text", "description": "Contact pincode"},
    {"field": "gst_number", "type": "text", "description": "GST number"},
    {"field": "contact_type", "type": "text", "description": "Type of contact (Customer, Vendor, Partner, etc.)"},
    {"field": "status", "type": "text", "description": "Contact status (Active, Inactive)"},
    {"field": "notes", "type": "text", "description": "Additional notes about the contact"},
    {"field": "last_contacted", "type": "timestamptz", "description": "Last contact date"},
    {"field": "tags", "type": "jsonb", "description": "Array of tags for categorizing contacts"},
    {"field": "created_at", "type": "timestamptz", "description": "When the contact was created"},
    {"field": "updated_at", "type": "timestamptz", "description": "When the contact was last updated"}
  ]'::jsonb,
  'Contact Management',
  'user-plus'
) ON CONFLICT (name) DO UPDATE SET
  display_name = EXCLUDED.display_name,
  description = EXCLUDED.description,
  event_name = EXCLUDED.event_name,
  event_schema = EXCLUDED.event_schema,
  category = EXCLUDED.category,
  icon = EXCLUDED.icon,
  updated_at = now();

-- Insert CONTACT_UPDATED trigger
INSERT INTO workflow_triggers (
  name,
  display_name,
  description,
  event_name,
  event_schema,
  category,
  icon
) VALUES (
  'CONTACT_UPDATED',
  'Contact Updated',
  'Trigger when a contact is updated',
  'CONTACT_UPDATED',
  '[
    {"field": "id", "type": "uuid", "description": "Unique identifier for the contact"},
    {"field": "contact_id", "type": "text", "description": "Human-readable contact ID (e.g., CONT0001)"},
    {"field": "full_name", "type": "text", "description": "Contact full name"},
    {"field": "email", "type": "text", "description": "Contact email address"},
    {"field": "phone", "type": "text", "description": "Contact phone number"},
    {"field": "date_of_birth", "type": "date", "description": "Contact date of birth"},
    {"field": "gender", "type": "text", "description": "Contact gender"},
    {"field": "education_level", "type": "text", "description": "Contact education level"},
    {"field": "profession", "type": "text", "description": "Contact profession"},
    {"field": "experience", "type": "text", "description": "Contact work experience"},
    {"field": "business_name", "type": "text", "description": "Business name"},
    {"field": "address", "type": "text", "description": "Contact address"},
    {"field": "city", "type": "text", "description": "Contact city"},
    {"field": "state", "type": "text", "description": "Contact state"},
    {"field": "pincode", "type": "text", "description": "Contact pincode"},
    {"field": "gst_number", "type": "text", "description": "GST number"},
    {"field": "contact_type", "type": "text", "description": "Type of contact (Customer, Vendor, Partner, etc.)"},
    {"field": "status", "type": "text", "description": "Contact status (Active, Inactive)"},
    {"field": "notes", "type": "text", "description": "Additional notes about the contact"},
    {"field": "last_contacted", "type": "timestamptz", "description": "Last contact date"},
    {"field": "tags", "type": "jsonb", "description": "Array of tags for categorizing contacts"},
    {"field": "created_at", "type": "timestamptz", "description": "When the contact was created"},
    {"field": "updated_at", "type": "timestamptz", "description": "When the contact was last updated"},
    {"field": "previous", "type": "jsonb", "description": "Previous values before the update"}
  ]'::jsonb,
  'Contact Management',
  'user-check'
) ON CONFLICT (name) DO UPDATE SET
  display_name = EXCLUDED.display_name,
  description = EXCLUDED.description,
  event_name = EXCLUDED.event_name,
  event_schema = EXCLUDED.event_schema,
  category = EXCLUDED.category,
  icon = EXCLUDED.icon,
  updated_at = now();

-- Insert CONTACT_DELETED trigger
INSERT INTO workflow_triggers (
  name,
  display_name,
  description,
  event_name,
  event_schema,
  category,
  icon
) VALUES (
  'CONTACT_DELETED',
  'Contact Deleted',
  'Trigger when a contact is deleted',
  'CONTACT_DELETED',
  '[
    {"field": "id", "type": "uuid", "description": "Unique identifier for the contact"},
    {"field": "contact_id", "type": "text", "description": "Human-readable contact ID (e.g., CONT0001)"},
    {"field": "full_name", "type": "text", "description": "Contact full name"},
    {"field": "email", "type": "text", "description": "Contact email address"},
    {"field": "phone", "type": "text", "description": "Contact phone number"},
    {"field": "date_of_birth", "type": "date", "description": "Contact date of birth"},
    {"field": "gender", "type": "text", "description": "Contact gender"},
    {"field": "education_level", "type": "text", "description": "Contact education level"},
    {"field": "profession", "type": "text", "description": "Contact profession"},
    {"field": "experience", "type": "text", "description": "Contact work experience"},
    {"field": "business_name", "type": "text", "description": "Business name"},
    {"field": "address", "type": "text", "description": "Contact address"},
    {"field": "city", "type": "text", "description": "Contact city"},
    {"field": "state", "type": "text", "description": "Contact state"},
    {"field": "pincode", "type": "text", "description": "Contact pincode"},
    {"field": "gst_number", "type": "text", "description": "GST number"},
    {"field": "contact_type", "type": "text", "description": "Type of contact (Customer, Vendor, Partner, etc.)"},
    {"field": "status", "type": "text", "description": "Contact status (Active, Inactive)"},
    {"field": "notes", "type": "text", "description": "Additional notes about the contact"},
    {"field": "last_contacted", "type": "timestamptz", "description": "Last contact date"},
    {"field": "tags", "type": "jsonb", "description": "Array of tags for categorizing contacts"},
    {"field": "created_at", "type": "timestamptz", "description": "When the contact was created"},
    {"field": "updated_at", "type": "timestamptz", "description": "When the contact was last updated"},
    {"field": "deleted_at", "type": "timestamptz", "description": "When the contact was deleted"}
  ]'::jsonb,
  'Contact Management',
  'user-x'
) ON CONFLICT (name) DO UPDATE SET
  display_name = EXCLUDED.display_name,
  description = EXCLUDED.description,
  event_name = EXCLUDED.event_name,
  event_schema = EXCLUDED.event_schema,
  category = EXCLUDED.category,
  icon = EXCLUDED.icon,
  updated_at = now();

-- Add comments
COMMENT ON TABLE workflow_triggers IS 'Stores workflow trigger definitions including contact management events';
