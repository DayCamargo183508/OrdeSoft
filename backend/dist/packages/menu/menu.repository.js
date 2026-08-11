"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.updateEstadoProducto = exports.deleteProducto = exports.updateProducto = exports.createProducto = exports.getProductosByCategoria = exports.getProductos = exports.updateCategoria = exports.deleteCategoria = exports.createCategoria = exports.getCategorias = void 0;
const db_1 = __importDefault(require("../../config/db"));
// --- CATEGORIAS ---
const getCategorias = async () => {
    const result = await db_1.default.query('SELECT * FROM categorias WHERE activa = true ORDER BY nombre ASC');
    return result.rows;
};
exports.getCategorias = getCategorias;
const createCategoria = async (nombre) => {
    const result = await db_1.default.query('INSERT INTO categorias (nombre) VALUES ($1) RETURNING *', [nombre]);
    return result.rows[0];
};
exports.createCategoria = createCategoria;
const deleteCategoria = async (id) => {
    const client = await db_1.default.connect();
    try {
        await client.query('BEGIN');
        await client.query('UPDATE productos SET disponible = false WHERE categoria_id = $1', [id]);
        const res = await client.query('UPDATE categorias SET activa = false WHERE id = $1 RETURNING *', [id]);
        await client.query('COMMIT');
        return res.rows[0];
    }
    catch (error) {
        await client.query('ROLLBACK');
        throw error;
    }
    finally {
        client.release();
    }
};
exports.deleteCategoria = deleteCategoria;
const updateCategoria = async (id, nombre) => {
    const result = await db_1.default.query('UPDATE categorias SET nombre = $1 WHERE id = $2 RETURNING *', [nombre, id]);
    return result.rows[0];
};
exports.updateCategoria = updateCategoria;
// --- PRODUCTOS ---
const getProductos = async (incluirInactivos = false) => {
    let query = `
    SELECT p.*, c.nombre as categoria_nombre 
    FROM productos p 
    LEFT JOIN categorias c ON p.categoria_id = c.id 
  `;
    if (!incluirInactivos) {
        query += ` WHERE p.disponible = true`;
    }
    query += ` ORDER BY p.id ASC`;
    const result = await db_1.default.query(query);
    return result.rows;
};
exports.getProductos = getProductos;
const getProductosByCategoria = async (categoria_id) => {
    const query = `
    SELECT p.*, c.nombre as categoria_nombre 
    FROM productos p 
    LEFT JOIN categorias c ON p.categoria_id = c.id 
    WHERE p.categoria_id = $1 AND p.disponible = true
    ORDER BY p.nombre ASC
  `;
    const result = await db_1.default.query(query, [categoria_id]);
    return result.rows;
};
exports.getProductosByCategoria = getProductosByCategoria;
const createProducto = async (categoria_id, nombre, descripcion, precio) => {
    const result = await db_1.default.query('INSERT INTO productos (categoria_id, nombre, descripcion, precio) VALUES ($1, $2, $3, $4) RETURNING *', [categoria_id, nombre, descripcion, precio]);
    return result.rows[0];
};
exports.createProducto = createProducto;
const updateProducto = async (id, data) => {
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
    if (updates.length === 0)
        return null;
    values.push(id);
    const query = `UPDATE productos SET ${updates.join(', ')} WHERE id = $${index} RETURNING *`;
    const result = await db_1.default.query(query, values);
    return result.rows[0];
};
exports.updateProducto = updateProducto;
const deleteProducto = async (id) => {
    const client = await db_1.default.connect();
    try {
        await client.query('BEGIN');
        await client.query('DELETE FROM comanda_detalles WHERE producto_id = $1', [id]);
        const result = await client.query('DELETE FROM productos WHERE id = $1 RETURNING *', [id]);
        await client.query('COMMIT');
        return result.rows[0];
    }
    catch (error) {
        await client.query('ROLLBACK');
        throw error;
    }
    finally {
        client.release();
    }
};
exports.deleteProducto = deleteProducto;
const updateEstadoProducto = async (id, disponible) => {
    const result = await db_1.default.query('UPDATE productos SET disponible = $1 WHERE id = $2 RETURNING *', [disponible, id]);
    return result.rows[0];
};
exports.updateEstadoProducto = updateEstadoProducto;
//# sourceMappingURL=menu.repository.js.map