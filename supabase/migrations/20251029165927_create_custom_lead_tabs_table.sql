/*
  # Create Custom Lead Tabs Table

  1. New Tables
    - `custom_lead_tabs`
      - `id` (uuid, primary key)
      - `tab_id` (text, unique identifier for the tab)
      - `pipeline_id` (uuid, foreign key to pipelines)
      - `tab_name` (text, the display name of the tab)
      - `tab_order` (integer, display order 1-3)
      - `is_active` (boolean, whether the tab is active)
      - `created_at` (timestamp)
      - `updated_at` (timestamp)

  2. Security
    - Enable RLS on `custom_lead_tabs` table
    - Add policy for anonymous users to read active tabs
    - Add policy for authenticated users to manage tabs

  3. Constraints
    - Unique constraint on (pipeline_id, tab_order) to prevent duplicate orders
    - Check constraint to ensure tab_order is between 1 and 3
    - Limit of 3 tabs per pipeline enforced at application level
*/

CREATE TABLE IF NOT EXISTS custom_lead_tabs (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  tab_id text UNIQUE NOT NULL,
  pipeline_id uuid NOT NULL REFERENCES pipelines(id) ON DELETE CASCADE,
  tab_name text NOT NULL,
  tab_order integer NOT NULL CHECK (tab_order >= 1 AND tab_order <= 3),
  is_active boolean DEFAULT true,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now(),
  UNIQUE(pipeline_id, tab_order)
);

ALTER TABLE custom_lead_tabs ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Anyone can read active custom lead tabs"
  ON custom_lead_tabs
  FOR SELECT
  USING (is_active = true);

CREATE POLICY "Authenticated users can insert custom lead tabs"
  ON custom_lead_tabs
  FOR INSERT
  TO authenticated
  WITH CHECK (true);

CREATE POLICY "Authenticated users can update custom lead tabs"
  ON custom_lead_tabs
  FOR UPDATE
  TO authenticated
  USING (true)
  WITH CHECK (true);

CREATE POLICY "Authenticated users can delete custom lead tabs"
  ON custom_lead_tabs
  FOR DELETE
  TO authenticated
  USING (true);

CREATE INDEX IF NOT EXISTS idx_custom_lead_tabs_pipeline ON custom_lead_tabs(pipeline_id);
CREATE INDEX IF NOT EXISTS idx_custom_lead_tabs_active ON custom_lead_tabs(is_active);