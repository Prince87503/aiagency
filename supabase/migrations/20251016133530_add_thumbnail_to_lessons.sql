/*
  # Add Thumbnail URL to Lessons

  1. Changes
    - Add `thumbnail_url` column to `lessons` table for lesson preview images
    - This allows each lesson to have its own thumbnail/preview image

  2. Notes
    - Existing lessons will have NULL thumbnail_url by default
*/

-- Add thumbnail_url column to lessons table
DO $$ 
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'lessons' AND column_name = 'thumbnail_url'
  ) THEN
    ALTER TABLE lessons ADD COLUMN thumbnail_url text;
  END IF;
END $$;