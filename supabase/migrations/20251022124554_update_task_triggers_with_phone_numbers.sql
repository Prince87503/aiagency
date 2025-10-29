/*
  # Update Task Triggers to Include Phone Numbers

  1. Overview
    - Updates task trigger functions to include phone numbers
    - Fetches assigned_by_phone from admin_users table for the user who created the task
    - Fetches assigned_to_phone from admin_users table for the assigned user
    - Maintains all existing functionality

  2. Changes
    - notify_task_created() - adds assigned_by_phone and assigned_to_phone
    - notify_task_updated() - adds assigned_by_phone and assigned_to_phone
    - notify_task_deleted() - adds assigned_by_phone and assigned_to_phone

  3. Purpose
    - Enable SMS/WhatsApp notifications to task creators and assignees
    - Provide complete contact information in webhook payloads
*/

-- Function to handle task created event (updated with phone numbers)
CREATE OR REPLACE FUNCTION notify_task_created()
RETURNS TRIGGER AS $$
DECLARE
  webhook_record RECORD;
  payload jsonb;
  v_assigned_by_phone text;
  v_assigned_to_phone text;
BEGIN
  -- Fetch phone numbers from admin_users table
  SELECT phone INTO v_assigned_by_phone
  FROM admin_users
  WHERE id = NEW.assigned_by;

  SELECT phone INTO v_assigned_to_phone
  FROM admin_users
  WHERE id = NEW.assigned_to;

  -- Build the payload with task data including phone numbers
  payload := jsonb_build_object(
    'trigger_event', 'TASK_CREATED',
    'task_id', NEW.task_id,
    'id', NEW.id,
    'title', NEW.title,
    'description', NEW.description,
    'status', NEW.status,
    'priority', NEW.priority,
    'assigned_to', NEW.assigned_to,
    'assigned_to_name', NEW.assigned_to_name,
    'assigned_to_phone', v_assigned_to_phone,
    'assigned_by', NEW.assigned_by,
    'assigned_by_name', NEW.assigned_by_name,
    'assigned_by_phone', v_assigned_by_phone,
    'contact_id', NEW.contact_id,
    'contact_name', NEW.contact_name,
    'contact_phone', NEW.contact_phone,
    'due_date', NEW.due_date,
    'start_date', NEW.start_date,
    'completion_date', NEW.completion_date,
    'estimated_hours', NEW.estimated_hours,
    'actual_hours', NEW.actual_hours,
    'category', NEW.category,
    'tags', NEW.tags,
    'attachments', NEW.attachments,
    'progress_percentage', NEW.progress_percentage,
    'notes', NEW.notes,
    'created_at', NEW.created_at,
    'updated_at', NEW.updated_at
  );

  -- Loop through all active webhooks for this trigger event
  FOR webhook_record IN
    SELECT id, webhook_url
    FROM api_webhooks
    WHERE trigger_event = 'TASK_CREATED'
    AND is_active = true
  LOOP
    -- Send HTTP POST request to webhook URL using pg_net extension
    PERFORM net.http_post(
      url := webhook_record.webhook_url,
      headers := '{"Content-Type": "application/json"}'::jsonb,
      body := payload
    );

    -- Update webhook statistics
    UPDATE api_webhooks
    SET
      last_triggered = NOW(),
      total_calls = COALESCE(total_calls, 0) + 1,
      success_count = COALESCE(success_count, 0) + 1
    WHERE id = webhook_record.id;
  END LOOP;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Function to handle task updated event (updated with phone numbers)
CREATE OR REPLACE FUNCTION notify_task_updated()
RETURNS TRIGGER AS $$
DECLARE
  webhook_record RECORD;
  payload jsonb;
  v_assigned_by_phone text;
  v_assigned_to_phone text;
