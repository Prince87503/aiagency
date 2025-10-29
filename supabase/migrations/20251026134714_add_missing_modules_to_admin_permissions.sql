/*
  # Add Missing Modules to Admin User Permissions

  1. Changes
    - Updates all existing admin_users to include the 12 new modules in their permissions JSONB column
    - Adds: contacts, tasks, appointments, lms, attendance, expenses, products, leave, media, integrations, ai_agents, pipelines
    - Each new module gets default permissions: { read: false, insert: false, update: false, delete: false }
    
  2. Notes
    - This ensures all team members have a consistent permission structure
    - Preserves existing permissions for the original 10 modules
    - New modules are added with all permissions set to false by default
*/

-- Update all existing admin users to include the new modules
UPDATE admin_users
SET permissions = permissions || jsonb_build_object(
  'contacts', jsonb_build_object('read', false, 'insert', false, 'update', false, 'delete', false),
  'tasks', jsonb_build_object('read', false, 'insert', false, 'update', false, 'delete', false),
  'appointments', jsonb_build_object('read', false, 'insert', false, 'update', false, 'delete', false),
  'lms', jsonb_build_object('read', false, 'insert', false, 'update', false, 'delete', false),
  'attendance', jsonb_build_object('read', false, 'insert', false, 'update', false, 'delete', false),
  'expenses', jsonb_build_object('read', false, 'insert', false, 'update', false, 'delete', false),
  'products', jsonb_build_object('read', false, 'insert', false, 'update', false, 'delete', false),
  'leave', jsonb_build_object('read', false, 'insert', false, 'update', false, 'delete', false),
  'media', jsonb_build_object('read', false, 'insert', false, 'update', false, 'delete', false),
  'integrations', jsonb_build_object('read', false, 'insert', false, 'update', false, 'delete', false),
  'ai_agents', jsonb_build_object('read', false, 'insert', false, 'update', false, 'delete', false),
  'pipelines', jsonb_build_object('read', false, 'insert', false, 'update', false, 'delete', false)
)
WHERE permissions IS NOT NULL
  AND NOT permissions ? 'contacts';  -- Only update if contacts module doesn't exist yet
