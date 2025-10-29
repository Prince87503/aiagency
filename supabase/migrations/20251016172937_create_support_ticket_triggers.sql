/*
  # Create Support Ticket Triggers for API Webhooks and Automations

  1. Changes
    - Create trigger function for support ticket INSERT operations
    - Create trigger function for support ticket UPDATE operations
    - Create trigger function for support ticket DELETE operations
    - All triggers support both API webhooks and workflow automations

  2. Functionality
    - TICKET_CREATED: Triggers when a new support ticket is created
    - TICKET_UPDATED: Triggers when an existing ticket is updated
    - TICKET_DELETED: Triggers when a ticket is deleted
    - Sends POST requests to configured webhook URLs
    - Tracks webhook statistics (total_calls, success_count, failure_count)
    - Creates workflow execution records for active automations

  3. Security
    - SECURITY DEFINER ensures triggers have permission to update statistics
    - Uses existing RLS policies on api_webhooks and workflow_executions tables
*/

-- Trigger function for TICKET_CREATED
CREATE OR REPLACE FUNCTION trigger_workflows_on_ticket_insert()
RETURNS TRIGGER AS $$
DECLARE
  automation_record RECORD;
  api_webhook_record RECORD;
  execution_id uuid;
  trigger_node jsonb;
  trigger_data jsonb;
  request_id bigint;
  webhook_success boolean;
BEGIN
  -- Build trigger data
  trigger_data := jsonb_build_object(
    'id', NEW.id,
    'ticket_id', NEW.ticket_id,
    'enrolled_member_id', NEW.enrolled_member_id,
    'subject', NEW.subject,
    'description', NEW.description,
    'priority', NEW.priority,
    'status', NEW.status,
    'category', NEW.category,
    'assigned_to', NEW.assigned_to,
    'response_time', NEW.response_time,
    'satisfaction', NEW.satisfaction,
    'tags', NEW.tags,
    'created_at', NEW.created_at,
    'updated_at', NEW.updated_at
  );

  -- Process API Webhooks first
  FOR api_webhook_record IN
    SELECT *
    FROM api_webhooks
    WHERE trigger_event = 'TICKET_CREATED'
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
    trigger_node := automation_record.workflow_nodes->0;
    
    IF trigger_node->>'type' = 'trigger' 
       AND trigger_node->'properties'->>'event_name' = 'TICKET_CREATED' THEN
      
      INSERT INTO workflow_executions (
        automation_id,
        trigger_type,
        trigger_data,
        status,
        total_steps,
        started_at
      ) VALUES (
        automation_record.id,
        'TICKET_CREATED',
        trigger_data,
        'pending',
        jsonb_array_length(automation_record.workflow_nodes) - 1,
        now()
      ) RETURNING id INTO execution_id;

      PERFORM pg_notify(
        'workflow_execution',
        json_build_object(
          'execution_id', execution_id,
          'automation_id', automation_record.id,
          'trigger_type', 'TICKET_CREATED'
        )::text
      );
    END IF;
  END LOOP;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger function for TICKET_UPDATED
CREATE OR REPLACE FUNCTION trigger_workflows_on_ticket_update()
RETURNS TRIGGER AS $$
DECLARE
  automation_record RECORD;
  api_webhook_record RECORD;
  execution_id uuid;
  trigger_node jsonb;
  trigger_data jsonb;
  request_id bigint;
  webhook_success boolean;
BEGIN
  -- Build trigger data
  trigger_data := jsonb_build_object(
    'id', NEW.id,
    'ticket_id', NEW.ticket_id,
    'enrolled_member_id', NEW.enrolled_member_id,
    'subject', NEW.subject,
    'description', NEW.description,
    'priority', NEW.priority,
    'status', NEW.status,
    'category', NEW.category,
    'assigned_to', NEW.assigned_to,
    'response_time', NEW.response_time,
    'satisfaction', NEW.satisfaction,
    'tags', NEW.tags,
    'created_at', NEW.created_at,
    'updated_at', NEW.updated_at,
    'previous', jsonb_build_object(
      'priority', OLD.priority,
      'status', OLD.status,
      'category', OLD.category,
      'assigned_to', OLD.assigned_to,
      'response_time', OLD.response_time,
      'satisfaction', OLD.satisfaction
    )
  );

  -- Process API Webhooks first
  FOR api_webhook_record IN
    SELECT *
    FROM api_webhooks
    WHERE trigger_event = 'TICKET_UPDATED'
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
    trigger_node := automation_record.workflow_nodes->0;
    
    IF trigger_node->>'type' = 'trigger' 
       AND trigger_node->'properties'->>'event_name' = 'TICKET_UPDATED' THEN
      
      INSERT INTO workflow_executions (
        automation_id,
        trigger_type,
        trigger_data,
        status,
        total_steps,
        started_at
      ) VALUES (
        automation_record.id,
        'TICKET_UPDATED',
        trigger_data,
        'pending',
        jsonb_array_length(automation_record.workflow_nodes) - 1,
        now()
      ) RETURNING id INTO execution_id;

      PERFORM pg_notify(
        'workflow_execution',
        json_build_object(
          'execution_id', execution_id,
          'automation_id', automation_record.id,
          'trigger_type', 'TICKET_UPDATED'
        )::text
      );
    END IF;
  END LOOP;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger function for TICKET_DELETED
