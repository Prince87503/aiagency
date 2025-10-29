/*
  # Update Task Workflow Triggers Schema with Phone Numbers

  1. Overview
    - Updates task workflow trigger event schemas to include phone number fields
    - Adds assigned_by_phone and assigned_to_phone to all task trigger schemas

  2. Changes
    - Updates task_created schema
    - Updates task_updated schema
    - Updates task_deleted schema

  3. Purpose
    - Reflect the actual data being sent in webhook payloads
    - Enable workflow automations to use phone numbers for SMS/WhatsApp
*/

-- Update Task Created trigger schema
UPDATE workflow_triggers
SET event_schema = '[
  {"type": "text", "field": "task_id", "description": "Human-readable task ID (e.g., TASK-123456)"},
  {"type": "uuid", "field": "id", "description": "Unique identifier"},
  {"type": "text", "field": "title", "description": "Task title"},
  {"type": "text", "field": "description", "description": "Task description"},
  {"type": "text", "field": "status", "description": "Task status (To Do, In Progress, In Review, Completed, Cancelled)"},
  {"type": "text", "field": "priority", "description": "Task priority (Low, Medium, High, Urgent)"},
  {"type": "uuid", "field": "assigned_to", "description": "User ID assigned to task"},
  {"type": "text", "field": "assigned_to_name", "description": "Name of assigned user"},
  {"type": "text", "field": "assigned_to_phone", "description": "Phone number of assigned user"},
  {"type": "uuid", "field": "assigned_by", "description": "User ID who assigned the task"},
  {"type": "text", "field": "assigned_by_name", "description": "Name of user who assigned"},
  {"type": "text", "field": "assigned_by_phone", "description": "Phone number of user who assigned"},
  {"type": "uuid", "field": "contact_id", "description": "Related contact ID (if linked)"},
  {"type": "text", "field": "contact_name", "description": "Related contact name"},
  {"type": "text", "field": "contact_phone", "description": "Related contact phone"},
  {"type": "date", "field": "due_date", "description": "Task due date"},
  {"type": "date", "field": "start_date", "description": "Task start date"},
  {"type": "timestamptz", "field": "completion_date", "description": "When task was completed"},
  {"type": "numeric", "field": "estimated_hours", "description": "Estimated hours to complete"},
  {"type": "numeric", "field": "actual_hours", "description": "Actual hours spent"},
  {"type": "text", "field": "category", "description": "Task category"},
  {"type": "array", "field": "tags", "description": "Task tags"},
  {"type": "jsonb", "field": "attachments", "description": "Task attachments"},
  {"type": "integer", "field": "progress_percentage", "description": "Progress percentage (0-100)"},
  {"type": "text", "field": "notes", "description": "Additional notes"},
  {"type": "timestamptz", "field": "created_at", "description": "When the task was created"},
  {"type": "timestamptz", "field": "updated_at", "description": "When the task was last updated"}
]'::jsonb,
updated_at = NOW()
WHERE name = 'task_created';

