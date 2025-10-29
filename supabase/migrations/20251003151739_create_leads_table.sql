/*
  # Create Leads Table

  1. New Tables
    - `leads`
      - `id` (uuid, primary key) - Unique identifier for each lead
      - `lead_id` (text, unique) - Human-readable lead ID (e.g., L001)
      - `name` (text) - Lead's full name
      - `email` (text) - Lead's email address
      - `phone` (text) - Lead's phone number
      - `source` (text) - Lead source (Ad, Referral, Webinar, Website, LinkedIn, etc.)
      - `interest` (text) - Interest level (Hot, Warm, Cold)
      - `status` (text) - Lead status (New, Contacted, Demo Booked, No Show, Won, Lost)
      - `owner` (text) - Lead owner/assigned to
      - `address` (text) - Lead's address
      - `company` (text) - Lead's company name
      - `notes` (text) - Additional notes about the lead
      - `last_contact` (timestamptz) - Last contact date
      - `lead_score` (integer) - Lead scoring (0-100)
      - `created_at` (timestamptz) - When the lead was created
      - `updated_at` (timestamptz) - When the lead was last updated
  
  2. Security
    - Enable RLS on `leads` table
    - Add policies for anon and authenticated users to read, insert, update, and delete records
  
  3. Indexes
    - Add index on lead_id for unique lookups
    - Add index on email for faster searches
    - Add index on status for filtering
    - Add index on created_at for sorting
*/

-- Create leads table
CREATE TABLE IF NOT EXISTS leads (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  lead_id text UNIQUE NOT NULL,
  name text NOT NULL,
  email text NOT NULL,
  phone text,
  source text DEFAULT 'Website',
  interest text DEFAULT 'Warm',
  status text DEFAULT 'New',
  owner text DEFAULT 'Sales Team',
  address text,
  company text,
  notes text,
  last_contact timestamptz,
  lead_score integer DEFAULT 50 CHECK (lead_score >= 0 AND lead_score <= 100),
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Create indexes for faster lookups
CREATE INDEX IF NOT EXISTS idx_leads_lead_id ON leads(lead_id);
CREATE INDEX IF NOT EXISTS idx_leads_email ON leads(email);
CREATE INDEX IF NOT EXISTS idx_leads_status ON leads(status);
CREATE INDEX IF NOT EXISTS idx_leads_created_at ON leads(created_at DESC);

-- Enable RLS
ALTER TABLE leads ENABLE ROW LEVEL SECURITY;

-- Create policies for anon access
CREATE POLICY "Allow anon to read leads"
  ON leads
  FOR SELECT
  TO anon
  USING (true);

CREATE POLICY "Allow authenticated to read leads"
  ON leads
  FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Allow anon to insert leads"
  ON leads
  FOR INSERT
  TO anon
  WITH CHECK (true);

CREATE POLICY "Allow authenticated to insert leads"
  ON leads
  FOR INSERT
  TO authenticated
  WITH CHECK (true);

CREATE POLICY "Allow anon to update leads"
  ON leads
  FOR UPDATE
  TO anon
  USING (true)
  WITH CHECK (true);

CREATE POLICY "Allow authenticated to update leads"
  ON leads
  FOR UPDATE
  TO authenticated
  USING (true)
  WITH CHECK (true);

CREATE POLICY "Allow anon to delete leads"
  ON leads
  FOR DELETE
  TO anon
  USING (true);

CREATE POLICY "Allow authenticated to delete leads"
  ON leads
  FOR DELETE
  TO authenticated
  USING (true);

-- Create trigger to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_leads_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_leads_updated_at_trigger
  BEFORE UPDATE ON leads
  FOR EACH ROW
  EXECUTE FUNCTION update_leads_updated_at();
