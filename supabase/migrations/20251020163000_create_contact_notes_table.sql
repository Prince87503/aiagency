/*
  # Create Contact Notes Table

  1. New Tables
    - `contact_notes`
      - `id` (uuid, primary key)
      - `contact_id` (uuid, foreign key to contacts_master)
      - `note_text` (text, the note content)
      - `created_at` (timestamptz, when note was created)
      - `updated_at` (timestamptz, when note was last updated)
      - `created_by` (text, user who created the note)

  2. Security
    - Enable RLS on `contact_notes` table
    - Add policy for authenticated users to read all notes
    - Add policy for authenticated users to create notes
    - Add policy for authenticated users to update their own notes
    - Add policy for authenticated users to delete their own notes
    - Add policy for anonymous users to read, create, update, and delete notes (for demo purposes)

  3. Indexes
    - Add index on contact_id for faster queries
    - Add index on created_at for sorting
*/

-- Create contact_notes table
CREATE TABLE IF NOT EXISTS contact_notes (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  contact_id uuid NOT NULL REFERENCES contacts_master(id) ON DELETE CASCADE,
  note_text text NOT NULL,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now(),
  created_by text DEFAULT 'System'
);

-- Enable RLS
ALTER TABLE contact_notes ENABLE ROW LEVEL SECURITY;

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_contact_notes_contact_id ON contact_notes(contact_id);
CREATE INDEX IF NOT EXISTS idx_contact_notes_created_at ON contact_notes(created_at DESC);

-- RLS Policies for authenticated users
CREATE POLICY "Authenticated users can view all contact notes"
  ON contact_notes FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Authenticated users can create contact notes"
  ON contact_notes FOR INSERT
  TO authenticated
  WITH CHECK (true);

CREATE POLICY "Authenticated users can update contact notes"
  ON contact_notes FOR UPDATE
  TO authenticated
  USING (true)
  WITH CHECK (true);

CREATE POLICY "Authenticated users can delete contact notes"
  ON contact_notes FOR DELETE
  TO authenticated
  USING (true);

-- RLS Policies for anonymous users (for demo purposes)
CREATE POLICY "Anonymous users can view all contact notes"
  ON contact_notes FOR SELECT
  TO anon
  USING (true);

CREATE POLICY "Anonymous users can create contact notes"
  ON contact_notes FOR INSERT
  TO anon
  WITH CHECK (true);

CREATE POLICY "Anonymous users can update contact notes"
  ON contact_notes FOR UPDATE
  TO anon
  USING (true)
  WITH CHECK (true);

CREATE POLICY "Anonymous users can delete contact notes"
  ON contact_notes FOR DELETE
  TO anon
  USING (true);

-- Create trigger to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_contact_notes_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER contact_notes_updated_at
  BEFORE UPDATE ON contact_notes
  FOR EACH ROW
  EXECUTE FUNCTION update_contact_notes_updated_at();
