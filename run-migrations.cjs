#!/usr/bin/env node

const fs = require('fs');
const path = require('path');
const https = require('https');

// Read environment variables
const supabaseUrl = process.env.VITE_SUPABASE_URL;
const supabaseAnonKey = process.env.VITE_SUPABASE_ANON_KEY;

if (!supabaseUrl || !supabaseAnonKey) {
  console.error('Error: Missing VITE_SUPABASE_URL or VITE_SUPABASE_ANON_KEY');
  process.exit(1);
}

// Read all migration files
const migrationsDir = path.join(__dirname, 'supabase', 'migrations');
const migrationFiles = fs.readdirSync(migrationsDir)
  .filter(f => f.endsWith('.sql'))
  .sort();

console.log(`Found ${migrationFiles.length} migration files to apply\n`);

// Function to execute SQL via Supabase REST API
async function executeSql(sql) {
  return new Promise((resolve, reject) => {
    const urlObj = new URL(supabaseUrl);
    const options = {
      hostname: urlObj.hostname,
      path: '/rest/v1/rpc/exec_sql',
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'apikey': supabaseAnonKey,
        'Authorization': `Bearer ${supabaseAnonKey}`
      }
    };

    const req = https.request(options, (res) => {
      let data = '';
      res.on('data', chunk => data += chunk);
      res.on('end', () => {
        if (res.statusCode >= 200 && res.statusCode < 300) {
          resolve(data);
        } else {
          reject(new Error(`HTTP ${res.statusCode}: ${data}`));
        }
      });
    });

    req.on('error', reject);
    req.write(JSON.stringify({ query: sql }));
    req.end();
  });
}

// Apply migrations sequentially
async function applyMigrations() {
  let successCount = 0;
  let errorCount = 0;

  for (const file of migrationFiles) {
    try {
      console.log(`Applying: ${file}`);
      const sql = fs.readFileSync(path.join(migrationsDir, file), 'utf8');

      await executeSql(sql);
      console.log(`✓ Success: ${file}\n`);
      successCount++;
    } catch (error) {
      console.error(`✗ Error in ${file}:`);
      console.error(`  ${error.message}\n`);
      errorCount++;
      // Continue with next migration
    }
  }

  console.log('\n' + '='.repeat(60));
  console.log(`Migration Summary:`);
  console.log(`  Total: ${migrationFiles.length}`);
  console.log(`  Success: ${successCount}`);
  console.log(`  Errors: ${errorCount}`);
  console.log('='.repeat(60));
}

applyMigrations().catch(console.error);
