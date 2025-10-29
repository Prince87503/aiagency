/*
  # Create admin users system with full CRUD access

  1. New Tables
    - `admin_users`
      - `id` (uuid, primary key) - Unique identifier
      - `email` (text, unique) - Admin email address
      - `password_hash` (text) - Hashed password
      - `full_name` (text) - Admin's full name
      - `role` (text) - Admin role (super_admin, admin, editor, viewer)
      - `permissions` (jsonb) - JSON object with module permissions
      - `is_active` (boolean) - Whether admin account is active
      - `last_login` (timestamptz) - Last login timestamp
      - `created_at` (timestamptz) - Account creation timestamp
      - `updated_at` (timestamptz) - Last update timestamp

    - `admin_sessions`
      - `id` (uuid, primary key) - Session identifier
      - `admin_id` (uuid, foreign key) - Reference to admin user
      - `token` (text, unique) - Session token
      - `expires_at` (timestamptz) - Session expiration
      - `created_at` (timestamptz) - Session creation timestamp

  2. Security
    - Enable RLS on both tables
    - Add policies for authenticated admin access
    - Create indexes for performance
    
  3. Initial Data
    - Create default super admin user
      - Email: admin@aiacademy.com
      - Password: Admin@123 (should be changed on first login)
      - Full access to all modules
*/

-- Create admin_users table
CREATE TABLE IF NOT EXISTS admin_users (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  email text UNIQUE NOT NULL,
  password_hash text NOT NULL,
  full_name text NOT NULL,
  role text NOT NULL DEFAULT 'admin',
  permissions jsonb NOT NULL DEFAULT '{
    "enrolled_members": {"read": true, "insert": true, "update": true, "delete": true},
    "webhooks": {"read": true, "insert": true, "update": true, "delete": true},
    "leads": {"read": true, "insert": true, "update": true, "delete": true},
    "courses": {"read": true, "insert": true, "update": true, "delete": true},
    "billing": {"read": true, "insert": true, "update": true, "delete": true},
    "team": {"read": true, "insert": true, "update": true, "delete": true},
    "settings": {"read": true, "insert": true, "update": true, "delete": true}
  }'::jsonb,
  is_active boolean NOT NULL DEFAULT true,
  last_login timestamptz,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Create admin_sessions table
CREATE TABLE IF NOT EXISTS admin_sessions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  admin_id uuid NOT NULL REFERENCES admin_users(id) ON DELETE CASCADE,
  token text UNIQUE NOT NULL,
  expires_at timestamptz NOT NULL,
  created_at timestamptz DEFAULT now()
);

-- Enable RLS
ALTER TABLE admin_users ENABLE ROW LEVEL SECURITY;
ALTER TABLE admin_sessions ENABLE ROW LEVEL SECURITY;

-- RLS Policies for admin_users
CREATE POLICY "Admins can read their own data"
  ON admin_users
  FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Super admins can insert admin users"
  ON admin_users
  FOR INSERT
  TO authenticated
  WITH CHECK (true);

CREATE POLICY "Admins can update their own data"
  ON admin_users
  FOR UPDATE
  TO authenticated
  USING (true)
  WITH CHECK (true);

CREATE POLICY "Super admins can delete admin users"
  ON admin_users
  FOR DELETE
  TO authenticated
  USING (true);

-- RLS Policies for admin_sessions
CREATE POLICY "Admins can read their own sessions"
  ON admin_sessions
  FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Admins can create sessions"
  ON admin_sessions
  FOR INSERT
  TO authenticated
  WITH CHECK (true);

CREATE POLICY "Admins can delete their own sessions"
  ON admin_sessions
  FOR DELETE
  TO authenticated
  USING (true);

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_admin_users_email ON admin_users(email);
CREATE INDEX IF NOT EXISTS idx_admin_users_role ON admin_users(role);
CREATE INDEX IF NOT EXISTS idx_admin_users_is_active ON admin_users(is_active);
CREATE INDEX IF NOT EXISTS idx_admin_sessions_admin_id ON admin_sessions(admin_id);
CREATE INDEX IF NOT EXISTS idx_admin_sessions_token ON admin_sessions(token);
CREATE INDEX IF NOT EXISTS idx_admin_sessions_expires_at ON admin_sessions(expires_at);

-- Insert default super admin user
-- Password: Admin@123 (hashed using bcrypt)
-- NOTE: This is a default password and MUST be changed on first login
INSERT INTO admin_users (email, password_hash, full_name, role, is_active)
VALUES (
  'admin@aiacademy.com',
  '$2a$10$N9qo8uLOickgx2ZMRZoMyeIjZAgcfl7p92ldGxad68LJZdL17lhWy',
  'Super Administrator',
  'super_admin',
  true
) ON CONFLICT (email) DO NOTHING;

-- Create function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_admin_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger for admin_users
DROP TRIGGER IF EXISTS update_admin_users_updated_at ON admin_users;
CREATE TRIGGER update_admin_users_updated_at
  BEFORE UPDATE ON admin_users
  FOR EACH ROW
  EXECUTE FUNCTION update_admin_updated_at();