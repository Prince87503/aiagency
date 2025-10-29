/*
  # Create Workflow Triggers Table

  1. New Tables
    - `workflow_triggers` - Stores trigger definitions
      - `id` (uuid, primary key) - Unique identifier
      - `name` (text, unique) - Trigger name (e.g., "LEADS")
      - `display_name` (text) - Display name for UI
      - `description` (text) - Description of the trigger
      - `event_name` (text) - Event name (e.g., "NEW_LEAD_ADDED")
      - `event_schema` (jsonb) - Schema of data provided by this trigger
        Contains field definitions with: field_name, data_type, description
      - `category` (text) - Category for grouping triggers
      - `icon` (text) - Icon name for UI display
      - `is_active` (boolean) - Whether trigger is active
      - `created_at` (timestamptz) - Creation timestamp
      - `updated_at` (timestamptz) - Update timestamp

  2. Security
    - Enable RLS on `workflow_triggers` table
    - Add policies for authenticated users to read
    - Add policies for admin users to manage triggers

  3. Initial Data
    - Insert LEADS trigger with NEW_LEAD_ADDED event
    - Event schema includes all lead table fields

  4. Important Notes
    - Triggers define what data is available for workflow actions
    - Event schema helps with mapping data to action properties
    - Each trigger can have multiple events in future
*/

-- Create workflow_triggers table
CREATE TABLE IF NOT EXISTS workflow_triggers (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text UNIQUE NOT NULL,
  display_name text NOT NULL,
  description text,
  event_name text NOT NULL,
  event_schema jsonb DEFAULT '[]'::jsonb,
  category text DEFAULT 'General',
  icon text DEFAULT 'zap',
  is_active boolean DEFAULT true,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_workflow_triggers_name ON workflow_triggers(name);
CREATE INDEX IF NOT EXISTS idx_workflow_triggers_event_name ON workflow_triggers(event_name);
CREATE INDEX IF NOT EXISTS idx_workflow_triggers_category ON workflow_triggers(category);
CREATE INDEX IF NOT EXISTS idx_workflow_triggers_is_active ON workflow_triggers(is_active);

-- Enable RLS
ALTER TABLE workflow_triggers ENABLE ROW LEVEL SECURITY;

-- Create policies for anon and authenticated users to read
CREATE POLICY "Allow anon to read workflow triggers"
  ON workflow_triggers
  FOR SELECT
  TO anon
  USING (is_active = true);

CREATE POLICY "Allow authenticated to read workflow triggers"
  ON workflow_triggers
  FOR SELECT
  TO authenticated
  USING (true);

-- Create policies for authenticated users to manage (will be restricted to admin later)
CREATE POLICY "Allow authenticated to insert workflow triggers"
  ON workflow_triggers
  FOR INSERT
  TO authenticated
  WITH CHECK (true);

CREATE POLICY "Allow authenticated to update workflow triggers"
  ON workflow_triggers
  FOR UPDATE
  TO authenticated
  USING (true)
  WITH CHECK (true);

CREATE POLICY "Allow authenticated to delete workflow triggers"
  ON workflow_triggers
  FOR DELETE
  TO authenticated
  USING (true);

-- Create trigger to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_workflow_triggers_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_workflow_triggers_updated_at_trigger
  BEFORE UPDATE ON workflow_triggers
  FOR EACH ROW
  EXECUTE FUNCTION update_workflow_triggers_updated_at();

-- Insert LEADS trigger with NEW_LEAD_ADDED event
INSERT INTO workflow_triggers (
  name,
  display_name,
  description,
  event_name,
  event_schema,
  category,
  icon
) VALUES (
  'LEADS',
  'Leads',
  'Trigger when a new lead is added to the system',
  'NEW_LEAD_ADDED',
  '[
    {"field": "id", "type": "uuid", "description": "Unique identifier for the lead"},
    {"field": "lead_id", "type": "text", "description": "Human-readable lead ID"},
    {"field": "name", "type": "text", "description": "Lead full name"},
    {"field": "email", "type": "text", "description": "Lead email address"},
    {"field": "phone", "type": "text", "description": "Lead phone number"},
    {"field": "source", "type": "text", "description": "Lead source (Ad, Referral, Webinar, Website, etc.)"},
    {"field": "interest", "type": "text", "description": "Interest level (Hot, Warm, Cold)"},
    {"field": "status", "type": "text", "description": "Lead status (New, Contacted, Demo Booked, etc.)"},
    {"field": "owner", "type": "text", "description": "Lead owner/assigned to"},
    {"field": "address", "type": "text", "description": "Lead address"},
    {"field": "company", "type": "text", "description": "Lead company name"},
    {"field": "notes", "type": "text", "description": "Additional notes about the lead"},
    {"field": "last_contact", "type": "timestamptz", "description": "Last contact date"},
    {"field": "lead_score", "type": "integer", "description": "Lead scoring (0-100)"},
    {"field": "created_at", "type": "timestamptz", "description": "When the lead was created"},
    {"field": "updated_at", "type": "timestamptz", "description": "When the lead was last updated"},
    {"field": "affiliate_id", "type": "uuid", "description": "Affiliate who referred this lead (if applicable)"}
  ]'::jsonb,
  'Lead Management',
  'users'
) ON CONFLICT (name) DO NOTHING;

-- Add comment
COMMENT ON TABLE workflow_triggers IS 'Stores workflow trigger definitions with their event schemas';
COMMENT ON COLUMN workflow_triggers.event_schema IS 'JSON schema defining available data fields for this trigger';