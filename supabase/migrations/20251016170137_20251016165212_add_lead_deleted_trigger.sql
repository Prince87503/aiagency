/*
  # Add Lead Deleted Trigger Event

  1. Changes
    - Create a new database trigger function for lead deletions
    - Add trigger on leads table for DELETE operations
    - When a lead is deleted, check for active workflows with LEAD_DELETED trigger
    - Create workflow execution records for matching workflows
    - Send notification via pg_notify for async workflow processing

  2. Functionality
    - Triggers workflows when any lead is deleted
    - Passes all lead data to the workflow before deletion
    - Works alongside existing NEW_LEAD_ADDED and LEAD_UPDATED triggers
    - Supports multiple workflows being triggered by the same event

  3. Security
    - Uses existing RLS policies on workflow_executions table
    - No additional security configuration needed
*/

-- Create function to trigger workflows when a lead is deleted
CREATE OR REPLACE FUNCTION trigger_workflows_on_lead_delete()
RETURNS TRIGGER AS $$
DECLARE
  automation_record RECORD;
  execution_id uuid;
  trigger_node jsonb;
BEGIN
  -- Find all active automations with LEAD_DELETED trigger
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

    -- Check if this is a LEAD_DELETED trigger
    IF trigger_node->>'type' = 'trigger'
       AND trigger_node->'properties'->>'event_name' = 'LEAD_DELETED' THEN

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
        'LEAD_DELETED',
        jsonb_build_object(
          'id', OLD.id,
          'lead_id', OLD.lead_id,
          'name', OLD.name,
          'email', OLD.email,
          'phone', OLD.phone,
          'source', OLD.source,
          'interest', OLD.interest,
          'status', OLD.status,
          'owner', OLD.owner,
          'address', OLD.address,
          'company', OLD.company,
          'notes', OLD.notes,
          'last_contact', OLD.last_contact,
          'lead_score', OLD.lead_score,
          'created_at', OLD.created_at,
          'updated_at', OLD.updated_at,
          'affiliate_id', OLD.affiliate_id,
          'deleted_at', now()
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
          'trigger_type', 'LEAD_DELETED'
        )::text
      );
    END IF;
  END LOOP;

  RETURN OLD;
END;
$$ LANGUAGE plpgsql;

-- Create trigger on leads table for deletions
DROP TRIGGER IF EXISTS trigger_workflows_on_lead_delete ON leads;
CREATE TRIGGER trigger_workflows_on_lead_delete
  AFTER DELETE ON leads
  FOR EACH ROW
  EXECUTE FUNCTION trigger_workflows_on_lead_delete();

-- Add comment
COMMENT ON FUNCTION trigger_workflows_on_lead_delete() IS 'Triggers workflows when a lead is deleted';
