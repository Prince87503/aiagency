/*
  # Update WhatsApp Config RLS for Anonymous Access

  1. Changes
    - Drop existing restrictive policies
    - Add policies allowing anonymous users to manage WhatsApp configuration
    - This matches the pattern used in other tables like admin_users and enrolled_members

  2. Security
    - Allow anonymous read access for WhatsApp configuration
    - Allow anonymous insert access for WhatsApp configuration
    - Allow anonymous update access for WhatsApp configuration
    - Allow anonymous delete access for WhatsApp configuration
*/

DROP POLICY IF EXISTS "Admin users can view WhatsApp config" ON whatsapp_config;
DROP POLICY IF EXISTS "Admin users can insert WhatsApp config" ON whatsapp_config;
DROP POLICY IF EXISTS "Admin users can update WhatsApp config" ON whatsapp_config;
DROP POLICY IF EXISTS "Admin users can delete WhatsApp config" ON whatsapp_config;

CREATE POLICY "Anyone can view WhatsApp config"
  ON whatsapp_config
  FOR SELECT
  TO anon, authenticated
  USING (true);

CREATE POLICY "Anyone can insert WhatsApp config"
  ON whatsapp_config
  FOR INSERT
  TO anon, authenticated
  WITH CHECK (true);

CREATE POLICY "Anyone can update WhatsApp config"
  ON whatsapp_config
  FOR UPDATE
  TO anon, authenticated
  USING (true)
  WITH CHECK (true);

CREATE POLICY "Anyone can delete WhatsApp config"
  ON whatsapp_config
  FOR DELETE
  TO anon, authenticated
  USING (true);