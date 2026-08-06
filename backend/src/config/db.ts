import { Pool } from 'pg';
import dotenv from 'dotenv';

// Cargar las variables del archivo .env
dotenv.config();

const pool = new Pool({
  host: process.env.DB_HOST,
  port: parseInt(process.env.DB_PORT || '5432', 10),
  user: process.env.DB_USER,
  password: process.env.DB_PASSWORD,
  database: process.env.DB_NAME,
  // Opciones de optimización para un servidor local rápido
  max: 20, // Máximo de clientes en el pool
  idleTimeoutMillis: 30000, // Cerrar conexiones inactivas tras 30s
  connectionTimeoutMillis: 2000, // Límite de 2s para conectar antes de lanzar error
});

// Probar conexión al iniciar el servidor
pool.query('SELECT NOW()', async (err, res) => {
  if (err) {
    console.error('Error al conectar a PostgreSQL:', err.stack);
  } else {
    console.log(`Base de datos OrdeSoft conectada exitosamente en el puerto ${process.env.DB_PORT}`);
    
    try {
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
          created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        )
      `);
      console.log('Tabla mesas verificada/creada exitosamente.');

      await pool.query(`
        CREATE TABLE IF NOT EXISTS categorias (
          id SERIAL PRIMARY KEY,
          nombre VARCHAR(100) UNIQUE NOT NULL,
          created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        )
      `);
      console.log('Tabla categorias verificada/creada exitosamente.');

      await pool.query(`
        CREATE TABLE IF NOT EXISTS productos (
          id SERIAL PRIMARY KEY,
          categoria_id INT REFERENCES categorias(id) ON DELETE CASCADE,
          nombre VARCHAR(100) NOT NULL,
          descripcion TEXT,
          precio DECIMAL(10, 2) NOT NULL,
          disponible BOOLEAN DEFAULT TRUE,
          created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        )
      `);
      console.log('Tabla productos verificada/creada exitosamente.');

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
          producto_id INT REFERENCES productos(id) ON DELETE RESTRICT,
          cantidad INT NOT NULL CHECK (cantidad > 0),
          precio_unitario DECIMAL(10, 2) NOT NULL,
          subtotal DECIMAL(10, 2) NOT NULL
        )
      `);
      console.log('Tabla comanda_detalles verificada/creada exitosamente.');

      // Migraciones (Añadir columnas si no existen)
      try {
        await pool.query("ALTER TABLE productos ADD COLUMN IF NOT EXISTS tipo VARCHAR(10) DEFAULT 'comida'");
        await pool.query("ALTER TABLE productos ADD COLUMN IF NOT EXISTS controla_stock BOOLEAN DEFAULT FALSE");
        await pool.query("ALTER TABLE productos ADD COLUMN IF NOT EXISTS stock_actual INT DEFAULT 0");
        await pool.query("ALTER TABLE comanda_detalles ADD COLUMN IF NOT EXISTS notas VARCHAR(100) DEFAULT NULL");
        await pool.query("ALTER TABLE comanda_detalles ADD COLUMN IF NOT EXISTS cuenta_id INT DEFAULT 1");
        await pool.query("ALTER TABLE comanda_detalles ADD COLUMN IF NOT EXISTS cliente_nombre VARCHAR(100) DEFAULT 'Cliente 1'");
        await pool.query("ALTER TABLE comanda_detalles ADD COLUMN IF NOT EXISTS estado_pago VARCHAR(20) DEFAULT 'pendiente'");
        await pool.query("ALTER TABLE comandas ALTER COLUMN mesa_id DROP NOT NULL");
        await pool.query("ALTER TABLE comandas ADD COLUMN IF NOT EXISTS tipo_orden VARCHAR(20) DEFAULT 'MESA'");
        await pool.query("ALTER TABLE comandas ADD COLUMN IF NOT EXISTS nombre_cliente VARCHAR(100) DEFAULT NULL");
        await pool.query("ALTER TABLE comandas ADD COLUMN IF NOT EXISTS metodo_pago VARCHAR(20) DEFAULT 'EFECTIVO'");
        console.log('Migraciones aplicadas exitosamente.');
      } catch (migErr) {
        console.error('Error aplicando migraciones:', migErr);
      }
    } catch (tableErr) {
      console.error('Error al verificar/crear las tablas:', tableErr);
    }
  }
});

export default pool;