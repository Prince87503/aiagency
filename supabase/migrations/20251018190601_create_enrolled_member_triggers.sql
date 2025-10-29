/*
  # Create Enrolled Member Trigger Events

  1. Changes
    - Create database trigger functions for enrolled member operations
    - Add triggers on enrolled_members table for INSERT, UPDATE, and DELETE operations
    - When a member is added/updated/deleted, check for active API webhooks
    - Send notification to configured webhook URLs
    - Track webhook statistics (total_calls, success_count, failure_count)

  2. New Trigger Events
    - MEMBER_ADDED: Triggers when a new enrolled member is created
    - MEMBER_UPDATED: Triggers when an enrolled member is updated
    - MEMBER_DELETED: Triggers when an enrolled member is deleted

  3. Functionality
    - Triggers both API webhooks and workflow automations based on member operations
    - Passes all enrolled member data to webhooks and workflows
    - For updates, includes both NEW and previous values
    - For deletes, includes the deleted member data with deleted_at timestamp
    - Supports multiple webhooks being triggered by the same event
    - Includes 'trigger_event' field in payload for easy event identification

  4. Security
    - Uses existing RLS policies on api_webhooks and workflow_executions tables
    - SECURITY DEFINER ensures triggers have permission to update statistics
*/

-- Create function to trigger workflows when a new enrolled member is added
CREATE OR REPLACE FUNCTION trigger_workflows_on_member_add()
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
  -- Build trigger data with trigger_event
  trigger_data := jsonb_build_object(
    'trigger_event', 'MEMBER_ADDED',
    'id', NEW.id,
    'user_id', NEW.user_id,
    'email', NEW.email,
    'full_name', NEW.full_name,
    'phone', NEW.phone,
    'enrollment_date', NEW.enrollment_date,
    'status', NEW.status,
    'course_id', NEW.course_id,
    'course_name', NEW.course_name,
    'payment_status', NEW.payment_status,
    'payment_amount', NEW.payment_amount,
    'payment_date', NEW.payment_date,
    'subscription_type', NEW.subscription_type,
    'last_activity', NEW.last_activity,
    'progress_percentage', NEW.progress_percentage,
    'notes', NEW.notes,
    'date_of_birth', NEW.date_of_birth,
    'gender', NEW.gender,
    'education_level', NEW.education_level,
    'profession', NEW.profession,
    'experience', NEW.experience,
    'business_name', NEW.business_name,
    'address', NEW.address,
    'city', NEW.city,
    'state', NEW.state,
    'pincode', NEW.pincode,
    'gst_number', NEW.gst_number,
    'created_at', NEW.created_at,
    'updated_at', NEW.updated_at
  );

  -- Process API Webhooks first
  FOR api_webhook_record IN
    SELECT *
    FROM api_webhooks
    WHERE trigger_event = 'MEMBER_ADDED'
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
    
    -- Check if this is a MEMBER_ADDED trigger
    IF trigger_node->>'type' = 'trigger' 
       AND trigger_node->'properties'->>'event_name' = 'MEMBER_ADDED' THEN
      
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
        'MEMBER_ADDED',
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
          'trigger_type', 'MEMBER_ADDED'
        )::text
      );
    END IF;
  END LOOP;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create function to trigger workflows when an enrolled member is updated
CREATE OR REPLACE FUNCTION trigger_workflows_on_member_update()
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
  -- Build trigger data with trigger_event and previous values
  trigger_data := jsonb_build_object(
    'trigger_event', 'MEMBER_UPDATED',
    'id', NEW.id,
    'user_id', NEW.user_id,
    'email', NEW.email,
    'full_name', NEW.full_name,
    'phone', NEW.phone,
    'enrollment_date', NEW.enrollment_date,
    'status', NEW.status,
    'course_id', NEW.course_id,
    'course_name', NEW.course_name,
    'payment_status', NEW.payment_status,
    'payment_amount', NEW.payment_amount,
    'payment_date', NEW.payment_date,
    'subscription_type', NEW.subscription_type,
    'last_activity', NEW.last_activity,
    'progress_percentage', NEW.progress_percentage,
    'notes', NEW.notes,
    'date_of_birth', NEW.date_of_birth,
    'gender', NEW.gender,
    'education_level', NEW.education_level,
    'profession', NEW.profession,
    'experience', NEW.experience,
    'business_name', NEW.business_name,
    'address', NEW.address,
    'city', NEW.city,
    'state', NEW.state,
    'pincode', NEW.pincode,
    'gst_number', NEW.gst_number,
    'created_at', NEW.created_at,
    'updated_at', NEW.updated_at,
    'previous', jsonb_build_object(
      'status', OLD.status,
      'payment_status', OLD.payment_status,
      'payment_amount', OLD.payment_amount,
      'subscription_type', OLD.subscription_type,
      'progress_percentage', OLD.progress_percentage,
      'last_activity', OLD.last_activity,
      'notes', OLD.notes
    )
  );

  -- Process API Webhooks first
  FOR api_webhook_record IN
    SELECT *
    FROM api_webhooks
    WHERE trigger_event = 'MEMBER_UPDATED'
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
    
    -- Check if this is a MEMBER_UPDATED trigger
    IF trigger_node->>'type' = 'trigger' 
       AND trigger_node->'properties'->>'event_name' = 'MEMBER_UPDATED' THEN
      
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
        'MEMBER_UPDATED',
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
          'trigger_type', 'MEMBER_UPDATED'
        )::text
      );
    END IF;
  END LOOP;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create function to trigger workflows when an enrolled member is deleted
