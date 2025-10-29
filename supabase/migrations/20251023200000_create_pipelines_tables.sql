/*
  # Create Pipelines and Pipeline Stages Tables

  1. New Tables
    - `pipelines`
      - `id` (uuid, primary key) - Unique identifier for each pipeline
      - `pipeline_id` (text, unique) - Human-readable pipeline ID (e.g., P001)
      - `name` (text) - Pipeline name (e.g., "Sales Pipeline", "Recruitment Pipeline")
      - `description` (text) - Optional description of the pipeline
      - `entity_type` (text) - Type of entity this pipeline is for (e.g., "lead", "candidate", "project")
      - `is_default` (boolean) - Whether this is the default pipeline for this entity type
      - `is_active` (boolean) - Whether this pipeline is currently active
      - `display_order` (integer) - Order in which pipelines are displayed
      - `created_at` (timestamptz) - When the pipeline was created
      - `updated_at` (timestamptz) - When the pipeline was last updated

    - `pipeline_stages`
      - `id` (uuid, primary key) - Unique identifier for each stage
      - `pipeline_id` (uuid, foreign key) - Reference to parent pipeline
      - `stage_id` (text) - Human-readable stage ID within the pipeline
      - `name` (text) - Stage name (e.g., "New", "Contacted", "Demo Booked")
      - `description` (text) - Optional description of the stage
      - `color` (text) - Color for the stage card (e.g., "bg-blue-100", "#3B82F6")
      - `display_order` (integer) - Order in which stages appear in the pipeline
      - `is_active` (boolean) - Whether this stage is currently active
      - `created_at` (timestamptz) - When the stage was created
      - `updated_at` (timestamptz) - When the stage was last updated

  2. Security
    - Enable RLS on both tables
    - Add policies for anon and authenticated users to read, insert, update, and delete records

  3. Indexes
    - Add indexes for faster lookups on pipeline_id, entity_type, and display_order
*/

