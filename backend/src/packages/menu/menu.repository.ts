import pool from '../../config/db';
import { firestore } from '../../config/firebase';
import { Query } from 'firebase-admin/firestore';

// --- CATEGORIAS ---
export const getCategorias = async () => {
  const result = await pool.query('SELECT id, nombre FROM categorias WHERE activa = true ORDER BY nombre ASC');
  return result.rows;
};

export const createCategoria = async (nombre: string) => {
  const result = await pool.query(
    'INSERT INTO categorias (nombre) VALUES ($1) RETURNING *',
    [nombre]
  );
  return result.rows[0];
};

export const deleteCategoria = async (id: number) => {
  const client = await pool.connect();
  try {
    await client.query('BEGIN');
    await client.query('UPDATE productos SET disponible = false WHERE categoria_id = $1', [id]);
    const res = await client.query('UPDATE categorias SET activa = false WHERE id = $1 RETURNING *', [id]);
    await client.query('COMMIT');
    return res.rows[0];
  } catch (error) {
    await client.query('ROLLBACK');
    throw error;
  } finally {
    client.release();
  }
};

export const updateCategoria = async (id: number, nombre: string) => {
  const result = await pool.query(
    'UPDATE categorias SET nombre = $1 WHERE id = $2 RETURNING *',
    [nombre, id]
  );
  return result.rows[0];
};

// --- PRODUCTOS (Firebase Firestore) ---
export const getProductos = async (incluirInactivos: boolean = false) => {
  // Obtenemos todas las categorías de Postgres para cruzar los nombres (Join manual)
  const catResult = await pool.query('SELECT id, nombre FROM categorias');
  const categoriasMap = new Map();
  catResult.rows.forEach((c: any) => categoriasMap.set(String(c.id), c.nombre));

  if (!firestore) throw new Error('Firestore no está inicializado. Verifica firebase-key.json');

  let query: Query = firestore.collection('productos');
  if (!incluirInactivos) {
    query = query.where('disponible', '==', true);
  }

  const snapshot = await query.get();
  const productos = snapshot.docs.map((doc: any) => {
    const data = doc.data();
    return {
      id: doc.id,
      ...data,
      categoria_nombre: categoriasMap.get(String(data.categoria_id)) || data.categoria || 'Sin categoría'
    };
  });
  
  return productos.sort((a: any, b: any) => (a.created_at || '').localeCompare(b.created_at || ''));
};

export const getProductosByCategoria = async (categoria_id: number) => {
  const catResult = await pool.query('SELECT nombre FROM categorias WHERE id = $1', [categoria_id]);
  const categoria_nombre = catResult.rows.length > 0 ? catResult.rows[0].nombre : 'Sin categoría';

  if (!firestore) throw new Error('Firestore no está inicializado.');

  const snapshot = await firestore.collection('productos')
    .where('categoria_id', '==', categoria_id)
    .where('disponible', '==', true)
    .get();

  return snapshot.docs.map((doc: any) => ({
    id: doc.id,
    ...doc.data(),
    categoria_nombre
  }));
};

export const createProducto = async (categoria_id: number, nombre: string, descripcion: string, precio: number) => {
  if (!firestore) throw new Error('Firestore no está inicializado.');
  const newRef = firestore.collection('productos').doc();
  const data = {
    categoria_id,
    nombre,
    descripcion,
    precio,
    disponible: true,
    created_at: new Date().toISOString()
  };
  await newRef.set(data);
  return { id: newRef.id, ...data };
};

export const updateProducto = async (id: string, data: any) => {
  if (!firestore) throw new Error('Firestore no está inicializado.');
  const docRef = firestore.collection('productos').doc(id);
  const doc = await docRef.get();
  if (!doc.exists) return null;

  await docRef.update(data);
  const updated = await docRef.get();
  return { id: updated.id, ...updated.data() };
};

export const deleteProducto = async (id: string) => {
  if (!firestore) throw new Error('Firestore no está inicializado.');
  const docRef = firestore.collection('productos').doc(id);
  const doc = await docRef.get();
  if (!doc.exists) return null;
  
  const data = doc.data();
  await docRef.delete();
  
  // Opcional: Eliminar referencias en postgres comanda_detalles (aquí id es string)
  await pool.query('DELETE FROM comanda_detalles WHERE producto_id = $1', [id]);
  
  return { id, ...data };
};

export const updateEstadoProducto = async (id: string, disponible: boolean) => {
  return await updateProducto(id, { disponible });
};
