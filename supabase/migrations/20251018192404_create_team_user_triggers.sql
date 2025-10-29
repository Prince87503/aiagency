/*
  # Create Team User Trigger Events

  1. Changes
    - Create database trigger functions for team member (admin_users) operations
    - Add triggers on admin_users table for INSERT, UPDATE, and DELETE operations
    - When a team member is added/updated/deleted, check for active API webhooks
    - Send notification to configured webhook URLs
    - Track webhook statistics (total_calls, success_count, failure_count)

  2. New Trigger Events
    - USER_ADDED: Triggers when a new team member is created
    - USER_UPDATED: Triggers when a team member is updated
    - USER_DELETED: Triggers when a team member is deleted

  3. Functionality
    - Triggers both API webhooks and workflow automations based on team member operations
    - Passes all team member data to webhooks and workflows (excluding password_hash for security)
    - For updates, includes both NEW and previous values
    - For deletes, includes the deleted team member data with deleted_at timestamp
    - Supports multiple webhooks being triggered by the same event
    - Includes 'trigger_event' field in payload for easy event identification

  4. Security
    - Password hash is NEVER included in webhook payloads
    - Uses existing RLS policies on api_webhooks and workflow_executions tables
    - SECURITY DEFINER ensures triggers have permission to update statistics
*/

-- Create function to trigger workflows when a new team member is added
CREATE OR REPLACE FUNCTION trigger_workflows_on_user_add()
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
  -- Build trigger data with trigger_event (excluding password_hash for security)
  trigger_data := jsonb_build_object(
    'trigger_event', 'USER_ADDED',
    'id', NEW.id,
    'email', NEW.email,
    'full_name', NEW.full_name,
    'role', NEW.role,
    'permissions', NEW.permissions,
    'is_active', NEW.is_active,
    'phone', NEW.phone,
    'department', NEW.department,
    'status', NEW.status,
    'member_id', NEW.member_id,
    'last_login', NEW.last_login,
    'created_at', NEW.created_at,
    'updated_at', NEW.updated_at
  );

  -- Process API Webhooks first
  FOR api_webhook_record IN
    SELECT *
    FROM api_webhooks
    WHERE trigger_event = 'USER_ADDED'
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
    
    -- Check if this is a USER_ADDED trigger
    IF trigger_node->>'type' = 'trigger' 
       AND trigger_node->'properties'->>'event_name' = 'USER_ADDED' THEN
      
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
        'USER_ADDED',
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
          'trigger_type', 'USER_ADDED'
        )::text
      );
    END IF;
  END LOOP;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create function to trigger workflows when a team member is updated
CREATE OR REPLACE FUNCTION trigger_workflows_on_user_update()
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
  -- Build trigger data with trigger_event and previous values (excluding password_hash for security)
  trigger_data := jsonb_build_object(
    'trigger_event', 'USER_UPDATED',
    'id', NEW.id,
    'email', NEW.email,
    'full_name', NEW.full_name,
    'role', NEW.role,
    'permissions', NEW.permissions,
    'is_active', NEW.is_active,
    'phone', NEW.phone,
    'department', NEW.department,
    'status', NEW.status,
    'member_id', NEW.member_id,
    'last_login', NEW.last_login,
    'created_at', NEW.created_at,
    'updated_at', NEW.updated_at,
    'previous', jsonb_build_object(
      'email', OLD.email,
      'full_name', OLD.full_name,
      'role', OLD.role,
      'permissions', OLD.permissions,
      'is_active', OLD.is_active,
      'phone', OLD.phone,
      'department', OLD.department,
      'status', OLD.status,
      'member_id', OLD.member_id
    )
  );

  -- Process API Webhooks first
  FOR api_webhook_record IN
    SELECT *
    FROM api_webhooks
    WHERE trigger_event = 'USER_UPDATED'
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
    
    -- Check if this is a USER_UPDATED trigger
    IF trigger_node->>'type' = 'trigger' 
       AND trigger_node->'properties'->>'event_name' = 'USER_UPDATED' THEN
      
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
        'USER_UPDATED',
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
          'trigger_type', 'USER_UPDATED'
        )::text
      );
    END IF;
  END LOOP;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create function to trigger workflows when a team member is deleted
CREATE OR REPLACE FUNCTION trigger_workflows_on_user_delete()
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
  -- Build trigger data with trigger_event (excluding password_hash for security)
  trigger_data := jsonb_build_object(
    'trigger_event', 'USER_DELETED',
    'id', OLD.id,
    'email', OLD.email,
    'full_name', OLD.full_name,
    'role', OLD.role,
    'permissions', OLD.permissions,
    'is_active', OLD.is_active,
    'phone', OLD.phone,
    'department', OLD.department,
    'status', OLD.status,
    'member_id', OLD.member_id,
    'last_login', OLD.last_login,
    'created_at', OLD.created_at,
    'updated_at', OLD.updated_at,
    'deleted_at', now()
  );

  -- Process API Webhooks first
  FOR api_webhook_record IN
    SELECT *
    FROM api_webhooks
    WHERE trigger_event = 'USER_DELETED'
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
    
    -- Check if this is a USER_DELETED trigger
    IF trigger_node->>'type' = 'trigger' 
       AND trigger_node->'properties'->>'event_name' = 'USER_DELETED' THEN
      
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
        'USER_DELETED',
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
          'trigger_type', 'USER_DELETED'
        )::text
      );
    END IF;
  END LOOP;

  RETURN OLD;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create trigger on admin_users table for inserts
DROP TRIGGER IF EXISTS trigger_workflows_on_user_add ON admin_users;
CREATE TRIGGER trigger_workflows_on_user_add
  AFTER INSERT ON admin_users
  FOR EACH ROW
  EXECUTE FUNCTION trigger_workflows_on_user_add();

-- Create trigger on admin_users table for updates
DROP TRIGGER IF EXISTS trigger_workflows_on_user_update ON admin_users;
CREATE TRIGGER trigger_workflows_on_user_update
  AFTER UPDATE ON admin_users
  FOR EACH ROW
  EXECUTE FUNCTION trigger_workflows_on_user_update();

-- Create trigger on admin_users table for deletes
DROP TRIGGER IF EXISTS trigger_workflows_on_user_delete ON admin_users;
CREATE TRIGGER trigger_workflows_on_user_delete
  AFTER DELETE ON admin_users
  FOR EACH ROW
  EXECUTE FUNCTION trigger_workflows_on_user_delete();

-- Add comments
COMMENT ON FUNCTION trigger_workflows_on_user_add() IS 'Triggers both API webhooks and workflow automations when a new team member is added. Includes trigger_event in payload. Password hash excluded for security.';
COMMENT ON FUNCTION trigger_workflows_on_user_update() IS 'Triggers both API webhooks and workflow automations when a team member is updated. Includes trigger_event in payload. Password hash excluded for security.';
COMMENT ON FUNCTION trigger_workflows_on_user_delete() IS 'Triggers both API webhooks and workflow automations when a team member is deleted. Includes trigger_event in payload. Password hash excluded for security.';