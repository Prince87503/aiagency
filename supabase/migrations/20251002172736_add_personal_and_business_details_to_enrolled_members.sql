/*
  # Add Personal and Business Details to Enrolled Members Table

  ## Overview
  This migration adds comprehensive personal and business detail fields to the enrolled_members table
  to match the Add Member form requirements.

  ## Changes
  
  ### Personal Details Fields Added:
  - `date_of_birth` (date) - Member's date of birth
  - `gender` (text) - Gender: 'Male', 'Female', 'Other'
  - `education_level` (text) - Education level: 'High School', 'Diploma', 'Graduate', 'Post Graduate'
  - `profession` (text) - Member's profession/occupation
  - `experience` (text) - Work experience: '0-1 years', '2+ years', '3+ years', '5+ years', '7+ years', '10+ years'

  ### Business Details Fields Added:
  - `business_name` (text) - Name of the member's business
  - `address` (text) - Complete business/residential address
  - `city` (text) - City name
  - `state` (text) - State name
  - `pincode` (text) - Postal/PIN code
  - `gst_number` (text) - GST registration number

  ## Indexes
  - Added index on `state` for faster filtering by location
  - Added index on `education_level` for analytics queries
  - Added index on `gender` for demographic analysis

  ## Notes
  - All new fields are optional (nullable) to allow gradual data migration
  - Existing records will have NULL values for these new fields
  - Fields match exactly with the frontend form structure
*/

-- Add Personal Details columns
DO $$
BEGIN
  -- Date of Birth
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'enrolled_members' AND column_name = 'date_of_birth'
  ) THEN
    ALTER TABLE enrolled_members ADD COLUMN date_of_birth date;
  END IF;

  -- Gender
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'enrolled_members' AND column_name = 'gender'
  ) THEN
    ALTER TABLE enrolled_members ADD COLUMN gender text;
  END IF;

  -- Education Level
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'enrolled_members' AND column_name = 'education_level'
  ) THEN
    ALTER TABLE enrolled_members ADD COLUMN education_level text;
  END IF;

  -- Profession
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'enrolled_members' AND column_name = 'profession'
  ) THEN
    ALTER TABLE enrolled_members ADD COLUMN profession text;
  END IF;

  -- Experience
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'enrolled_members' AND column_name = 'experience'
  ) THEN
    ALTER TABLE enrolled_members ADD COLUMN experience text;
  END IF;
END $$;

-- Add Business Details columns
DO $$
BEGIN
  -- Business Name
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'enrolled_members' AND column_name = 'business_name'
  ) THEN
    ALTER TABLE enrolled_members ADD COLUMN business_name text;
  END IF;

  -- Address
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'enrolled_members' AND column_name = 'address'
  ) THEN
    ALTER TABLE enrolled_members ADD COLUMN address text;
  END IF;

  -- City
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'enrolled_members' AND column_name = 'city'
  ) THEN
    ALTER TABLE enrolled_members ADD COLUMN city text;
  END IF;

  -- State
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'enrolled_members' AND column_name = 'state'
  ) THEN
    ALTER TABLE enrolled_members ADD COLUMN state text;
  END IF;

  -- Pincode
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'enrolled_members' AND column_name = 'pincode'
  ) THEN
    ALTER TABLE enrolled_members ADD COLUMN pincode text;
  END IF;

  -- GST Number
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'enrolled_members' AND column_name = 'gst_number'
  ) THEN
    ALTER TABLE enrolled_members ADD COLUMN gst_number text;
  END IF;
END $$;

-- Create indexes for frequently queried columns
CREATE INDEX IF NOT EXISTS idx_enrolled_members_state ON enrolled_members(state);
CREATE INDEX IF NOT EXISTS idx_enrolled_members_education_level ON enrolled_members(education_level);
CREATE INDEX IF NOT EXISTS idx_enrolled_members_gender ON enrolled_members(gender);
CREATE INDEX IF NOT EXISTS idx_enrolled_members_city ON enrolled_members(city);

-- Add comments for documentation
COMMENT ON COLUMN enrolled_members.date_of_birth IS 'Member''s date of birth';
COMMENT ON COLUMN enrolled_members.gender IS 'Gender: Male, Female, Other';
COMMENT ON COLUMN enrolled_members.education_level IS 'Education level: High School, Diploma, Graduate, Post Graduate';
COMMENT ON COLUMN enrolled_members.profession IS 'Member''s profession or occupation';
COMMENT ON COLUMN enrolled_members.experience IS 'Work experience: 0-1 years, 2+ years, 3+ years, 5+ years, 7+ years, 10+ years';
COMMENT ON COLUMN enrolled_members.business_name IS 'Name of the member''s business';
COMMENT ON COLUMN enrolled_members.address IS 'Complete business/residential address';
COMMENT ON COLUMN enrolled_members.city IS 'City name';
COMMENT ON COLUMN enrolled_members.state IS 'State name';
COMMENT ON COLUMN enrolled_members.pincode IS 'Postal/PIN code';
COMMENT ON COLUMN enrolled_members.gst_number IS 'GST registration number';
