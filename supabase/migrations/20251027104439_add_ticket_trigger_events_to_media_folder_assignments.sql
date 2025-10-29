/*
  # Add Support Ticket Trigger Events to Media Folder Assignments

  1. Changes
    - Add TICKET_CREATED trigger event for Support module
    - Add TICKET_UPDATED trigger event for Support module
    - Allows support ticket attachments to be organized into specific GHL folders

  2. New Assignments
    - TICKET_CREATED: For attachments when creating support tickets
    - TICKET_UPDATED: For attachments when updating support tickets

  3. Notes
    - media_folder_id is initially set to NULL (will be configured via UI)
    - Uses ON CONFLICT to prevent duplicate entries if already exists
*/

-- Insert support ticket trigger events into media_folder_assignments
INSERT INTO media_folder_assignments (trigger_event, module, media_folder_id)
VALUES
  ('TICKET_CREATED', 'Support', NULL),
  ('TICKET_UPDATED', 'Support', NULL)
ON CONFLICT (trigger_event) DO NOTHING;

-- Add comment for documentation
COMMENT ON TABLE media_folder_assignments IS 'Maps trigger events to specific media folders for GHL media file organization. Includes events for Attendance, Expenses, and Support tickets.';