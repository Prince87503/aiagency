/*
  # Create Workflow Execution System

  1. New Tables
    - `workflow_executions` - Stores workflow execution logs
      - `id` (uuid, primary key) - Unique identifier
      - `automation_id` (uuid) - Reference to the automation/workflow
      - `trigger_type` (text) - Type of trigger that started this execution
      - `trigger_data` (jsonb) - The data from the trigger event
      - `status` (text) - Execution status (pending, running, completed, failed)
      - `steps_completed` (integer) - Number of steps completed
      - `total_steps` (integer) - Total number of steps in workflow
      - `error_message` (text) - Error message if failed
      - `started_at` (timestamptz) - When execution started
      - `completed_at` (timestamptz) - When execution completed
      - `created_at` (timestamptz) - Creation timestamp

  2. New Functions
    - `trigger_workflows_on_lead_insert()` - Function that triggers workflows when a new lead is added
    - This function will be called by a database trigger on the leads table

  3. Security
    - Enable RLS on `workflow_executions` table
    - Add policies for authenticated users to read and create executions

  4. Important Notes
    - When a new lead is inserted, all active workflows with LEADS trigger will be executed
    - Workflow execution is async and handled by edge functions
    - This migration creates the infrastructure for workflow execution
*/

-- Create workflow_executions table
CREATE TABLE IF NOT EXISTS workflow_executions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  automation_id uuid REFERENCES automations(id) ON DELETE CASCADE,
  trigger_type text NOT NULL,
  trigger_data jsonb DEFAULT '{}'::jsonb,
  status text DEFAULT 'pending' CHECK (status IN ('pending', 'running', 'completed', 'failed')),
  steps_completed integer DEFAULT 0,
  total_steps integer DEFAULT 0,
  error_message text,
  started_at timestamptz,
  completed_at timestamptz,
  created_at timestamptz DEFAULT now()
);

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_workflow_executions_automation_id ON workflow_executions(automation_id);
CREATE INDEX IF NOT EXISTS idx_workflow_executions_status ON workflow_executions(status);
CREATE INDEX IF NOT EXISTS idx_workflow_executions_trigger_type ON workflow_executions(trigger_type);
CREATE INDEX IF NOT EXISTS idx_workflow_executions_created_at ON workflow_executions(created_at DESC);

-- Enable RLS
ALTER TABLE workflow_executions ENABLE ROW LEVEL SECURITY;

-- Create policies
CREATE POLICY "Allow anon to read workflow executions"
  ON workflow_executions
  FOR SELECT
  TO anon
  USING (true);

CREATE POLICY "Allow authenticated to read workflow executions"
  ON workflow_executions
  FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Allow anon to insert workflow executions"
  ON workflow_executions
  FOR INSERT
  TO anon
  WITH CHECK (true);

CREATE POLICY "Allow authenticated to insert workflow executions"
  ON workflow_executions
  FOR INSERT
  TO authenticated
  WITH CHECK (true);

CREATE POLICY "Allow anon to update workflow executions"
  ON workflow_executions
  FOR UPDATE
  TO anon
  USING (true)
  WITH CHECK (true);

CREATE POLICY "Allow authenticated to update workflow executions"
  ON workflow_executions
  FOR UPDATE
  TO authenticated
  USING (true)
  WITH CHECK (true);

-- Create function to trigger workflows when a new lead is inserted
CREATE OR REPLACE FUNCTION trigger_workflows_on_lead_insert()
RETURNS TRIGGER AS $$
DECLARE
  automation_record RECORD;
  execution_id uuid;
  trigger_node jsonb;
BEGIN
  -- Find all active automations with LEADS trigger
  FOR automation_record IN
    SELECT 
      a.id,
      a.workflow_nodes
    FROM automations a
    WHERE a.status = 'Active'
      AND a.workflow_nodes IS NOT NULL
      AND jsonb_array_length(a.workflow_nodes) > 0
  LOOP
    -- Get the first node (trigger node)
    trigger_node := automation_record.workflow_nodes->0;
    
    -- Check if this is a LEADS trigger
    IF trigger_node->>'type' = 'trigger' 
       AND trigger_node->'properties'->>'event_name' = 'NEW_LEAD_ADDED' THEN
      
      -- Create a workflow execution record
      INSERT INTO workflow_executions (
        automation_id,
        trigger_type,
        trigger_data,
        status,
        total_steps,
        started_at
      ) VALUES (
        automation_record.id,
        'NEW_LEAD_ADDED',
        jsonb_build_object(
          'id', NEW.id,
          'lead_id', NEW.lead_id,
          'name', NEW.name,
          'email', NEW.email,
          'phone', NEW.phone,
          'source', NEW.source,
          'interest', NEW.interest,
          'status', NEW.status,
          'owner', NEW.owner,
          'address', NEW.address,
          'company', NEW.company,
          'notes', NEW.notes,
          'last_contact', NEW.last_contact,
          'lead_score', NEW.lead_score,
          'created_at', NEW.created_at,
          'updated_at', NEW.updated_at,
          'affiliate_id', NEW.affiliate_id
        ),
        'pending',
        jsonb_array_length(automation_record.workflow_nodes) - 1,
        now()
      ) RETURNING id INTO execution_id;

      -- Signal that a workflow needs to be executed
      PERFORM pg_notify(
        'workflow_execution',
        json_build_object(
          'execution_id', execution_id,
          'automation_id', automation_record.id,
          'trigger_type', 'NEW_LEAD_ADDED'
        )::text
      );
    END IF;
  END LOOP;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger on leads table
DROP TRIGGER IF EXISTS trigger_workflows_on_new_lead ON leads;
CREATE TRIGGER trigger_workflows_on_new_lead
  AFTER INSERT ON leads
  FOR EACH ROW
  EXECUTE FUNCTION trigger_workflows_on_lead_insert();

-- Add comments
COMMENT ON TABLE workflow_executions IS 'Stores workflow execution logs and status';
COMMENT ON FUNCTION trigger_workflows_on_lead_insert() IS 'Triggers workflows when a new lead is inserted';