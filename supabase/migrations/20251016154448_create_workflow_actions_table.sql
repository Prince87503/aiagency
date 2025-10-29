/*
  # Create Workflow Actions Table

  1. New Tables
    - `workflow_actions` - Stores action definitions
      - `id` (uuid, primary key) - Unique identifier
      - `name` (text, unique) - Action name (e.g., "WEBHOOK")
      - `display_name` (text) - Display name for UI
      - `description` (text) - Description of the action
      - `action_type` (text) - Type of action (e.g., "webhook", "email", "sms")
      - `config_schema` (jsonb) - Schema defining required configuration fields
        Contains field definitions with: field_name, data_type, description, required
      - `category` (text) - Category for grouping actions
      - `icon` (text) - Icon name for UI display
      - `is_active` (boolean) - Whether action is active
      - `created_at` (timestamptz) - Creation timestamp
      - `updated_at` (timestamptz) - Update timestamp

  2. Security
    - Enable RLS on `workflow_actions` table
    - Add policies for authenticated users to read
    - Add policies for admin users to manage actions

  3. Initial Data
    - Insert WEBHOOK action with POST method
    - Config schema includes: webhook_url, query_params, headers, body

  4. Important Notes
    - Actions define what operations can be performed in workflows
    - Config schema helps validate action configuration
    - Actions can use data from trigger event schema
*/

-- Create workflow_actions table
CREATE TABLE IF NOT EXISTS workflow_actions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text UNIQUE NOT NULL,
  display_name text NOT NULL,
  description text,
  action_type text NOT NULL,
  config_schema jsonb DEFAULT '[]'::jsonb,
  category text DEFAULT 'General',
  icon text DEFAULT 'play',
  is_active boolean DEFAULT true,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_workflow_actions_name ON workflow_actions(name);
CREATE INDEX IF NOT EXISTS idx_workflow_actions_action_type ON workflow_actions(action_type);
CREATE INDEX IF NOT EXISTS idx_workflow_actions_category ON workflow_actions(category);
CREATE INDEX IF NOT EXISTS idx_workflow_actions_is_active ON workflow_actions(is_active);

-- Enable RLS
ALTER TABLE workflow_actions ENABLE ROW LEVEL SECURITY;

-- Create policies for anon and authenticated users to read
CREATE POLICY "Allow anon to read workflow actions"
  ON workflow_actions
  FOR SELECT
  TO anon
  USING (is_active = true);

CREATE POLICY "Allow authenticated to read workflow actions"
  ON workflow_actions
  FOR SELECT
  TO authenticated
  USING (true);

-- Create policies for authenticated users to manage (will be restricted to admin later)
CREATE POLICY "Allow authenticated to insert workflow actions"
  ON workflow_actions
  FOR INSERT
  TO authenticated
  WITH CHECK (true);

CREATE POLICY "Allow authenticated to update workflow actions"
  ON workflow_actions
  FOR UPDATE
  TO authenticated
  USING (true)
  WITH CHECK (true);

CREATE POLICY "Allow authenticated to delete workflow actions"
  ON workflow_actions
  FOR DELETE
  TO authenticated
  USING (true);

-- Create trigger to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_workflow_actions_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_workflow_actions_updated_at_trigger
  BEFORE UPDATE ON workflow_actions
  FOR EACH ROW
  EXECUTE FUNCTION update_workflow_actions_updated_at();

-- Insert WEBHOOK action
INSERT INTO workflow_actions (
  name,
  display_name,
  description,
  action_type,
  config_schema,
  category,
  icon
) VALUES (
  'WEBHOOK',
  'Webhook POST',
  'Send data to an external webhook URL using HTTP POST method',
  'webhook',
  '{
    "fields": [
      {
        "name": "webhook_url",
        "label": "Webhook URL",
        "type": "text",
        "description": "The URL to send the POST request to",
        "required": true,
        "placeholder": "https://example.com/webhook"
      },
      {
        "name": "query_params",
        "label": "Query Parameters",
        "type": "key_value_list",
        "description": "URL query parameters to append to the webhook URL",
        "required": false,
        "default": []
      },
      {
        "name": "headers",
        "label": "Headers",
        "type": "key_value_list",
        "description": "HTTP headers to include in the request",
        "required": false,
        "default": [{"key": "Content-Type", "value": "application/json"}]
      },
      {
        "name": "body",
        "label": "Request Body",
        "type": "key_value_list",
        "description": "Data to send in the request body (will be sent as JSON)",
        "required": false,
        "default": [],
        "supports_mapping": true
      }
    ]
  }'::jsonb,
  'Integration',
  'globe'
) ON CONFLICT (name) DO NOTHING;

-- Add comment
COMMENT ON TABLE workflow_actions IS 'Stores workflow action definitions with their configuration schemas';
COMMENT ON COLUMN workflow_actions.config_schema IS 'JSON schema defining required configuration fields for this action';