/*
  # Create Integrations Configuration Table

  1. New Tables
    - `integrations`
      - `id` (uuid, primary key)
      - `integration_type` (text) - Type of integration (whatsapp, ghl_api, etc.)
      - `name` (text) - Display name
      - `description` (text) - Integration description
      - `icon` (text) - Emoji or icon identifier
      - `status` (text) - Connected/Disconnected
      - `config` (jsonb) - Configuration data (API keys, tokens, etc.)
      - `last_sync` (timestamptz) - Last synchronization time
      - `created_at` (timestamptz)
      - `updated_at` (timestamptz)

  2. Security
    - Enable RLS on `integrations` table
    - Add policies for anonymous access (read/write)
*/

CREATE TABLE IF NOT EXISTS integrations (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  integration_type text NOT NULL,
  name text NOT NULL,
  description text,
  icon text,
  status text DEFAULT 'Disconnected',
  config jsonb DEFAULT '{}'::jsonb,
  last_sync timestamptz,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

ALTER TABLE integrations ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Allow anonymous read access to integrations"
  ON integrations
  FOR SELECT
  TO anon
  USING (true);

CREATE POLICY "Allow anonymous insert access to integrations"
  ON integrations
  FOR INSERT
  TO anon
  WITH CHECK (true);

CREATE POLICY "Allow anonymous update access to integrations"
  ON integrations
  FOR UPDATE
  TO anon
  USING (true)
  WITH CHECK (true);

CREATE POLICY "Allow anonymous delete access to integrations"
  ON integrations
  FOR DELETE
  TO anon
  USING (true);

CREATE INDEX IF NOT EXISTS idx_integrations_type ON integrations(integration_type);
CREATE INDEX IF NOT EXISTS idx_integrations_status ON integrations(status);

CREATE OR REPLACE FUNCTION update_integrations_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_integrations_updated_at
  BEFORE UPDATE ON integrations
  FOR EACH ROW
  EXECUTE FUNCTION update_integrations_updated_at();

INSERT INTO integrations (integration_type, name, description, icon, status, config)
VALUES 
  ('whatsapp', 'WhatsApp Business API', 'Connect WhatsApp for automated messaging', '💬', 'Disconnected', '{"businessName":"","apiKey":"","wabaNumber":""}'::jsonb),
  ('ghl_api', 'GHL API', 'Connect GoHighLevel CRM for lead management', '🔗', 'Disconnected', '{"businessName":"","accessToken":""}'::jsonb)
ON CONFLICT DO NOTHING;
