import pool from '../../config/db';

export interface DetalleComandaInput {
  producto_id: number;
  cantidad: number;
  precio_unitario: number;
  notas?: string;
  cuenta_id?: number;
  cliente_nombre?: string;
}

export const crearComandaTransaccional = async (mesa_id: number | null, tipo_orden: string, nombre_cliente: string | null, usuario_id: number, detalles: DetalleComandaInput[]) => {
  const client = await pool.connect();
  try {
    await client.query('BEGIN');

    // 1. Insertar cabecera de la comanda
    const comandaResult = await client.query(
      'INSERT INTO comandas (mesa_id, usuario_id, estado, total, tipo_orden, nombre_cliente) VALUES ($1, $2, $3, $4, $5, $6) RETURNING *',
      [mesa_id, usuario_id, 'pendiente', 0.00, tipo_orden, nombre_cliente]
    );
    const comandaId = comandaResult.rows[0].id;

    // 2. Insertar detalles y calcular total
    let totalComanda = 0;
    for (const detalle of detalles) {
      const subtotal = detalle.cantidad * detalle.precio_unitario;
      totalComanda += subtotal;

      await client.query(
        'INSERT INTO comanda_detalles (comanda_id, producto_id, cantidad, precio_unitario, subtotal, notas, cuenta_id, cliente_nombre) VALUES ($1, $2, $3, $4, $5, $6, $7, $8)',
        [comandaId, detalle.producto_id, detalle.cantidad, detalle.precio_unitario, subtotal, detalle.notas || null, detalle.cuenta_id || 1, detalle.cliente_nombre || 'Cliente 1']
      );
    }

    // 3. Actualizar total de la comanda
    await client.query(
      'UPDATE comandas SET total = $1 WHERE id = $2',
      [totalComanda, comandaId]
    );

    // 4. Cambiar estado de la mesa a ocupada (solo si hay mesa)
    if (mesa_id && tipo_orden === 'MESA') {
      await client.query(
        'UPDATE mesas SET estado = $1 WHERE id = $2',
        ['ocupada', mesa_id]
      );
    }

    await client.query('COMMIT');
    
    // Devolvemos la comanda actualizada
    const comandaFinal = await client.query('SELECT * FROM comandas WHERE id = $1', [comandaId]);
    const comanda = comandaFinal.rows[0];
    comanda.total = parseFloat(comanda.total);
    return comanda;
  } catch (error) {
    await client.query('ROLLBACK');
    throw error;
  } finally {
    client.release();
  }
};

export const agregarDetallesComandaTransaccional = async (comanda_id: number, detalles: DetalleComandaInput[]) => {
  const client = await pool.connect();
  try {
    await client.query('BEGIN');
    
    let totalAdicional = 0;
    for (const detalle of detalles) {
      const subtotal = detalle.cantidad * detalle.precio_unitario;
      totalAdicional += subtotal;

      await client.query(
        'INSERT INTO comanda_detalles (comanda_id, producto_id, cantidad, precio_unitario, subtotal, notas, cuenta_id, cliente_nombre) VALUES ($1, $2, $3, $4, $5, $6, $7, $8)',
        [comanda_id, detalle.producto_id, detalle.cantidad, detalle.precio_unitario, subtotal, detalle.notas || null, detalle.cuenta_id || 1, detalle.cliente_nombre || 'Cliente 1']
      );
    }

    await client.query(
      'UPDATE comandas SET total = total + $1 WHERE id = $2',
      [totalAdicional, comanda_id]
    );

    await client.query('COMMIT');
    
    const comandaFinal = await client.query('SELECT * FROM comandas WHERE id = $1', [comanda_id]);
    const comanda = comandaFinal.rows[0];
    comanda.total = parseFloat(comanda.total);
    return comanda;
  } catch (error) {
    await client.query('ROLLBACK');
    throw error;
  } finally {
    client.release();
  }
};

export const obtenerComandaPorId = async (id: number) => {
  // Cabecera
  const comandaResult = await pool.query(
    'SELECT c.*, m.numero as mesa_numero, u.nombre as mesero FROM comandas c LEFT JOIN mesas m ON c.mesa_id = m.id LEFT JOIN usuarios u ON c.usuario_id = u.id WHERE c.id = $1',
    [id]
  );
  if (comandaResult.rows.length === 0) return null;
  const comanda = comandaResult.rows[0];

  // Detalles
  const detallesResult = await pool.query(
    "SELECT d.*, p.nombre as producto_nombre FROM comanda_detalles d LEFT JOIN productos p ON d.producto_id = p.id WHERE d.comanda_id = $1 AND d.estado_pago = 'pendiente'",
    [id]
  );
  
  comanda.total = parseFloat(comanda.total);
  comanda.detalles = detallesResult.rows.map(d => ({
    ...d,
    precio_unitario: parseFloat(d.precio_unitario),
    subtotal: parseFloat(d.subtotal)
  }));
  return comanda;
};