CREATE OR REPLACE FUNCTION trigger_workflows_on_member_delete()
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
  -- Build trigger data with trigger_event
  trigger_data := jsonb_build_object(
    'trigger_event', 'MEMBER_DELETED',
    'id', OLD.id,
    'user_id', OLD.user_id,
    'email', OLD.email,
    'full_name', OLD.full_name,
    'phone', OLD.phone,
    'enrollment_date', OLD.enrollment_date,
    'status', OLD.status,
    'course_id', OLD.course_id,
    'course_name', OLD.course_name,
    'payment_status', OLD.payment_status,
    'payment_amount', OLD.payment_amount,
    'payment_date', OLD.payment_date,
    'subscription_type', OLD.subscription_type,
    'last_activity', OLD.last_activity,
    'progress_percentage', OLD.progress_percentage,
    'notes', OLD.notes,
    'date_of_birth', OLD.date_of_birth,
    'gender', OLD.gender,
    'education_level', OLD.education_level,
    'profession', OLD.profession,
    'experience', OLD.experience,
    'business_name', OLD.business_name,
    'address', OLD.address,
    'city', OLD.city,
    'state', OLD.state,
    'pincode', OLD.pincode,
    'gst_number', OLD.gst_number,
    'created_at', OLD.created_at,
    'updated_at', OLD.updated_at,
    'deleted_at', now()
  );

  -- Process API Webhooks first
  FOR api_webhook_record IN
    SELECT *
    FROM api_webhooks
    WHERE trigger_event = 'MEMBER_DELETED'
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
    
    -- Check if this is a MEMBER_DELETED trigger
    IF trigger_node->>'type' = 'trigger' 
       AND trigger_node->'properties'->>'event_name' = 'MEMBER_DELETED' THEN
      
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
        'MEMBER_DELETED',
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
          'trigger_type', 'MEMBER_DELETED'
        )::text
      );
    END IF;
  END LOOP;

  RETURN OLD;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create trigger on enrolled_members table for inserts
DROP TRIGGER IF EXISTS trigger_workflows_on_member_add ON enrolled_members;
CREATE TRIGGER trigger_workflows_on_member_add
  AFTER INSERT ON enrolled_members
  FOR EACH ROW
  EXECUTE FUNCTION trigger_workflows_on_member_add();

-- Create trigger on enrolled_members table for updates
DROP TRIGGER IF EXISTS trigger_workflows_on_member_update ON enrolled_members;
CREATE TRIGGER trigger_workflows_on_member_update
  AFTER UPDATE ON enrolled_members
  FOR EACH ROW
  EXECUTE FUNCTION trigger_workflows_on_member_update();

-- Create trigger on enrolled_members table for deletes
DROP TRIGGER IF EXISTS trigger_workflows_on_member_delete ON enrolled_members;
CREATE TRIGGER trigger_workflows_on_member_delete
  AFTER DELETE ON enrolled_members
  FOR EACH ROW
  EXECUTE FUNCTION trigger_workflows_on_member_delete();

-- Add comments
COMMENT ON FUNCTION trigger_workflows_on_member_add() IS 'Triggers both API webhooks and workflow automations when a new enrolled member is added. Includes trigger_event in payload.';
COMMENT ON FUNCTION trigger_workflows_on_member_update() IS 'Triggers both API webhooks and workflow automations when an enrolled member is updated. Includes trigger_event in payload.';
COMMENT ON FUNCTION trigger_workflows_on_member_delete() IS 'Triggers both API webhooks and workflow automations when an enrolled member is deleted. Includes trigger_event in payload.';