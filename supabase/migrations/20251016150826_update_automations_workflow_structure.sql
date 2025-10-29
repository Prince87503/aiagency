/*
  # Update Automations to Workflow Structure

  1. Changes to Tables
    - Update `automations` table structure for workflow-based design
    - Remove old trigger/action fields
    - Add workflow nodes structure (trigger node + action nodes)
    - Each node has: type, name, properties (JSONB for configuration)

  2. New Structure
    - `workflow_nodes` (jsonb) - Array of nodes:
      - Each node: { id, type, name, properties, position }
      - First node is always trigger
      - Subsequent nodes are actions
    - Remove: trigger, trigger_type, actions fields
    - Keep: status, category, description for workflow metadata

  3. Important Notes
    - Workflow nodes stored as JSONB for flexibility
    - Each node type will have custom properties
    - Position data for visual workflow builder
*/

-- Add workflow_nodes column and remove old fields
DO $$
BEGIN
  -- Add new workflow_nodes column if it doesn't exist
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'automations' AND column_name = 'workflow_nodes'
  ) THEN
    ALTER TABLE automations ADD COLUMN workflow_nodes jsonb DEFAULT '[]'::jsonb;
  END IF;

  -- Drop old columns if they exist
  IF EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'automations' AND column_name = 'trigger'
  ) THEN
    ALTER TABLE automations DROP COLUMN trigger;
  END IF;

  IF EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'automations' AND column_name = 'trigger_type'
  ) THEN
    ALTER TABLE automations DROP COLUMN trigger_type;
  END IF;

  IF EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'automations' AND column_name = 'actions'
  ) THEN
    ALTER TABLE automations DROP COLUMN actions;
  END IF;
END $$;

-- Create index for workflow_nodes for better query performance
CREATE INDEX IF NOT EXISTS idx_automations_workflow_nodes ON automations USING gin(workflow_nodes);

-- Update workflow_config to be more flexible
COMMENT ON COLUMN automations.workflow_nodes IS 'Array of workflow nodes: [{id, type, name, properties, position}]';
COMMENT ON COLUMN automations.workflow_config IS 'Additional workflow configuration and metadata';