BEGIN
  -- Fetch phone numbers from admin_users table
  SELECT phone INTO v_assigned_by_phone
  FROM admin_users
  WHERE id = NEW.assigned_by;

  SELECT phone INTO v_assigned_to_phone
  FROM admin_users
  WHERE id = NEW.assigned_to;

  -- Build the payload with task data including phone numbers and previous values
  payload := jsonb_build_object(
    'trigger_event', 'TASK_UPDATED',
    'task_id', NEW.task_id,
    'id', NEW.id,
    'title', NEW.title,
    'description', NEW.description,
    'status', NEW.status,
    'priority', NEW.priority,
    'assigned_to', NEW.assigned_to,
    'assigned_to_name', NEW.assigned_to_name,
    'assigned_to_phone', v_assigned_to_phone,
    'assigned_by', NEW.assigned_by,
    'assigned_by_name', NEW.assigned_by_name,
    'assigned_by_phone', v_assigned_by_phone,
    'contact_id', NEW.contact_id,
    'contact_name', NEW.contact_name,
    'contact_phone', NEW.contact_phone,
    'due_date', NEW.due_date,
    'start_date', NEW.start_date,
    'completion_date', NEW.completion_date,
    'estimated_hours', NEW.estimated_hours,
    'actual_hours', NEW.actual_hours,
    'category', NEW.category,
    'tags', NEW.tags,
    'attachments', NEW.attachments,
    'progress_percentage', NEW.progress_percentage,
    'notes', NEW.notes,
    'created_at', NEW.created_at,
    'updated_at', NEW.updated_at,
    'previous_status', OLD.status,
    'previous_priority', OLD.priority,
    'previous_assigned_to', OLD.assigned_to,
    'previous_due_date', OLD.due_date,
    'previous_progress_percentage', OLD.progress_percentage
  );

  -- Loop through all active webhooks for this trigger event
  FOR webhook_record IN
    SELECT id, webhook_url
    FROM api_webhooks
    WHERE trigger_event = 'TASK_UPDATED'
    AND is_active = true
  LOOP
    -- Send HTTP POST request to webhook URL
    PERFORM net.http_post(
      url := webhook_record.webhook_url,
      headers := '{"Content-Type": "application/json"}'::jsonb,
      body := payload
    );

    -- Update webhook statistics
    UPDATE api_webhooks
    SET
      last_triggered = NOW(),
      total_calls = COALESCE(total_calls, 0) + 1,
      success_count = COALESCE(success_count, 0) + 1
    WHERE id = webhook_record.id;
  END LOOP;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Function to handle task deleted event (updated with phone numbers)
CREATE OR REPLACE FUNCTION notify_task_deleted()
RETURNS TRIGGER AS $$
DECLARE
  webhook_record RECORD;
  payload jsonb;
  v_assigned_by_phone text;
  v_assigned_to_phone text;
BEGIN
  -- Fetch phone numbers from admin_users table
  SELECT phone INTO v_assigned_by_phone
  FROM admin_users
  WHERE id = OLD.assigned_by;

  SELECT phone INTO v_assigned_to_phone
  FROM admin_users
  WHERE id = OLD.assigned_to;

  -- Build the payload with deleted task data including phone numbers
  payload := jsonb_build_object(
    'trigger_event', 'TASK_DELETED',
    'task_id', OLD.task_id,
    'id', OLD.id,
    'title', OLD.title,
    'description', OLD.description,
    'status', OLD.status,
    'priority', OLD.priority,
    'assigned_to', OLD.assigned_to,
    'assigned_to_name', OLD.assigned_to_name,
    'assigned_to_phone', v_assigned_to_phone,
    'assigned_by', OLD.assigned_by,
    'assigned_by_name', OLD.assigned_by_name,
    'assigned_by_phone', v_assigned_by_phone,
    'contact_id', OLD.contact_id,
    'contact_name', OLD.contact_name,
    'contact_phone', OLD.contact_phone,
    'due_date', OLD.due_date,
    'start_date', OLD.start_date,
    'completion_date', OLD.completion_date,
    'estimated_hours', OLD.estimated_hours,
    'actual_hours', OLD.actual_hours,
    'category', OLD.category,
    'tags', OLD.tags,
    'progress_percentage', OLD.progress_percentage,
    'deleted_at', NOW()
  );

  -- Loop through all active webhooks for this trigger event
  FOR webhook_record IN
    SELECT id, webhook_url
    FROM api_webhooks
    WHERE trigger_event = 'TASK_DELETED'
    AND is_active = true
  LOOP
    -- Send HTTP POST request to webhook URL
    PERFORM net.http_post(
      url := webhook_record.webhook_url,
      headers := '{"Content-Type": "application/json"}'::jsonb,
      body := payload
    );

    -- Update webhook statistics
    UPDATE api_webhooks
    SET
      last_triggered = NOW(),
      total_calls = COALESCE(total_calls, 0) + 1,
      success_count = COALESCE(success_count, 0) + 1
    WHERE id = webhook_record.id;
  END LOOP;

  RETURN OLD;
END;
$$ LANGUAGE plpgsql;
