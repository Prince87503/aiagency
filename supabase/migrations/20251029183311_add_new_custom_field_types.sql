/*
  # Add New Custom Field Types
  
  1. Changes
    - Update the field_type check constraint in custom_fields table
    - Add support for: number, email, phone, url, currency, longtext
    - Previous types: text, dropdown_single, dropdown_multiple, date
    - New types: number, email, phone, url, currency, longtext
    
  2. Field Types
    - number: For numeric values
    - email: For email addresses with validation
    - phone: For phone numbers
    - url: For website URLs
    - currency: For monetary values
    - longtext: For longer text entries (textarea)
  
  3. Notes
    - This migration safely adds new field types without affecting existing data
    - All existing fields with old types remain valid
*/

-- Drop the existing check constraint
ALTER TABLE custom_fields 
  DROP CONSTRAINT IF EXISTS custom_fields_field_type_check;

-- Add the updated check constraint with all field types
ALTER TABLE custom_fields 
  ADD CONSTRAINT custom_fields_field_type_check 
  CHECK (field_type IN (
    'text', 
    'dropdown_single', 
    'dropdown_multiple', 
    'date',
    'number',
    'email',
    'phone',
    'url',
    'currency',
    'longtext'
  ));