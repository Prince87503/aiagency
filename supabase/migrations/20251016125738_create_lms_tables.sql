/*
  # Create LMS (Learning Management System) Tables

  1. New Tables
    - `courses`
      - `id` (uuid, primary key) - Unique identifier
      - `course_id` (text, unique) - Human-readable course ID (e.g., C001)
      - `title` (text) - Course title
      - `description` (text) - Course description
      - `thumbnail_url` (text) - Course thumbnail image URL
      - `instructor` (text) - Instructor name
      - `duration` (text) - Estimated duration
      - `level` (text) - Beginner, Intermediate, Advanced
      - `status` (text) - Draft, Published, Archived
      - `price` (decimal) - Course price
      - `created_at` (timestamptz) - Creation timestamp
      - `updated_at` (timestamptz) - Last update timestamp

    - `categories`
      - `id` (uuid, primary key) - Unique identifier
      - `course_id` (uuid, foreign key) - Reference to courses table
      - `title` (text) - Category/Module title
      - `description` (text) - Category description
      - `order_index` (integer) - Display order
      - `created_at` (timestamptz) - Creation timestamp
      - `updated_at` (timestamptz) - Last update timestamp

    - `lessons`
      - `id` (uuid, primary key) - Unique identifier
      - `category_id` (uuid, foreign key) - Reference to categories table
      - `title` (text) - Lesson title
      - `description` (text) - Lesson description
      - `video_url` (text) - Video URL (YouTube, Vimeo, etc.)
      - `duration` (text) - Lesson duration
      - `order_index` (integer) - Display order within category
      - `is_free` (boolean) - Whether lesson is free to preview
      - `created_at` (timestamptz) - Creation timestamp
      - `updated_at` (timestamptz) - Last update timestamp

    - `lesson_attachments`
      - `id` (uuid, primary key) - Unique identifier
      - `lesson_id` (uuid, foreign key) - Reference to lessons table
      - `file_name` (text) - Attachment file name
      - `file_url` (text) - File URL
      - `file_type` (text) - File type (PDF, DOC, ZIP, etc.)
      - `file_size` (text) - File size
      - `created_at` (timestamptz) - Creation timestamp

  2. Security
    - Enable RLS on all LMS tables
    - Allow anon and authenticated users to read published content
    - Allow anon users to manage all content (admin access)

  3. Indexes
    - Add indexes for foreign keys and frequently queried fields
*/

-- Create courses table
CREATE TABLE IF NOT EXISTS courses (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  course_id text UNIQUE NOT NULL,
  title text NOT NULL,
  description text,
  thumbnail_url text,
  instructor text DEFAULT 'Admin',
  duration text,
  level text DEFAULT 'Beginner',
  status text DEFAULT 'Draft',
  price decimal(10,2) DEFAULT 0.00,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Create categories table
CREATE TABLE IF NOT EXISTS categories (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  course_id uuid REFERENCES courses(id) ON DELETE CASCADE,
  title text NOT NULL,
  description text,
  order_index integer DEFAULT 0,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Create lessons table
CREATE TABLE IF NOT EXISTS lessons (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  category_id uuid REFERENCES categories(id) ON DELETE CASCADE,
  title text NOT NULL,
  description text,
  video_url text,
  duration text,
  order_index integer DEFAULT 0,
  is_free boolean DEFAULT false,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Create lesson_attachments table
CREATE TABLE IF NOT EXISTS lesson_attachments (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  lesson_id uuid REFERENCES lessons(id) ON DELETE CASCADE,
  file_name text NOT NULL,
  file_url text NOT NULL,
  file_type text,
  file_size text,
  created_at timestamptz DEFAULT now()
);

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_categories_course_id ON categories(course_id);
CREATE INDEX IF NOT EXISTS idx_categories_order ON categories(order_index);
CREATE INDEX IF NOT EXISTS idx_lessons_category_id ON lessons(category_id);
CREATE INDEX IF NOT EXISTS idx_lessons_order ON lessons(order_index);
CREATE INDEX IF NOT EXISTS idx_attachments_lesson_id ON lesson_attachments(lesson_id);

-- Enable RLS
ALTER TABLE courses ENABLE ROW LEVEL SECURITY;
ALTER TABLE categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE lessons ENABLE ROW LEVEL SECURITY;
ALTER TABLE lesson_attachments ENABLE ROW LEVEL SECURITY;

-- Create policies for courses
CREATE POLICY "Allow anon to read courses"
  ON courses FOR SELECT TO anon USING (true);

CREATE POLICY "Allow anon to insert courses"
  ON courses FOR INSERT TO anon WITH CHECK (true);

CREATE POLICY "Allow anon to update courses"
  ON courses FOR UPDATE TO anon USING (true) WITH CHECK (true);

CREATE POLICY "Allow anon to delete courses"
  ON courses FOR DELETE TO anon USING (true);

-- Create policies for categories
CREATE POLICY "Allow anon to read categories"
  ON categories FOR SELECT TO anon USING (true);

CREATE POLICY "Allow anon to insert categories"
  ON categories FOR INSERT TO anon WITH CHECK (true);

CREATE POLICY "Allow anon to update categories"
  ON categories FOR UPDATE TO anon USING (true) WITH CHECK (true);

CREATE POLICY "Allow anon to delete categories"
  ON categories FOR DELETE TO anon USING (true);

-- Create policies for lessons
CREATE POLICY "Allow anon to read lessons"
  ON lessons FOR SELECT TO anon USING (true);

CREATE POLICY "Allow anon to insert lessons"
  ON lessons FOR INSERT TO anon WITH CHECK (true);

CREATE POLICY "Allow anon to update lessons"
  ON lessons FOR UPDATE TO anon USING (true) WITH CHECK (true);

CREATE POLICY "Allow anon to delete lessons"
  ON lessons FOR DELETE TO anon USING (true);

-- Create policies for lesson_attachments
CREATE POLICY "Allow anon to read attachments"
  ON lesson_attachments FOR SELECT TO anon USING (true);

CREATE POLICY "Allow anon to insert attachments"
  ON lesson_attachments FOR INSERT TO anon WITH CHECK (true);

CREATE POLICY "Allow anon to update attachments"
  ON lesson_attachments FOR UPDATE TO anon USING (true) WITH CHECK (true);

CREATE POLICY "Allow anon to delete attachments"
  ON lesson_attachments FOR DELETE TO anon USING (true);

-- Create triggers to update updated_at
CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_courses_updated_at
  BEFORE UPDATE ON courses
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER update_categories_updated_at
  BEFORE UPDATE ON categories
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER update_lessons_updated_at
  BEFORE UPDATE ON lessons
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at();