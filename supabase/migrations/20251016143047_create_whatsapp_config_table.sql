/*
  # Create WhatsApp Business API Configuration Table

  1. New Tables
    - `whatsapp_config`
      - `id` (uuid, primary key) - Unique identifier
      - `business_name` (text) - Business name for WhatsApp
      - `api_key` (text) - Doubletick API key (encrypted/sensitive)
      - `waba_number` (text) - WhatsApp Business Account phone number
      - `status` (text) - Connection status (Connected, Disconnected, Pending, Error)
      - `last_sync` (timestamptz) - Last synchronization timestamp
      - `created_at` (timestamptz) - Record creation timestamp
      - `updated_at` (timestamptz) - Record update timestamp
  
  2. Security
    - Enable RLS on `whatsapp_config` table
    - Add policy for authenticated admin users to read configuration
    - Add policy for authenticated admin users to update configuration
    - Add policy for authenticated admin users to insert configuration
  
  3. Important Notes
    - Only one configuration record should exist (enforced by application logic)
    - The table stores sensitive API keys, ensure proper access control
    - Default status is 'Disconnected' for new records
*/

CREATE TABLE IF NOT EXISTS whatsapp_config (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_name text DEFAULT '',
  api_key text DEFAULT '',
  waba_number text DEFAULT '',
  status text DEFAULT 'Disconnected',
  last_sync timestamptz,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

ALTER TABLE whatsapp_config ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Admin users can view WhatsApp config"
  ON whatsapp_config
  FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM admin_users
      WHERE admin_users.id = auth.uid()
    )
  );

CREATE POLICY "Admin users can insert WhatsApp config"
  ON whatsapp_config
  FOR INSERT
  TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM admin_users
      WHERE admin_users.id = auth.uid()
    )
  );

CREATE POLICY "Admin users can update WhatsApp config"
  ON whatsapp_config
  FOR UPDATE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM admin_users
      WHERE admin_users.id = auth.uid()
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM admin_users
      WHERE admin_users.id = auth.uid()
    )
  );

CREATE POLICY "Admin users can delete WhatsApp config"
  ON whatsapp_config
  FOR DELETE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM admin_users
      WHERE admin_users.id = auth.uid()
    )
  );

CREATE OR REPLACE FUNCTION update_whatsapp_config_timestamp()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER whatsapp_config_updated_at
  BEFORE UPDATE ON whatsapp_config
  FOR EACH ROW
  EXECUTE FUNCTION update_whatsapp_config_timestamp();