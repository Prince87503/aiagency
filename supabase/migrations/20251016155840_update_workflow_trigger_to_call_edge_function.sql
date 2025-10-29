/*
  # Update Workflow Trigger to Call Edge Function

  1. Changes
    - Update trigger_workflows_on_lead_insert() function to call the execute-workflow edge function
    - Use pg_net extension to make HTTP requests to the edge function

  2. Important Notes
    - The edge function will handle the actual workflow execution
    - This keeps the database trigger lightweight and fast
    - Edge function can handle complex operations like HTTP requests
*/

-- Enable pg_net extension if not already enabled
CREATE EXTENSION IF NOT EXISTS pg_net;

-- Update the function to call the edge function
CREATE OR REPLACE FUNCTION trigger_workflows_on_lead_insert()
RETURNS TRIGGER AS $$
DECLARE
  automation_record RECORD;
  execution_id uuid;
  trigger_node jsonb;
  supabase_url text;
  supabase_anon_key text;
  request_id bigint;
BEGIN
  -- Get Supabase URL and key from environment
  supabase_url := current_setting('app.settings.supabase_url', true);
  supabase_anon_key := current_setting('app.settings.supabase_anon_key', true);
  
  -- Fallback to default if not set
  IF supabase_url IS NULL THEN
    supabase_url := 'https://' || current_setting('request.header.host', true);
  END IF;

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

      -- Call the edge function asynchronously using pg_net
      BEGIN
        SELECT net.http_post(
          url := supabase_url || '/functions/v1/execute-workflow',
          headers := jsonb_build_object(
            'Content-Type', 'application/json',
            'Authorization', 'Bearer ' || COALESCE(supabase_anon_key, '')
          ),
          body := jsonb_build_object(
            'execution_id', execution_id
          )
        ) INTO request_id;
      EXCEPTION
        WHEN OTHERS THEN
          -- If edge function call fails, just log it and continue
          RAISE NOTICE 'Failed to call edge function: %', SQLERRM;
      END;
    END IF;
  END LOOP;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Update trigger
DROP TRIGGER IF EXISTS trigger_workflows_on_new_lead ON leads;
CREATE TRIGGER trigger_workflows_on_new_lead
  AFTER INSERT ON leads
  FOR EACH ROW
  EXECUTE FUNCTION trigger_workflows_on_lead_insert();