-- Update Task Updated trigger schema
UPDATE workflow_triggers
SET event_schema = '[
  {"type": "text", "field": "task_id", "description": "Human-readable task ID (e.g., TASK-123456)"},
  {"type": "uuid", "field": "id", "description": "Unique identifier"},
  {"type": "text", "field": "title", "description": "Task title"},
  {"type": "text", "field": "description", "description": "Task description"},
  {"type": "text", "field": "status", "description": "Task status (To Do, In Progress, In Review, Completed, Cancelled)"},
  {"type": "text", "field": "priority", "description": "Task priority (Low, Medium, High, Urgent)"},
  {"type": "uuid", "field": "assigned_to", "description": "User ID assigned to task"},
  {"type": "text", "field": "assigned_to_name", "description": "Name of assigned user"},
  {"type": "text", "field": "assigned_to_phone", "description": "Phone number of assigned user"},
  {"type": "uuid", "field": "assigned_by", "description": "User ID who assigned the task"},
  {"type": "text", "field": "assigned_by_name", "description": "Name of user who assigned"},
  {"type": "text", "field": "assigned_by_phone", "description": "Phone number of user who assigned"},
  {"type": "uuid", "field": "contact_id", "description": "Related contact ID (if linked)"},
  {"type": "text", "field": "contact_name", "description": "Related contact name"},
  {"type": "text", "field": "contact_phone", "description": "Related contact phone"},
  {"type": "date", "field": "due_date", "description": "Task due date"},
  {"type": "date", "field": "start_date", "description": "Task start date"},
  {"type": "timestamptz", "field": "completion_date", "description": "When task was completed"},
  {"type": "numeric", "field": "estimated_hours", "description": "Estimated hours to complete"},
  {"type": "numeric", "field": "actual_hours", "description": "Actual hours spent"},
  {"type": "text", "field": "category", "description": "Task category"},
  {"type": "array", "field": "tags", "description": "Task tags"},
  {"type": "jsonb", "field": "attachments", "description": "Task attachments"},
  {"type": "integer", "field": "progress_percentage", "description": "Progress percentage (0-100)"},
  {"type": "text", "field": "notes", "description": "Additional notes"},
  {"type": "timestamptz", "field": "created_at", "description": "When the task was created"},
  {"type": "timestamptz", "field": "updated_at", "description": "When the task was last updated"},
  {"type": "text", "field": "previous_status", "description": "Previous status before update"},
  {"type": "text", "field": "previous_priority", "description": "Previous priority before update"},
  {"type": "uuid", "field": "previous_assigned_to", "description": "Previous assigned user"},
  {"type": "date", "field": "previous_due_date", "description": "Previous due date"},
  {"type": "integer", "field": "previous_progress_percentage", "description": "Previous progress percentage"}
]'::jsonb,
updated_at = NOW()
WHERE name = 'task_updated';

-- Update Task Deleted trigger schema
UPDATE workflow_triggers
SET event_schema = '[
  {"type": "text", "field": "task_id", "description": "Human-readable task ID (e.g., TASK-123456)"},
  {"type": "uuid", "field": "id", "description": "Unique identifier"},
  {"type": "text", "field": "title", "description": "Task title"},
  {"type": "text", "field": "description", "description": "Task description"},
  {"type": "text", "field": "status", "description": "Task status at deletion"},
  {"type": "text", "field": "priority", "description": "Task priority"},
  {"type": "uuid", "field": "assigned_to", "description": "User ID assigned to task"},
  {"type": "text", "field": "assigned_to_name", "description": "Name of assigned user"},
  {"type": "text", "field": "assigned_to_phone", "description": "Phone number of assigned user"},
  {"type": "uuid", "field": "assigned_by", "description": "User ID who assigned the task"},
  {"type": "text", "field": "assigned_by_name", "description": "Name of user who assigned"},
  {"type": "text", "field": "assigned_by_phone", "description": "Phone number of user who assigned"},
  {"type": "uuid", "field": "contact_id", "description": "Related contact ID (if linked)"},
  {"type": "text", "field": "contact_name", "description": "Related contact name"},
  {"type": "text", "field": "contact_phone", "description": "Related contact phone"},
  {"type": "date", "field": "due_date", "description": "Task due date"},
  {"type": "date", "field": "start_date", "description": "Task start date"},
  {"type": "timestamptz", "field": "completion_date", "description": "When task was completed"},
  {"type": "numeric", "field": "estimated_hours", "description": "Estimated hours to complete"},
  {"type": "numeric", "field": "actual_hours", "description": "Actual hours spent"},
  {"type": "text", "field": "category", "description": "Task category"},
  {"type": "array", "field": "tags", "description": "Task tags"},
  {"type": "integer", "field": "progress_percentage", "description": "Progress percentage (0-100)"},
  {"type": "timestamptz", "field": "deleted_at", "description": "When the task was deleted"}
]'::jsonb,
updated_at = NOW()
WHERE name = 'task_deleted';
