/*
  # Create API Webhooks Table

  1. New Tables
    - `api_webhooks` - Stores API webhook configurations
      - `id` (uuid, primary key) - Unique identifier
      - `name` (text) - Webhook name for identification
      - `trigger_event` (text) - Trigger event (e.g., NEW_LEAD_ADDED, NEW_MEMBER_ENROLLED)
      - `webhook_url` (text) - URL to send POST request to
      - `is_active` (boolean) - Whether webhook is active
      - `description` (text) - Optional description
      - `last_triggered` (timestamptz) - Last time webhook was triggered
      - `total_calls` (integer) - Total number of calls made
      - `success_count` (integer) - Number of successful calls
      - `failure_count` (integer) - Number of failed calls
      - `created_at` (timestamptz) - Creation timestamp
      - `updated_at` (timestamptz) - Update timestamp

  2. Security
    - Enable RLS on `api_webhooks` table
    - Add policies for authenticated users to manage webhooks

  3. Important Notes
    - Each webhook will send all trigger data to the configured URL
    - Simple POST request with JSON payload
    - No custom field mapping - all data is sent automatically
    - Multiple webhooks can be configured for the same trigger event
*/

-- Create api_webhooks table
CREATE TABLE IF NOT EXISTS api_webhooks (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text NOT NULL,
  trigger_event text NOT NULL,
  webhook_url text NOT NULL,
  is_active boolean DEFAULT true,
  description text DEFAULT '',
  last_triggered timestamptz,
  total_calls integer DEFAULT 0,
  success_count integer DEFAULT 0,
  failure_count integer DEFAULT 0,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_api_webhooks_trigger_event ON api_webhooks(trigger_event);
CREATE INDEX IF NOT EXISTS idx_api_webhooks_is_active ON api_webhooks(is_active);
CREATE INDEX IF NOT EXISTS idx_api_webhooks_created_at ON api_webhooks(created_at DESC);

-- Enable RLS
ALTER TABLE api_webhooks ENABLE ROW LEVEL SECURITY;

-- Create policies for anon and authenticated users
CREATE POLICY "Allow anon to read api webhooks"
  ON api_webhooks
  FOR SELECT
  TO anon
  USING (true);

CREATE POLICY "Allow authenticated to read api webhooks"
  ON api_webhooks
  FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Allow authenticated to insert api webhooks"
  ON api_webhooks
  FOR INSERT
  TO authenticated
  WITH CHECK (true);

CREATE POLICY "Allow authenticated to update api webhooks"
  ON api_webhooks
  FOR UPDATE
  TO authenticated
  USING (true)
  WITH CHECK (true);

CREATE POLICY "Allow authenticated to delete api webhooks"
  ON api_webhooks
  FOR DELETE
  TO authenticated
  USING (true);

-- Create trigger to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_api_webhooks_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_api_webhooks_updated_at_trigger
  BEFORE UPDATE ON api_webhooks
  FOR EACH ROW
  EXECUTE FUNCTION update_api_webhooks_updated_at();

-- Add comments
COMMENT ON TABLE api_webhooks IS 'Stores API webhook configurations for sending trigger data to external URLs';
COMMENT ON COLUMN api_webhooks.trigger_event IS 'Event that triggers this webhook (e.g., NEW_LEAD_ADDED)';