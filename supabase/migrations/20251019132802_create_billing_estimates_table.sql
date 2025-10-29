/*
  # Create Estimates Table

  1. New Tables
    - `estimates`
      - `id` (uuid, primary key)
      - `estimate_id` (text, unique, human-readable ID like EST0001)
      - `customer_id` (uuid, nullable reference to enrolled_members or can be standalone)
      - `customer_name` (text, customer name)
      - `customer_email` (text, customer email)
      - `customer_phone` (text, customer phone)
      - `title` (text, estimate title/description)
      - `items` (jsonb, array of line items with description, quantity, rate, amount)
      - `subtotal` (numeric, sum of all items before tax and discount)
      - `discount` (numeric, discount amount)
      - `tax_rate` (numeric, tax rate percentage)
      - `tax_amount` (numeric, calculated tax amount)
      - `total_amount` (numeric, final amount)
      - `notes` (text, additional notes or terms)
      - `status` (text, 'Draft', 'Sent', 'Accepted', 'Rejected', 'Expired')
      - `valid_until` (date, estimate expiry date)
      - `created_at` (timestamptz)
      - `updated_at` (timestamptz)
      - `sent_at` (timestamptz, when estimate was sent)
      - `responded_at` (timestamptz, when customer accepted/rejected)

  2. Security
    - Enable RLS on `estimates` table
    - Add policy for anonymous users to read all estimates
    - Add policy for anonymous users to insert estimates
    - Add policy for anonymous users to update estimates
    - Add policy for anonymous users to delete estimates

  3. Indexes
    - Index on customer_email for customer lookups
    - Index on status for filtering by status
    - Index on created_at for sorting

  4. Functions
    - Auto-generate estimate_id
    - Auto-update updated_at timestamp
*/

-- Create estimates table
CREATE TABLE IF NOT EXISTS estimates (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  estimate_id text UNIQUE NOT NULL,
  customer_id uuid REFERENCES enrolled_members(id) ON DELETE SET NULL,
  customer_name text NOT NULL,
  customer_email text NOT NULL,
  customer_phone text,
  title text NOT NULL,
  items jsonb DEFAULT '[]'::jsonb,
  subtotal numeric(12, 2) DEFAULT 0,
  discount numeric(12, 2) DEFAULT 0,
  tax_rate numeric(5, 2) DEFAULT 0,
  tax_amount numeric(12, 2) DEFAULT 0,
  total_amount numeric(12, 2) DEFAULT 0,
  notes text,
  status text DEFAULT 'Draft' CHECK (status IN ('Draft', 'Sent', 'Accepted', 'Rejected', 'Expired')),
  valid_until date,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now(),
  sent_at timestamptz,
  responded_at timestamptz
);

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_estimates_customer_email ON estimates(customer_email);
CREATE INDEX IF NOT EXISTS idx_estimates_status ON estimates(status);
CREATE INDEX IF NOT EXISTS idx_estimates_created_at ON estimates(created_at);

-- Create function to generate estimate ID
CREATE OR REPLACE FUNCTION generate_estimate_id()
RETURNS text AS $$
DECLARE
  next_id integer;
  new_estimate_id text;
BEGIN
  SELECT COUNT(*) + 1 INTO next_id FROM estimates;
  new_estimate_id := 'EST' || LPAD(next_id::text, 4, '0');
  
  WHILE EXISTS (SELECT 1 FROM estimates WHERE estimate_id = new_estimate_id) LOOP
    next_id := next_id + 1;
    new_estimate_id := 'EST' || LPAD(next_id::text, 4, '0');
  END LOOP;
  
  RETURN new_estimate_id;
END;
$$ LANGUAGE plpgsql;

-- Create trigger to auto-generate estimate_id
CREATE OR REPLACE FUNCTION set_estimate_id()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.estimate_id IS NULL OR NEW.estimate_id = '' THEN
    NEW.estimate_id := generate_estimate_id();
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_set_estimate_id ON estimates;
CREATE TRIGGER trigger_set_estimate_id
  BEFORE INSERT ON estimates
  FOR EACH ROW
  EXECUTE FUNCTION set_estimate_id();

-- Create function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_estimates_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS update_estimates_updated_at_trigger ON estimates;
CREATE TRIGGER update_estimates_updated_at_trigger
  BEFORE UPDATE ON estimates
  FOR EACH ROW
  EXECUTE FUNCTION update_estimates_updated_at();

-- Enable RLS
ALTER TABLE estimates ENABLE ROW LEVEL SECURITY;

-- Create RLS policies for anonymous access
CREATE POLICY "Allow anonymous read access to estimates"
  ON estimates
  FOR SELECT
  TO anon
  USING (true);

CREATE POLICY "Allow anonymous insert access to estimates"
  ON estimates
  FOR INSERT
  TO anon
  WITH CHECK (true);

CREATE POLICY "Allow anonymous update access to estimates"
  ON estimates
  FOR UPDATE
  TO anon
  USING (true)
  WITH CHECK (true);

CREATE POLICY "Allow anonymous delete access to estimates"
  ON estimates
  FOR DELETE
  TO anon
  USING (true);

-- Add comments
COMMENT ON TABLE estimates IS 'Table for managing customer estimates/quotations';
COMMENT ON COLUMN estimates.estimate_id IS 'Human-readable estimate ID (e.g., EST0001)';
COMMENT ON COLUMN estimates.items IS 'JSON array of line items: [{description, quantity, rate, amount}]';
COMMENT ON COLUMN estimates.status IS 'Draft, Sent, Accepted, Rejected, or Expired';
COMMENT ON COLUMN estimates.valid_until IS 'Date when the estimate expires';