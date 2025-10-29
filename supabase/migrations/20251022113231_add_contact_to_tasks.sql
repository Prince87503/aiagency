/*
  # Add Contact Field to Tasks Table

  1. Changes
    - Add `contact_id` column to tasks table (optional, references contacts_master)
    - Add `contact_name` column for display purposes
    - Add `contact_phone` column for easy reference
    - Create index for efficient contact-based task queries
    
  2. Purpose
    - Associate tasks with specific contacts
    - Enable contact-centric task management
    - Improve task organization and filtering by contact
*/

-- Add contact fields to tasks table
ALTER TABLE tasks 
ADD COLUMN IF NOT EXISTS contact_id uuid REFERENCES contacts_master(id) ON DELETE SET NULL,
ADD COLUMN IF NOT EXISTS contact_name text,
ADD COLUMN IF NOT EXISTS contact_phone text;

-- Create index for contact-based queries
CREATE INDEX IF NOT EXISTS idx_tasks_contact_id ON tasks(contact_id);
