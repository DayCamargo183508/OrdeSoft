import { Pool } from 'pg';
import dotenv from 'dotenv';

// Cargar las variables del archivo .env
dotenv.config();

const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
  ssl: process.env.DATABASE_URL ? { rejectUnauthorized: false } : false,
  max: 10, // Reducido a 10 para balancear conexiones serverless
  idleTimeoutMillis: 30000, // Cerrar conexiones inactivas tras 30s
  connectionTimeoutMillis: 15000, // Dar 15 segundos a Neon para despertar antes de arrojar Timeout
});

// Probar conexión al iniciar el servidor con reintentos para Neon (Wake Up)
const initDatabase = async () => {
  let retries = 3;
  while (retries > 0) {
    try {
      await pool.query('SELECT NOW()');
      console.log(`Base de datos OrdeSoft conectada exitosamente en el puerto ${process.env.DB_PORT || 'por defecto'}`);
      // Crear tabla usuarios (meseros)
      await pool.query(`
        CREATE TABLE IF NOT EXISTS usuarios (
          id SERIAL PRIMARY KEY,
          nombre VARCHAR(100) NOT NULL,
          pin_hash VARCHAR(255) NOT NULL,
          rol VARCHAR(20) NOT NULL CHECK (rol IN ('admin', 'mesero')),
          activo BOOLEAN DEFAULT TRUE,
          creado_en TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        )
      `);
      console.log('Tabla usuarios verificada/creada exitosamente.');

      // Crear tabla configuraciones
      await pool.query(`
        CREATE TABLE IF NOT EXISTS configuraciones (
          id SERIAL PRIMARY KEY,
          min_mesas INT DEFAULT 1,
          max_mesas INT DEFAULT 10,
          actualizado_en TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        )
      `);
      console.log('Tabla configuraciones verificada/creada exitosamente.');

      // Insertar configuración por defecto si está vacía
      await pool.query(`
        INSERT INTO configuraciones (min_mesas, max_mesas)
        SELECT 1, 10
        WHERE NOT EXISTS (SELECT 1 FROM configuraciones)
      `);

      // Crear tabla notas_rapidas
      await pool.query(`
        CREATE TABLE IF NOT EXISTS notas_rapidas (
          id SERIAL PRIMARY KEY,
          texto VARCHAR(50) NOT NULL,
          precio_extra DECIMAL(10,2) DEFAULT 0.00 NOT NULL,
          creado_en TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        )
      `);
      
      // Asegurarse de que la columna exista si la tabla ya fue creada antes
      await pool.query(`
        ALTER TABLE notas_rapidas 
        ADD COLUMN IF NOT EXISTS precio_extra DECIMAL(10,2) DEFAULT 0.00 NOT NULL
      `);
      console.log('Tabla notas_rapidas verificada/creada exitosamente.');

      // Crear tabla mesas si no existe
      await pool.query(`
        CREATE TABLE IF NOT EXISTS mesas (
          id SERIAL PRIMARY KEY,
          numero VARCHAR(50) UNIQUE NOT NULL,
          capacidad INT DEFAULT 4,
          estado VARCHAR(20) DEFAULT 'libre',
          mesa_padre_id INT REFERENCES mesas(id) ON DELETE SET NULL,
          created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        )
      `);
      console.log('Tabla mesas verificada/creada exitosamente.');

      await pool.query(`
        CREATE TABLE IF NOT EXISTS categorias (
          id SERIAL PRIMARY KEY,
          nombre VARCHAR(100) UNIQUE NOT NULL,
          activa BOOLEAN DEFAULT TRUE,
          created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        )
      `);
      console.log('Tabla categorias verificada/creada exitosamente.');

      // Insertar categoría General por defecto si está vacía
      await pool.query(`
        INSERT INTO categorias (nombre)
        SELECT 'General'
        WHERE NOT EXISTS (SELECT 1 FROM categorias)
      `);



      await pool.query(`
        CREATE TABLE IF NOT EXISTS comandas (
          id SERIAL PRIMARY KEY,
          mesa_id INT REFERENCES mesas(id) ON DELETE RESTRICT,
          usuario_id INT REFERENCES usuarios(id) ON DELETE RESTRICT,
          estado VARCHAR(20) DEFAULT 'pendiente',
          total DECIMAL(10, 2) DEFAULT 0.00,
          tipo_orden VARCHAR(20) DEFAULT 'MESA',
          nombre_cliente VARCHAR(100),
          created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        )
      `);
      console.log('Tabla comandas verificada/creada exitosamente.');

      await pool.query(`
        CREATE TABLE IF NOT EXISTS comanda_detalles (
          id SERIAL PRIMARY KEY,
          comanda_id INT REFERENCES comandas(id) ON DELETE CASCADE,
          producto_id VARCHAR(255) NOT NULL,
          producto_nombre VARCHAR(100) NOT NULL,
          cantidad INT NOT NULL CHECK (cantidad > 0),
          precio_unitario DECIMAL(10, 2) NOT NULL,
          subtotal DECIMAL(10, 2) NOT NULL
        )
      `);
      console.log('Tabla comanda_detalles verificada/creada exitosamente.');

      // Migraciones (Añadir columnas si no existen)
      try {
        await pool.query("ALTER TABLE comanda_detalles ADD COLUMN IF NOT EXISTS notas VARCHAR(100) DEFAULT NULL");
        await pool.query("ALTER TABLE comanda_detalles ADD COLUMN IF NOT EXISTS cuenta_id INT DEFAULT 1");
        await pool.query("ALTER TABLE comanda_detalles ADD COLUMN IF NOT EXISTS cliente_nombre VARCHAR(100) DEFAULT 'Cliente 1'");
        await pool.query("ALTER TABLE comanda_detalles ADD COLUMN IF NOT EXISTS estado_pago VARCHAR(20) DEFAULT 'pendiente'");
        await pool.query("ALTER TABLE comandas ALTER COLUMN mesa_id DROP NOT NULL");
        await pool.query("ALTER TABLE comandas ADD COLUMN IF NOT EXISTS tipo_orden VARCHAR(20) DEFAULT 'MESA'");
        await pool.query("ALTER TABLE comandas ADD COLUMN IF NOT EXISTS nombre_cliente VARCHAR(100) DEFAULT NULL");
        await pool.query("ALTER TABLE comandas ADD COLUMN IF NOT EXISTS metodo_pago VARCHAR(20) DEFAULT 'EFECTIVO'");
        await pool.query("ALTER TABLE mesas ADD COLUMN IF NOT EXISTS mesa_padre_id INT REFERENCES mesas(id) ON DELETE SET NULL");
        await pool.query("ALTER TABLE categorias ADD COLUMN IF NOT EXISTS activa BOOLEAN DEFAULT TRUE");
        console.log('Migraciones aplicadas exitosamente.');
      } catch (migErr) {
        console.error('Error aplicando migraciones:', migErr);
      }
    // Si llegamos hasta aquí, todo cargó bien. Salimos del bucle.
    break;

  } catch (err: any) {
    console.error(`[DATABASE ERROR] Fallo al conectar o inicializar PostgreSQL:`, err.message);
    retries--;
    if (retries === 0) {
      console.error('❌ Error definitivo al conectar a PostgreSQL tras 3 intentos. Revisa tu DATABASE_URL o el estado del servidor.');
    } else {
      console.log(`⏳ Reintentando conexión a PostgreSQL en 3 segundos... (Quedan ${retries} intentos)`);
      await new Promise(res => setTimeout(res, 3000)); // Esperar 3 segundos antes de intentar de nuevo
    }
    }
  }
};

initDatabase();

export default pool;