/*
  # Create Task Reminder Scheduler Function

  1. Overview
    - Creates a function to check and trigger task reminders that are due
    - Sends reminder events to api_webhooks for processing
    - Marks reminders as sent after triggering
    - Can be called periodically by a cron job or scheduled task

  2. Components
    - Function: process_due_task_reminders()
    - Processes all unsent reminders where calculated_reminder_time <= NOW()
    - Sends webhook events to api_webhooks table
    - Updates reminder status to sent

  3. Usage
    - Can be called manually: SELECT process_due_task_reminders();
    - Should be scheduled to run every minute via external cron or pg_cron
*/

-- Function to process due task reminders
CREATE OR REPLACE FUNCTION process_due_task_reminders()
RETURNS TABLE (
  processed_count integer,
  reminder_ids uuid[]
) AS $$
DECLARE
  reminder_record RECORD;
  task_record RECORD;
  reminder_display_text text;
  processed_ids uuid[] := ARRAY[]::uuid[];
  count_processed integer := 0;
BEGIN
  -- Loop through all unsent reminders that are due
  FOR reminder_record IN
    SELECT * FROM task_reminders
    WHERE is_sent = false
    AND calculated_reminder_time IS NOT NULL
    AND calculated_reminder_time <= NOW()
    ORDER BY calculated_reminder_time ASC
  LOOP
    -- Get the task details
    SELECT * INTO task_record
    FROM tasks
    WHERE id = reminder_record.task_id;

    -- Skip if task not found or deleted
    IF task_record.id IS NULL THEN
      CONTINUE;
    END IF;

    -- Build reminder display text
    IF reminder_record.reminder_type = 'start_date' THEN
      reminder_display_text := reminder_record.offset_value::text || ' ' || 
                               reminder_record.offset_unit || ' ' || 
                               reminder_record.offset_timing || ' Start Date';
    ELSIF reminder_record.reminder_type = 'due_date' THEN
      reminder_display_text := reminder_record.offset_value::text || ' ' || 
                               reminder_record.offset_unit || ' ' || 
                               reminder_record.offset_timing || ' Due Date';
    ELSE
      reminder_display_text := reminder_record.offset_value::text || ' ' || 
                               reminder_record.offset_unit || ' ' || 
                               reminder_record.offset_timing || ' Custom Date';
    END IF;

    -- Insert webhook event to api_webhooks
    INSERT INTO api_webhooks (event_type, payload)
    VALUES (
      'TASK_REMINDER',
      jsonb_build_object(
        'trigger_event', 'TASK_REMINDER',
        'reminder_id', reminder_record.id,
        'task_id', task_record.id,
        'task_readable_id', task_record.task_id,
        'task_title', task_record.title,
        'task_description', task_record.description,
        'task_status', task_record.status,
        'task_priority', task_record.priority,
        'task_category', task_record.category,
        'assigned_to', task_record.assigned_to,
        'assigned_to_name', task_record.assigned_to_name,
        'assigned_by', task_record.assigned_by,
        'assigned_by_name', task_record.assigned_by_name,
        'contact_id', task_record.contact_id,
        'contact_name', task_record.contact_name,
        'contact_phone', task_record.contact_phone,
        'task_due_date', task_record.due_date,
        'task_start_date', task_record.start_date,
        'task_estimated_hours', task_record.estimated_hours,
        'task_progress_percentage', task_record.progress_percentage,
        'reminder_type', reminder_record.reminder_type,
        'reminder_custom_datetime', reminder_record.custom_datetime,
        'reminder_offset_timing', reminder_record.offset_timing,
        'reminder_offset_value', reminder_record.offset_value,
        'reminder_offset_unit', reminder_record.offset_unit,
        'reminder_scheduled_time', reminder_record.calculated_reminder_time,
        'reminder_display', reminder_display_text,
        'created_at', reminder_record.created_at
      )
    );

    -- Mark reminder as sent
    UPDATE task_reminders
    SET is_sent = true,
        sent_at = NOW()
    WHERE id = reminder_record.id;

    -- Add to processed list
    processed_ids := array_append(processed_ids, reminder_record.id);
    count_processed := count_processed + 1;
  END LOOP;

  -- Return results
  RETURN QUERY SELECT count_processed, processed_ids;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant execute permission to anon and authenticated users
GRANT EXECUTE ON FUNCTION process_due_task_reminders() TO anon;
GRANT EXECUTE ON FUNCTION process_due_task_reminders() TO authenticated;

-- Add comment
COMMENT ON FUNCTION process_due_task_reminders() IS 
'Processes all due task reminders and sends them to api_webhooks. Should be called periodically via cron.';