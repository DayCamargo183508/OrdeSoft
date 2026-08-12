import { Request, Response } from 'express';
import * as MenuRepository from './menu.repository';

// --- CATEGORIAS ---
export const getCategorias = async (req: Request, res: Response) => {
  try {
    const categorias = await MenuRepository.getCategorias();
    res.json(categorias || []);
  } catch (error) {
    console.error('[DATABASE ERROR]:', error);
    console.error('[CATEGORIAS ERROR]: Error obteniendo categorias:', error);
    // Retornamos 200 con un arreglo vacío para evitar romper el flujo en la app Flutter
    res.status(200).json([]);
  }
};

export const createCategoria = async (req: Request, res: Response) => {
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
  } catch (error: any) {
    console.error('[DATABASE ERROR]:', error);
    console.error('Error creando categoria:', error);
    if (error.code === '23505') {
      res.status(400).json({ error: 'La categoría ya existe.' });
      return;
    }
    res.status(500).json({ message: (error as Error).message || 'Error al crear categoria' });
  }
};

export const deleteCategoria = async (req: Request, res: Response) => {
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
  } catch (error) {
    console.error('[DATABASE ERROR]:', error);
    console.error('Error eliminando categoria:', error);
    res.status(500).json({ message: (error as Error).message || 'Error al eliminar categoria' });
  }
};

export const updateCategoria = async (req: Request, res: Response) => {
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
  } catch (error: any) {
    console.error('[DATABASE ERROR]:', error);
    console.error('Error actualizando categoria:', error);
    if (error.code === '23505') {
      res.status(400).json({ error: 'La categoría ya existe.' });
      return;
    }
    res.status(500).json({ message: (error as Error).message || 'Error al actualizar categoria' });
  }
};

// --- PRODUCTOS ---
export const getProductos = async (req: Request, res: Response) => {
  try {
    const incluirInactivos = req.query.incluirInactivos === 'true';
    const productos = await MenuRepository.getProductos(incluirInactivos);
    res.json(productos);
  } catch (error) {
    res.status(200).json([]);
  }
};

export const createProducto = async (req: Request, res: Response) => {
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
  } catch (error) {
    console.error('[DATABASE ERROR]:', error);
    console.error('Error creando producto:', error);
    res.status(500).json({ message: (error as Error).message || 'Error al crear producto' });
  }
};

export const updateProducto = async (req: Request, res: Response) => {
  try {
    if (req.user?.rol !== 'admin') {
      res.status(403).json({ error: 'Se requiere rol admin.' });
      return;
    }
    const { id } = req.params;
    const productoActualizado = await MenuRepository.updateProducto(id as string, req.body);
    
    if (!productoActualizado) {
      res.status(404).json({ error: 'Producto no encontrado o no hay campos para actualizar.' });
      return;
    }
    res.status(200).json({
      message: 'Producto actualizado con éxito',
      producto: Array.isArray(productoActualizado) ? productoActualizado[0] : productoActualizado
    });
  } catch (error) {
    console.error('[DATABASE ERROR]:', error);
    console.error('Error actualizando producto:', error);
    res.status(500).json({ message: (error as Error).message || 'Error al actualizar producto' });
  }
};

export const deleteProducto = async (req: Request, res: Response) => {
  try {
    if (req.user?.rol !== 'admin') {
      res.status(403).json({ error: 'Se requiere rol admin.' });
      return;
    }
    const { id } = req.params;
    const producto = await MenuRepository.deleteProducto(id as string);
    if (!producto) {
      res.status(404).json({ error: 'Producto no encontrado.' });
      return;
    }
    res.status(200).json({ message: 'Producto e historial eliminados correctamente' });
  } catch (error) {
    console.error('[DATABASE ERROR]:', error);
    console.error('Error eliminando producto:', error);
    res.status(500).json({ message: (error as Error).message || 'Error al eliminar producto' });
  }
};

export const updateEstadoProducto = async (req: Request, res: Response) => {
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
    
    const productoActualizado = await MenuRepository.updateEstadoProducto(id as string, Boolean(estado));
    
    if (!productoActualizado) {
      res.status(404).json({ error: 'Producto no encontrado.' });
      return;
    }
    res.json({ message: 'Estado del producto actualizado con éxito', producto: productoActualizado });
  } catch (error) {
    console.error('[DATABASE ERROR]:', error);
    console.error('[UPDATE DISPONIBILIDAD ERROR]:', error);
    res.status(500).json({ message: (error as Error).message || 'Error al actualizar estado del producto' });
  }
};
