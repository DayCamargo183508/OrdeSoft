import pool from '../../config/db';

export const getMesas = async () => {
  const result = await pool.query(`
    SELECT 
        m.id, 
        m.numero, 
        m.capacidad, 
        m.estado, 
        m.mesa_padre_id,
        (SELECT numero FROM mesas WHERE id = m.mesa_padre_id) as numero_padre,
        COALESCE(m.mesa_padre_id, m.id) as grupo_id
    FROM mesas m 
    ORDER BY m.numero ASC
  `);
  return result.rows;
};

export const createMesa = async (capacidad: number) => {
  const configRes = await pool.query('SELECT max_mesas FROM configuraciones LIMIT 1');
  const maxMesas = configRes.rows.length > 0 ? parseInt(configRes.rows[0].max_mesas, 10) : 30;

  const queryResult = await pool.query('SELECT numero FROM mesas;');
  
  if (queryResult.rows.length >= maxMesas) {
    throw new Error(`No se pueden crear más mesas. El máximo permitido es ${maxMesas}.`);
  }

  const numeros = queryResult.rows
    .map(r => parseInt(String(r.numero).replace(/\D/g, ''), 10))
    .filter(n => !isNaN(n));
  const maxNumero = numeros.length > 0 ? Math.max(...numeros) : 0;
  const siguienteNumero = maxNumero + 1;

  const result = await pool.query(
    `INSERT INTO mesas (numero, estado, capacidad, mesa_padre_id)
     VALUES ($1, $2, $3, NULL)
     RETURNING *;`,
    [siguienteNumero.toString(), 'libre', capacidad]
  );
  return result.rows[0];
};

export const updateEstadoMesa = async (id: number, estado: string) => {
  const result = await pool.query(
    'UPDATE mesas SET estado = $1 WHERE id = $2 RETURNING *',
    [estado, id]
  );
  return result.rows[0];
};

export const getTotalMesas = async () => {
  const result = await pool.query('SELECT COUNT(*) FROM mesas');
  return parseInt(result.rows[0].count, 10);
};

export const deleteUltimaMesa = async () => {
  const configRes = await pool.query('SELECT min_mesas FROM configuraciones LIMIT 1');
  const minMesas = configRes.rows.length > 0 ? parseInt(configRes.rows[0].min_mesas, 10) : 1;

  const queryResult = await pool.query('SELECT id, numero FROM mesas;');
  const filas = queryResult.rows;
  
  if (filas.length <= minMesas) {
    throw new Error(`No se pueden eliminar más mesas. El mínimo permitido es ${minMesas}.`);
  }

  let maxNumero = -1;
  let idToDelete = null;

  for (const fila of filas) {
    const num = parseInt(String(fila.numero).replace(/\\D/g, ''), 10);
    if (!isNaN(num) && num > maxNumero) {
      maxNumero = num;
      idToDelete = fila.id;
    }
  }

  if (idToDelete === null) return null;

  // 1. Validar si hay comandas activas en la mesa a eliminar
  const comandasActivas = await pool.query(
    "SELECT id FROM comandas WHERE mesa_id = $1 AND estado IN ('abierta', 'pendiente', 'en_proceso') LIMIT 1",
    [idToDelete]
  );
  
  if (comandasActivas.rows.length > 0) {
    throw new Error('No se puede eliminar la mesa porque tiene un pedido activo.');
  }

  // 2. Transacción: desvincular histórico y eliminar mesa
  await pool.query('BEGIN');
  try {
    await pool.query('UPDATE mesas SET mesa_padre_id = NULL WHERE mesa_padre_id = $1;', [idToDelete]);
    await pool.query('UPDATE comandas SET mesa_id = NULL WHERE mesa_id = $1;', [idToDelete]);
    const result = await pool.query('DELETE FROM mesas WHERE id = $1 RETURNING *;', [idToDelete]);
    await pool.query('COMMIT');
    return result.rows[0];
  } catch (error) {
    await pool.query('ROLLBACK');
    throw error;
  }
};

export const juntarMesas = async (mesaHijaId: number, mesaPadreId: number) => {
  const padreResult = await pool.query('SELECT mesa_padre_id FROM mesas WHERE id = $1', [mesaPadreId]);
  let rootPadreId = mesaPadreId;
  if (padreResult.rows.length > 0 && padreResult.rows[0].mesa_padre_id) {
    rootPadreId = padreResult.rows[0].mesa_padre_id;
  }
  const result = await pool.query(
    `UPDATE mesas SET mesa_padre_id = $1, estado = 'ocupada' WHERE id = $2 RETURNING *`,
    [rootPadreId, mesaHijaId]
  );
  return result.rows[0];
};

export const separarMesa = async (mesaId: number) => {
  const result = await pool.query(
    `UPDATE mesas SET mesa_padre_id = NULL, estado = 'libre' WHERE id = $1 RETURNING *`,
    [mesaId]
  );
  await pool.query(
    `UPDATE mesas SET mesa_padre_id = NULL, estado = 'libre' WHERE mesa_padre_id = $1`,
    [mesaId]
  );
  return result.rows[0];
};
