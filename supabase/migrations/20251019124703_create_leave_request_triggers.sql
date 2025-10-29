/*
  # Create Leave Request Trigger Events

  1. Changes
    - Create database trigger functions for leave request operations
    - Add triggers on leave_requests table for INSERT, UPDATE, and DELETE operations
    - When a leave request is added/updated/deleted, check for active API webhooks
    - Send notification to configured webhook URLs
    - Track webhook statistics (total_calls, success_count, failure_count)

  2. New Trigger Events
    - LEAVE_REQUEST_ADDED: Triggers when a new leave request is created
    - LEAVE_REQUEST_UPDATED: Triggers when a leave request is updated
    - LEAVE_REQUEST_DELETED: Triggers when a leave request is deleted

  3. Functionality
    - Triggers both API webhooks and workflow automations based on leave request operations
    - Passes all leave request data to webhooks and workflows
    - For updates, includes both NEW and previous values
    - For deletes, includes the deleted request data with deleted_at timestamp
    - Supports multiple webhooks being triggered by the same event
    - Includes 'trigger_event' field in payload for easy event identification

  4. Security
    - Uses existing RLS policies on api_webhooks and workflow_executions tables
    - SECURITY DEFINER ensures triggers have permission to update statistics
*/

-- Create function to trigger workflows when a new leave request is added
CREATE OR REPLACE FUNCTION trigger_workflows_on_leave_request_add()
RETURNS TRIGGER AS $$
DECLARE
  automation_record RECORD;
  api_webhook_record RECORD;
  execution_id uuid;
  trigger_node jsonb;
  trigger_data jsonb;
  request_id bigint;
  webhook_success boolean;
  team_member_name text;
  approver_name text;
BEGIN
  -- Get team member name
  SELECT full_name INTO team_member_name
  FROM admin_users
  WHERE id = NEW.admin_user_id;

  -- Get approver name if applicable
  IF NEW.approved_by IS NOT NULL THEN
    SELECT full_name INTO approver_name
    FROM admin_users
    WHERE id = NEW.approved_by;
  END IF;

  -- Build trigger data with trigger_event
  trigger_data := jsonb_build_object(
    'trigger_event', 'LEAVE_REQUEST_ADDED',
    'id', NEW.id,
    'request_id', NEW.request_id,
    'admin_user_id', NEW.admin_user_id,
    'team_member_name', team_member_name,
    'request_type', NEW.request_type,
    'start_date', NEW.start_date,
    'end_date', NEW.end_date,
    'total_days', NEW.total_days,
    'reason', NEW.reason,
    'status', NEW.status,
    'approved_by', NEW.approved_by,
    'approver_name', approver_name,
    'approved_at', NEW.approved_at,
    'rejection_reason', NEW.rejection_reason,
    'notes', NEW.notes,
    'created_at', NEW.created_at,
    'updated_at', NEW.updated_at
  );

  -- Process API Webhooks first
  FOR api_webhook_record IN
    SELECT *
    FROM api_webhooks
    WHERE trigger_event = 'LEAVE_REQUEST_ADDED'
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
    
    -- Check if this is a LEAVE_REQUEST_ADDED trigger
    IF trigger_node->>'type' = 'trigger' 
       AND trigger_node->'properties'->>'event_name' = 'LEAVE_REQUEST_ADDED' THEN
      
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
        'LEAVE_REQUEST_ADDED',
        trigger_data,
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
          'trigger_type', 'LEAVE_REQUEST_ADDED'
        )::text
      );
    END IF;
  END LOOP;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create function to trigger workflows when a leave request is updated
CREATE OR REPLACE FUNCTION trigger_workflows_on_leave_request_update()
RETURNS TRIGGER AS $$
DECLARE
  automation_record RECORD;
  api_webhook_record RECORD;
  execution_id uuid;
  trigger_node jsonb;
  trigger_data jsonb;
  request_id bigint;
  webhook_success boolean;
  team_member_name text;
  approver_name text;
