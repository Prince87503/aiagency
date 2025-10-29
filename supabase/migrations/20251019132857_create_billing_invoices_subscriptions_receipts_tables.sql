/*
  # Create Invoices, Subscriptions, and Receipts Tables

  1. New Tables
    - `invoices`
      - Invoice management with line items, taxes, discounts
      - Status tracking: Draft, Sent, Paid, Partially Paid, Overdue, Cancelled
      
    - `subscriptions`
      - Recurring subscription management
      - Status: Active, Paused, Cancelled, Expired
      
    - `receipts`
      - Payment receipts for completed transactions
      - Links to invoices or subscriptions

  2. Security
    - Enable RLS on all tables
    - Add policies for anonymous access

  3. Indexes
    - Indexes for common queries

  4. Functions
    - Auto-generate IDs
    - Auto-update timestamps
*/

-- Create invoices table
CREATE TABLE IF NOT EXISTS invoices (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  invoice_id text UNIQUE NOT NULL,
  estimate_id uuid REFERENCES estimates(id) ON DELETE SET NULL,
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
  paid_amount numeric(12, 2) DEFAULT 0,
  balance_due numeric(12, 2) DEFAULT 0,
  notes text,
  terms text,
  status text DEFAULT 'Draft' CHECK (status IN ('Draft', 'Sent', 'Paid', 'Partially Paid', 'Overdue', 'Cancelled')),
  payment_method text,
  issue_date date NOT NULL,
  due_date date NOT NULL,
  paid_date date,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now(),
  sent_at timestamptz
);

-- Create subscriptions table
CREATE TABLE IF NOT EXISTS subscriptions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  subscription_id text UNIQUE NOT NULL,
  customer_id uuid REFERENCES enrolled_members(id) ON DELETE SET NULL,
  customer_name text NOT NULL,
  customer_email text NOT NULL,
  customer_phone text,
  plan_name text NOT NULL,
  plan_type text NOT NULL CHECK (plan_type IN ('Monthly', 'Quarterly', 'Yearly', 'Custom')),
  amount numeric(12, 2) NOT NULL,
  currency text DEFAULT 'INR',
  billing_cycle_day integer DEFAULT 1,
  status text DEFAULT 'Active' CHECK (status IN ('Active', 'Paused', 'Cancelled', 'Expired')),
  payment_method text,
  start_date date NOT NULL,
  end_date date,
  next_billing_date date,
  last_billing_date date,
  auto_renew boolean DEFAULT true,
  notes text,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now(),
  cancelled_at timestamptz,
  cancelled_reason text
);

