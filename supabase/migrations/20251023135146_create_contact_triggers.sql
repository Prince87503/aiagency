/*
  # Create Contact Trigger Events

  1. Changes
    - Create database trigger functions for contact (contacts_master) operations
    - Add triggers on contacts_master table for INSERT, UPDATE, and DELETE operations
    - When a contact is added/updated/deleted, check for active API webhooks
    - Send notification to configured webhook URLs
    - Track webhook statistics (total_calls, success_count, failure_count)

  2. New Trigger Events
    - CONTACT_ADDED: Triggers when a new contact is created
    - CONTACT_UPDATED: Triggers when a contact is updated
    - CONTACT_DELETED: Triggers when a contact is deleted

  3. Functionality
    - Triggers both API webhooks and workflow automations based on contact operations
    - Passes all contact data to webhooks and workflows
    - For updates, includes both NEW and previous values
    - For deletes, includes the deleted contact data with deleted_at timestamp
    - Supports multiple webhooks being triggered by the same event
    - Includes 'trigger_event' field in payload for easy event identification

  4. Security
    - Uses existing RLS policies on api_webhooks and workflow_executions tables
    - SECURITY DEFINER ensures triggers have permission to update statistics
*/

-- Create function to trigger workflows when a new contact is added
CREATE OR REPLACE FUNCTION trigger_workflows_on_contact_add()
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
    'trigger_event', 'CONTACT_ADDED',
    'id', NEW.id,
    'contact_id', NEW.contact_id,
    'full_name', NEW.full_name,
    'email', NEW.email,
    'phone', NEW.phone,
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
    'contact_type', NEW.contact_type,
    'status', NEW.status,
    'notes', NEW.notes,
    'last_contacted', NEW.last_contacted,
    'tags', NEW.tags,
    'created_at', NEW.created_at,
    'updated_at', NEW.updated_at
  );

  -- Process API Webhooks first
  FOR api_webhook_record IN
    SELECT *
    FROM api_webhooks
    WHERE trigger_event = 'CONTACT_ADDED'
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

    -- Check if this is a CONTACT_ADDED trigger
    IF trigger_node->>'type' = 'trigger'
       AND trigger_node->'properties'->>'event_name' = 'CONTACT_ADDED' THEN

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
        'CONTACT_ADDED',
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
          'trigger_type', 'CONTACT_ADDED'
        )::text
      );
    END IF;
  END LOOP;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create function to trigger workflows when a contact is updated
CREATE OR REPLACE FUNCTION trigger_workflows_on_contact_update()
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
    'trigger_event', 'CONTACT_UPDATED',
    'id', NEW.id,
    'contact_id', NEW.contact_id,
    'full_name', NEW.full_name,
    'email', NEW.email,
    'phone', NEW.phone,
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
    'contact_type', NEW.contact_type,
    'status', NEW.status,
    'notes', NEW.notes,
    'last_contacted', NEW.last_contacted,
    'tags', NEW.tags,
    'created_at', NEW.created_at,
    'updated_at', NEW.updated_at,
    'previous', jsonb_build_object(
      'full_name', OLD.full_name,
      'email', OLD.email,
      'phone', OLD.phone,
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
      'contact_type', OLD.contact_type,
      'status', OLD.status,
      'notes', OLD.notes,
      'last_contacted', OLD.last_contacted,
      'tags', OLD.tags
    )
  );

  -- Process API Webhooks first
  FOR api_webhook_record IN
    SELECT *
    FROM api_webhooks
    WHERE trigger_event = 'CONTACT_UPDATED'
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

    -- Check if this is a CONTACT_UPDATED trigger
    IF trigger_node->>'type' = 'trigger'
       AND trigger_node->'properties'->>'event_name' = 'CONTACT_UPDATED' THEN

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
        'CONTACT_UPDATED',
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
          'trigger_type', 'CONTACT_UPDATED'
        )::text
      );
    END IF;
  END LOOP;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create function to trigger workflows when a contact is deleted
CREATE OR REPLACE FUNCTION trigger_workflows_on_contact_delete()
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
    'trigger_event', 'CONTACT_DELETED',
    'id', OLD.id,
    'contact_id', OLD.contact_id,
    'full_name', OLD.full_name,
    'email', OLD.email,
    'phone', OLD.phone,
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
    'contact_type', OLD.contact_type,
    'status', OLD.status,
    'notes', OLD.notes,
    'last_contacted', OLD.last_contacted,
    'tags', OLD.tags,
    'created_at', OLD.created_at,
    'updated_at', OLD.updated_at,
    'deleted_at', now()
  );

  -- Process API Webhooks first
  FOR api_webhook_record IN
    SELECT *
    FROM api_webhooks
    WHERE trigger_event = 'CONTACT_DELETED'
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

    -- Check if this is a CONTACT_DELETED trigger
    IF trigger_node->>'type' = 'trigger'
       AND trigger_node->'properties'->>'event_name' = 'CONTACT_DELETED' THEN

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
        'CONTACT_DELETED',
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
          'trigger_type', 'CONTACT_DELETED'
        )::text
      );
    END IF;
  END LOOP;

  RETURN OLD;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create trigger on contacts_master table for inserts
DROP TRIGGER IF EXISTS trigger_workflows_on_contact_add ON contacts_master;
CREATE TRIGGER trigger_workflows_on_contact_add
  AFTER INSERT ON contacts_master
  FOR EACH ROW
  EXECUTE FUNCTION trigger_workflows_on_contact_add();

-- Create trigger on contacts_master table for updates
DROP TRIGGER IF EXISTS trigger_workflows_on_contact_update ON contacts_master;
CREATE TRIGGER trigger_workflows_on_contact_update
  AFTER UPDATE ON contacts_master
  FOR EACH ROW
  EXECUTE FUNCTION trigger_workflows_on_contact_update();

-- Create trigger on contacts_master table for deletes
DROP TRIGGER IF EXISTS trigger_workflows_on_contact_delete ON contacts_master;
CREATE TRIGGER trigger_workflows_on_contact_delete
  AFTER DELETE ON contacts_master
  FOR EACH ROW
  EXECUTE FUNCTION trigger_workflows_on_contact_delete();

-- Add comments
COMMENT ON FUNCTION trigger_workflows_on_contact_add() IS 'Triggers both API webhooks and workflow automations when a new contact is added. Includes trigger_event in payload.';
COMMENT ON FUNCTION trigger_workflows_on_contact_update() IS 'Triggers both API webhooks and workflow automations when a contact is updated. Includes trigger_event in payload with previous values.';
COMMENT ON FUNCTION trigger_workflows_on_contact_delete() IS 'Triggers both API webhooks and workflow automations when a contact is deleted. Includes trigger_event in payload with deleted_at timestamp.';
