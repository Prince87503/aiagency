/*
  # Create Products Master Table

  1. New Tables
    - `products`
      - `id` (uuid, primary key)
      - `product_id` (text, unique, human-readable ID like PROD001)
      - `product_name` (text, product name)
      - `product_type` (text, 'AI Automation Training' or 'AI Automation Agency Service')
      - `description` (text, product description)
      - `pricing_model` (text, 'One-Time', 'Recurring', 'Mixed')
      - `course_price` (numeric, for training products - one-time price)
      - `onboarding_fee` (numeric, for agency service - one-time setup fee)
      - `retainer_fee` (numeric, for agency service - monthly recurring fee)
      - `currency` (text, default 'INR')
      - `features` (jsonb, array of product features)
      - `duration` (text, course duration or service commitment period)
      - `is_active` (boolean, product availability)
      - `category` (text, product category/subcategory)
      - `thumbnail_url` (text, product image)
      - `sales_page_url` (text, sales/landing page URL)
      - `total_sales` (integer, default 0)
      - `total_revenue` (numeric, default 0)
      - `created_at` (timestamptz)
      - `updated_at` (timestamptz)

  2. Security
    - Enable RLS on `products` table
    - Add policy for anonymous users to read all products
    - Add policy for anonymous users to insert products
    - Add policy for anonymous users to update products
    - Add policy for anonymous users to delete products

  3. Indexes
    - Index on product_type for filtering by vertical
    - Index on is_active for filtering active products
    - Index on category for categorization
*/

-- Create products table
CREATE TABLE IF NOT EXISTS products (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  product_id text UNIQUE NOT NULL,
  product_name text NOT NULL,
  product_type text NOT NULL CHECK (product_type IN ('AI Automation Training', 'AI Automation Agency Service')),
  description text,
  pricing_model text NOT NULL CHECK (pricing_model IN ('One-Time', 'Recurring', 'Mixed')),
  course_price numeric(10, 2) DEFAULT 0,
  onboarding_fee numeric(10, 2) DEFAULT 0,
  retainer_fee numeric(10, 2) DEFAULT 0,
  currency text DEFAULT 'INR',
  features jsonb DEFAULT '[]'::jsonb,
  duration text,
  is_active boolean DEFAULT true,
  category text,
  thumbnail_url text,
  sales_page_url text,
  total_sales integer DEFAULT 0,
  total_revenue numeric(12, 2) DEFAULT 0,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_products_product_type ON products(product_type);
CREATE INDEX IF NOT EXISTS idx_products_is_active ON products(is_active);
CREATE INDEX IF NOT EXISTS idx_products_category ON products(category);

-- Create function to generate product ID
CREATE OR REPLACE FUNCTION generate_product_id()
RETURNS text AS $$
DECLARE
  next_id integer;
  new_product_id text;
BEGIN
  SELECT COUNT(*) + 1 INTO next_id FROM products;
  new_product_id := 'PROD' || LPAD(next_id::text, 3, '0');
  
  WHILE EXISTS (SELECT 1 FROM products WHERE product_id = new_product_id) LOOP
    next_id := next_id + 1;
    new_product_id := 'PROD' || LPAD(next_id::text, 3, '0');
  END LOOP;
  
  RETURN new_product_id;
END;
$$ LANGUAGE plpgsql;

-- Create trigger to auto-generate product_id
CREATE OR REPLACE FUNCTION set_product_id()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.product_id IS NULL OR NEW.product_id = '' THEN
    NEW.product_id := generate_product_id();
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_set_product_id ON products;
CREATE TRIGGER trigger_set_product_id
  BEFORE INSERT ON products
  FOR EACH ROW
  EXECUTE FUNCTION set_product_id();

-- Create function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_products_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS update_products_updated_at_trigger ON products;
CREATE TRIGGER update_products_updated_at_trigger
  BEFORE UPDATE ON products
  FOR EACH ROW
  EXECUTE FUNCTION update_products_updated_at();

-- Enable RLS
ALTER TABLE products ENABLE ROW LEVEL SECURITY;

-- Create RLS policies for anonymous access
CREATE POLICY "Allow anonymous read access to products"
  ON products
  FOR SELECT
  TO anon
  USING (true);

CREATE POLICY "Allow anonymous insert access to products"
  ON products
  FOR INSERT
  TO anon
  WITH CHECK (true);

CREATE POLICY "Allow anonymous update access to products"
  ON products
  FOR UPDATE
  TO anon
  USING (true)
  WITH CHECK (true);

CREATE POLICY "Allow anonymous delete access to products"
  ON products
  FOR DELETE
  TO anon
  USING (true);

-- Add comments
COMMENT ON TABLE products IS 'Master table for managing products across AI Automation Training and Agency Service verticals';
COMMENT ON COLUMN products.product_id IS 'Human-readable product ID (e.g., PROD001)';
COMMENT ON COLUMN products.product_type IS 'Product vertical: AI Automation Training or AI Automation Agency Service';
COMMENT ON COLUMN products.pricing_model IS 'Pricing structure: One-Time (training), Recurring (agency retainer), or Mixed (onboarding + retainer)';
COMMENT ON COLUMN products.course_price IS 'One-time price for training courses';
COMMENT ON COLUMN products.onboarding_fee IS 'One-time setup fee for agency services';
COMMENT ON COLUMN products.retainer_fee IS 'Monthly recurring fee for agency services';
COMMENT ON COLUMN products.features IS 'JSON array of product features/benefits';
COMMENT ON COLUMN products.duration IS 'Course duration or service commitment period';
COMMENT ON COLUMN products.total_sales IS 'Total number of units sold';
COMMENT ON COLUMN products.total_revenue IS 'Total revenue generated from this product';