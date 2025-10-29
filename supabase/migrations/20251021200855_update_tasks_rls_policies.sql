/*
  # Update Tasks RLS Policies
  
  1. Changes
    - Drop existing restrictive policies
    - Add new policies that allow any authenticated admin user
    - Policies now check if user exists in admin_users table with is_active = true
    
  2. Security
    - All authenticated users in admin_users table can manage tasks
    - Only active admin users can access tasks
*/

-- Drop existing policies
DROP POLICY IF EXISTS "Admin users can view all tasks" ON tasks;
DROP POLICY IF EXISTS "Admin users can create tasks" ON tasks;
DROP POLICY IF EXISTS "Admin users can update tasks" ON tasks;
DROP POLICY IF EXISTS "Admin users can delete tasks" ON tasks;

-- Policy: Authenticated admin users can view all tasks
CREATE POLICY "Authenticated admin users can view all tasks"
  ON tasks
  FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM admin_users
      WHERE admin_users.id = auth.uid()
      AND admin_users.is_active = true
    )
  );

-- Policy: Authenticated admin users can create tasks
CREATE POLICY "Authenticated admin users can create tasks"
  ON tasks
  FOR INSERT
  TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM admin_users
      WHERE admin_users.id = auth.uid()
      AND admin_users.is_active = true
    )
  );

-- Policy: Authenticated admin users can update tasks
CREATE POLICY "Authenticated admin users can update tasks"
  ON tasks
  FOR UPDATE
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

-- Policy: Authenticated admin users can delete tasks
CREATE POLICY "Authenticated admin users can delete tasks"
  ON tasks
  FOR DELETE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM admin_users
      WHERE admin_users.id = auth.uid()
      AND admin_users.is_active = true
    )
  );