/*
  # Create Media Storage Tables

  1. New Tables
    - `media_folders`
      - `id` (uuid, primary key)
      - `folder_name` (text) - Display name
      - `ghl_folder_id` (text) - GoHighLevel folder ID
      - `parent_id` (uuid) - Parent folder reference (self-referential)
      - `location_id` (text) - GHL location ID
      - `created_at` (timestamptz)
      - `updated_at` (timestamptz)
    
    - `media_files`
      - `id` (uuid, primary key)
      - `file_name` (text) - Original file name
      - `file_url` (text) - GHL file URL
      - `file_type` (text) - MIME type
      - `file_size` (bigint) - File size in bytes
      - `ghl_file_id` (text) - GoHighLevel file ID
      - `folder_id` (uuid) - Reference to media_folders
      - `location_id` (text) - GHL location ID
      - `thumbnail_url` (text) - Preview/thumbnail URL
      - `uploaded_by` (text) - User who uploaded
      - `created_at` (timestamptz)
      - `updated_at` (timestamptz)

  2. Security
    - Enable RLS on both tables
    - Add policies for anonymous access (read/write)

  3. Indexes
    - Index on parent_id for folder hierarchy
    - Index on folder_id for file lookups
    - Index on ghl_folder_id and ghl_file_id
*/

CREATE TABLE IF NOT EXISTS media_folders (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  folder_name text NOT NULL,
  ghl_folder_id text,
  parent_id uuid REFERENCES media_folders(id) ON DELETE CASCADE,
  location_id text DEFAULT 'iDIRFjdZBWH7SqBzTowc',
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

CREATE TABLE IF NOT EXISTS media_files (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  file_name text NOT NULL,
  file_url text NOT NULL,
  file_type text,
  file_size bigint,
  ghl_file_id text,
  folder_id uuid REFERENCES media_folders(id) ON DELETE SET NULL,
  location_id text DEFAULT 'iDIRFjdZBWH7SqBzTowc',
  thumbnail_url text,
  uploaded_by text,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

ALTER TABLE media_folders ENABLE ROW LEVEL SECURITY;
ALTER TABLE media_files ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Allow anonymous read access to media_folders"
  ON media_folders
  FOR SELECT
  TO anon
  USING (true);

CREATE POLICY "Allow anonymous insert access to media_folders"
  ON media_folders
  FOR INSERT
  TO anon
  WITH CHECK (true);

CREATE POLICY "Allow anonymous update access to media_folders"
  ON media_folders
  FOR UPDATE
  TO anon
  USING (true)
  WITH CHECK (true);

CREATE POLICY "Allow anonymous delete access to media_folders"
  ON media_folders
  FOR DELETE
  TO anon
  USING (true);

CREATE POLICY "Allow anonymous read access to media_files"
  ON media_files
  FOR SELECT
  TO anon
  USING (true);

CREATE POLICY "Allow anonymous insert access to media_files"
  ON media_files
  FOR INSERT
  TO anon
  WITH CHECK (true);

CREATE POLICY "Allow anonymous update access to media_files"
  ON media_files
  FOR UPDATE
  TO anon
  USING (true)
  WITH CHECK (true);

CREATE POLICY "Allow anonymous delete access to media_files"
  ON media_files
  FOR DELETE
  TO anon
  USING (true);

CREATE INDEX IF NOT EXISTS idx_media_folders_parent ON media_folders(parent_id);
CREATE INDEX IF NOT EXISTS idx_media_folders_ghl_id ON media_folders(ghl_folder_id);
CREATE INDEX IF NOT EXISTS idx_media_files_folder ON media_files(folder_id);
CREATE INDEX IF NOT EXISTS idx_media_files_ghl_id ON media_files(ghl_file_id);

CREATE OR REPLACE FUNCTION update_media_folders_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION update_media_files_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_media_folders_updated_at
  BEFORE UPDATE ON media_folders
  FOR EACH ROW
  EXECUTE FUNCTION update_media_folders_updated_at();

CREATE TRIGGER trigger_update_media_files_updated_at
  BEFORE UPDATE ON media_files
  FOR EACH ROW
  EXECUTE FUNCTION update_media_files_updated_at();
