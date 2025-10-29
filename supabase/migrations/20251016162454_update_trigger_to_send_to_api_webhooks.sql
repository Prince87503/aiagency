/*
  # Update Trigger to Send Data to API Webhooks

  1. Changes
    - Update trigger_workflows_on_lead_insert() to also send data to configured API webhooks
    - API webhooks receive all trigger data as JSON POST request
    - Track success/failure statistics for each webhook

  2. Important Notes
    - API webhooks are simpler than workflow automations
    - They send ALL trigger data automatically, no field mapping needed
    - Multiple webhooks can be configured for the same trigger event
*/

-- Update the main trigger function to also handle API webhooks
CREATE OR REPLACE FUNCTION trigger_workflows_on_lead_insert()
RETURNS TRIGGER AS $$
DECLARE
  automation_record RECORD;
  api_webhook_record RECORD;
  execution_id uuid;
  trigger_node jsonb;
  action_node jsonb;
  webhook_config jsonb;
  v_steps_completed integer;
  v_total_steps integer;
  trigger_data jsonb;
  i integer;
  request_id bigint;
  webhook_success boolean;
BEGIN
  -- Build trigger data
  trigger_data := jsonb_build_object(
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
  );

  -- Process API Webhooks first
  FOR api_webhook_record IN
    SELECT *
    FROM api_webhooks
    WHERE trigger_event = 'NEW_LEAD_ADDED'
      AND is_active = true
  LOOP
    BEGIN
      webhook_success := false;
      
      -- Make HTTP POST request using pg_net
      SELECT net.http_post(
        url := api_webhook_record.webhook_url,
        headers := jsonb_build_object(
          'Content-Type', 'application/json'
        ),
        body := trigger_data
      ) INTO request_id;
      
      webhook_success := true;
      
      -- Update success statistics
      UPDATE api_webhooks
      SET 
        total_calls = COALESCE(total_calls, 0) + 1,
        success_count = COALESCE(success_count, 0) + 1,
        last_triggered = now()
      WHERE id = api_webhook_record.id;
      
    EXCEPTION
      WHEN OTHERS THEN
        -- Update failure statistics
        UPDATE api_webhooks
        SET 
          total_calls = COALESCE(total_calls, 0) + 1,
          failure_count = COALESCE(failure_count, 0) + 1,
          last_triggered = now()
        WHERE id = api_webhook_record.id;
        
        RAISE NOTICE 'API Webhook failed for %: %', api_webhook_record.name, SQLERRM;
    END;
  END LOOP;

  -- Process Workflow Automations
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
      
      v_total_steps := jsonb_array_length(automation_record.workflow_nodes) - 1;
      v_steps_completed := 0;
      
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
        trigger_data,
        'running',
        v_total_steps,
        now()
      ) RETURNING id INTO execution_id;
      
      -- Execute each action node
      BEGIN
        i := 1;
        WHILE i < jsonb_array_length(automation_record.workflow_nodes) LOOP
          action_node := automation_record.workflow_nodes->i;
          
          IF action_node->>'type' = 'action' 
             AND action_node->'properties'->>'action_type' = 'webhook' THEN
            
            webhook_config := action_node->'properties'->'webhook_config';
            
            IF webhook_config->>'webhook_url' IS NOT NULL THEN
              -- Execute webhook
              PERFORM execute_webhook_action(
                webhook_config->>'webhook_url',
                webhook_config->'headers',
                webhook_config->'body',
                trigger_data
              );
              
              v_steps_completed := v_steps_completed + 1;
            END IF;
          END IF;
          
          i := i + 1;
        END LOOP;
        
        -- Mark as completed
        UPDATE workflow_executions
        SET 
          status = 'completed',
          steps_completed = v_steps_completed,
          completed_at = now()
        WHERE workflow_executions.id = execution_id;
        
        -- Update automation stats
        UPDATE automations
        SET 
          total_runs = COALESCE(automations.total_runs, 0) + 1,
          last_run = now()
        WHERE automations.id = automation_record.id;
        
      EXCEPTION
        WHEN OTHERS THEN
          -- Mark as failed
          UPDATE workflow_executions
          SET 
            status = 'failed',
            steps_completed = v_steps_completed,
            error_message = SQLERRM,
            completed_at = now()
          WHERE workflow_executions.id = execution_id;
      END;
    END IF;
  END LOOP;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Recreate trigger
DROP TRIGGER IF EXISTS trigger_workflows_on_new_lead ON leads;
CREATE TRIGGER trigger_workflows_on_new_lead
  AFTER INSERT ON leads
  FOR EACH ROW
  EXECUTE FUNCTION trigger_workflows_on_lead_insert();

-- Add comment
COMMENT ON FUNCTION trigger_workflows_on_lead_insert() IS 'Triggers both API webhooks and workflow automations when a new lead is inserted';