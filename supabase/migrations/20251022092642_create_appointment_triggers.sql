/*
  # Create Appointment Triggers for Webhooks

  1. Overview
    - Creates database triggers for appointments table
    - Sends webhook notifications for create, update, and delete operations
    - Follows existing pattern used for leads, affiliates, and other tables

  2. Triggers Created
    - `trigger_appointment_created` - Fires when a new appointment is added
    - `trigger_appointment_updated` - Fires when an appointment is modified
    - `trigger_appointment_deleted` - Fires when an appointment is removed

  3. Webhook Integration
    - All triggers send data to `api_webhooks` table
    - Includes full appointment record in payload
    - Includes trigger event type for filtering

  4. Use Cases
    - Notify external systems when appointments are created
    - Sync appointment updates to third-party calendars
    - Track appointment lifecycle for reporting
    - Trigger automated reminders and notifications
*/

-- Function to handle appointment created event
CREATE OR REPLACE FUNCTION notify_appointment_created()
RETURNS TRIGGER AS $$
DECLARE
  webhook_record RECORD;
  payload jsonb;
BEGIN
  -- Build the payload with appointment data
  payload := jsonb_build_object(
    'trigger_event', 'APPOINTMENT_CREATED',
    'appointment_id', NEW.appointment_id,
    'id', NEW.id,
    'calendar_id', NEW.calendar_id,
    'contact_id', NEW.contact_id,
    'contact_name', NEW.contact_name,
    'contact_email', NEW.contact_email,
    'contact_phone', NEW.contact_phone,
    'title', NEW.title,
    'appointment_date', NEW.appointment_date,
    'appointment_time', NEW.appointment_time,
    'duration_minutes', NEW.duration_minutes,
    'status', NEW.status,
    'location', NEW.location,
    'meeting_type', NEW.meeting_type,
    'purpose', NEW.purpose,
    'notes', NEW.notes,
    'reminder_sent', NEW.reminder_sent,
    'assigned_to', NEW.assigned_to,
    'created_at', NEW.created_at,
    'updated_at', NEW.updated_at
  );

  -- Loop through all active webhooks for this trigger event
  FOR webhook_record IN
    SELECT id, webhook_url
    FROM api_webhooks
    WHERE trigger_event = 'APPOINTMENT_CREATED'
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

-- Function to handle appointment updated event
CREATE OR REPLACE FUNCTION notify_appointment_updated()
RETURNS TRIGGER AS $$
DECLARE
  webhook_record RECORD;
  payload jsonb;
BEGIN
  -- Build the payload with appointment data including previous values
  payload := jsonb_build_object(
    'trigger_event', 'APPOINTMENT_UPDATED',
    'appointment_id', NEW.appointment_id,
    'id', NEW.id,
    'calendar_id', NEW.calendar_id,
    'contact_id', NEW.contact_id,
    'contact_name', NEW.contact_name,
    'contact_email', NEW.contact_email,
    'contact_phone', NEW.contact_phone,
    'title', NEW.title,
    'appointment_date', NEW.appointment_date,
    'appointment_time', NEW.appointment_time,
    'duration_minutes', NEW.duration_minutes,
    'status', NEW.status,
    'location', NEW.location,
    'meeting_type', NEW.meeting_type,
    'purpose', NEW.purpose,
    'notes', NEW.notes,
    'reminder_sent', NEW.reminder_sent,
    'assigned_to', NEW.assigned_to,
    'created_at', NEW.created_at,
    'updated_at', NEW.updated_at,
    'previous_status', OLD.status,
    'previous_appointment_date', OLD.appointment_date,
    'previous_appointment_time', OLD.appointment_time
  );

  -- Loop through all active webhooks for this trigger event
  FOR webhook_record IN
    SELECT id, webhook_url
    FROM api_webhooks
    WHERE trigger_event = 'APPOINTMENT_UPDATED'
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

-- Function to handle appointment deleted event
CREATE OR REPLACE FUNCTION notify_appointment_deleted()
RETURNS TRIGGER AS $$
DECLARE
  webhook_record RECORD;
  payload jsonb;
BEGIN
  -- Build the payload with deleted appointment data
  payload := jsonb_build_object(
    'trigger_event', 'APPOINTMENT_DELETED',
    'appointment_id', OLD.appointment_id,
    'id', OLD.id,
    'calendar_id', OLD.calendar_id,
    'contact_id', OLD.contact_id,
    'contact_name', OLD.contact_name,
    'contact_email', OLD.contact_email,
    'contact_phone', OLD.contact_phone,
    'title', OLD.title,
    'appointment_date', OLD.appointment_date,
    'appointment_time', OLD.appointment_time,
    'duration_minutes', OLD.duration_minutes,
    'status', OLD.status,
    'location', OLD.location,
    'meeting_type', OLD.meeting_type,
    'purpose', OLD.purpose,
    'notes', OLD.notes,
    'deleted_at', NOW()
  );

  -- Loop through all active webhooks for this trigger event
  FOR webhook_record IN
    SELECT id, webhook_url
    FROM api_webhooks
    WHERE trigger_event = 'APPOINTMENT_DELETED'
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

-- Drop existing triggers if they exist
DROP TRIGGER IF EXISTS trigger_appointment_created ON appointments;
DROP TRIGGER IF EXISTS trigger_appointment_updated ON appointments;
DROP TRIGGER IF EXISTS trigger_appointment_deleted ON appointments;

-- Create trigger for appointment creation
CREATE TRIGGER trigger_appointment_created
  AFTER INSERT ON appointments
  FOR EACH ROW
  EXECUTE FUNCTION notify_appointment_created();

-- Create trigger for appointment update
CREATE TRIGGER trigger_appointment_updated
  AFTER UPDATE ON appointments
  FOR EACH ROW
  EXECUTE FUNCTION notify_appointment_updated();

-- Create trigger for appointment deletion
CREATE TRIGGER trigger_appointment_deleted
  AFTER DELETE ON appointments
  FOR EACH ROW
  EXECUTE FUNCTION notify_appointment_deleted();