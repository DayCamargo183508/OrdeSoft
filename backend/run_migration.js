const pool = require('./src/config/db').default || require('./src/config/db');

async function runMigration() {
  try {
    console.log('Running migration...');
    await pool.query('ALTER TABLE categorias ADD COLUMN IF NOT EXISTS activa BOOLEAN DEFAULT true;');
    console.log('Migration successful: Column activa added to categorias.');
    process.exit(0);
  } catch (error) {
    console.error('Migration failed:', error);
    process.exit(1);
  }
}

runMigration();
