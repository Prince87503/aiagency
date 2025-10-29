/*
  # Update Tasks Table - Remove Tags and Notes, Add Supporting Documents

  1. Changes
    - Remove `tags` column from tasks table
    - Remove `notes` column from tasks table
    - Add `supporting_documents` column (text array) to store file paths from media storage
    - Add entry to media_folder_assignments for Tasks module

  2. Notes
    - Supporting documents will be stored in the folder: 88babbbd-3e5d-49fa-b4dc-ff4b81f2cdda
    - Folder name: Tasks (69026dc57e5798abb745da59)
*/

-- Drop tags and notes columns from tasks table
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'tasks' AND column_name = 'tags'
  ) THEN
    ALTER TABLE tasks DROP COLUMN tags;
  END IF;

  IF EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'tasks' AND column_name = 'notes'
  ) THEN
    ALTER TABLE tasks DROP COLUMN notes;
  END IF;
END $$;

-- Add supporting_documents column
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'tasks' AND column_name = 'supporting_documents'
  ) THEN
    ALTER TABLE tasks ADD COLUMN supporting_documents text[] DEFAULT '{}';
  END IF;
END $$;

-- Add media folder assignments for Tasks module
INSERT INTO media_folder_assignments (trigger_event, module, media_folder_id)
VALUES
  ('TASK_CREATED', 'Tasks', '88babbbd-3e5d-49fa-b4dc-ff4b81f2cdda'),
  ('TASK_UPDATED', 'Tasks', '88babbbd-3e5d-49fa-b4dc-ff4b81f2cdda')
ON CONFLICT (trigger_event) DO UPDATE
SET
  module = EXCLUDED.module,
  media_folder_id = EXCLUDED.media_folder_id,
  updated_at = now();
