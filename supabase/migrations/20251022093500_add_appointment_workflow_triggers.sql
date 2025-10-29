/*
  # Add Appointment Workflow Triggers

  1. Overview
    - Adds appointment trigger definitions to workflow_triggers table
    - Enables appointment events to appear in workflow automation UI
    - Makes triggers available for use in automations and API webhooks

  2. New Workflow Triggers
    - APPOINTMENT_CREATED - Triggered when a new appointment is created
    - APPOINTMENT_UPDATED - Triggered when an appointment is modified
    - APPOINTMENT_DELETED - Triggered when an appointment is deleted

  3. Event Schemas
    - Each trigger includes detailed event schema with all relevant fields
    - Schemas define what data is available for workflow automations
    - Update event includes both current and previous values

  4. Important Notes
    - These triggers integrate with existing database triggers on appointments table
    - Triggers will show in Settings > API Webhooks section
    - Can be used to create automated workflows and notifications
*/

-- Insert APPOINTMENT_CREATED trigger
INSERT INTO workflow_triggers (
  name,
  display_name,
  description,
  event_name,
  event_schema,
  category,
  icon
) VALUES (
  'appointment_created',
  'Appointment Created',
  'Triggered when a new appointment is created',
  'APPOINTMENT_CREATED',
  '[
    {"field": "appointment_id", "type": "uuid", "description": "Unique appointment identifier"},
    {"field": "calendar_id", "type": "uuid", "description": "Calendar the appointment belongs to"},
    {"field": "contact_id", "type": "uuid", "description": "Contact ID (if linked to contacts)"},
    {"field": "contact_name", "type": "text", "description": "Name of the person booking"},
    {"field": "contact_email", "type": "text", "description": "Email of the person booking"},
    {"field": "contact_phone", "type": "text", "description": "Phone of the person booking"},
    {"field": "title", "type": "text", "description": "Appointment title"},
    {"field": "description", "type": "text", "description": "Appointment description"},
    {"field": "start_time", "type": "timestamptz", "description": "Appointment start date and time"},
    {"field": "end_time", "type": "timestamptz", "description": "Appointment end date and time"},
    {"field": "duration_minutes", "type": "integer", "description": "Duration in minutes"},
    {"field": "status", "type": "text", "description": "Status: Scheduled, Confirmed, Cancelled, Completed, No Show"},
    {"field": "location", "type": "text", "description": "Physical location or address"},
    {"field": "meeting_link", "type": "text", "description": "Virtual meeting link (Zoom, Meet, etc.)"},
    {"field": "notes", "type": "text", "description": "Additional notes"},
    {"field": "reminder_sent", "type": "boolean", "description": "Whether reminder was sent"},
    {"field": "created_at", "type": "timestamptz", "description": "When appointment was created"},
    {"field": "updated_at", "type": "timestamptz", "description": "When appointment was last updated"}
  ]'::jsonb,
  'Appointments',
  'calendar'
) ON CONFLICT (name) DO NOTHING;

-- Insert APPOINTMENT_UPDATED trigger
INSERT INTO workflow_triggers (
  name,
  display_name,
  description,
  event_name,
  event_schema,
  category,
  icon
) VALUES (
  'appointment_updated',
  'Appointment Updated',
  'Triggered when an appointment is modified',
  'APPOINTMENT_UPDATED',
  '[
    {"field": "appointment_id", "type": "uuid", "description": "Unique appointment identifier"},
    {"field": "calendar_id", "type": "uuid", "description": "Calendar the appointment belongs to"},
    {"field": "contact_id", "type": "uuid", "description": "Contact ID (if linked to contacts)"},
    {"field": "contact_name", "type": "text", "description": "Name of the person booking"},
    {"field": "contact_email", "type": "text", "description": "Email of the person booking"},
    {"field": "contact_phone", "type": "text", "description": "Phone of the person booking"},
    {"field": "title", "type": "text", "description": "Appointment title"},
    {"field": "description", "type": "text", "description": "Appointment description"},
    {"field": "start_time", "type": "timestamptz", "description": "Appointment start date and time"},
    {"field": "end_time", "type": "timestamptz", "description": "Appointment end date and time"},
    {"field": "duration_minutes", "type": "integer", "description": "Duration in minutes"},
    {"field": "status", "type": "text", "description": "Status: Scheduled, Confirmed, Cancelled, Completed, No Show"},
    {"field": "location", "type": "text", "description": "Physical location or address"},
    {"field": "meeting_link", "type": "text", "description": "Virtual meeting link (Zoom, Meet, etc.)"},
    {"field": "notes", "type": "text", "description": "Additional notes"},
    {"field": "reminder_sent", "type": "boolean", "description": "Whether reminder was sent"},
    {"field": "previous_status", "type": "text", "description": "Previous status before update"},
    {"field": "previous_start_time", "type": "timestamptz", "description": "Previous start time"},
    {"field": "previous_end_time", "type": "timestamptz", "description": "Previous end time"},
    {"field": "created_at", "type": "timestamptz", "description": "When appointment was created"},
    {"field": "updated_at", "type": "timestamptz", "description": "When appointment was last updated"}
  ]'::jsonb,
  'Appointments',
  'calendar'
) ON CONFLICT (name) DO NOTHING;

-- Insert APPOINTMENT_DELETED trigger
INSERT INTO workflow_triggers (
  name,
  display_name,
  description,
  event_name,
  event_schema,
  category,
  icon
) VALUES (
  'appointment_deleted',
  'Appointment Deleted',
  'Triggered when an appointment is deleted',
  'APPOINTMENT_DELETED',
  '[
    {"field": "appointment_id", "type": "uuid", "description": "Unique appointment identifier"},
    {"field": "calendar_id", "type": "uuid", "description": "Calendar the appointment belongs to"},
    {"field": "contact_id", "type": "uuid", "description": "Contact ID (if linked to contacts)"},
    {"field": "contact_name", "type": "text", "description": "Name of the person booking"},
    {"field": "contact_email", "type": "text", "description": "Email of the person booking"},
    {"field": "contact_phone", "type": "text", "description": "Phone of the person booking"},
    {"field": "title", "type": "text", "description": "Appointment title"},
    {"field": "description", "type": "text", "description": "Appointment description"},
    {"field": "start_time", "type": "timestamptz", "description": "Appointment start date and time"},
    {"field": "end_time", "type": "timestamptz", "description": "Appointment end date and time"},
    {"field": "duration_minutes", "type": "integer", "description": "Duration in minutes"},
    {"field": "status", "type": "text", "description": "Status at time of deletion"},
    {"field": "location", "type": "text", "description": "Physical location or address"},
    {"field": "meeting_link", "type": "text", "description": "Virtual meeting link"},
    {"field": "notes", "type": "text", "description": "Additional notes"},
    {"field": "deleted_at", "type": "timestamptz", "description": "When appointment was deleted"}
  ]'::jsonb,
  'Appointments',
  'calendar'
) ON CONFLICT (name) DO NOTHING;
