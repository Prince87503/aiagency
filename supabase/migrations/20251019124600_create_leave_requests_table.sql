/*
  # Create Leave Requests Table

  1. New Tables
    - `leave_requests`
      - `id` (uuid, primary key)
      - `request_id` (text, unique, human-readable ID like LR001)
      - `admin_user_id` (uuid, foreign key to admin_users)
      - `request_type` (text, 'Leave', 'Work From Home', 'Half Day')
      - `start_date` (date, start date of leave/WFH)
      - `end_date` (date, end date of leave/WFH)
      - `total_days` (numeric, calculated duration)
      - `reason` (text, reason for request)
      - `status` (text, 'Pending', 'Approved', 'Rejected')
      - `approved_by` (uuid, foreign key to admin_users - who approved/rejected)
      - `approved_at` (timestamptz, when it was approved/rejected)
      - `rejection_reason` (text, reason for rejection if applicable)
      - `notes` (text, additional notes)
      - `created_at` (timestamptz)
      - `updated_at` (timestamptz)

  2. Security
    - Enable RLS on `leave_requests` table
    - Add policy for anonymous users to read all leave requests
    - Add policy for anonymous users to insert leave requests
    - Add policy for anonymous users to update leave requests
    - Add policy for anonymous users to delete leave requests

  3. Indexes
    - Index on admin_user_id for filtering by team member
    - Index on request_type for filtering by type
    - Index on status for filtering by status
    - Index on start_date for date-based queries

  4. Functions
    - Auto-generate request_id
    - Auto-update updated_at timestamp
    - Calculate total_days based on start_date and end_date
*/

-- Create leave_requests table
CREATE TABLE IF NOT EXISTS leave_requests (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  request_id text UNIQUE NOT NULL,
  admin_user_id uuid NOT NULL REFERENCES admin_users(id) ON DELETE CASCADE,
  request_type text NOT NULL CHECK (request_type IN ('Leave', 'Work From Home', 'Half Day')),
  start_date date NOT NULL,
  end_date date NOT NULL,
  total_days numeric(4, 1) DEFAULT 0,
  reason text NOT NULL,
  status text DEFAULT 'Pending' CHECK (status IN ('Pending', 'Approved', 'Rejected')),
  approved_by uuid REFERENCES admin_users(id) ON DELETE SET NULL,
  approved_at timestamptz,
  rejection_reason text,
  notes text,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now(),
  CONSTRAINT valid_date_range CHECK (end_date >= start_date)
);

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_leave_requests_admin_user_id ON leave_requests(admin_user_id);
CREATE INDEX IF NOT EXISTS idx_leave_requests_request_type ON leave_requests(request_type);
CREATE INDEX IF NOT EXISTS idx_leave_requests_status ON leave_requests(status);
CREATE INDEX IF NOT EXISTS idx_leave_requests_start_date ON leave_requests(start_date);

-- Create function to generate request ID
CREATE OR REPLACE FUNCTION generate_leave_request_id()
RETURNS text AS $$
DECLARE
  next_id integer;
  new_request_id text;
BEGIN
  SELECT COUNT(*) + 1 INTO next_id FROM leave_requests;
  new_request_id := 'LR' || LPAD(next_id::text, 4, '0');
  
  WHILE EXISTS (SELECT 1 FROM leave_requests WHERE request_id = new_request_id) LOOP
    next_id := next_id + 1;
    new_request_id := 'LR' || LPAD(next_id::text, 4, '0');
  END LOOP;
  
  RETURN new_request_id;
END;
$$ LANGUAGE plpgsql;

-- Create function to calculate total days
CREATE OR REPLACE FUNCTION calculate_leave_days()
RETURNS TRIGGER AS $$
BEGIN
  -- For Half Day, always set to 0.5
  IF NEW.request_type = 'Half Day' THEN
    NEW.total_days := 0.5;
  ELSE
    -- Calculate days including start and end date
    NEW.total_days := (NEW.end_date - NEW.start_date) + 1;
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger to auto-generate request_id
CREATE OR REPLACE FUNCTION set_leave_request_id()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.request_id IS NULL OR NEW.request_id = '' THEN
    NEW.request_id := generate_leave_request_id();
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_set_leave_request_id ON leave_requests;
CREATE TRIGGER trigger_set_leave_request_id
  BEFORE INSERT ON leave_requests
  FOR EACH ROW
  EXECUTE FUNCTION set_leave_request_id();

-- Create trigger to calculate total days
DROP TRIGGER IF EXISTS trigger_calculate_leave_days ON leave_requests;
CREATE TRIGGER trigger_calculate_leave_days
  BEFORE INSERT OR UPDATE ON leave_requests
  FOR EACH ROW
  EXECUTE FUNCTION calculate_leave_days();

-- Create function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_leave_requests_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS update_leave_requests_updated_at_trigger ON leave_requests;
CREATE TRIGGER update_leave_requests_updated_at_trigger
  BEFORE UPDATE ON leave_requests
  FOR EACH ROW
  EXECUTE FUNCTION update_leave_requests_updated_at();

-- Enable RLS
ALTER TABLE leave_requests ENABLE ROW LEVEL SECURITY;

-- Create RLS policies for anonymous access
CREATE POLICY "Allow anonymous read access to leave_requests"
  ON leave_requests
  FOR SELECT
  TO anon
  USING (true);

CREATE POLICY "Allow anonymous insert access to leave_requests"
  ON leave_requests
  FOR INSERT
  TO anon
  WITH CHECK (true);

CREATE POLICY "Allow anonymous update access to leave_requests"
  ON leave_requests
  FOR UPDATE
  TO anon
  USING (true)
  WITH CHECK (true);

CREATE POLICY "Allow anonymous delete access to leave_requests"
  ON leave_requests
  FOR DELETE
  TO anon
  USING (true);

-- Add comments
COMMENT ON TABLE leave_requests IS 'Table for managing team member leave requests, work from home, and half day requests';
COMMENT ON COLUMN leave_requests.request_id IS 'Human-readable request ID (e.g., LR0001)';
COMMENT ON COLUMN leave_requests.request_type IS 'Type of request: Leave, Work From Home, or Half Day';
COMMENT ON COLUMN leave_requests.total_days IS 'Total days for the request (0.5 for half day, calculated for others)';
COMMENT ON COLUMN leave_requests.status IS 'Current status: Pending, Approved, or Rejected';
COMMENT ON COLUMN leave_requests.approved_by IS 'Admin user who approved or rejected the request';
COMMENT ON COLUMN leave_requests.rejection_reason IS 'Reason provided if request was rejected';