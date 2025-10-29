/*
  # Create Task Reminders Table

  1. New Tables
    - `task_reminders`
      - `id` (uuid, primary key)
      - `task_id` (uuid, foreign key to tasks)
      - `reminder_type` (text, enum: 'start_date', 'due_date', 'custom')
      - `custom_datetime` (timestamptz, nullable, for custom datetime)
      - `offset_timing` (text, enum: 'before', 'after')
      - `offset_value` (integer, the number of units)
      - `offset_unit` (text, enum: 'minutes', 'hours', 'days')
      - `calculated_reminder_time` (timestamptz, the actual computed reminder time)
      - `is_sent` (boolean, default false)
      - `sent_at` (timestamptz, nullable)
      - `created_at` (timestamptz)
      - `updated_at` (timestamptz)

  2. Security
    - Enable RLS on `task_reminders` table
    - Add policy for anon users to read all reminders
    - Add policy for anon users to insert/update/delete reminders
    - Add policy for authenticated admin users to manage all reminders

  3. Indexes
    - Index on task_id for fast lookups by task
    - Index on calculated_reminder_time for scheduled reminder queries
    - Index on is_sent for filtering sent/pending reminders

  4. Triggers
    - Auto-update updated_at timestamp
    - Auto-calculate reminder time based on task dates and offset
*/

-- Create task_reminders table
CREATE TABLE IF NOT EXISTS task_reminders (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  task_id uuid NOT NULL REFERENCES tasks(id) ON DELETE CASCADE,
  reminder_type text NOT NULL CHECK (reminder_type IN ('start_date', 'due_date', 'custom')),
  custom_datetime timestamptz,
  offset_timing text NOT NULL CHECK (offset_timing IN ('before', 'after')),
  offset_value integer NOT NULL CHECK (offset_value >= 0),
  offset_unit text NOT NULL CHECK (offset_unit IN ('minutes', 'hours', 'days')),
  calculated_reminder_time timestamptz,
  is_sent boolean DEFAULT false,
  sent_at timestamptz,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now(),
  CONSTRAINT valid_custom_datetime CHECK (
    (reminder_type = 'custom' AND custom_datetime IS NOT NULL) OR
    (reminder_type != 'custom' AND custom_datetime IS NULL)
  )
);

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_task_reminders_task_id ON task_reminders(task_id);
CREATE INDEX IF NOT EXISTS idx_task_reminders_calculated_time ON task_reminders(calculated_reminder_time);
CREATE INDEX IF NOT EXISTS idx_task_reminders_is_sent ON task_reminders(is_sent);

-- Enable RLS
ALTER TABLE task_reminders ENABLE ROW LEVEL SECURITY;

-- RLS Policies for anon access
CREATE POLICY "Allow anon read access to task_reminders"
  ON task_reminders FOR SELECT
  TO anon
  USING (true);

CREATE POLICY "Allow anon insert access to task_reminders"
  ON task_reminders FOR INSERT
  TO anon
  WITH CHECK (true);

CREATE POLICY "Allow anon update access to task_reminders"
  ON task_reminders FOR UPDATE
  TO anon
  USING (true)
  WITH CHECK (true);

CREATE POLICY "Allow anon delete access to task_reminders"
  ON task_reminders FOR DELETE
  TO anon
  USING (true);

-- RLS Policies for authenticated admin users
CREATE POLICY "Admins can read all task_reminders"
  ON task_reminders FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM admin_users
      WHERE admin_users.id = auth.uid()
      AND admin_users.is_active = true
    )
  );

CREATE POLICY "Admins can insert task_reminders"
  ON task_reminders FOR INSERT
  TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM admin_users
      WHERE admin_users.id = auth.uid()
      AND admin_users.is_active = true
    )
  );

CREATE POLICY "Admins can update task_reminders"
  ON task_reminders FOR UPDATE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM admin_users
      WHERE admin_users.id = auth.uid()
      AND admin_users.is_active = true
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM admin_users
      WHERE admin_users.id = auth.uid()
      AND admin_users.is_active = true
    )
  );

CREATE POLICY "Admins can delete task_reminders"
  ON task_reminders FOR DELETE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM admin_users
      WHERE admin_users.id = auth.uid()
      AND admin_users.is_active = true
    )
  );

-- Function to calculate reminder time
CREATE OR REPLACE FUNCTION calculate_reminder_time()
RETURNS TRIGGER AS $$
DECLARE
  base_time timestamptz;
  interval_value interval;
BEGIN
  -- Determine base time based on reminder type
  IF NEW.reminder_type = 'custom' THEN
    base_time := NEW.custom_datetime;
  ELSIF NEW.reminder_type = 'start_date' THEN
    SELECT start_date INTO base_time FROM tasks WHERE id = NEW.task_id;
  ELSIF NEW.reminder_type = 'due_date' THEN
    SELECT due_date INTO base_time FROM tasks WHERE id = NEW.task_id;
  END IF;

  -- If base_time is NULL, set calculated_reminder_time to NULL
  IF base_time IS NULL THEN
    NEW.calculated_reminder_time := NULL;
    RETURN NEW;
  END IF;

  -- Calculate interval based on unit
  IF NEW.offset_unit = 'minutes' THEN
    interval_value := make_interval(mins => NEW.offset_value);
  ELSIF NEW.offset_unit = 'hours' THEN
    interval_value := make_interval(hours => NEW.offset_value);
  ELSIF NEW.offset_unit = 'days' THEN
    interval_value := make_interval(days => NEW.offset_value);
  END IF;

  -- Apply offset
  IF NEW.offset_timing = 'before' THEN
    NEW.calculated_reminder_time := base_time - interval_value;
  ELSE
    NEW.calculated_reminder_time := base_time + interval_value;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger to auto-calculate reminder time on insert/update
CREATE TRIGGER trigger_calculate_reminder_time
  BEFORE INSERT OR UPDATE ON task_reminders
  FOR EACH ROW
  EXECUTE FUNCTION calculate_reminder_time();

-- Trigger to update updated_at timestamp
CREATE TRIGGER trigger_update_task_reminders_updated_at
  BEFORE UPDATE ON task_reminders
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- Function to recalculate reminders when task dates change
CREATE OR REPLACE FUNCTION recalculate_task_reminders()
RETURNS TRIGGER AS $$
BEGIN
  -- Only recalculate if start_date or due_date changed
  IF (OLD.start_date IS DISTINCT FROM NEW.start_date) OR
     (OLD.due_date IS DISTINCT FROM NEW.due_date) THEN
    
    -- Update all non-custom reminders for this task
    UPDATE task_reminders
    SET updated_at = now()
    WHERE task_id = NEW.id
    AND reminder_type IN ('start_date', 'due_date')
    AND is_sent = false;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger on tasks table to recalculate reminders
CREATE TRIGGER trigger_recalculate_reminders_on_task_update
  AFTER UPDATE ON tasks
  FOR EACH ROW
  EXECUTE FUNCTION recalculate_task_reminders();