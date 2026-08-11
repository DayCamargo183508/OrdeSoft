"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.updateEstadoProducto = exports.deleteProducto = exports.updateProducto = exports.createProducto = exports.getProductosByCategoria = exports.getProductos = exports.updateCategoria = exports.deleteCategoria = exports.createCategoria = exports.getCategorias = void 0;
const db_1 = __importDefault(require("../../config/db"));
const firebase_1 = require("../../config/firebase");
// --- CATEGORIAS ---
const getCategorias = async () => {
    const result = await db_1.default.query('SELECT id, nombre FROM categorias WHERE activa = true ORDER BY nombre ASC');
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
// --- PRODUCTOS (Firebase Firestore) ---
const getProductos = async (incluirInactivos = false) => {
    // Obtenemos todas las categorías de Postgres para cruzar los nombres (Join manual)
    const catResult = await db_1.default.query('SELECT id, nombre FROM categorias');
    const categoriasMap = new Map();
    catResult.rows.forEach((c) => categoriasMap.set(c.id, c.nombre));
    if (!firebase_1.firestore)
        throw new Error('Firestore no está inicializado. Verifica firebase-key.json');
    let query = firebase_1.firestore.collection('productos');
    if (!incluirInactivos) {
        query = query.where('disponible', '==', true);
    }
    const snapshot = await query.get();
    const productos = snapshot.docs.map((doc) => {
        const data = doc.data();
        return {
            id: doc.id,
            ...data,
            categoria_nombre: categoriasMap.get(data.categoria_id) || 'Sin categoría'
        };
    });
    return productos.sort((a, b) => (a.created_at || '').localeCompare(b.created_at || ''));
};
exports.getProductos = getProductos;
const getProductosByCategoria = async (categoria_id) => {
    const catResult = await db_1.default.query('SELECT nombre FROM categorias WHERE id = $1', [categoria_id]);
    const categoria_nombre = catResult.rows.length > 0 ? catResult.rows[0].nombre : 'Sin categoría';
    if (!firebase_1.firestore)
        throw new Error('Firestore no está inicializado.');
    const snapshot = await firebase_1.firestore.collection('productos')
        .where('categoria_id', '==', categoria_id)
        .where('disponible', '==', true)
        .get();
    return snapshot.docs.map((doc) => ({
        id: doc.id,
        ...doc.data(),
        categoria_nombre
    }));
};
exports.getProductosByCategoria = getProductosByCategoria;
const createProducto = async (categoria_id, nombre, descripcion, precio) => {
    if (!firebase_1.firestore)
        throw new Error('Firestore no está inicializado.');
    const newRef = firebase_1.firestore.collection('productos').doc();
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
exports.createProducto = createProducto;
const updateProducto = async (id, data) => {
    if (!firebase_1.firestore)
        throw new Error('Firestore no está inicializado.');
    const docRef = firebase_1.firestore.collection('productos').doc(id);
    const doc = await docRef.get();
    if (!doc.exists)
        return null;
    await docRef.update(data);
    const updated = await docRef.get();
    return { id: updated.id, ...updated.data() };
};
exports.updateProducto = updateProducto;
const deleteProducto = async (id) => {
    if (!firebase_1.firestore)
        throw new Error('Firestore no está inicializado.');
    const docRef = firebase_1.firestore.collection('productos').doc(id);
    const doc = await docRef.get();
    if (!doc.exists)
        return null;
    const data = doc.data();
    await docRef.delete();
    // Opcional: Eliminar referencias en postgres comanda_detalles (aquí id es string)
    await db_1.default.query('DELETE FROM comanda_detalles WHERE producto_id = $1', [id]);
    return { id, ...data };
};
exports.deleteProducto = deleteProducto;
const updateEstadoProducto = async (id, disponible) => {
    return await (0, exports.updateProducto)(id, { disponible });
};
exports.updateEstadoProducto = updateEstadoProducto;
//# sourceMappingURL=menu.repository.js.map