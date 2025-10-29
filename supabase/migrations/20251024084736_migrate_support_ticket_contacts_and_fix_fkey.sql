/*
  # Migrate Support Ticket Contacts and Fix Foreign Key

  1. Changes
    - Migrate enrolled members referenced in support_tickets to contacts_master
    - Drop old foreign key constraint pointing to enrolled_members
    - Add new foreign key constraint pointing to contacts_master
  
  2. Data Migration
    - Insert missing contacts from enrolled_members into contacts_master
    - Preserve all contact data (full_name, email, phone)
    - Auto-generate contact_id for migrated contacts
  
  3. Security
    - Maintains referential integrity
    - Ensures contact_id references valid contacts in contacts_master table
*/

-- Migrate enrolled members referenced in support tickets to contacts_master
INSERT INTO contacts_master (
  id, 
  contact_id, 
  full_name, 
  email, 
  phone, 
  contact_type,
  status,
  created_at, 
  updated_at
)
SELECT 
  em.id,
  'CNT-' || EXTRACT(YEAR FROM NOW())::text || '-' || LPAD(((
    SELECT COUNT(*) 
    FROM contacts_master 
    WHERE contact_id LIKE 'CNT-' || EXTRACT(YEAR FROM NOW())::text || '-%'
  ) + ROW_NUMBER() OVER (ORDER BY em.created_at))::text, 3, '0'),
  em.full_name,
  em.email,
  em.phone,
  'Customer',
  'Active',
  em.created_at,
  em.updated_at
FROM enrolled_members em
WHERE em.id IN (
  SELECT DISTINCT contact_id 
  FROM support_tickets 
  WHERE contact_id IS NOT NULL
)
AND em.id NOT IN (SELECT id FROM contacts_master)
ON CONFLICT (id) DO NOTHING;

-- Drop the old foreign key constraint
ALTER TABLE support_tickets 
  DROP CONSTRAINT IF EXISTS support_tickets_enrolled_member_id_fkey;

-- Add new foreign key constraint pointing to contacts_master
ALTER TABLE support_tickets 
  ADD CONSTRAINT support_tickets_contact_id_fkey 
  FOREIGN KEY (contact_id) 
  REFERENCES contacts_master(id) 
  ON DELETE CASCADE;