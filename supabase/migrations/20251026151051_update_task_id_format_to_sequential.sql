/*
  # Update Task ID Format to Sequential Series

  1. Changes
    - Creates a sequence for task IDs starting from 10001
    - Updates all existing tasks to use the new sequential format (TASK-10001, TASK-10002, etc.)
    - Updates the default value generator to use the sequence
    - Creates a trigger to auto-generate task_id for new tasks
    
  2. Purpose
    - Provides cleaner, more professional task IDs
    - Ensures sequential numbering without gaps
    - Maintains uniqueness across all tasks
*/

-- Create sequence for task IDs starting from 10001
CREATE SEQUENCE IF NOT EXISTS task_id_seq START WITH 10001;

-- Update existing tasks with new sequential IDs ordered by created_at
DO $$
DECLARE
  task_record RECORD;
  counter INTEGER := 10001;
BEGIN
  FOR task_record IN 
    SELECT id FROM tasks ORDER BY created_at ASC
  LOOP
    UPDATE tasks 
    SET task_id = 'TASK-' || counter 
    WHERE id = task_record.id;
    counter := counter + 1;
  END LOOP;
  
  -- Set the sequence to the next value
  PERFORM setval('task_id_seq', counter);
END $$;

-- Drop the old default constraint
ALTER TABLE tasks ALTER COLUMN task_id DROP DEFAULT;

-- Create function to generate task_id using sequence
CREATE OR REPLACE FUNCTION generate_task_id()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.task_id IS NULL OR NEW.task_id = '' THEN
    NEW.task_id := 'TASK-' || nextval('task_id_seq');
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Drop existing trigger if it exists
DROP TRIGGER IF EXISTS trigger_generate_task_id ON tasks;

-- Create trigger to auto-generate task_id
CREATE TRIGGER trigger_generate_task_id
  BEFORE INSERT ON tasks
  FOR EACH ROW
  EXECUTE FUNCTION generate_task_id();
