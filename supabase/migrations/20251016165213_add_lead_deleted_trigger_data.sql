/*
  # Add Lead Deleted Trigger to Workflow Triggers

  1. Changes
    - Insert the LEAD_DELETED trigger into workflow_triggers table
    - Provides trigger configuration for when leads are deleted
    - Makes the trigger available in the automation builder UI

  2. Trigger Details
    - Event Name: LEAD_DELETED
    - Category: Leads
    - 15 data fields including deleted_at timestamp
    - Icon: users

  3. Security
    - Uses existing RLS policies on workflow_triggers table
*/

INSERT INTO workflow_triggers (
  name,
  display_name,
  description,
  event_name,
  event_schema,
  category,
  icon,
  is_active
) VALUES (
  'lead_deleted',
  'Lead Deleted',
  'Triggered when a lead is deleted from the CRM',
  'LEAD_DELETED',
  '[
    {"field": "id", "type": "uuid", "description": "Unique identifier"},
    {"field": "lead_id", "type": "string", "description": "Lead ID (e.g., L001)"},
    {"field": "name", "type": "string", "description": "Lead name"},
    {"field": "email", "type": "string", "description": "Lead email address"},
    {"field": "phone", "type": "string", "description": "Lead phone number"},
    {"field": "source", "type": "string", "description": "Lead source"},
    {"field": "interest", "type": "string", "description": "Lead interest level"},
    {"field": "status", "type": "string", "description": "Lead status"},
    {"field": "owner", "type": "string", "description": "Assigned owner"},
    {"field": "address", "type": "string", "description": "Lead address"},
    {"field": "company", "type": "string", "description": "Company name"},
    {"field": "notes", "type": "string", "description": "Lead notes"},
    {"field": "last_contact", "type": "date", "description": "Last contact date"},
    {"field": "lead_score", "type": "number", "description": "Lead score"},
    {"field": "deleted_at", "type": "timestamp", "description": "When the lead was deleted"}
  ]'::jsonb,
  'Leads',
  'users',
  true
);
