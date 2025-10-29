/*
  # Create Contacts Master Table

  1. New Tables
    - `contacts_master` - Stores all contact information with personal and business details
      - `id` (uuid, primary key)
      - `contact_id` (text) - Human-readable contact ID (e.g., CONT0001)
      - Personal Details:
        - `full_name` (text, required)
        - `email` (text, required, unique)
        - `phone` (text)
        - `date_of_birth` (date)
        - `gender` (text)
        - `education_level` (text)
        - `profession` (text)
        - `experience` (text)
      - Business Details:
        - `business_name` (text)
        - `address` (text)
        - `city` (text)
        - `state` (text)
        - `pincode` (text)
        - `gst_number` (text)
      - Other Fields:
        - `contact_type` (text) - Customer, Vendor, Partner, etc.
        - `status` (text) - Active, Inactive
        - `notes` (text)
        - `last_contacted` (timestamptz)
        - `tags` (jsonb) - Array of tags
        - `created_at` (timestamptz)
        - `updated_at` (timestamptz)

  2. Security
    - Enable RLS on `contacts_master` table
    - Add policy for anonymous access (for public forms)
    - Add policy for authenticated users

  3. Functions
    - Auto-generate contact_id function
    - Auto-update updated_at timestamp
*/

-- Create contacts_master table
CREATE TABLE IF NOT EXISTS contacts_master (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  contact_id text UNIQUE,
  full_name text NOT NULL,
  email text NOT NULL UNIQUE,
  phone text,
  date_of_birth date,
  gender text,
  education_level text,
  profession text,
  experience text,
  business_name text,
  address text,
  city text,
  state text,
  pincode text,
  gst_number text,
  contact_type text DEFAULT 'Customer',
  status text DEFAULT 'Active',
  notes text,
  last_contacted timestamptz,
  tags jsonb DEFAULT '[]'::jsonb,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Create function to auto-generate contact_id
CREATE OR REPLACE FUNCTION generate_contact_id()
RETURNS TRIGGER AS $$
DECLARE
  max_id integer;
  new_id text;
BEGIN
  IF NEW.contact_id IS NULL THEN
    SELECT COALESCE(
      MAX(CAST(SUBSTRING(contact_id FROM 5) AS integer)), 0
    ) INTO max_id
    FROM contacts_master
    WHERE contact_id ~ '^CONT[0-9]+$';
    
    new_id := 'CONT' || LPAD((max_id + 1)::text, 4, '0');
    NEW.contact_id := new_id;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger to auto-generate contact_id
DROP TRIGGER IF EXISTS trigger_generate_contact_id ON contacts_master;
CREATE TRIGGER trigger_generate_contact_id
  BEFORE INSERT ON contacts_master
  FOR EACH ROW
  EXECUTE FUNCTION generate_contact_id();

-- Create function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_contacts_master_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger to update updated_at
DROP TRIGGER IF EXISTS trigger_update_contacts_master_updated_at ON contacts_master;
CREATE TRIGGER trigger_update_contacts_master_updated_at
  BEFORE UPDATE ON contacts_master
  FOR EACH ROW
  EXECUTE FUNCTION update_contacts_master_updated_at();

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_contacts_master_contact_id ON contacts_master(contact_id);
CREATE INDEX IF NOT EXISTS idx_contacts_master_email ON contacts_master(email);
CREATE INDEX IF NOT EXISTS idx_contacts_master_phone ON contacts_master(phone);
CREATE INDEX IF NOT EXISTS idx_contacts_master_contact_type ON contacts_master(contact_type);
CREATE INDEX IF NOT EXISTS idx_contacts_master_status ON contacts_master(status);
CREATE INDEX IF NOT EXISTS idx_contacts_master_created_at ON contacts_master(created_at DESC);

-- Enable RLS
ALTER TABLE contacts_master ENABLE ROW LEVEL SECURITY;

-- Create policies for anonymous access
CREATE POLICY "Allow anonymous to read contacts"
  ON contacts_master
  FOR SELECT
  TO anon
  USING (true);

CREATE POLICY "Allow anonymous to insert contacts"
  ON contacts_master
  FOR INSERT
  TO anon
  WITH CHECK (true);

CREATE POLICY "Allow anonymous to update contacts"
  ON contacts_master
  FOR UPDATE
  TO anon
  USING (true)
  WITH CHECK (true);

CREATE POLICY "Allow anonymous to delete contacts"
  ON contacts_master
  FOR DELETE
  TO anon
  USING (true);

-- Create policies for authenticated users
CREATE POLICY "Allow authenticated to read contacts"
  ON contacts_master
  FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Allow authenticated to insert contacts"
  ON contacts_master
  FOR INSERT
  TO authenticated
  WITH CHECK (true);

CREATE POLICY "Allow authenticated to update contacts"
  ON contacts_master
  FOR UPDATE
  TO authenticated
  USING (true)
  WITH CHECK (true);

CREATE POLICY "Allow authenticated to delete contacts"
  ON contacts_master
  FOR DELETE
  TO authenticated
  USING (true);

-- Add comments
COMMENT ON TABLE contacts_master IS 'Master table for storing all contact information including personal and business details';
COMMENT ON COLUMN contacts_master.contact_id IS 'Human-readable contact ID (e.g., CONT0001)';
COMMENT ON COLUMN contacts_master.contact_type IS 'Type of contact: Customer, Vendor, Partner, Lead, etc.';
COMMENT ON COLUMN contacts_master.status IS 'Contact status: Active or Inactive';
COMMENT ON COLUMN contacts_master.tags IS 'Array of tags for categorizing contacts';
