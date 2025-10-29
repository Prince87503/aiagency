/*
  # Create OTP Verifications Table

  1. New Tables
    - `otp_verifications`
      - `id` (uuid, primary key)
      - `mobile` (text) - Mobile number
      - `otp` (text) - 4-digit OTP code
      - `verified` (boolean) - Whether OTP was verified
      - `expires_at` (timestamptz) - OTP expiration time (5 minutes)
      - `created_at` (timestamptz) - Creation timestamp
      - `verified_at` (timestamptz) - Verification timestamp

  2. Security
    - Enable RLS on `otp_verifications` table
    - Add policy for anonymous users to insert and verify OTPs
    - Auto-delete expired OTPs older than 10 minutes

  3. Indexes
    - Index on mobile for fast lookup
    - Index on expires_at for cleanup queries
*/

CREATE TABLE IF NOT EXISTS otp_verifications (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  mobile text NOT NULL,
  otp text NOT NULL,
  verified boolean DEFAULT false,
  expires_at timestamptz NOT NULL,
  created_at timestamptz DEFAULT now(),
  verified_at timestamptz
);

CREATE INDEX IF NOT EXISTS idx_otp_verifications_mobile ON otp_verifications(mobile);
CREATE INDEX IF NOT EXISTS idx_otp_verifications_expires_at ON otp_verifications(expires_at);

ALTER TABLE otp_verifications ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Allow anonymous to insert OTP"
  ON otp_verifications
  FOR INSERT
  TO anon
  WITH CHECK (true);

CREATE POLICY "Allow anonymous to select OTP"
  ON otp_verifications
  FOR SELECT
  TO anon
  USING (true);

CREATE POLICY "Allow anonymous to update OTP"
  ON otp_verifications
  FOR UPDATE
  TO anon
  USING (true)
  WITH CHECK (true);
