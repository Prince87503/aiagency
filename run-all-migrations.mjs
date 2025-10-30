import { createClient } from '@supabase/supabase-js';
import { readFileSync, readdirSync } from 'fs';
import { join } from 'path';

const supabaseUrl = process.env.VITE_SUPABASE_URL;
const supabaseKey = process.env.VITE_SUPABASE_ANON_KEY;

if (!supabaseUrl || !supabaseKey) {
  console.error('Error: Missing Supabase credentials in environment variables');
  process.exit(1);
}

const supabase = createClient(supabaseUrl, supabaseKey);

async function applyMigrations() {
  const migrationsDir = './supabase/migrations';
  const files = readdirSync(migrationsDir)
    .filter(f => f.endsWith('.sql'))
    .sort();

  console.log(`\n🚀 Starting migration process...`);
  console.log(`📊 Found ${files.length} migration files\n`);

  let successCount = 0;
  let errorCount = 0;
  const errors = [];

  for (const file of files) {
    try {
      const sql = readFileSync(join(migrationsDir, file), 'utf8');

      // Use the raw SQL execution via the REST API
      const response = await fetch(`${supabaseUrl}/rest/v1/rpc/exec_sql`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'apikey': supabaseKey,
          'Authorization': `Bearer ${supabaseKey}`
        },
        body: JSON.stringify({ query: sql })
      });

      if (!response.ok) {
        throw new Error(`HTTP ${response.status}: ${await response.text()}`);
      }

      console.log(`✅ ${file}`);
      successCount++;
    } catch (error) {
      console.log(`❌ ${file}`);
      console.log(`   Error: ${error.message}\n`);
      errorCount++;
      errors.push({ file, error: error.message });
    }
  }

  console.log('\n' + '='.repeat(70));
  console.log(`📈 Migration Summary:`);
  console.log(`   Total: ${files.length}`);
  console.log(`   ✅ Success: ${successCount}`);
  console.log(`   ❌ Errors: ${errorCount}`);
  console.log('='.repeat(70));

  if (errors.length > 0) {
    console.log('\n⚠️  Failed Migrations:');
    errors.forEach(({ file, error }) => {
      console.log(`\n  ${file}:`);
      console.log(`    ${error}`);
    });
  }

  process.exit(errorCount > 0 ? 1 : 0);
}

applyMigrations().catch(err => {
  console.error('Fatal error:', err);
  process.exit(1);
});
