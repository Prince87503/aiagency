/*
  # Create AI Agent Chat Memory Table

  1. New Tables
    - `ai_agent_chat_memory`
      - `id` (uuid, primary key)
      - `agent_id` (uuid, references ai_agents)
      - `phone_number` (text) - Phone number of the contact
      - `message` (text) - Chat message content
      - `role` (text) - Either 'user' or 'assistant'
      - `metadata` (jsonb) - Additional message metadata
      - `created_at` (timestamptz)
  
  2. Security
    - Enable RLS on `ai_agent_chat_memory` table
    - Add policy for authenticated admin users to manage chat memory
  
  3. Indexes
    - Index on agent_id for faster lookups
    - Index on phone_number for faster filtering
    - Composite index on (phone_number, created_at) for efficient cleanup
  
  4. Automatic Cleanup
    - Add trigger function to automatically delete old messages
    - Keep only the last 100 messages per phone number
    - Trigger fires after each insert
*/

CREATE TABLE IF NOT EXISTS ai_agent_chat_memory (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  agent_id uuid REFERENCES ai_agents(id) ON DELETE CASCADE,
  phone_number text NOT NULL,
  message text NOT NULL,
  role text NOT NULL CHECK (role IN ('user', 'assistant')),
  metadata jsonb DEFAULT '{}'::jsonb,
  created_at timestamptz DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_ai_agent_chat_memory_agent_id ON ai_agent_chat_memory(agent_id);
CREATE INDEX IF NOT EXISTS idx_ai_agent_chat_memory_phone ON ai_agent_chat_memory(phone_number);
CREATE INDEX IF NOT EXISTS idx_ai_agent_chat_memory_phone_created ON ai_agent_chat_memory(phone_number, created_at DESC);

ALTER TABLE ai_agent_chat_memory ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Admin users can manage chat memory"
  ON ai_agent_chat_memory
  FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM admin_users
      WHERE admin_users.id = auth.uid()
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM admin_users
      WHERE admin_users.id = auth.uid()
    )
  );

CREATE POLICY "Allow anon read access to chat memory"
  ON ai_agent_chat_memory
  FOR SELECT
  TO anon
  USING (true);

CREATE POLICY "Allow anon insert access to chat memory"
  ON ai_agent_chat_memory
  FOR INSERT
  TO anon
  WITH CHECK (true);

CREATE OR REPLACE FUNCTION cleanup_old_chat_messages()
RETURNS TRIGGER AS $$
BEGIN
  DELETE FROM ai_agent_chat_memory
  WHERE id IN (
    SELECT id
    FROM ai_agent_chat_memory
    WHERE phone_number = NEW.phone_number
    ORDER BY created_at DESC
    OFFSET 100
  );
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_cleanup_old_chat_messages
  AFTER INSERT ON ai_agent_chat_memory
  FOR EACH ROW
  EXECUTE FUNCTION cleanup_old_chat_messages();
