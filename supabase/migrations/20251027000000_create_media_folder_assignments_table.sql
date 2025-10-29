/*
  # Create Media Folder Assignments Table

  1. New Tables
    - `media_folder_assignments`
      - `id` (uuid, primary key) - Unique identifier
      - `trigger_event` (text) - Trigger event name (e.g., ATTENDANCE_CHECKIN, EXPENSE_ADDED)
      - `module` (text) - Module name (e.g., Attendance, Expenses)
      - `media_folder_id` (uuid) - Reference to media_folders table
      - `created_at` (timestamptz) - Creation timestamp
      - `updated_at` (timestamptz) - Update timestamp

  2. Security
    - Enable RLS on table
    - Add policies for anonymous access (read/write)

  3. Indexes
    - Index on trigger_event for fast lookups
    - Index on module for filtering
    - Unique constraint on trigger_event to prevent duplicates

  4. Initial Data
    - Add default assignments for Attendance and Expense events
*/

CREATE TABLE IF NOT EXISTS media_folder_assignments (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  trigger_event text UNIQUE NOT NULL,
  module text NOT NULL,
  media_folder_id uuid REFERENCES media_folders(id) ON DELETE SET NULL,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

ALTER TABLE media_folder_assignments ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Allow anonymous read access to media_folder_assignments"
  ON media_folder_assignments
  FOR SELECT
  TO anon
  USING (true);

CREATE POLICY "Allow anonymous insert access to media_folder_assignments"
  ON media_folder_assignments
  FOR INSERT
  TO anon
  WITH CHECK (true);

CREATE POLICY "Allow anonymous update access to media_folder_assignments"
  ON media_folder_assignments
  FOR UPDATE
  TO anon
  USING (true)
  WITH CHECK (true);

CREATE POLICY "Allow anonymous delete access to media_folder_assignments"
  ON media_folder_assignments
  FOR DELETE
  TO anon
  USING (true);

CREATE INDEX IF NOT EXISTS idx_media_folder_assignments_trigger_event ON media_folder_assignments(trigger_event);
CREATE INDEX IF NOT EXISTS idx_media_folder_assignments_module ON media_folder_assignments(module);
CREATE INDEX IF NOT EXISTS idx_media_folder_assignments_folder_id ON media_folder_assignments(media_folder_id);

CREATE OR REPLACE FUNCTION update_media_folder_assignments_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_media_folder_assignments_updated_at
  BEFORE UPDATE ON media_folder_assignments
  FOR EACH ROW
  EXECUTE FUNCTION update_media_folder_assignments_updated_at();

-- Insert default media folder assignments for common triggers
INSERT INTO media_folder_assignments (trigger_event, module, media_folder_id)
VALUES
  ('ATTENDANCE_CHECKIN', 'Attendance', NULL),
  ('ATTENDANCE_CHECKOUT', 'Attendance', NULL),
  ('EXPENSE_ADDED', 'Expenses', NULL),
  ('EXPENSE_UPDATED', 'Expenses', NULL),
  ('EXPENSE_DELETED', 'Expenses', NULL)
ON CONFLICT (trigger_event) DO NOTHING;

COMMENT ON TABLE media_folder_assignments IS 'Maps trigger events to specific media folders for GHL media file organization';
COMMENT ON COLUMN media_folder_assignments.trigger_event IS 'The trigger event name from workflow_triggers or database triggers';
COMMENT ON COLUMN media_folder_assignments.module IS 'The module this trigger belongs to (for grouping in UI)';
COMMENT ON COLUMN media_folder_assignments.media_folder_id IS 'The media folder where files related to this trigger should be displayed';
