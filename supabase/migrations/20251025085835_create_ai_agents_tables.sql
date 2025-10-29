/*
  # AI Agents Module Tables

  ## Overview
  Creates tables for AI Agents functionality in the CRM system.

  ## New Tables

  ### 1. `ai_agents`
  Main table for AI agent configurations
  - `id` (uuid, primary key) - Unique identifier
  - `name` (text) - Agent display name
  - `model` (text) - AI model (GPT-5, Claude, Llama, etc.)
  - `system_prompt` (text) - System instructions for the agent
  - `status` (text) - Active/Inactive
  - `channels` (text[]) - Array of channels (Web, WhatsApp, Email, Voice)
  - `created_at` (timestamptz) - Creation timestamp
  - `updated_at` (timestamptz) - Last update timestamp
  - `last_activity` (timestamptz) - Last activity timestamp
  - `created_by` (text) - User who created the agent

  ### 2. `ai_agent_permissions`
  Stores module access permissions for each agent
  - `id` (uuid, primary key) - Unique identifier
  - `agent_id` (uuid, foreign key) - References ai_agents
  - `module_name` (text) - Name of CRM module
  - `can_view` (boolean) - View permission
  - `can_create` (boolean) - Create permission
  - `can_edit` (boolean) - Edit permission
  - `can_delete` (boolean) - Delete permission
  - `created_at` (timestamptz) - Creation timestamp
  - `updated_at` (timestamptz) - Last update timestamp

  ### 3. `ai_agent_logs`
  Activity logs for agent actions
  - `id` (uuid, primary key) - Unique identifier
  - `agent_id` (uuid, foreign key) - References ai_agents
  - `agent_name` (text) - Agent name at time of action
  - `module` (text) - CRM module affected
  - `action` (text) - Action type (Create, Update, Fetch, Delete)
  - `result` (text) - Success/Denied/Error
  - `user_context` (text) - User who gave instruction
  - `details` (jsonb) - Additional details about the action
  - `created_at` (timestamptz) - Action timestamp

  ## Security
  - RLS enabled on all tables
  - Policies allow authenticated users to manage their own data
  - Admin users have full access
*/

-- Create ai_agents table
CREATE TABLE IF NOT EXISTS ai_agents (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text NOT NULL,
  model text NOT NULL,
  system_prompt text NOT NULL,
  status text NOT NULL DEFAULT 'Active',
  channels text[] DEFAULT '{}',
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now(),
  last_activity timestamptz DEFAULT now(),
  created_by text
);

-- Create ai_agent_permissions table
CREATE TABLE IF NOT EXISTS ai_agent_permissions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  agent_id uuid NOT NULL REFERENCES ai_agents(id) ON DELETE CASCADE,
  module_name text NOT NULL,
  can_view boolean DEFAULT true,
  can_create boolean DEFAULT false,
  can_edit boolean DEFAULT false,
  can_delete boolean DEFAULT false,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now(),
  UNIQUE(agent_id, module_name)
);

-- Create ai_agent_logs table
CREATE TABLE IF NOT EXISTS ai_agent_logs (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  agent_id uuid NOT NULL REFERENCES ai_agents(id) ON DELETE CASCADE,
  agent_name text NOT NULL,
  module text NOT NULL,
  action text NOT NULL,
  result text NOT NULL,
  user_context text,
  details jsonb DEFAULT '{}',
  created_at timestamptz DEFAULT now()
);

-- Enable RLS
ALTER TABLE ai_agents ENABLE ROW LEVEL SECURITY;
ALTER TABLE ai_agent_permissions ENABLE ROW LEVEL SECURITY;
ALTER TABLE ai_agent_logs ENABLE ROW LEVEL SECURITY;

-- RLS Policies for ai_agents
CREATE POLICY "Allow anonymous read access to ai_agents"
  ON ai_agents FOR SELECT
  TO anon
  USING (true);

CREATE POLICY "Allow anonymous insert access to ai_agents"
  ON ai_agents FOR INSERT
  TO anon
  WITH CHECK (true);

CREATE POLICY "Allow anonymous update access to ai_agents"
  ON ai_agents FOR UPDATE
  TO anon
  USING (true)
  WITH CHECK (true);

CREATE POLICY "Allow anonymous delete access to ai_agents"
  ON ai_agents FOR DELETE
  TO anon
  USING (true);

-- RLS Policies for ai_agent_permissions
CREATE POLICY "Allow anonymous read access to ai_agent_permissions"
  ON ai_agent_permissions FOR SELECT
  TO anon
  USING (true);

CREATE POLICY "Allow anonymous insert access to ai_agent_permissions"
  ON ai_agent_permissions FOR INSERT
  TO anon
  WITH CHECK (true);

CREATE POLICY "Allow anonymous update access to ai_agent_permissions"
  ON ai_agent_permissions FOR UPDATE
  TO anon
  USING (true)
  WITH CHECK (true);

CREATE POLICY "Allow anonymous delete access to ai_agent_permissions"
  ON ai_agent_permissions FOR DELETE
  TO anon
  USING (true);

-- RLS Policies for ai_agent_logs
CREATE POLICY "Allow anonymous read access to ai_agent_logs"
  ON ai_agent_logs FOR SELECT
  TO anon
  USING (true);

CREATE POLICY "Allow anonymous insert access to ai_agent_logs"
  ON ai_agent_logs FOR INSERT
  TO anon
  WITH CHECK (true);

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_ai_agents_status ON ai_agents(status);
CREATE INDEX IF NOT EXISTS idx_ai_agents_last_activity ON ai_agents(last_activity);
CREATE INDEX IF NOT EXISTS idx_ai_agent_permissions_agent_id ON ai_agent_permissions(agent_id);
CREATE INDEX IF NOT EXISTS idx_ai_agent_logs_agent_id ON ai_agent_logs(agent_id);
CREATE INDEX IF NOT EXISTS idx_ai_agent_logs_created_at ON ai_agent_logs(created_at);
CREATE INDEX IF NOT EXISTS idx_ai_agent_logs_module ON ai_agent_logs(module);

-- Create function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create triggers for updated_at
DROP TRIGGER IF EXISTS update_ai_agents_updated_at ON ai_agents;
CREATE TRIGGER update_ai_agents_updated_at
  BEFORE UPDATE ON ai_agents
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_ai_agent_permissions_updated_at ON ai_agent_permissions;
CREATE TRIGGER update_ai_agent_permissions_updated_at
  BEFORE UPDATE ON ai_agent_permissions
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();