export const obtenerComandasActivas = async () => {
  const result = await pool.query(
    'SELECT c.*, m.numero as mesa_numero, u.nombre as mesero FROM comandas c LEFT JOIN mesas m ON c.mesa_id = m.id LEFT JOIN usuarios u ON c.usuario_id = u.id WHERE c.estado != $1 ORDER BY c.created_at DESC',
    ['pagado']
  );
  return result.rows.map(c => ({
    ...c,
    total: parseFloat(c.total)
  }));
};

export const obtenerComandasParaLlevar = async () => {
  const result = await pool.query(
    `SELECT c.*, u.nombre as mesero 
     FROM comandas c 
     LEFT JOIN usuarios u ON c.usuario_id = u.id 
     WHERE c.tipo_orden = $1 AND c.estado NOT IN ($2, $3) 
     ORDER BY c.created_at DESC`,
    ['PARA_LLEVAR', 'pagado', 'cancelado']
  );

  const comandas = await Promise.all(result.rows.map(async (c) => {
    const detallesResult = await pool.query(
      "SELECT d.*, p.nombre as producto_nombre FROM comanda_detalles d LEFT JOIN productos p ON d.producto_id = p.id WHERE d.comanda_id = $1 AND d.estado_pago = 'pendiente'",
      [c.id]
    );
    
    return {
      ...c,
      total: parseFloat(c.total),
      detalles: detallesResult.rows.map(d => ({
        ...d,
        precio_unitario: parseFloat(d.precio_unitario),
        subtotal: parseFloat(d.subtotal)
      }))
    };
  }));

  return comandas;
};

export const pagarComanda = async (comanda_id: number) => {
  const client = await pool.connect();
  try {
    await client.query('BEGIN');

    // Cambiar estado de la comanda a pagado
    const comandaResult = await client.query(
      'UPDATE comandas SET estado = $1 WHERE id = $2 RETURNING *',
      ['pagado', comanda_id]
    );
    
    if (comandaResult.rows.length === 0) {
      throw new Error('Comanda no encontrada');
    }
    
    const mesaId = comandaResult.rows[0].mesa_id;

    // Cambiar estado de la mesa a libre
    await client.query(
      'UPDATE mesas SET estado = $1 WHERE id = $2',
      ['libre', mesaId]
    );

    await client.query('COMMIT');
    return comandaResult.rows[0];
  } catch (error) {
    await client.query('ROLLBACK');
    throw error;
  } finally {
    client.release();
  }
};

export const obtenerTicketCocina = async (comanda_id: number) => {
  const cabeceraQuery = await pool.query(
    'SELECT m.numero as mesa_numero, u.nombre as mesero FROM comandas c JOIN mesas m ON c.mesa_id = m.id JOIN usuarios u ON c.usuario_id = u.id WHERE c.id = $1',
    [comanda_id]
  );
  if (cabeceraQuery.rows.length === 0) return null;
  const cabecera = cabeceraQuery.rows[0];

  const detallesQuery = await pool.query(
    `SELECT d.cantidad, p.nombre as producto, d.notas 
     FROM comanda_detalles d 
     JOIN productos p ON d.producto_id = p.id 
     WHERE d.comanda_id = $1 AND p.tipo = 'comida'`,
    [comanda_id]
  );

  return { cabecera, detalles: detallesQuery.rows };
};

export const pagarCuenta = async (comanda_id: number, cuenta_id: number) => {
  const client = await pool.connect();
  try {
    await client.query('BEGIN');

    // Marcar los items de la cuenta como pagados
    await client.query(
      "UPDATE comanda_detalles SET estado_pago = 'pagado' WHERE comanda_id = $1 AND cuenta_id = $2 AND estado_pago = 'pendiente'",
      [comanda_id, cuenta_id]
    );

    // Verificar si quedan pendientes
    const pendientesRes = await client.query(
      "SELECT COUNT(*) FROM comanda_detalles WHERE comanda_id = $1 AND estado_pago = 'pendiente'",
      [comanda_id]
    );

    const pendientes = parseInt(pendientesRes.rows[0].count, 10);
    
    if (pendientes === 0) {
      // Liberar mesa y cerrar comanda
      const comandaResult = await client.query(
        "UPDATE comandas SET estado = 'pagado' WHERE id = $1 RETURNING *",
        [comanda_id]
      );
      
      const mesaId = comandaResult.rows[0]?.mesa_id;
      if (mesaId) {
        await client.query("UPDATE mesas SET estado = 'libre' WHERE id = $1", [mesaId]);
      }
      
      await client.query('COMMIT');
      return { mesaDesocupada: true, restantes: 0 };
    } else {
      await client.query('COMMIT');
      return { mesaDesocupada: false, restantes: pendientes };
    }
  } catch (error) {
    await client.query('ROLLBACK');
    throw error;
  } finally {
    client.release();
  }
};
