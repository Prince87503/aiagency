/*
  # Create Attendance Trigger Events

  1. Changes
    - Create database trigger functions for attendance operations
    - Add triggers on attendance table for INSERT and UPDATE operations
    - When a check-in occurs (INSERT), trigger ATTENDANCE_CHECKIN event
    - When a check-out occurs (UPDATE with check_out_time), trigger ATTENDANCE_CHECKOUT event
    - Send notifications to configured webhook URLs
    - Track webhook statistics (total_calls, success_count, failure_count)

  2. New Trigger Events
    - ATTENDANCE_CHECKIN: Triggers when an employee checks in (attendance record created)
    - ATTENDANCE_CHECKOUT: Triggers when an employee checks out (check_out_time updated)

  3. Functionality
    - Triggers both API webhooks and workflow automations based on attendance operations
    - Passes all attendance data to webhooks and workflows
    - For check-out, includes both current and check-in time data
    - Supports multiple webhooks being triggered by the same event
    - Includes 'trigger_event' field in payload for easy event identification

  4. Security
    - Uses existing RLS policies on api_webhooks and workflow_executions tables
    - SECURITY DEFINER ensures triggers have permission to update statistics
*/

-- Create function to trigger workflows when check-in occurs
CREATE OR REPLACE FUNCTION trigger_workflows_on_attendance_checkin()
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
  -- Build trigger data with trigger_event for check-in
  trigger_data := jsonb_build_object(
    'trigger_event', 'ATTENDANCE_CHECKIN',
    'id', NEW.id,
    'admin_user_id', NEW.admin_user_id,
    'date', NEW.date,
    'check_in_time', NEW.check_in_time,
    'check_in_selfie_url', NEW.check_in_selfie_url,
    'check_in_location', NEW.check_in_location,
    'status', NEW.status,
    'notes', NEW.notes,
    'created_at', NEW.created_at,
    'updated_at', NEW.updated_at
  );

  -- Process API Webhooks first
  FOR api_webhook_record IN
    SELECT *
    FROM api_webhooks
    WHERE trigger_event = 'ATTENDANCE_CHECKIN'
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
    
    -- Check if this is an ATTENDANCE_CHECKIN trigger
    IF trigger_node->>'type' = 'trigger' 
       AND trigger_node->'properties'->>'event_name' = 'ATTENDANCE_CHECKIN' THEN
      
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
        'ATTENDANCE_CHECKIN',
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
          'trigger_type', 'ATTENDANCE_CHECKIN'
        )::text
      );
    END IF;
  END LOOP;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create function to trigger workflows when check-out occurs
CREATE OR REPLACE FUNCTION trigger_workflows_on_attendance_checkout()
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
  -- Only trigger if check_out_time was just set (was NULL and now has a value)
  IF OLD.check_out_time IS NULL AND NEW.check_out_time IS NOT NULL THEN
    -- Build trigger data with trigger_event for check-out
    trigger_data := jsonb_build_object(
      'trigger_event', 'ATTENDANCE_CHECKOUT',
      'id', NEW.id,
      'admin_user_id', NEW.admin_user_id,
      'date', NEW.date,
      'check_in_time', NEW.check_in_time,
      'check_out_time', NEW.check_out_time,
      'check_in_selfie_url', NEW.check_in_selfie_url,
      'check_in_location', NEW.check_in_location,
      'status', NEW.status,
      'notes', NEW.notes,
      'created_at', NEW.created_at,
      'updated_at', NEW.updated_at
    );

    -- Process API Webhooks first
    FOR api_webhook_record IN
      SELECT *
      FROM api_webhooks
      WHERE trigger_event = 'ATTENDANCE_CHECKOUT'
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
      
      -- Check if this is an ATTENDANCE_CHECKOUT trigger
      IF trigger_node->>'type' = 'trigger' 
         AND trigger_node->'properties'->>'event_name' = 'ATTENDANCE_CHECKOUT' THEN
        
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
          'ATTENDANCE_CHECKOUT',
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
            'trigger_type', 'ATTENDANCE_CHECKOUT'
          )::text
        );
      END IF;
    END LOOP;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create trigger on attendance table for inserts (check-in)
DROP TRIGGER IF EXISTS trigger_workflows_on_attendance_checkin ON attendance;
CREATE TRIGGER trigger_workflows_on_attendance_checkin
  AFTER INSERT ON attendance
  FOR EACH ROW
  EXECUTE FUNCTION trigger_workflows_on_attendance_checkin();

-- Create trigger on attendance table for updates (check-out)
DROP TRIGGER IF EXISTS trigger_workflows_on_attendance_checkout ON attendance;
CREATE TRIGGER trigger_workflows_on_attendance_checkout
  AFTER UPDATE ON attendance
  FOR EACH ROW
  EXECUTE FUNCTION trigger_workflows_on_attendance_checkout();

-- Add comments
COMMENT ON FUNCTION trigger_workflows_on_attendance_checkin() IS 'Triggers both API webhooks and workflow automations when an employee checks in. Includes trigger_event in payload.';
COMMENT ON FUNCTION trigger_workflows_on_attendance_checkout() IS 'Triggers both API webhooks and workflow automations when an employee checks out. Includes trigger_event in payload.';