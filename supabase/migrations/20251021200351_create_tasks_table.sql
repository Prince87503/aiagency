/*
  # Create Tasks Management Table

  1. New Tables
    - `tasks`
      - `id` (uuid, primary key)
      - `task_id` (text, unique, auto-generated)
      - `title` (text, required)
      - `description` (text)
      - `status` (text) - Options: To Do, In Progress, In Review, Completed, Cancelled
      - `priority` (text) - Options: Low, Medium, High, Urgent
      - `assigned_to` (uuid, foreign key to admin_users)
      - `assigned_to_name` (text)
      - `assigned_by` (uuid, foreign key to admin_users)
      - `assigned_by_name` (text)
      - `due_date` (date)
      - `start_date` (date)
      - `completion_date` (timestamptz)
      - `estimated_hours` (numeric)
      - `actual_hours` (numeric)
      - `category` (text) - Development, Design, Marketing, Sales, Support, Operations, Other
      - `tags` (text array)
      - `attachments` (jsonb)
      - `progress_percentage` (integer, 0-100)
      - `notes` (text)
      - `created_at` (timestamptz)
      - `updated_at` (timestamptz)

  2. Security
    - Enable RLS on `tasks` table
    - Add policies for authenticated admin users to manage tasks
    - Add policy for users to view tasks assigned to them
*/

-- Create tasks table
CREATE TABLE IF NOT EXISTS tasks (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  task_id text UNIQUE NOT NULL DEFAULT 'TASK-' || LPAD(FLOOR(RANDOM() * 999999)::text, 6, '0'),
  title text NOT NULL,
  description text,
  status text NOT NULL DEFAULT 'To Do',
  priority text NOT NULL DEFAULT 'Medium',
  assigned_to uuid REFERENCES admin_users(id) ON DELETE SET NULL,
  assigned_to_name text,
  assigned_by uuid REFERENCES admin_users(id) ON DELETE SET NULL,
  assigned_by_name text,
  due_date date,
  start_date date,
  completion_date timestamptz,
  estimated_hours numeric(5,2),
  actual_hours numeric(5,2),
  category text DEFAULT 'Other',
  tags text[] DEFAULT '{}',
  attachments jsonb DEFAULT '[]',
  progress_percentage integer DEFAULT 0 CHECK (progress_percentage >= 0 AND progress_percentage <= 100),
  notes text,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Enable RLS
ALTER TABLE tasks ENABLE ROW LEVEL SECURITY;

-- Policy: Admin users can view all tasks
CREATE POLICY "Admin users can view all tasks"
  ON tasks
  FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM admin_users
      WHERE admin_users.id = auth.uid()
      AND admin_users.role IN ('Owner', 'Admin', 'Manager', 'Team Member')
    )
  );

-- Policy: Admin users can create tasks
CREATE POLICY "Admin users can create tasks"
  ON tasks
  FOR INSERT
  TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM admin_users
      WHERE admin_users.id = auth.uid()
      AND admin_users.role IN ('Owner', 'Admin', 'Manager', 'Team Member')
    )
  );

-- Policy: Admin users can update tasks
CREATE POLICY "Admin users can update tasks"
  ON tasks
  FOR UPDATE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM admin_users
      WHERE admin_users.id = auth.uid()
      AND admin_users.role IN ('Owner', 'Admin', 'Manager', 'Team Member')
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM admin_users
      WHERE admin_users.id = auth.uid()
      AND admin_users.role IN ('Owner', 'Admin', 'Manager', 'Team Member')
    )
  );

-- Policy: Admin users can delete tasks
CREATE POLICY "Admin users can delete tasks"
  ON tasks
  FOR DELETE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM admin_users
      WHERE admin_users.id = auth.uid()
      AND admin_users.role IN ('Owner', 'Admin', 'Manager')
    )
  );

-- Create index for faster queries
CREATE INDEX IF NOT EXISTS idx_tasks_assigned_to ON tasks(assigned_to);
CREATE INDEX IF NOT EXISTS idx_tasks_status ON tasks(status);
CREATE INDEX IF NOT EXISTS idx_tasks_priority ON tasks(priority);
CREATE INDEX IF NOT EXISTS idx_tasks_due_date ON tasks(due_date);
CREATE INDEX IF NOT EXISTS idx_tasks_created_at ON tasks(created_at DESC);

-- Create function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_tasks_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger to automatically update updated_at
CREATE TRIGGER tasks_updated_at
  BEFORE UPDATE ON tasks
  FOR EACH ROW
  EXECUTE FUNCTION update_tasks_updated_at();