CREATE OR REPLACE FUNCTION trigger_workflows_on_ticket_delete()
RETURNS TRIGGER AS $$
DECLARE
  automation_record RECORD;
  api_webhook_record RECORD;
  execution_id uuid;
  trigger_node jsonb;
  trigger_data jsonb;
  request_id bigint;
  webhook_success boolean;
BEGIN
  -- Build trigger data
  trigger_data := jsonb_build_object(
    'id', OLD.id,
    'ticket_id', OLD.ticket_id,
    'enrolled_member_id', OLD.enrolled_member_id,
    'subject', OLD.subject,
    'description', OLD.description,
    'priority', OLD.priority,
    'status', OLD.status,
    'category', OLD.category,
    'assigned_to', OLD.assigned_to,
    'response_time', OLD.response_time,
    'satisfaction', OLD.satisfaction,
    'tags', OLD.tags,
    'created_at', OLD.created_at,
    'updated_at', OLD.updated_at,
    'deleted_at', now()
  );

  -- Process API Webhooks first
  FOR api_webhook_record IN
    SELECT *
    FROM api_webhooks
    WHERE trigger_event = 'TICKET_DELETED'
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
    trigger_node := automation_record.workflow_nodes->0;

    IF trigger_node->>'type' = 'trigger'
       AND trigger_node->'properties'->>'event_name' = 'TICKET_DELETED' THEN

      INSERT INTO workflow_executions (
        automation_id,
        trigger_type,
        trigger_data,
        status,
        total_steps,
        started_at
      ) VALUES (
        automation_record.id,
        'TICKET_DELETED',
        trigger_data,
        'pending',
        jsonb_array_length(automation_record.workflow_nodes) - 1,
        now()
      ) RETURNING id INTO execution_id;

      PERFORM pg_notify(
        'workflow_execution',
        json_build_object(
          'execution_id', execution_id,
          'automation_id', automation_record.id,
          'trigger_type', 'TICKET_DELETED'
        )::text
      );
    END IF;
  END LOOP;

  RETURN OLD;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create triggers on support_tickets table
DROP TRIGGER IF EXISTS trigger_workflows_on_ticket_insert ON support_tickets;
CREATE TRIGGER trigger_workflows_on_ticket_insert
  AFTER INSERT ON support_tickets
  FOR EACH ROW
  EXECUTE FUNCTION trigger_workflows_on_ticket_insert();

DROP TRIGGER IF EXISTS trigger_workflows_on_ticket_update ON support_tickets;
CREATE TRIGGER trigger_workflows_on_ticket_update
  AFTER UPDATE ON support_tickets
  FOR EACH ROW
  EXECUTE FUNCTION trigger_workflows_on_ticket_update();

DROP TRIGGER IF EXISTS trigger_workflows_on_ticket_delete ON support_tickets;
CREATE TRIGGER trigger_workflows_on_ticket_delete
  AFTER DELETE ON support_tickets
  FOR EACH ROW
  EXECUTE FUNCTION trigger_workflows_on_ticket_delete();

-- Add comments
COMMENT ON FUNCTION trigger_workflows_on_ticket_insert() IS 'Triggers both API webhooks and workflow automations when a support ticket is created';
COMMENT ON FUNCTION trigger_workflows_on_ticket_update() IS 'Triggers both API webhooks and workflow automations when a support ticket is updated';
COMMENT ON FUNCTION trigger_workflows_on_ticket_delete() IS 'Triggers both API webhooks and workflow automations when a support ticket is deleted';
