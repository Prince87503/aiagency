/*
  # Simplify Workflow Trigger Execution

  1. Changes
    - Simplify the trigger function to directly execute workflows inline
    - Remove dependency on edge function for simple webhook actions
    - Makes execution faster and more reliable

  2. Important Notes
    - For webhook actions, we'll execute them directly from the trigger
    - This is more efficient than calling an edge function
    - Complex actions can still use edge functions in future
*/

-- Create function to execute webhook action
CREATE OR REPLACE FUNCTION execute_webhook_action(
  webhook_url text,
  headers jsonb,
  body_params jsonb,
  trigger_data jsonb
)
RETURNS void AS $$
DECLARE
  final_url text;
  final_headers jsonb;
  final_body jsonb;
  header_item jsonb;
  body_item jsonb;
  key text;
  value text;
  request_id bigint;
BEGIN
  -- Build final URL (no query params for now, can be added later)
  final_url := webhook_url;
  
  -- Build headers
  final_headers := '{}'::jsonb;
  IF headers IS NOT NULL THEN
    FOR header_item IN SELECT * FROM jsonb_array_elements(headers)
    LOOP
      key := header_item->>'key';
      value := header_item->>'value';
      IF key IS NOT NULL AND key != '' THEN
        -- Replace placeholders
        value := regexp_replace(value, '\\{\\{(\\w+)\\}\\}', trigger_data->>E'\\1', 'g');
        final_headers := final_headers || jsonb_build_object(key, value);
      END IF;
    END LOOP;
  END IF;
  
  -- Build body
  final_body := '{}'::jsonb;
  IF body_params IS NOT NULL THEN
    FOR body_item IN SELECT * FROM jsonb_array_elements(body_params)
    LOOP
      key := body_item->>'key';
      value := body_item->>'value';
      IF key IS NOT NULL AND key != '' THEN
        -- Replace placeholders
        value := regexp_replace(value, '\\{\\{(\\w+)\\}\\}', trigger_data->>E'\\1', 'g');
        final_body := final_body || jsonb_build_object(key, value);
      END IF;
    END LOOP;
  END IF;
  
  -- Make HTTP request using pg_net
  BEGIN
    SELECT net.http_post(
      url := final_url,
      headers := final_headers,
      body := final_body
    ) INTO request_id;
  EXCEPTION
    WHEN OTHERS THEN
      RAISE NOTICE 'Webhook request failed: %', SQLERRM;
  END;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Update the main trigger function to execute actions inline
CREATE OR REPLACE FUNCTION trigger_workflows_on_lead_insert()
RETURNS TRIGGER AS $$
DECLARE
  automation_record RECORD;
  execution_id uuid;
  trigger_node jsonb;
  action_node jsonb;
  webhook_config jsonb;
  steps_completed integer;
  total_steps integer;
  trigger_data jsonb;
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
      
      total_steps := jsonb_array_length(automation_record.workflow_nodes) - 1;
      steps_completed := 0;
      
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
        total_steps,
        now()
      ) RETURNING id INTO execution_id;
      
      -- Execute each action node
      BEGIN
        FOR i IN 1..jsonb_array_length(automation_record.workflow_nodes)-1 LOOP
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
              
              steps_completed := steps_completed + 1;
            END IF;
          END IF;
        END LOOP;
        
        -- Mark as completed
        UPDATE workflow_executions
        SET 
          status = 'completed',
          steps_completed = steps_completed,
          completed_at = now()
        WHERE id = execution_id;
        
        -- Update automation stats
        UPDATE automations
        SET 
          total_runs = COALESCE(total_runs, 0) + 1,
          last_run = now()
        WHERE id = automation_record.id;
        
      EXCEPTION
        WHEN OTHERS THEN
          -- Mark as failed
          UPDATE workflow_executions
          SET 
            status = 'failed',
            steps_completed = steps_completed,
            error_message = SQLERRM,
            completed_at = now()
          WHERE id = execution_id;
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