-- Create pipelines table
CREATE TABLE IF NOT EXISTS pipelines (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  pipeline_id text UNIQUE NOT NULL,
  name text NOT NULL,
  description text,
  entity_type text DEFAULT 'lead',
  is_default boolean DEFAULT false,
  is_active boolean DEFAULT true,
  display_order integer DEFAULT 0,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Create pipeline_stages table
CREATE TABLE IF NOT EXISTS pipeline_stages (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  pipeline_id uuid REFERENCES pipelines(id) ON DELETE CASCADE,
  stage_id text NOT NULL,
  name text NOT NULL,
  description text,
  color text DEFAULT 'bg-gray-100',
  display_order integer DEFAULT 0,
  is_active boolean DEFAULT true,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now(),
  UNIQUE(pipeline_id, stage_id)
);

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_pipelines_pipeline_id ON pipelines(pipeline_id);
CREATE INDEX IF NOT EXISTS idx_pipelines_entity_type ON pipelines(entity_type);
CREATE INDEX IF NOT EXISTS idx_pipelines_display_order ON pipelines(display_order);
CREATE INDEX IF NOT EXISTS idx_pipeline_stages_pipeline_id ON pipeline_stages(pipeline_id);
CREATE INDEX IF NOT EXISTS idx_pipeline_stages_display_order ON pipeline_stages(display_order);

-- Enable RLS
ALTER TABLE pipelines ENABLE ROW LEVEL SECURITY;
ALTER TABLE pipeline_stages ENABLE ROW LEVEL SECURITY;

-- Create policies for pipelines
CREATE POLICY "Allow anon to read pipelines"
  ON pipelines
  FOR SELECT
  TO anon
  USING (true);

CREATE POLICY "Allow authenticated to read pipelines"
  ON pipelines
  FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Allow anon to insert pipelines"
  ON pipelines
  FOR INSERT
  TO anon
  WITH CHECK (true);

CREATE POLICY "Allow authenticated to insert pipelines"
  ON pipelines
  FOR INSERT
  TO authenticated
  WITH CHECK (true);

CREATE POLICY "Allow anon to update pipelines"
  ON pipelines
  FOR UPDATE
  TO anon
  USING (true)
  WITH CHECK (true);

CREATE POLICY "Allow authenticated to update pipelines"
  ON pipelines
  FOR UPDATE
  TO authenticated
  USING (true)
  WITH CHECK (true);

CREATE POLICY "Allow anon to delete pipelines"
  ON pipelines
  FOR DELETE
  TO anon
  USING (true);

CREATE POLICY "Allow authenticated to delete pipelines"
  ON pipelines
  FOR DELETE
  TO authenticated
  USING (true);

-- Create policies for pipeline_stages
CREATE POLICY "Allow anon to read pipeline_stages"
  ON pipeline_stages
  FOR SELECT
  TO anon
  USING (true);

CREATE POLICY "Allow authenticated to read pipeline_stages"
  ON pipeline_stages
  FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Allow anon to insert pipeline_stages"
  ON pipeline_stages
  FOR INSERT
  TO anon
  WITH CHECK (true);

CREATE POLICY "Allow authenticated to insert pipeline_stages"
  ON pipeline_stages
  FOR INSERT
  TO authenticated
  WITH CHECK (true);

CREATE POLICY "Allow anon to update pipeline_stages"
  ON pipeline_stages
  FOR UPDATE
  TO anon
  USING (true)
  WITH CHECK (true);

CREATE POLICY "Allow authenticated to update pipeline_stages"
  ON pipeline_stages
  FOR UPDATE
  TO authenticated
  USING (true)
  WITH CHECK (true);

CREATE POLICY "Allow anon to delete pipeline_stages"
  ON pipeline_stages
  FOR DELETE
  TO anon
  USING (true);

CREATE POLICY "Allow authenticated to delete pipeline_stages"
  ON pipeline_stages
  FOR DELETE
  TO authenticated
  USING (true);

-- Create trigger functions to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_pipelines_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION update_pipeline_stages_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create triggers
CREATE TRIGGER update_pipelines_updated_at_trigger
  BEFORE UPDATE ON pipelines
  FOR EACH ROW
  EXECUTE FUNCTION update_pipelines_updated_at();

CREATE TRIGGER update_pipeline_stages_updated_at_trigger
  BEFORE UPDATE ON pipeline_stages
  FOR EACH ROW
  EXECUTE FUNCTION update_pipeline_stages_updated_at();

-- Insert default Sales Pipeline for leads
INSERT INTO pipelines (pipeline_id, name, description, entity_type, is_default, display_order)
VALUES ('P001', 'Sales Pipeline', 'Default pipeline for managing sales leads', 'lead', true, 1);

-- Insert default stages for the Sales Pipeline
INSERT INTO pipeline_stages (pipeline_id, stage_id, name, color, display_order)
SELECT
  id,
  'new',
  'New',
  'bg-blue-100',
  1
FROM pipelines WHERE pipeline_id = 'P001';

INSERT INTO pipeline_stages (pipeline_id, stage_id, name, color, display_order)
SELECT
  id,
  'contacted',
  'Contacted',
  'bg-yellow-100',
  2
FROM pipelines WHERE pipeline_id = 'P001';

INSERT INTO pipeline_stages (pipeline_id, stage_id, name, color, display_order)
SELECT
  id,
  'demo_booked',
  'Demo Booked',
  'bg-purple-100',
  3
FROM pipelines WHERE pipeline_id = 'P001';

INSERT INTO pipeline_stages (pipeline_id, stage_id, name, color, display_order)
SELECT
  id,
  'no_show',
  'No Show',
  'bg-red-100',
  4
FROM pipelines WHERE pipeline_id = 'P001';

INSERT INTO pipeline_stages (pipeline_id, stage_id, name, color, display_order)
SELECT
  id,
  'won',
  'Won',
  'bg-green-100',
  5
FROM pipelines WHERE pipeline_id = 'P001';

INSERT INTO pipeline_stages (pipeline_id, stage_id, name, color, display_order)
SELECT
  id,
  'lost',
  'Lost',
  'bg-gray-100',
  6
FROM pipelines WHERE pipeline_id = 'P001';
