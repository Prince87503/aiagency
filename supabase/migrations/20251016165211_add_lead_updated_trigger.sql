/*
  # Add Lead Updated Trigger Event

  1. Changes
    - Create a new database trigger function for lead updates
    - Add trigger on leads table for UPDATE operations
    - When a lead is updated, check for active workflows with LEAD_UPDATED trigger
    - Create workflow execution records for matching workflows
    - Send notification via pg_notify for async workflow processing

  2. Functionality
    - Triggers workflows when any lead is updated
    - Passes all lead data (both OLD and NEW values) to the workflow
    - Works alongside the existing NEW_LEAD_ADDED trigger
    - Supports multiple workflows being triggered by the same event

  3. Security
    - Uses existing RLS policies on workflow_executions table
    - No additional security configuration needed
*/

-- Create function to trigger workflows when a lead is updated
CREATE OR REPLACE FUNCTION trigger_workflows_on_lead_update()
RETURNS TRIGGER AS $$
DECLARE
  automation_record RECORD;
  execution_id uuid;
  trigger_node jsonb;
BEGIN
  -- Find all active automations with LEAD_UPDATED trigger
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
    
    -- Check if this is a LEAD_UPDATED trigger
    IF trigger_node->>'type' = 'trigger' 
       AND trigger_node->'properties'->>'event_name' = 'LEAD_UPDATED' THEN
      
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
        'LEAD_UPDATED',
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
          'affiliate_id', NEW.affiliate_id,
          'previous', jsonb_build_object(
            'status', OLD.status,
            'interest', OLD.interest,
            'owner', OLD.owner,
            'notes', OLD.notes,
            'last_contact', OLD.last_contact,
            'lead_score', OLD.lead_score
          )
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
          'trigger_type', 'LEAD_UPDATED'
        )::text
      );
    END IF;
  END LOOP;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger on leads table for updates
DROP TRIGGER IF EXISTS trigger_workflows_on_lead_update ON leads;
CREATE TRIGGER trigger_workflows_on_lead_update
  AFTER UPDATE ON leads
  FOR EACH ROW
  EXECUTE FUNCTION trigger_workflows_on_lead_update();

-- Add comment
COMMENT ON FUNCTION trigger_workflows_on_lead_update() IS 'Triggers workflows when a lead is updated';