BEGIN
  -- Get team member name
  SELECT full_name INTO team_member_name
  FROM admin_users
  WHERE id = NEW.admin_user_id;

  -- Get approver name if applicable
  IF NEW.approved_by IS NOT NULL THEN
    SELECT full_name INTO approver_name
    FROM admin_users
    WHERE id = NEW.approved_by;
  END IF;

  -- Build trigger data with trigger_event and previous values
  trigger_data := jsonb_build_object(
    'trigger_event', 'LEAVE_REQUEST_UPDATED',
    'id', NEW.id,
    'request_id', NEW.request_id,
    'admin_user_id', NEW.admin_user_id,
    'team_member_name', team_member_name,
    'request_type', NEW.request_type,
    'start_date', NEW.start_date,
    'end_date', NEW.end_date,
    'total_days', NEW.total_days,
    'reason', NEW.reason,
    'status', NEW.status,
    'approved_by', NEW.approved_by,
    'approver_name', approver_name,
    'approved_at', NEW.approved_at,
    'rejection_reason', NEW.rejection_reason,
    'notes', NEW.notes,
    'created_at', NEW.created_at,
    'updated_at', NEW.updated_at,
    'previous', jsonb_build_object(
      'request_type', OLD.request_type,
      'start_date', OLD.start_date,
      'end_date', OLD.end_date,
      'total_days', OLD.total_days,
      'reason', OLD.reason,
      'status', OLD.status,
      'approved_by', OLD.approved_by,
      'approved_at', OLD.approved_at,
      'rejection_reason', OLD.rejection_reason
    )
  );

  -- Process API Webhooks first
  FOR api_webhook_record IN
    SELECT *
    FROM api_webhooks
    WHERE trigger_event = 'LEAVE_REQUEST_UPDATED'
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
    
    -- Check if this is a LEAVE_REQUEST_UPDATED trigger
    IF trigger_node->>'type' = 'trigger' 
       AND trigger_node->'properties'->>'event_name' = 'LEAVE_REQUEST_UPDATED' THEN
      
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
        'LEAVE_REQUEST_UPDATED',
        trigger_data,
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
          'trigger_type', 'LEAVE_REQUEST_UPDATED'
        )::text
      );
    END IF;
  END LOOP;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create function to trigger workflows when a leave request is deleted
CREATE OR REPLACE FUNCTION trigger_workflows_on_leave_request_delete()
RETURNS TRIGGER AS $$
DECLARE
  automation_record RECORD;
  api_webhook_record RECORD;
  execution_id uuid;
  trigger_node jsonb;
  trigger_data jsonb;
  request_id bigint;
  webhook_success boolean;
  team_member_name text;
  approver_name text;
BEGIN
  -- Get team member name
  SELECT full_name INTO team_member_name
  FROM admin_users
  WHERE id = OLD.admin_user_id;

  -- Get approver name if applicable
  IF OLD.approved_by IS NOT NULL THEN
    SELECT full_name INTO approver_name
    FROM admin_users
    WHERE id = OLD.approved_by;
  END IF;

  -- Build trigger data with trigger_event
  trigger_data := jsonb_build_object(
    'trigger_event', 'LEAVE_REQUEST_DELETED',
    'id', OLD.id,
    'request_id', OLD.request_id,
    'admin_user_id', OLD.admin_user_id,
    'team_member_name', team_member_name,
    'request_type', OLD.request_type,
    'start_date', OLD.start_date,
    'end_date', OLD.end_date,
    'total_days', OLD.total_days,
    'reason', OLD.reason,
    'status', OLD.status,
    'approved_by', OLD.approved_by,
    'approver_name', approver_name,
    'approved_at', OLD.approved_at,
    'rejection_reason', OLD.rejection_reason,
    'notes', OLD.notes,
    'created_at', OLD.created_at,
    'updated_at', OLD.updated_at,
    'deleted_at', now()
  );

  -- Process API Webhooks first
  FOR api_webhook_record IN
    SELECT *
    FROM api_webhooks
    WHERE trigger_event = 'LEAVE_REQUEST_DELETED'
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
    
    -- Check if this is a LEAVE_REQUEST_DELETED trigger
    IF trigger_node->>'type' = 'trigger' 
       AND trigger_node->'properties'->>'event_name' = 'LEAVE_REQUEST_DELETED' THEN
      
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
        'LEAVE_REQUEST_DELETED',
        trigger_data,
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
          'trigger_type', 'LEAVE_REQUEST_DELETED'
        )::text
      );
    END IF;
  END LOOP;

  RETURN OLD;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create trigger on leave_requests table for inserts
DROP TRIGGER IF EXISTS trigger_workflows_on_leave_request_add ON leave_requests;
CREATE TRIGGER trigger_workflows_on_leave_request_add
  AFTER INSERT ON leave_requests
  FOR EACH ROW
  EXECUTE FUNCTION trigger_workflows_on_leave_request_add();

-- Create trigger on leave_requests table for updates
DROP TRIGGER IF EXISTS trigger_workflows_on_leave_request_update ON leave_requests;
CREATE TRIGGER trigger_workflows_on_leave_request_update
  AFTER UPDATE ON leave_requests
  FOR EACH ROW
  EXECUTE FUNCTION trigger_workflows_on_leave_request_update();

-- Create trigger on leave_requests table for deletes
DROP TRIGGER IF EXISTS trigger_workflows_on_leave_request_delete ON leave_requests;
CREATE TRIGGER trigger_workflows_on_leave_request_delete
  AFTER DELETE ON leave_requests
  FOR EACH ROW
  EXECUTE FUNCTION trigger_workflows_on_leave_request_delete();

-- Add comments
COMMENT ON FUNCTION trigger_workflows_on_leave_request_add() IS 'Triggers both API webhooks and workflow automations when a new leave request is added. Includes trigger_event in payload.';
COMMENT ON FUNCTION trigger_workflows_on_leave_request_update() IS 'Triggers both API webhooks and workflow automations when a leave request is updated. Includes trigger_event in payload.';
COMMENT ON FUNCTION trigger_workflows_on_leave_request_delete() IS 'Triggers both API webhooks and workflow automations when a leave request is deleted. Includes trigger_event in payload.';