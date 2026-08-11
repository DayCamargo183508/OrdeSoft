"use strict";
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    var desc = Object.getOwnPropertyDescriptor(m, k);
    if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
      desc = { enumerable: true, get: function() { return m[k]; } };
    }
    Object.defineProperty(o, k2, desc);
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __setModuleDefault = (this && this.__setModuleDefault) || (Object.create ? (function(o, v) {
    Object.defineProperty(o, "default", { enumerable: true, value: v });
}) : function(o, v) {
    o["default"] = v;
});
var __importStar = (this && this.__importStar) || (function () {
    var ownKeys = function(o) {
        ownKeys = Object.getOwnPropertyNames || function (o) {
            var ar = [];
            for (var k in o) if (Object.prototype.hasOwnProperty.call(o, k)) ar[ar.length] = k;
            return ar;
        };
        return ownKeys(o);
    };
    return function (mod) {
        if (mod && mod.__esModule) return mod;
        var result = {};
        if (mod != null) for (var k = ownKeys(mod), i = 0; i < k.length; i++) if (k[i] !== "default") __createBinding(result, mod, k[i]);
        __setModuleDefault(result, mod);
        return result;
    };
})();
Object.defineProperty(exports, "__esModule", { value: true });
exports.updateEstadoProducto = exports.deleteProducto = exports.updateProducto = exports.createProducto = exports.getProductos = exports.updateCategoria = exports.deleteCategoria = exports.createCategoria = exports.getCategorias = void 0;
const MenuRepository = __importStar(require("./menu.repository"));
// --- CATEGORIAS ---
const getCategorias = async (req, res) => {
    try {
        const categorias = await MenuRepository.getCategorias();
        res.json(categorias);
    }
    catch (error) {
        console.error('[DATABASE ERROR]:', error);
        console.error('Error obteniendo categorias:', error);
        res.status(500).json({ message: error.message || 'Error al obtener categorias' });
    }
};
exports.getCategorias = getCategorias;
const createCategoria = async (req, res) => {
    try {
        if (req.user?.rol !== 'admin') {
            res.status(403).json({ error: 'Se requiere rol admin.' });
            return;
        }
        const { nombre } = req.body;
        if (!nombre) {
            res.status(400).json({ error: 'El nombre es requerido.' });
            return;
        }
        const nuevaCategoria = await MenuRepository.createCategoria(nombre);
        res.status(201).json(nuevaCategoria);
    }
    catch (error) {
        console.error('[DATABASE ERROR]:', error);
        console.error('Error creando categoria:', error);
        if (error.code === '23505') {
            res.status(400).json({ error: 'La categoría ya existe.' });
            return;
        }
        res.status(500).json({ message: error.message || 'Error al crear categoria' });
    }
};
exports.createCategoria = createCategoria;
const deleteCategoria = async (req, res) => {
    try {
        if (req.user?.rol !== 'admin') {
            res.status(403).json({ error: 'Se requiere rol admin.' });
            return;
        }
        const { id } = req.params;
        const categoria = await MenuRepository.deleteCategoria(Number(id));
        if (!categoria) {
            res.status(404).json({ error: 'Categoría no encontrada.' });
            return;
        }
        res.json({ message: 'Categoría y sus productos deshabilitados con éxito', categoria });
    }
    catch (error) {
        console.error('[DATABASE ERROR]:', error);
        console.error('Error eliminando categoria:', error);
        res.status(500).json({ message: error.message || 'Error al eliminar categoria' });
    }
};
exports.deleteCategoria = deleteCategoria;
const updateCategoria = async (req, res) => {
    try {
        if (req.user?.rol !== 'admin') {
            res.status(403).json({ error: 'Se requiere rol admin.' });
            return;
        }
        const { id } = req.params;
        const { nombre } = req.body;
        if (!nombre) {
            res.status(400).json({ error: 'El nombre es requerido.' });
            return;
        }
        const categoria = await MenuRepository.updateCategoria(Number(id), nombre);
        if (!categoria) {
            res.status(404).json({ error: 'Categoría no encontrada.' });
            return;
        }
        res.json(categoria);
    }
    catch (error) {
        console.error('[DATABASE ERROR]:', error);
        console.error('Error actualizando categoria:', error);
        if (error.code === '23505') {
            res.status(400).json({ error: 'La categoría ya existe.' });
            return;
        }
        res.status(500).json({ message: error.message || 'Error al actualizar categoria' });
    }
};
exports.updateCategoria = updateCategoria;
// --- PRODUCTOS ---
const getProductos = async (req, res) => {
    try {
        const incluirInactivos = req.query.incluirInactivos === 'true';
        const productos = await MenuRepository.getProductos(incluirInactivos);
        res.json(productos);
    }
    catch (error) {
        console.error('[DATABASE ERROR]:', error);
        console.error('Error obteniendo productos:', error);
        res.status(500).json({ message: error.message || 'Error al obtener productos' });
    }
};
exports.getProductos = getProductos;
const createProducto = async (req, res) => {
    try {
        if (req.user?.rol !== 'admin') {
            res.status(403).json({ error: 'Se requiere rol admin.' });
            return;
        }
        const { categoria_id, nombre, descripcion, precio } = req.body;
        if (!categoria_id || !nombre || precio === undefined) {
            res.status(400).json({ error: 'categoria_id, nombre y precio son requeridos.' });
            return;
        }
        const nuevoProducto = await MenuRepository.createProducto(categoria_id, nombre, descripcion || '', precio);
        res.status(201).json(nuevoProducto);
    }
    catch (error) {
        console.error('[DATABASE ERROR]:', error);
        console.error('Error creando producto:', error);
        res.status(500).json({ message: error.message || 'Error al crear producto' });
    }
};
exports.createProducto = createProducto;
const updateProducto = async (req, res) => {
    try {
        if (req.user?.rol !== 'admin') {
            res.status(403).json({ error: 'Se requiere rol admin.' });
            return;
        }
        const { id } = req.params;
        const productoActualizado = await MenuRepository.updateProducto(id, req.body);
        if (!productoActualizado) {
            res.status(404).json({ error: 'Producto no encontrado o no hay campos para actualizar.' });
            return;
        }
        res.status(200).json({
            message: 'Producto actualizado con éxito',
            producto: Array.isArray(productoActualizado) ? productoActualizado[0] : productoActualizado
        });
    }
    catch (error) {
        console.error('[DATABASE ERROR]:', error);
        console.error('Error actualizando producto:', error);
        res.status(500).json({ message: error.message || 'Error al actualizar producto' });
    }
};
exports.updateProducto = updateProducto;
const deleteProducto = async (req, res) => {
    try {
        if (req.user?.rol !== 'admin') {
            res.status(403).json({ error: 'Se requiere rol admin.' });
            return;
        }
        const { id } = req.params;
        const producto = await MenuRepository.deleteProducto(id);
        if (!producto) {
            res.status(404).json({ error: 'Producto no encontrado.' });
            return;
        }
        res.status(200).json({ message: 'Producto e historial eliminados correctamente' });
    }
    catch (error) {
        console.error('[DATABASE ERROR]:', error);
        console.error('Error eliminando producto:', error);
        res.status(500).json({ message: error.message || 'Error al eliminar producto' });
    }
};
exports.deleteProducto = deleteProducto;
const updateEstadoProducto = async (req, res) => {
    try {
        if (req.user?.rol !== 'admin') {
            res.status(403).json({ error: 'Se requiere rol admin.' });
            return;
        }
        const { id } = req.params;
        const estado = req.body.disponible ?? req.body.activo;
        if (estado === undefined) {
            res.status(400).json({ error: 'El estado (disponible o activo) es requerido.' });
            return;
        }
        const productoActualizado = await MenuRepository.updateEstadoProducto(id, Boolean(estado));
        if (!productoActualizado) {
            res.status(404).json({ error: 'Producto no encontrado.' });
            return;
        }
        res.json({ message: 'Estado del producto actualizado con éxito', producto: productoActualizado });
    }
    catch (error) {
        console.error('[DATABASE ERROR]:', error);
        console.error('Error actualizando estado del producto:', error);
        res.status(500).json({ message: error.message || 'Error al actualizar estado del producto' });
    }
};
exports.updateEstadoProducto = updateEstadoProducto;
//# sourceMappingURL=menu.controller.js.map