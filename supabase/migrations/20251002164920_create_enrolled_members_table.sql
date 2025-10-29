/*
  # Create Enrolled Members Table

  ## Overview
  This migration creates a table to store enrolled members data for the platform.

  ## New Tables
  
  ### `enrolled_members`
  Stores information about members enrolled in courses or programs.
  
  #### Columns:
  - `id` (uuid, primary key) - Unique identifier for each enrolled member
  - `user_id` (uuid) - Reference to the user/member
  - `email` (text, not null) - Member's email address
  - `full_name` (text, not null) - Member's full name
  - `phone` (text) - Contact phone number
  - `enrollment_date` (timestamptz, not null) - Date when member enrolled
  - `status` (text, not null, default 'active') - Enrollment status: 'active', 'inactive', 'suspended', 'completed'
  - `course_id` (text) - Course or program identifier
  - `course_name` (text) - Name of the course/program enrolled in
  - `payment_status` (text, not null, default 'pending') - Payment status: 'pending', 'paid', 'refunded', 'failed'
  - `payment_amount` (numeric) - Amount paid for enrollment
  - `payment_date` (timestamptz) - Date of payment
  - `subscription_type` (text) - Type of subscription: 'monthly', 'yearly', 'lifetime', 'one-time'
  - `last_activity` (timestamptz) - Last activity timestamp
  - `progress_percentage` (integer, default 0) - Course completion progress (0-100)
  - `notes` (text) - Additional notes or comments
  - `created_at` (timestamptz) - Record creation timestamp
  - `updated_at` (timestamptz) - Last update timestamp

  ## Security
  
  1. Enable Row Level Security (RLS) on the table
  2. Create policies for authenticated users to manage enrolled members data
*/

-- Create enrolled_members table
CREATE TABLE IF NOT EXISTS enrolled_members (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid,
  email text NOT NULL,
  full_name text NOT NULL,
  phone text,
  enrollment_date timestamptz NOT NULL DEFAULT now(),
  status text NOT NULL DEFAULT 'active',
  course_id text,
  course_name text,
  payment_status text NOT NULL DEFAULT 'pending',
  payment_amount numeric,
  payment_date timestamptz,
  subscription_type text,
  last_activity timestamptz,
  progress_percentage integer DEFAULT 0 CHECK (progress_percentage >= 0 AND progress_percentage <= 100),
  notes text,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Create indexes for faster lookups
CREATE INDEX IF NOT EXISTS idx_enrolled_members_email ON enrolled_members(email);
CREATE INDEX IF NOT EXISTS idx_enrolled_members_user_id ON enrolled_members(user_id);
CREATE INDEX IF NOT EXISTS idx_enrolled_members_status ON enrolled_members(status);
CREATE INDEX IF NOT EXISTS idx_enrolled_members_enrollment_date ON enrolled_members(enrollment_date DESC);

-- Enable Row Level Security
ALTER TABLE enrolled_members ENABLE ROW LEVEL SECURITY;

-- Policy: Authenticated users can view all enrolled members
CREATE POLICY "Authenticated users can view enrolled members"
  ON enrolled_members
  FOR SELECT
  TO authenticated
  USING (true);

-- Policy: Authenticated users can insert new enrollments
CREATE POLICY "Authenticated users can insert enrollments"
  ON enrolled_members
  FOR INSERT
  TO authenticated
  WITH CHECK (true);

-- Policy: Authenticated users can update enrollments
CREATE POLICY "Authenticated users can update enrollments"
  ON enrolled_members
  FOR UPDATE
  TO authenticated
  USING (true)
  WITH CHECK (true);

-- Policy: Authenticated users can delete enrollments
CREATE POLICY "Authenticated users can delete enrollments"
  ON enrolled_members
  FOR DELETE
  TO authenticated
  USING (true);

-- Create function to automatically update updated_at timestamp
CREATE OR REPLACE FUNCTION update_enrolled_members_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger to call the function before update
DROP TRIGGER IF EXISTS update_enrolled_members_updated_at_trigger ON enrolled_members;
CREATE TRIGGER update_enrolled_members_updated_at_trigger
  BEFORE UPDATE ON enrolled_members
  FOR EACH ROW
  EXECUTE FUNCTION update_enrolled_members_updated_at();