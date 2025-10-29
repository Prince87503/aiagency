/*
  # Update Tasks RLS for Anonymous Access
  
  1. Changes
    - Drop existing restrictive policies
    - Add new policies that allow anonymous users to manage tasks
    - Allow both authenticated admin users and anonymous users full access
    
  2. Security
    - Anonymous users can create, read, update, and delete tasks
    - Authenticated admin users retain full access
*/

-- Drop existing policies
DROP POLICY IF EXISTS "Authenticated admin users can view all tasks" ON tasks;
DROP POLICY IF EXISTS "Authenticated admin users can create tasks" ON tasks;
DROP POLICY IF EXISTS "Authenticated admin users can update tasks" ON tasks;
DROP POLICY IF EXISTS "Authenticated admin users can delete tasks" ON tasks;

-- Policy: Allow anonymous and authenticated users to view all tasks
CREATE POLICY "Allow all to view tasks"
  ON tasks
  FOR SELECT
  TO anon, authenticated
  USING (true);

-- Policy: Allow anonymous and authenticated users to create tasks
CREATE POLICY "Allow all to create tasks"
  ON tasks
  FOR INSERT
  TO anon, authenticated
  WITH CHECK (true);

-- Policy: Allow anonymous and authenticated users to update tasks
CREATE POLICY "Allow all to update tasks"
  ON tasks
  FOR UPDATE
  TO anon, authenticated
  USING (true)
  WITH CHECK (true);

-- Policy: Allow anonymous and authenticated users to delete tasks
CREATE POLICY "Allow all to delete tasks"
  ON tasks
  FOR DELETE
  TO anon, authenticated
  USING (true);