-- Create receipts table
CREATE TABLE IF NOT EXISTS receipts (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  receipt_id text UNIQUE NOT NULL,
  invoice_id uuid REFERENCES invoices(id) ON DELETE SET NULL,
  subscription_id uuid REFERENCES subscriptions(id) ON DELETE SET NULL,
  customer_id uuid REFERENCES enrolled_members(id) ON DELETE SET NULL,
  customer_name text NOT NULL,
  customer_email text NOT NULL,
  payment_method text NOT NULL,
  payment_reference text,
  amount_paid numeric(12, 2) NOT NULL,
  currency text DEFAULT 'INR',
  payment_date date NOT NULL,
  description text,
  notes text,
  status text DEFAULT 'Completed' CHECK (status IN ('Completed', 'Failed', 'Refunded', 'Pending')),
  refund_amount numeric(12, 2) DEFAULT 0,
  refund_date date,
  refund_reason text,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Create indexes for invoices
CREATE INDEX IF NOT EXISTS idx_invoices_customer_email ON invoices(customer_email);
CREATE INDEX IF NOT EXISTS idx_invoices_status ON invoices(status);
CREATE INDEX IF NOT EXISTS idx_invoices_due_date ON invoices(due_date);
CREATE INDEX IF NOT EXISTS idx_invoices_created_at ON invoices(created_at);

-- Create indexes for subscriptions
CREATE INDEX IF NOT EXISTS idx_subscriptions_customer_email ON subscriptions(customer_email);
CREATE INDEX IF NOT EXISTS idx_subscriptions_status ON subscriptions(status);
CREATE INDEX IF NOT EXISTS idx_subscriptions_next_billing_date ON subscriptions(next_billing_date);
CREATE INDEX IF NOT EXISTS idx_subscriptions_created_at ON subscriptions(created_at);

-- Create indexes for receipts
CREATE INDEX IF NOT EXISTS idx_receipts_customer_email ON receipts(customer_email);
CREATE INDEX IF NOT EXISTS idx_receipts_payment_date ON receipts(payment_date);
CREATE INDEX IF NOT EXISTS idx_receipts_status ON receipts(status);
CREATE INDEX IF NOT EXISTS idx_receipts_invoice_id ON receipts(invoice_id);
CREATE INDEX IF NOT EXISTS idx_receipts_subscription_id ON receipts(subscription_id);

-- Functions to generate IDs
CREATE OR REPLACE FUNCTION generate_invoice_id()
RETURNS text AS $$
DECLARE
  next_id integer;
  new_id text;
BEGIN
  SELECT COUNT(*) + 1 INTO next_id FROM invoices;
  new_id := 'INV' || LPAD(next_id::text, 4, '0');
  WHILE EXISTS (SELECT 1 FROM invoices WHERE invoice_id = new_id) LOOP
    next_id := next_id + 1;
    new_id := 'INV' || LPAD(next_id::text, 4, '0');
  END LOOP;
  RETURN new_id;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION generate_subscription_id()
RETURNS text AS $$
DECLARE
  next_id integer;
  new_id text;
BEGIN
  SELECT COUNT(*) + 1 INTO next_id FROM subscriptions;
  new_id := 'SUB' || LPAD(next_id::text, 4, '0');
  WHILE EXISTS (SELECT 1 FROM subscriptions WHERE subscription_id = new_id) LOOP
    next_id := next_id + 1;
    new_id := 'SUB' || LPAD(next_id::text, 4, '0');
  END LOOP;
  RETURN new_id;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION generate_receipt_id()
RETURNS text AS $$
DECLARE
  next_id integer;
  new_id text;
BEGIN
  SELECT COUNT(*) + 1 INTO next_id FROM receipts;
  new_id := 'REC' || LPAD(next_id::text, 4, '0');
  WHILE EXISTS (SELECT 1 FROM receipts WHERE receipt_id = new_id) LOOP
    next_id := next_id + 1;
    new_id := 'REC' || LPAD(next_id::text, 4, '0');
  END LOOP;
  RETURN new_id;
END;
$$ LANGUAGE plpgsql;

-- Triggers to set IDs
CREATE OR REPLACE FUNCTION set_invoice_id()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.invoice_id IS NULL OR NEW.invoice_id = '' THEN
    NEW.invoice_id := generate_invoice_id();
  END IF;
  NEW.balance_due := NEW.total_amount - NEW.paid_amount;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION set_subscription_id()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.subscription_id IS NULL OR NEW.subscription_id = '' THEN
    NEW.subscription_id := generate_subscription_id();
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION set_receipt_id()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.receipt_id IS NULL OR NEW.receipt_id = '' THEN
    NEW.receipt_id := generate_receipt_id();
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_set_invoice_id ON invoices;
CREATE TRIGGER trigger_set_invoice_id
  BEFORE INSERT OR UPDATE ON invoices
  FOR EACH ROW
  EXECUTE FUNCTION set_invoice_id();

DROP TRIGGER IF EXISTS trigger_set_subscription_id ON subscriptions;
CREATE TRIGGER trigger_set_subscription_id
  BEFORE INSERT ON subscriptions
  FOR EACH ROW
  EXECUTE FUNCTION set_subscription_id();

DROP TRIGGER IF EXISTS trigger_set_receipt_id ON receipts;
CREATE TRIGGER trigger_set_receipt_id
  BEFORE INSERT ON receipts
  FOR EACH ROW
  EXECUTE FUNCTION set_receipt_id();

-- Triggers for updated_at
CREATE OR REPLACE FUNCTION update_invoices_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION update_subscriptions_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION update_receipts_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS update_invoices_updated_at_trigger ON invoices;
CREATE TRIGGER update_invoices_updated_at_trigger
  BEFORE UPDATE ON invoices
  FOR EACH ROW
  EXECUTE FUNCTION update_invoices_updated_at();

DROP TRIGGER IF EXISTS update_subscriptions_updated_at_trigger ON subscriptions;
CREATE TRIGGER update_subscriptions_updated_at_trigger
  BEFORE UPDATE ON subscriptions
  FOR EACH ROW
  EXECUTE FUNCTION update_subscriptions_updated_at();

DROP TRIGGER IF EXISTS update_receipts_updated_at_trigger ON receipts;
CREATE TRIGGER update_receipts_updated_at_trigger
  BEFORE UPDATE ON receipts
  FOR EACH ROW
  EXECUTE FUNCTION update_receipts_updated_at();

-- Enable RLS
ALTER TABLE invoices ENABLE ROW LEVEL SECURITY;
ALTER TABLE subscriptions ENABLE ROW LEVEL SECURITY;
ALTER TABLE receipts ENABLE ROW LEVEL SECURITY;

-- RLS policies for invoices
CREATE POLICY "Allow anonymous read access to invoices"
  ON invoices FOR SELECT TO anon USING (true);
CREATE POLICY "Allow anonymous insert access to invoices"
  ON invoices FOR INSERT TO anon WITH CHECK (true);
CREATE POLICY "Allow anonymous update access to invoices"
  ON invoices FOR UPDATE TO anon USING (true) WITH CHECK (true);
CREATE POLICY "Allow anonymous delete access to invoices"
  ON invoices FOR DELETE TO anon USING (true);

-- RLS policies for subscriptions
CREATE POLICY "Allow anonymous read access to subscriptions"
  ON subscriptions FOR SELECT TO anon USING (true);
CREATE POLICY "Allow anonymous insert access to subscriptions"
  ON subscriptions FOR INSERT TO anon WITH CHECK (true);
CREATE POLICY "Allow anonymous update access to subscriptions"
  ON subscriptions FOR UPDATE TO anon USING (true) WITH CHECK (true);
CREATE POLICY "Allow anonymous delete access to subscriptions"
  ON subscriptions FOR DELETE TO anon USING (true);

-- RLS policies for receipts
CREATE POLICY "Allow anonymous read access to receipts"
  ON receipts FOR SELECT TO anon USING (true);
CREATE POLICY "Allow anonymous insert access to receipts"
  ON receipts FOR INSERT TO anon WITH CHECK (true);
CREATE POLICY "Allow anonymous update access to receipts"
  ON receipts FOR UPDATE TO anon USING (true) WITH CHECK (true);
CREATE POLICY "Allow anonymous delete access to receipts"
  ON receipts FOR DELETE TO anon USING (true);

-- Comments
COMMENT ON TABLE invoices IS 'Table for managing customer invoices with line items and payment tracking';
COMMENT ON TABLE subscriptions IS 'Table for managing recurring subscriptions and billing cycles';
COMMENT ON TABLE receipts IS 'Table for managing payment receipts and transaction records';
COMMENT ON COLUMN invoices.balance_due IS 'Automatically calculated as total_amount - paid_amount';
COMMENT ON COLUMN subscriptions.next_billing_date IS 'Next scheduled billing date for active subscriptions';
COMMENT ON COLUMN receipts.payment_reference IS 'External payment reference (transaction ID, check number, etc)';