import { initializeApp, cert, getApps } from 'firebase-admin/app';
import { getFirestore } from 'firebase-admin/firestore';
import path from 'path';
import fs from 'fs';

const keyPath = path.resolve(process.cwd(), 'firebase-key.json');

if (!fs.existsSync(keyPath)) {
  console.error(`❌ ERROR: No se encontró el archivo en: ${keyPath}`);
  console.error(`Verifica que 'firebase-key.json' esté en la raíz de la carpeta backend.`);
} else {
  try {
    const serviceAccount = JSON.parse(fs.readFileSync(keyPath, 'utf8'));

    if (!getApps().length) {
      initializeApp({
        credential: cert(serviceAccount),
      });
      console.log('🔥 Firebase Admin SDK conectado correctamente');
    }
  } catch (error) {
    console.error('❌ Error al inicializar Firebase Admin:', error);
  }
}

export const firestore = getApps().length ? getFirestore() : (null as any);
