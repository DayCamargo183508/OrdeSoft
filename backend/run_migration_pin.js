const pool = require('./src/config/db').default || require('./src/config/db');

async function runMigration() {
  try {
    console.log('Running migration...');
    await pool.query('ALTER TABLE usuarios ALTER COLUMN pin_hash TYPE VARCHAR(255);');
    console.log('Migration successful: Column pin_hash altered to VARCHAR(255).');
    process.exit(0);
  } catch (error) {
    console.error('Migration failed:', error);
    process.exit(1);
  }
}

runMigration();
