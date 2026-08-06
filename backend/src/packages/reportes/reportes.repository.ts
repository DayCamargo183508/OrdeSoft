import pool from '../../config/db';

export const getVentasHoy = async () => {
  const query = `
    SELECT COALESCE(SUM(total), 0) as total_ingresos, COUNT(id) as total_comandas
    FROM comandas
    WHERE estado = 'pagado' AND DATE(created_at) = CURRENT_DATE
  `;
  const result = await pool.query(query);
  return result.rows[0];
};

export const getProductosMasVendidosHoy = async () => {
  const query = `
    SELECT p.nombre, SUM(d.cantidad) as total_vendido
    FROM comanda_detalles d
    JOIN comandas c ON d.comanda_id = c.id
    JOIN productos p ON d.producto_id = p.id
    WHERE c.estado = 'pagado' AND DATE(c.created_at) = CURRENT_DATE
    GROUP BY p.id, p.nombre
    ORDER BY total_vendido DESC
    LIMIT 10
  `;
  const result = await pool.query(query);
  return result.rows;
};
