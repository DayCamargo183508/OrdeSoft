import pool from '../../config/db';

// --- CATEGORIAS ---
export const getCategorias = async () => {
  const result = await pool.query('SELECT * FROM categorias WHERE activa = true ORDER BY nombre ASC');
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

// --- PRODUCTOS ---
export const getProductos = async (incluirInactivos: boolean = false) => {
  let query = `
    SELECT p.*, c.nombre as categoria_nombre 
    FROM productos p 
    LEFT JOIN categorias c ON p.categoria_id = c.id 
  `;
  if (!incluirInactivos) {
    query += ` WHERE p.disponible = true`;
  }
  query += ` ORDER BY p.id ASC`;
  const result = await pool.query(query);
  return result.rows;
};

export const getProductosByCategoria = async (categoria_id: number) => {
  const query = `
    SELECT p.*, c.nombre as categoria_nombre 
    FROM productos p 
    LEFT JOIN categorias c ON p.categoria_id = c.id 
    WHERE p.categoria_id = $1 AND p.disponible = true
    ORDER BY p.nombre ASC
  `;
  const result = await pool.query(query, [categoria_id]);
  return result.rows;
};

export const createProducto = async (categoria_id: number, nombre: string, descripcion: string, precio: number) => {
  const result = await pool.query(
    'INSERT INTO productos (categoria_id, nombre, descripcion, precio) VALUES ($1, $2, $3, $4) RETURNING *',
    [categoria_id, nombre, descripcion, precio]
  );
  return result.rows[0];
};

export const updateProducto = async (id: number, data: { categoria_id?: number, nombre?: string, descripcion?: string, precio?: number, disponible?: boolean }) => {
  const updates = [];
  const values = [];
  let index = 1;

  if (data.categoria_id !== undefined) {
    updates.push(`categoria_id = $${index++}`);
    values.push(data.categoria_id);
  }
  if (data.nombre !== undefined) {
    updates.push(`nombre = $${index++}`);
    values.push(data.nombre);
  }
  if (data.descripcion !== undefined) {
    updates.push(`descripcion = $${index++}`);
    values.push(data.descripcion);
  }
  if (data.precio !== undefined) {
    updates.push(`precio = $${index++}`);
    values.push(data.precio);
  }
  if (data.disponible !== undefined) {
    updates.push(`disponible = $${index++}`);
    values.push(data.disponible);
  }

  if (updates.length === 0) return null;

  values.push(id);
  const query = `UPDATE productos SET ${updates.join(', ')} WHERE id = $${index} RETURNING *`;
  
  const result = await pool.query(query, values);
  return result.rows[0];
};

export const deleteProducto = async (id: number) => {
  const client = await pool.connect();
  try {
    await client.query('BEGIN');
    await client.query('DELETE FROM comanda_detalles WHERE producto_id = $1', [id]);
    const result = await client.query('DELETE FROM productos WHERE id = $1 RETURNING *', [id]);
    await client.query('COMMIT');
    return result.rows[0];
  } catch (error) {
    await client.query('ROLLBACK');
    throw error;
  } finally {
    client.release();
  }
};

export const updateEstadoProducto = async (id: number, disponible: boolean) => {
  const result = await pool.query('UPDATE productos SET disponible = $1 WHERE id = $2 RETURNING *', [disponible, id]);
  return result.rows[0];
};
