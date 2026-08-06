-- 1. Crear extensión para UUIDs (En caso de que quieras usarlos en el futuro)
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- 2. Tabla de Usuarios (Meseros y Administradores)
CREATE TABLE usuarios (
    id SERIAL PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    pin_hash VARCHAR(255) NOT NULL, -- PIN de 4 dígitos encriptado con bcrypt
    rol VARCHAR(20) NOT NULL CHECK (rol IN ('admin', 'mesero')),
    activo BOOLEAN DEFAULT TRUE,
    creado_en TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 3. Tabla de Categorías de Menú
CREATE TABLE categorias (
    id SERIAL PRIMARY KEY,
    nombre VARCHAR(50) NOT NULL UNIQUE,
    activo BOOLEAN DEFAULT TRUE
);

-- 4. Tabla de Productos (Catálogo del Menú)
CREATE TABLE productos (
    id SERIAL PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    precio DECIMAL(10, 2) NOT NULL CHECK (precio > 0),
    disponible BOOLEAN DEFAULT TRUE,
    categoria_id INT REFERENCES categorias(id) ON DELETE SET NULL,
    detalles JSONB DEFAULT '{}'::jsonb, -- Para alérgenos, ingredientes o descripción
    creado_en TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 5. Tabla de Órdenes / Comandas (Cabecera)
CREATE TABLE ordenes (
    id SERIAL PRIMARY KEY,
    mesa VARCHAR(20) NOT NULL,
    usuario_id INT REFERENCES usuarios(id) ON DELETE RESTRICT, -- Quién levantó la orden
    estado VARCHAR(20) DEFAULT 'pendiente' CHECK (estado IN ('pendiente', 'entregado', 'pagado', 'cancelado')),
    total DECIMAL(10, 2) DEFAULT 0.00 CHECK (total >= 0),
    creado_en TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 6. Tabla de Detalles de la Orden (Artículos solicitados)
CREATE TABLE detalle_ordenes (
    id SERIAL PRIMARY KEY,
    orden_id INT REFERENCES ordenes(id) ON DELETE CASCADE,
    producto_id INT REFERENCES productos(id) ON DELETE RESTRICT,
    cantidad INT NOT NULL CHECK (cantidad > 0),
    precio_unitario DECIMAL(10, 2) NOT NULL CHECK (precio_unitario > 0),
    notas_especiales VARCHAR(255) DEFAULT '', -- Ej: "Sin cebolla y bien cocida"
    creado_en TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);