/*
  # Create Automations Module Tables

  1. New Tables
    - `automations`
      - `id` (uuid, primary key) - Unique identifier
      - `name` (text) - Automation name
      - `description` (text) - Automation description
      - `status` (text) - Status: Active, Paused, Draft, Error
      - `trigger` (text) - Trigger name/description
      - `trigger_type` (text) - Type: Lead Capture, Course Progress, Payment Event, Calendar Event, Affiliate Event
      - `actions` (jsonb) - Array of action names
      - `category` (text) - Category: Lead Nurturing, Student Engagement, Payment Recovery, Demo Management, Affiliate Management
      - `runs_today` (integer) - Number of runs today
      - `total_runs` (integer) - Total number of runs
      - `success_rate` (numeric) - Success rate percentage
      - `last_run` (timestamptz) - Last run timestamp
      - `created_by` (text) - Creator name
      - `tags` (jsonb) - Array of tags
      - `workflow_config` (jsonb) - Complete workflow configuration
      - `created_at` (timestamptz) - Creation timestamp
      - `updated_at` (timestamptz) - Update timestamp

    - `automation_templates`
      - `id` (uuid, primary key) - Unique identifier
      - `name` (text) - Template name
      - `description` (text) - Template description
      - `category` (text) - Category
      - `uses` (integer) - Number of times used
      - `rating` (numeric) - Rating (0-5)
      - `actions` (jsonb) - Array of action names
      - `thumbnail` (text) - Thumbnail URL
      - `workflow_config` (jsonb) - Template workflow configuration
      - `created_at` (timestamptz) - Creation timestamp
      - `updated_at` (timestamptz) - Update timestamp

    - `automation_runs`
      - `id` (uuid, primary key) - Unique identifier
      - `automation_id` (uuid, foreign key) - Reference to automation
      - `status` (text) - success, failed, running
      - `trigger_data` (jsonb) - Data that triggered the automation
      - `result_data` (jsonb) - Result of the automation
      - `error_message` (text) - Error message if failed
      - `duration_ms` (integer) - Duration in milliseconds
      - `created_at` (timestamptz) - Run timestamp

  2. Security
    - Enable RLS on all tables
    - Allow anonymous and authenticated access for all operations
    - This matches the pattern used in other admin tables

  3. Important Notes
    - JSONB fields store arrays and complex data structures
    - Automation runs are logged for analytics and debugging
    - Success rate is calculated from automation_runs table
*/

-- Automations table
CREATE TABLE IF NOT EXISTS automations (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text NOT NULL,
  description text DEFAULT '',
  status text DEFAULT 'Draft',
  trigger text DEFAULT '',
  trigger_type text DEFAULT '',
  actions jsonb DEFAULT '[]'::jsonb,
  category text DEFAULT '',
  runs_today integer DEFAULT 0,
  total_runs integer DEFAULT 0,
  success_rate numeric DEFAULT 0,
  last_run timestamptz,
  created_by text DEFAULT '',
  tags jsonb DEFAULT '[]'::jsonb,
  workflow_config jsonb DEFAULT '{}'::jsonb,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

ALTER TABLE automations ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Anyone can view automations"
  ON automations
  FOR SELECT
  TO anon, authenticated
  USING (true);

CREATE POLICY "Anyone can insert automations"
  ON automations
  FOR INSERT
  TO anon, authenticated
  WITH CHECK (true);

CREATE POLICY "Anyone can update automations"
  ON automations
  FOR UPDATE
  TO anon, authenticated
  USING (true)
  WITH CHECK (true);

CREATE POLICY "Anyone can delete automations"
  ON automations
  FOR DELETE
  TO anon, authenticated
  USING (true);

-- Automation templates table
CREATE TABLE IF NOT EXISTS automation_templates (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text NOT NULL,
  description text DEFAULT '',
  category text DEFAULT '',
  uses integer DEFAULT 0,
  rating numeric DEFAULT 0,
  actions jsonb DEFAULT '[]'::jsonb,
  thumbnail text DEFAULT '',
  workflow_config jsonb DEFAULT '{}'::jsonb,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

ALTER TABLE automation_templates ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Anyone can view automation templates"
  ON automation_templates
  FOR SELECT
  TO anon, authenticated
  USING (true);

CREATE POLICY "Anyone can insert automation templates"
  ON automation_templates
  FOR INSERT
  TO anon, authenticated
  WITH CHECK (true);

CREATE POLICY "Anyone can update automation templates"
  ON automation_templates
  FOR UPDATE
  TO anon, authenticated
  USING (true)
  WITH CHECK (true);

CREATE POLICY "Anyone can delete automation templates"
  ON automation_templates
  FOR DELETE
  TO anon, authenticated
  USING (true);

-- Automation runs table (for logging and analytics)
CREATE TABLE IF NOT EXISTS automation_runs (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  automation_id uuid REFERENCES automations(id) ON DELETE CASCADE,
  status text DEFAULT 'running',
  trigger_data jsonb DEFAULT '{}'::jsonb,
  result_data jsonb DEFAULT '{}'::jsonb,
  error_message text,
  duration_ms integer DEFAULT 0,
  created_at timestamptz DEFAULT now()
);

ALTER TABLE automation_runs ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Anyone can view automation runs"
  ON automation_runs
  FOR SELECT
  TO anon, authenticated
  USING (true);

CREATE POLICY "Anyone can insert automation runs"
  ON automation_runs
  FOR INSERT
  TO anon, authenticated
  WITH CHECK (true);

CREATE POLICY "Anyone can update automation runs"
  ON automation_runs
  FOR UPDATE
  TO anon, authenticated
  USING (true)
  WITH CHECK (true);

CREATE POLICY "Anyone can delete automation runs"
  ON automation_runs
  FOR DELETE
  TO anon, authenticated
  USING (true);

-- Create indexes for better query performance
CREATE INDEX IF NOT EXISTS idx_automations_status ON automations(status);
CREATE INDEX IF NOT EXISTS idx_automations_category ON automations(category);
CREATE INDEX IF NOT EXISTS idx_automations_created_at ON automations(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_automation_runs_automation_id ON automation_runs(automation_id);
CREATE INDEX IF NOT EXISTS idx_automation_runs_created_at ON automation_runs(created_at DESC);

-- Trigger to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_automations_timestamp()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER automations_updated_at
  BEFORE UPDATE ON automations
  FOR EACH ROW
  EXECUTE FUNCTION update_automations_timestamp();

CREATE TRIGGER automation_templates_updated_at
  BEFORE UPDATE ON automation_templates
  FOR EACH ROW
  EXECUTE FUNCTION update_automations_timestamp();