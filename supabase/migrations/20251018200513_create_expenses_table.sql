/*
  # Create Expenses Table

  1. New Tables
    - `expenses`
      - `id` (uuid, primary key)
      - `expense_id` (text, unique, human-readable ID like EXP001)
      - `admin_user_id` (uuid, foreign key to admin_users)
      - `category` (text, expense category)
      - `amount` (numeric, expense amount)
      - `currency` (text, default 'INR')
      - `description` (text, expense description)
      - `expense_date` (date, when the expense occurred)
      - `payment_method` (text, Cash, Card, UPI, etc.)
      - `receipt_url` (text, URL to receipt/invoice)
      - `status` (text, Pending, Approved, Rejected, Reimbursed)
      - `approved_by` (uuid, foreign key to admin_users)
      - `approved_at` (timestamptz, when approved)
      - `notes` (text, additional notes)
      - `created_at` (timestamptz)
      - `updated_at` (timestamptz)

  2. Security
    - Enable RLS on `expenses` table
    - Add policy for anonymous users to read all expenses
    - Add policy for anonymous users to insert expenses
    - Add policy for anonymous users to update expenses
    - Add policy for anonymous users to delete expenses

  3. Indexes
    - Index on admin_user_id for faster queries
    - Index on expense_date for filtering by date
    - Index on status for filtering by status
*/

-- Create expenses table
CREATE TABLE IF NOT EXISTS expenses (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  expense_id text UNIQUE NOT NULL,
  admin_user_id uuid REFERENCES admin_users(id) ON DELETE CASCADE,
  category text NOT NULL,
  amount numeric(10, 2) NOT NULL CHECK (amount > 0),
  currency text DEFAULT 'INR',
  description text,
  expense_date date NOT NULL DEFAULT CURRENT_DATE,
  payment_method text,
  receipt_url text,
  status text DEFAULT 'Pending' CHECK (status IN ('Pending', 'Approved', 'Rejected', 'Reimbursed')),
  approved_by uuid REFERENCES admin_users(id) ON DELETE SET NULL,
  approved_at timestamptz,
  notes text,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_expenses_admin_user_id ON expenses(admin_user_id);
CREATE INDEX IF NOT EXISTS idx_expenses_expense_date ON expenses(expense_date);
CREATE INDEX IF NOT EXISTS idx_expenses_status ON expenses(status);

-- Create function to generate expense ID
CREATE OR REPLACE FUNCTION generate_expense_id()
RETURNS text AS $$
DECLARE
  next_id integer;
  new_expense_id text;
BEGIN
  SELECT COUNT(*) + 1 INTO next_id FROM expenses;
  new_expense_id := 'EXP' || LPAD(next_id::text, 3, '0');
  
  WHILE EXISTS (SELECT 1 FROM expenses WHERE expense_id = new_expense_id) LOOP
    next_id := next_id + 1;
    new_expense_id := 'EXP' || LPAD(next_id::text, 3, '0');
  END LOOP;
  
  RETURN new_expense_id;
END;
$$ LANGUAGE plpgsql;

-- Create trigger to auto-generate expense_id
CREATE OR REPLACE FUNCTION set_expense_id()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.expense_id IS NULL OR NEW.expense_id = '' THEN
    NEW.expense_id := generate_expense_id();
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_set_expense_id ON expenses;
CREATE TRIGGER trigger_set_expense_id
  BEFORE INSERT ON expenses
  FOR EACH ROW
  EXECUTE FUNCTION set_expense_id();

-- Create function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_expenses_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS update_expenses_updated_at_trigger ON expenses;
CREATE TRIGGER update_expenses_updated_at_trigger
  BEFORE UPDATE ON expenses
  FOR EACH ROW
  EXECUTE FUNCTION update_expenses_updated_at();

-- Enable RLS
ALTER TABLE expenses ENABLE ROW LEVEL SECURITY;

-- Create RLS policies for anonymous access (temporary - should be restricted in production)
CREATE POLICY "Allow anonymous read access to expenses"
  ON expenses
  FOR SELECT
  TO anon
  USING (true);

CREATE POLICY "Allow anonymous insert access to expenses"
  ON expenses
  FOR INSERT
  TO anon
  WITH CHECK (true);

CREATE POLICY "Allow anonymous update access to expenses"
  ON expenses
  FOR UPDATE
  TO anon
  USING (true)
  WITH CHECK (true);

CREATE POLICY "Allow anonymous delete access to expenses"
  ON expenses
  FOR DELETE
  TO anon
  USING (true);

-- Add comments
COMMENT ON TABLE expenses IS 'Stores expense records for team members';
COMMENT ON COLUMN expenses.expense_id IS 'Human-readable expense ID (e.g., EXP001)';
COMMENT ON COLUMN expenses.admin_user_id IS 'Team member who submitted the expense';
COMMENT ON COLUMN expenses.category IS 'Expense category (Travel, Food, Office Supplies, etc.)';
COMMENT ON COLUMN expenses.amount IS 'Expense amount';
COMMENT ON COLUMN expenses.currency IS 'Currency code (default: INR)';
COMMENT ON COLUMN expenses.status IS 'Expense status (Pending, Approved, Rejected, Reimbursed)';
COMMENT ON COLUMN expenses.approved_by IS 'Admin who approved/rejected the expense';
COMMENT ON COLUMN expenses.approved_at IS 'When the expense was approved/rejected';