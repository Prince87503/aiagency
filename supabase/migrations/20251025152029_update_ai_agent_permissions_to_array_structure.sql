/*
  # Restructure AI Agent Permissions to Array-Based Storage

  ## Overview
  Converts ai_agent_permissions from one-row-per-module to one-row-per-agent with all permissions in a JSONB object.
  This matches the pattern used in admin_users for consistency.

  ## Changes
  
  ### 1. Backup existing data
  Creates a temporary backup of existing permissions
  
  ### 2. Drop existing table
  Removes the old table structure with individual rows per module
  
  ### 3. Create new table structure
  - `ai_agent_permissions` with single row per agent
  - Stores all module permissions in a JSONB object
  - Structure: {"module_name": {"can_view": bool, "can_create": bool, "can_edit": bool, "can_delete": bool}}
  
  ### 4. Migrate data
  Converts old row-per-module data to new JSONB structure
  
  ## Security
  - RLS policies maintained for anonymous access
  - All existing security rules preserved
*/

-- Step 1: Create backup of existing data
CREATE TEMP TABLE ai_agent_permissions_backup AS 
SELECT * FROM ai_agent_permissions;

-- Step 2: Drop old table and recreate with new structure
DROP TABLE IF EXISTS ai_agent_permissions CASCADE;

CREATE TABLE ai_agent_permissions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  agent_id uuid UNIQUE NOT NULL REFERENCES ai_agents(id) ON DELETE CASCADE,
  permissions jsonb NOT NULL DEFAULT '{}'::jsonb,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Step 3: Migrate existing data to new structure
DO $$
DECLARE
  agent_record RECORD;
  permissions_json jsonb := '{}'::jsonb;
BEGIN
  -- Get unique agents from backup
  FOR agent_record IN 
    SELECT DISTINCT agent_id FROM ai_agent_permissions_backup
  LOOP
    -- Build permissions JSON for this agent
    permissions_json := '{}'::jsonb;
    
    -- Aggregate all module permissions for this agent
    SELECT jsonb_object_agg(
      module_name,
      jsonb_build_object(
        'can_view', can_view,
        'can_create', can_create,
        'can_edit', can_edit,
        'can_delete', can_delete
      )
    )
    INTO permissions_json
    FROM ai_agent_permissions_backup
    WHERE agent_id = agent_record.agent_id;
    
    -- Insert into new table
    INSERT INTO ai_agent_permissions (agent_id, permissions)
    VALUES (agent_record.agent_id, permissions_json);
  END LOOP;
END $$;

-- Step 4: Enable RLS
ALTER TABLE ai_agent_permissions ENABLE ROW LEVEL SECURITY;

-- Step 5: Create RLS policies
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

-- Step 6: Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_ai_agent_permissions_agent_id ON ai_agent_permissions(agent_id);

-- Step 7: Create trigger for updated_at
DROP TRIGGER IF EXISTS update_ai_agent_permissions_updated_at ON ai_agent_permissions;
CREATE TRIGGER update_ai_agent_permissions_updated_at
  BEFORE UPDATE ON ai_agent_permissions
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();
