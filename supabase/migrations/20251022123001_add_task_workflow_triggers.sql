/*
  # Add Task Workflow Triggers

  1. Overview
    - Adds task trigger events to workflow_triggers table
    - Enables workflow automation for task lifecycle events
    - Follows existing pattern from appointments, leads, affiliates, etc.

  2. Triggers Added
    - Task Created - When a new task is created
    - Task Updated - When a task is modified
    - Task Deleted - When a task is removed

  3. Purpose
    - Enable workflow automations based on task events
    - Integrate tasks with external systems
    - Trigger automated notifications and actions
*/

-- Insert Task Created trigger
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
  'task_created',
  'Task Created',
  'Triggered when a new task is created in the system',
  'TASK_CREATED',
  '[
    {"type": "text", "field": "task_id", "description": "Human-readable task ID (e.g., TASK-123456)"},
    {"type": "uuid", "field": "id", "description": "Unique identifier"},
    {"type": "text", "field": "title", "description": "Task title"},
    {"type": "text", "field": "description", "description": "Task description"},
    {"type": "text", "field": "status", "description": "Task status (To Do, In Progress, In Review, Completed, Cancelled)"},
    {"type": "text", "field": "priority", "description": "Task priority (Low, Medium, High, Urgent)"},
    {"type": "uuid", "field": "assigned_to", "description": "User ID assigned to task"},
    {"type": "text", "field": "assigned_to_name", "description": "Name of assigned user"},
    {"type": "uuid", "field": "assigned_by", "description": "User ID who assigned the task"},
    {"type": "text", "field": "assigned_by_name", "description": "Name of user who assigned"},
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
  'Tasks',
  'list-checks',
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

-- Insert Task Updated trigger
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
  'task_updated',
  'Task Updated',
  'Triggered when an existing task is modified',
  'TASK_UPDATED',
  '[
    {"type": "text", "field": "task_id", "description": "Human-readable task ID (e.g., TASK-123456)"},
    {"type": "uuid", "field": "id", "description": "Unique identifier"},
    {"type": "text", "field": "title", "description": "Task title"},
    {"type": "text", "field": "description", "description": "Task description"},
    {"type": "text", "field": "status", "description": "Task status (To Do, In Progress, In Review, Completed, Cancelled)"},
    {"type": "text", "field": "priority", "description": "Task priority (Low, Medium, High, Urgent)"},
    {"type": "uuid", "field": "assigned_to", "description": "User ID assigned to task"},
    {"type": "text", "field": "assigned_to_name", "description": "Name of assigned user"},
    {"type": "uuid", "field": "assigned_by", "description": "User ID who assigned the task"},
    {"type": "text", "field": "assigned_by_name", "description": "Name of user who assigned"},
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
  'Tasks',
  'list-checks',
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

-- Insert Task Deleted trigger
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
  'task_deleted',
  'Task Deleted',
  'Triggered when a task is deleted from the system',
  'TASK_DELETED',
  '[
    {"type": "text", "field": "task_id", "description": "Human-readable task ID (e.g., TASK-123456)"},
    {"type": "uuid", "field": "id", "description": "Unique identifier"},
    {"type": "text", "field": "title", "description": "Task title"},
    {"type": "text", "field": "description", "description": "Task description"},
    {"type": "text", "field": "status", "description": "Task status at deletion"},
    {"type": "text", "field": "priority", "description": "Task priority"},
    {"type": "uuid", "field": "assigned_to", "description": "User ID assigned to task"},
    {"type": "text", "field": "assigned_to_name", "description": "Name of assigned user"},
    {"type": "uuid", "field": "assigned_by", "description": "User ID who assigned the task"},
    {"type": "text", "field": "assigned_by_name", "description": "Name of user who assigned"},
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
  'Tasks',
  'list-checks',
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
