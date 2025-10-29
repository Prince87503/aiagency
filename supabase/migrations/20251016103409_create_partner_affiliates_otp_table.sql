/*
  # Create Partner OTP Verifications Table
  
  1. New Tables
    - `partner_otp_verifications`
      - `id` (uuid, primary key)
      - `mobile` (text) - Mobile number for partner login
      - `otp` (text) - 4-digit OTP code
      - `verified` (boolean) - Whether OTP was verified
      - `expires_at` (timestamptz) - OTP expiration time (5 minutes)
      - `created_at` (timestamptz) - Creation timestamp
      - `verified_at` (timestamptz) - Verification timestamp
      - `affiliate_id` (uuid) - Reference to affiliate
  
  2. Security
    - Enable RLS on `partner_otp_verifications` table
    - Add policy for anonymous users to insert and verify OTPs
    - Link to affiliates table for authentication
  
  3. Indexes
    - Index on mobile for fast lookup
    - Index on expires_at for cleanup queries
*/

CREATE TABLE IF NOT EXISTS partner_otp_verifications (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  mobile text NOT NULL,
  otp text NOT NULL,
  verified boolean DEFAULT false,
  expires_at timestamptz NOT NULL,
  created_at timestamptz DEFAULT now(),
  verified_at timestamptz,
  affiliate_id uuid REFERENCES affiliates(id)
);

CREATE INDEX IF NOT EXISTS idx_partner_otp_mobile ON partner_otp_verifications(mobile);
CREATE INDEX IF NOT EXISTS idx_partner_otp_expires_at ON partner_otp_verifications(expires_at);

ALTER TABLE partner_otp_verifications ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Allow anonymous to insert partner OTP"
  ON partner_otp_verifications
  FOR INSERT
  TO anon
  WITH CHECK (true);

CREATE POLICY "Allow anonymous to select partner OTP"
  ON partner_otp_verifications
  FOR SELECT
  TO anon
  USING (true);

CREATE POLICY "Allow anonymous to update partner OTP"
  ON partner_otp_verifications
  FOR UPDATE
  TO anon
  USING (true)
  WITH CHECK (true);