/*
  # Create Support Tickets Table

  1. New Tables
    - `support_tickets`
      - `id` (uuid, primary key) - Unique identifier for each ticket
      - `ticket_id` (text, unique) - Human-readable ticket ID (e.g., TKT-2024-001)
      - `enrolled_member_id` (uuid, foreign key) - References enrolled_members table
      - `subject` (text) - Ticket subject
      - `description` (text) - Detailed description of the issue
      - `priority` (text) - Priority level (Low, Medium, High, Critical)
      - `status` (text) - Ticket status (Open, In Progress, Resolved, Closed, Escalated)
      - `category` (text) - Category (Technical, Billing, Course, Refund, Feature Request, General)
      - `assigned_to` (text) - Name of the agent assigned to the ticket
      - `response_time` (text) - Response time duration
      - `satisfaction` (integer) - Customer satisfaction rating (1-5)
      - `tags` (jsonb) - Array of tags
      - `created_at` (timestamptz) - When the ticket was created
      - `updated_at` (timestamptz) - When the ticket was last updated
  
  2. Security
    - Enable RLS on `support_tickets` table
    - Add policies for anon and authenticated users to read, insert, update, and delete records
    - This enables the Support page to manage customer support tickets
  
  3. Indexes
    - Add index on enrolled_member_id for fast lookups
    - Add index on ticket_id for unique ticket ID lookups
    - Add index on status for filtering by ticket status
*/

-- Create support_tickets table
CREATE TABLE IF NOT EXISTS support_tickets (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  ticket_id text UNIQUE NOT NULL,
  enrolled_member_id uuid NOT NULL REFERENCES enrolled_members(id) ON DELETE CASCADE,
  subject text NOT NULL,
  description text NOT NULL,
  priority text DEFAULT 'Medium',
  status text DEFAULT 'Open',
  category text DEFAULT 'General',
  assigned_to text,
  response_time text,
  satisfaction integer CHECK (satisfaction >= 1 AND satisfaction <= 5),
  tags jsonb DEFAULT '[]'::jsonb,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Create indexes for faster lookups
CREATE INDEX IF NOT EXISTS idx_support_tickets_enrolled_member_id 
  ON support_tickets(enrolled_member_id);

CREATE INDEX IF NOT EXISTS idx_support_tickets_ticket_id 
  ON support_tickets(ticket_id);

CREATE INDEX IF NOT EXISTS idx_support_tickets_status 
  ON support_tickets(status);

-- Enable RLS
ALTER TABLE support_tickets ENABLE ROW LEVEL SECURITY;

-- Create policies for anon access
CREATE POLICY "Allow anon to read support tickets"
  ON support_tickets
  FOR SELECT
  TO anon
  USING (true);

CREATE POLICY "Allow authenticated to read support tickets"
  ON support_tickets
  FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Allow anon to insert support tickets"
  ON support_tickets
  FOR INSERT
  TO anon
  WITH CHECK (true);

CREATE POLICY "Allow authenticated to insert support tickets"
  ON support_tickets
  FOR INSERT
  TO authenticated
  WITH CHECK (true);

CREATE POLICY "Allow anon to update support tickets"
  ON support_tickets
  FOR UPDATE
  TO anon
  USING (true)
  WITH CHECK (true);

CREATE POLICY "Allow authenticated to update support tickets"
  ON support_tickets
  FOR UPDATE
  TO authenticated
  USING (true)
  WITH CHECK (true);

CREATE POLICY "Allow anon to delete support tickets"
  ON support_tickets
  FOR DELETE
  TO anon
  USING (true);

CREATE POLICY "Allow authenticated to delete support tickets"
  ON support_tickets
  FOR DELETE
  TO authenticated
  USING (true);

-- Create trigger to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_support_tickets_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_support_tickets_updated_at_trigger
  BEFORE UPDATE ON support_tickets
  FOR EACH ROW
  EXECUTE FUNCTION update_support_tickets_updated_at();
