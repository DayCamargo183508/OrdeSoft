import * as admin from 'firebase-admin';
import pool from './config/db';
import { firestore } from './config/firebase';

async function syncCategories() {
  try {
    // Check if connected to Postgres
    await pool.query('SELECT NOW()');
    console.log("Connected to PostgreSQL");

    const snapshot = await firestore.collection('productos').get();
    const categoriesSet = new Set<string>();
    
    snapshot.forEach(doc => {
      const data = doc.data();
      if (data.categoria && typeof data.categoria === 'string') {
        categoriesSet.add(data.categoria.trim());
      }
    });

    const uniqueCategories = Array.from(categoriesSet);
    console.log(`Found ${uniqueCategories.length} unique categories in Firebase:`, uniqueCategories);

    for (const cat of uniqueCategories) {
      await pool.query(
        "INSERT INTO categorias (nombre) VALUES ($1) ON CONFLICT (nombre) DO NOTHING",
        [cat]
      );
    }
    
    console.log("Categorias sync completed successfully!");
  } catch (error) {
    console.error("Error syncing categories:", error);
  } finally {
    process.exit(0);
  }
}

syncCategories();
