const { createClient } = require('@supabase/supabase-js');
const fs = require('fs');
const path = require('path');

const supabaseUrl = process.env.VITE_SUPABASE_URL;
const supabaseKey = process.env.VITE_SUPABASE_ANON_KEY;

if (!supabaseUrl || !supabaseKey) {
  console.error('Error: Missing Supabase credentials');
  process.exit(1);
}

const supabase = createClient(supabaseUrl, supabaseKey);

async function applyMigrations() {
  const migrationsDir = path.join(__dirname, 'supabase', 'migrations');
  const files = fs.readdirSync(migrationsDir)
    .filter(f => f.endsWith('.sql'))
    .sort();

  console.log(`Found ${files.length} migration files`);

  for (const file of files) {
    try {
      console.log(`Applying: ${file}`);
      const sql = fs.readFileSync(path.join(migrationsDir, file), 'utf8');

      const { error } = await supabase.rpc('exec_sql', { query: sql });

      if (error) {
        console.error(`Error in ${file}:`, error.message);
        // Continue with other migrations
      } else {
        console.log(`✓ ${file} applied successfully`);
      }
    } catch (err) {
      console.error(`Exception in ${file}:`, err.message);
    }
  }

  console.log('\nMigrations complete!');
}

applyMigrations().catch(console.error);
