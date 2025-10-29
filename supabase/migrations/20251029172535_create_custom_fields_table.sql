/*
  # Create Custom Fields Table

  1. New Tables
    - `custom_fields`
      - `id` (uuid, primary key)
      - `field_key` (text, unique identifier for the field)
      - `custom_tab_id` (uuid, foreign key to custom_lead_tabs)
      - `field_name` (text, display name of the field)
      - `field_type` (text, type: text, dropdown_single, dropdown_multiple, date)
      - `dropdown_options` (jsonb, array of options for dropdown fields)
      - `is_required` (boolean, whether the field is required)
      - `display_order` (integer, order in which field appears)
      - `is_active` (boolean, whether the field is active)
      - `created_at` (timestamp)
      - `updated_at` (timestamp)

    - `custom_field_values`
      - `id` (uuid, primary key)
      - `custom_field_id` (uuid, foreign key to custom_fields)
      - `lead_id` (uuid, foreign key to leads)
      - `field_value` (text, the actual value entered)
      - `created_at` (timestamp)
      - `updated_at` (timestamp)

  2. Security
    - Enable RLS on both tables
    - Add policies for anon and authenticated users

  3. Constraints
    - Unique constraint on field_key
    - Check constraint for valid field types
*/

-- Create custom_fields table
CREATE TABLE IF NOT EXISTS custom_fields (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  field_key text UNIQUE NOT NULL,
  custom_tab_id uuid NOT NULL REFERENCES custom_lead_tabs(id) ON DELETE CASCADE,
  field_name text NOT NULL,
  field_type text NOT NULL CHECK (field_type IN ('text', 'dropdown_single', 'dropdown_multiple', 'date')),
  dropdown_options jsonb DEFAULT '[]'::jsonb,
  is_required boolean DEFAULT false,
  display_order integer NOT NULL DEFAULT 0,
  is_active boolean DEFAULT true,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Create custom_field_values table
CREATE TABLE IF NOT EXISTS custom_field_values (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  custom_field_id uuid NOT NULL REFERENCES custom_fields(id) ON DELETE CASCADE,
  lead_id uuid NOT NULL REFERENCES leads(id) ON DELETE CASCADE,
  field_value text,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now(),
  UNIQUE(custom_field_id, lead_id)
);

-- Enable RLS
ALTER TABLE custom_fields ENABLE ROW LEVEL SECURITY;
ALTER TABLE custom_field_values ENABLE ROW LEVEL SECURITY;

-- RLS Policies for custom_fields
CREATE POLICY "Allow anon to read custom fields"
  ON custom_fields
  FOR SELECT
  TO anon
  USING (true);

CREATE POLICY "Allow authenticated to read custom fields"
  ON custom_fields
  FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Allow anon to insert custom fields"
  ON custom_fields
  FOR INSERT
  TO anon
  WITH CHECK (true);

CREATE POLICY "Allow authenticated to insert custom fields"
  ON custom_fields
  FOR INSERT
  TO authenticated
  WITH CHECK (true);

CREATE POLICY "Allow anon to update custom fields"
  ON custom_fields
  FOR UPDATE
  TO anon
  USING (true)
  WITH CHECK (true);

CREATE POLICY "Allow authenticated to update custom fields"
  ON custom_fields
  FOR UPDATE
  TO authenticated
  USING (true)
  WITH CHECK (true);

CREATE POLICY "Allow anon to delete custom fields"
  ON custom_fields
  FOR DELETE
  TO anon
  USING (true);

CREATE POLICY "Allow authenticated to delete custom fields"
  ON custom_fields
  FOR DELETE
  TO authenticated
  USING (true);

-- RLS Policies for custom_field_values
CREATE POLICY "Allow anon to read custom field values"
  ON custom_field_values
  FOR SELECT
  TO anon
  USING (true);

CREATE POLICY "Allow authenticated to read custom field values"
  ON custom_field_values
  FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Allow anon to insert custom field values"
  ON custom_field_values
  FOR INSERT
  TO anon
  WITH CHECK (true);

CREATE POLICY "Allow authenticated to insert custom field values"
  ON custom_field_values
  FOR INSERT
  TO authenticated
  WITH CHECK (true);

CREATE POLICY "Allow anon to update custom field values"
  ON custom_field_values
  FOR UPDATE
  TO anon
  USING (true)
  WITH CHECK (true);

CREATE POLICY "Allow authenticated to update custom field values"
  ON custom_field_values
  FOR UPDATE
  TO authenticated
  USING (true)
  WITH CHECK (true);

CREATE POLICY "Allow anon to delete custom field values"
  ON custom_field_values
  FOR DELETE
  TO anon
  USING (true);

CREATE POLICY "Allow authenticated to delete custom field values"
  ON custom_field_values
  FOR DELETE
  TO authenticated
  USING (true);

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_custom_fields_tab ON custom_fields(custom_tab_id);
CREATE INDEX IF NOT EXISTS idx_custom_fields_active ON custom_fields(is_active);
CREATE INDEX IF NOT EXISTS idx_custom_field_values_field ON custom_field_values(custom_field_id);
CREATE INDEX IF NOT EXISTS idx_custom_field_values_lead ON custom_field_values(lead_id);