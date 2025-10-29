/*
  # Create webhooks table

  1. New Tables
    - `webhooks`
      - `id` (uuid, primary key) - Unique identifier for the webhook
      - `name` (text) - Name of the webhook
      - `module` (text) - Module associated with the webhook (e.g., Members, Leads)
      - `trigger` (text) - Action that triggers the webhook
      - `url` (text) - Webhook URL endpoint
      - `payload_fields` (jsonb) - JSON object containing payload field definitions
      - `created_at` (timestamptz) - Timestamp when webhook was created
      - `updated_at` (timestamptz) - Timestamp when webhook was last updated

  2. Security
    - Enable RLS on `webhooks` table
    - Add policy for authenticated users to read webhooks
    - Add policy for authenticated users to insert webhooks
    - Add policy for authenticated users to update webhooks
    - Add policy for authenticated users to delete webhooks
*/

CREATE TABLE IF NOT EXISTS webhooks (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text NOT NULL,
  module text NOT NULL,
  trigger text NOT NULL,
  url text NOT NULL,
  payload_fields jsonb NOT NULL DEFAULT '{}'::jsonb,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

ALTER TABLE webhooks ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Authenticated users can read webhooks"
  ON webhooks
  FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Authenticated users can insert webhooks"
  ON webhooks
  FOR INSERT
  TO authenticated
  WITH CHECK (true);

CREATE POLICY "Authenticated users can update webhooks"
  ON webhooks
  FOR UPDATE
  TO authenticated
  USING (true)
  WITH CHECK (true);

CREATE POLICY "Authenticated users can delete webhooks"
  ON webhooks
  FOR DELETE
  TO authenticated
  USING (true);

-- Create index on module for faster filtering
CREATE INDEX IF NOT EXISTS idx_webhooks_module ON webhooks(module);

-- Create index on created_at for sorting
CREATE INDEX IF NOT EXISTS idx_webhooks_created_at ON webhooks(created_at DESC);