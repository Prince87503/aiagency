/*
  # Create Affiliates Table

  1. New Tables
    - `affiliates`
      - `id` (uuid, primary key) - Unique identifier for each affiliate
      - `affiliate_id` (text, unique) - Human-readable affiliate ID (e.g., A001)
      - `name` (text) - Affiliate's full name
      - `email` (text, unique) - Affiliate's email address
      - `phone` (text) - Affiliate's phone number
      - `commission_pct` (integer) - Commission percentage (1-50)
      - `unique_link` (text) - Unique referral link
      - `referrals` (integer) - Total number of referrals
      - `earnings_paid` (numeric) - Total earnings paid to affiliate
      - `earnings_pending` (numeric) - Pending earnings
      - `status` (text) - Affiliate status (Active, Inactive, Suspended)
      - `company` (text) - Affiliate's company name
      - `address` (text) - Affiliate's address
      - `notes` (text) - Additional notes about the affiliate
      - `joined_on` (date) - Date when affiliate joined
      - `last_activity` (timestamptz) - Last activity timestamp
      - `created_at` (timestamptz) - When the record was created
      - `updated_at` (timestamptz) - When the record was last updated
  
  2. Security
    - Enable RLS on `affiliates` table
    - Add policies for anon and authenticated users to read, insert, update, and delete records
  
  3. Indexes
    - Add index on affiliate_id for unique lookups
    - Add index on email for faster searches
    - Add index on status for filtering
    - Add index on created_at for sorting

  4. Sample Data
    - Insert 2 sample affiliate records
*/

-- Create affiliates table
CREATE TABLE IF NOT EXISTS affiliates (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  affiliate_id text UNIQUE NOT NULL,
  name text NOT NULL,
  email text UNIQUE NOT NULL,
  phone text,
  commission_pct integer DEFAULT 15 CHECK (commission_pct >= 1 AND commission_pct <= 50),
  unique_link text NOT NULL,
  referrals integer DEFAULT 0,
  earnings_paid numeric DEFAULT 0,
  earnings_pending numeric DEFAULT 0,
  status text DEFAULT 'Active' CHECK (status IN ('Active', 'Inactive', 'Suspended')),
  company text,
  address text,
  notes text,
  joined_on date DEFAULT CURRENT_DATE,
  last_activity timestamptz,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Create indexes for faster lookups
CREATE INDEX IF NOT EXISTS idx_affiliates_affiliate_id ON affiliates(affiliate_id);
CREATE INDEX IF NOT EXISTS idx_affiliates_email ON affiliates(email);
CREATE INDEX IF NOT EXISTS idx_affiliates_status ON affiliates(status);
CREATE INDEX IF NOT EXISTS idx_affiliates_created_at ON affiliates(created_at DESC);

-- Enable RLS
ALTER TABLE affiliates ENABLE ROW LEVEL SECURITY;

-- Create policies for anon access
CREATE POLICY "Allow anon to read affiliates"
  ON affiliates
  FOR SELECT
  TO anon
  USING (true);

CREATE POLICY "Allow authenticated to read affiliates"
  ON affiliates
  FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Allow anon to insert affiliates"
  ON affiliates
  FOR INSERT
  TO anon
  WITH CHECK (true);

CREATE POLICY "Allow authenticated to insert affiliates"
  ON affiliates
  FOR INSERT
  TO authenticated
  WITH CHECK (true);

CREATE POLICY "Allow anon to update affiliates"
  ON affiliates
  FOR UPDATE
  TO anon
  USING (true)
  WITH CHECK (true);

CREATE POLICY "Allow authenticated to update affiliates"
  ON affiliates
  FOR UPDATE
  TO authenticated
  USING (true)
  WITH CHECK (true);

CREATE POLICY "Allow anon to delete affiliates"
  ON affiliates
  FOR DELETE
  TO anon
  USING (true);

CREATE POLICY "Allow authenticated to delete affiliates"
  ON affiliates
  FOR DELETE
  TO authenticated
  USING (true);

-- Create trigger to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_affiliates_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_affiliates_updated_at_trigger
  BEFORE UPDATE ON affiliates
  FOR EACH ROW
  EXECUTE FUNCTION update_affiliates_updated_at();

-- Insert sample data
INSERT INTO affiliates (
  affiliate_id, name, email, phone, commission_pct, unique_link,
  referrals, earnings_paid, earnings_pending, status, joined_on, last_activity
) VALUES
(
  'A001',
  'Rajesh Kumar',
  'rajesh@example.com',
  '919876543210',
  15,
  'https://aiacoach.com/ref/rajesh-kumar',
  120,
  180000,
  75000,
  'Active',
  '2024-01-10',
  '2024-01-20'
),
(
  'A002',
  'Priya Sharma',
  'priya@example.com',
  '919876543211',
  20,
  'https://aiacoach.com/ref/priya-sharma',
  80,
  240000,
  45000,
  'Active',
  '2024-01-08',
  '2024-01-19'
);
