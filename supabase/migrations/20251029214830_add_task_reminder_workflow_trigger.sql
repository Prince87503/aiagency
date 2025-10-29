/*
  # Add Task Reminder Workflow Trigger

  1. Overview
    - Adds "Task Reminder" trigger event to workflow_triggers table
    - Enables workflow automation when scheduled task reminders are due
    - Follows existing pattern from task triggers

  2. Trigger Added
    - Task Reminder - Triggered at the scheduled reminder date/time

  3. Purpose
    - Enable workflow automations based on task reminder events
    - Send notifications when reminders are due
    - Integrate reminders with external systems (WhatsApp, Email, SMS, etc.)
    - Automate follow-up actions based on reminders

  4. Event Schema
    - Includes task details, reminder details, and contact information
    - Provides all necessary data for notification workflows
*/

-- Insert Task Reminder trigger
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
  'task_reminder',
  'Task Reminder',
  'Triggered at the scheduled task reminder date/time',
  'TASK_REMINDER',
  '[
    {"type": "uuid", "field": "reminder_id", "description": "Unique reminder identifier"},
    {"type": "uuid", "field": "task_id", "description": "Task unique identifier"},
    {"type": "text", "field": "task_readable_id", "description": "Human-readable task ID (e.g., TASK-123456)"},
    {"type": "text", "field": "task_title", "description": "Task title"},
    {"type": "text", "field": "task_description", "description": "Task description"},
    {"type": "text", "field": "task_status", "description": "Task status (To Do, In Progress, In Review, Completed, Cancelled)"},
    {"type": "text", "field": "task_priority", "description": "Task priority (Low, Medium, High, Urgent)"},
    {"type": "text", "field": "task_category", "description": "Task category"},
    {"type": "uuid", "field": "assigned_to", "description": "User ID assigned to task"},
    {"type": "text", "field": "assigned_to_name", "description": "Name of assigned user"},
    {"type": "uuid", "field": "assigned_by", "description": "User ID who assigned the task"},
    {"type": "text", "field": "assigned_by_name", "description": "Name of user who assigned"},
    {"type": "uuid", "field": "contact_id", "description": "Related contact ID (if linked)"},
    {"type": "text", "field": "contact_name", "description": "Related contact name"},
    {"type": "text", "field": "contact_phone", "description": "Related contact phone"},
    {"type": "timestamptz", "field": "task_due_date", "description": "Task due date and time"},
    {"type": "timestamptz", "field": "task_start_date", "description": "Task start date and time"},
    {"type": "numeric", "field": "task_estimated_hours", "description": "Estimated hours to complete"},
    {"type": "integer", "field": "task_progress_percentage", "description": "Progress percentage (0-100)"},
    {"type": "text", "field": "reminder_type", "description": "Reminder type (start_date, due_date, custom)"},
    {"type": "timestamptz", "field": "reminder_custom_datetime", "description": "Custom datetime if reminder type is custom"},
    {"type": "text", "field": "reminder_offset_timing", "description": "Offset timing (before, after)"},
    {"type": "integer", "field": "reminder_offset_value", "description": "Offset value (e.g., 1, 2, 3)"},
    {"type": "text", "field": "reminder_offset_unit", "description": "Offset unit (minutes, hours, days)"},
    {"type": "timestamptz", "field": "reminder_scheduled_time", "description": "Calculated reminder time when it should trigger"},
    {"type": "text", "field": "reminder_display", "description": "Human-readable reminder description (e.g., 2 hours before Due Date)"},
    {"type": "timestamptz", "field": "created_at", "description": "When the reminder was created"}
  ]'::jsonb,
  'Tasks',
  'bell',
  true
) ON CONFLICT (name) DO UPDATE SET
  display_name = EXCLUDED.display_name,
  description = EXCLUDED.description,
  event_name = EXCLUDED.event_name,
  event_schema = EXCLUDED.event_schema,
  category = EXCLUDED.category,
  icon = EXCLUDED.icon,
  is_active = EXCLUDED.is_active,
  updated_at = NOW();