/*
  # Create Appearance Settings Table

  1. New Tables
    - `appearance_settings`
      - `id` (uuid, primary key)
      - `user_id` (uuid, nullable - null means system default)
      - `primary_color` (text) - Color for Primary/Total metrics
      - `success_color` (text) - Color for Success/Revenue/Active metrics
      - `warning_color` (text) - Color for Warning/Pending metrics
      - `secondary_color` (text) - Color for Secondary/Category metrics
      - `created_at` (timestamp)
      - `updated_at` (timestamp)

  2. Security
    - Enable RLS on `appearance_settings` table
    - Add policies for authenticated users to manage their settings
    - Add policy for anonymous users to read system defaults
*/

CREATE TABLE IF NOT EXISTS appearance_settings (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid REFERENCES auth.users(id) ON DELETE CASCADE,
  primary_color text NOT NULL DEFAULT 'blue',
  success_color text NOT NULL DEFAULT 'green',
  warning_color text NOT NULL DEFAULT 'orange',
  secondary_color text NOT NULL DEFAULT 'purple',
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now(),
  UNIQUE(user_id)
);

ALTER TABLE appearance_settings ENABLE ROW LEVEL SECURITY;

-- Allow authenticated users to read their own settings
CREATE POLICY "Users can read own appearance settings"
  ON appearance_settings
  FOR SELECT
  TO authenticated
  USING (auth.uid() = user_id);

-- Allow authenticated users to insert their own settings
CREATE POLICY "Users can insert own appearance settings"
  ON appearance_settings
  FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = user_id);

-- Allow authenticated users to update their own settings
CREATE POLICY "Users can update own appearance settings"
  ON appearance_settings
  FOR UPDATE
  TO authenticated
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- Allow everyone to read system default settings (user_id is null)
CREATE POLICY "Anyone can read system default appearance settings"
  ON appearance_settings
  FOR SELECT
  TO public
  USING (user_id IS NULL);

-- Insert system default settings
INSERT INTO appearance_settings (user_id, primary_color, success_color, warning_color, secondary_color)
VALUES (NULL, 'blue', 'green', 'orange', 'purple')
ON CONFLICT (user_id) DO NOTHING;