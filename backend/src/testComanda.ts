import pool from './config/db';
import * as ComandasRepository from './packages/comandas/comandas.repository';

async function testComanda() {
  try {
    const mesaId = 1;
    
    // Verificar si la mesa existe
    const mesaQuery = await pool.query('SELECT * FROM mesas LIMIT 1');
    if (mesaQuery.rows.length === 0) {
        console.log("No hay mesas.");
        process.exit();
    }
    const realMesaId = mesaQuery.rows[0].id;

    // Verificar si usuario existe
    const userQuery = await pool.query('SELECT * FROM usuarios LIMIT 1');
    const realUserId = userQuery.rows[0]?.id || 1;

    const detalles = [
      {
        producto_id: '1',
        producto_nombre: 'Test Producto',
        cantidad: 1,
        precio_unitario: 10,
        notas: '',
        cuenta_id: 1,
        cliente_nombre: 'Cliente 1'
      }
    ];

    console.log("Insertando comanda transaccional con mesa " + realMesaId + " y usuario " + realUserId);
    const result = await ComandasRepository.crearComandaTransaccional(
      realMesaId,
      'MESA',
      null,
      realUserId,
      detalles
    );
    
    console.log("EXITO:", result);
  } catch (error) {
    console.error("ERROR CREANDO COMANDA:", error);
  } finally {
    process.exit();
  }
}

testComanda();
