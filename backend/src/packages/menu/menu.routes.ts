import { Router } from 'express';
import { authMiddleware } from '../auth/auth.middleware';
import * as menuController from './menu.controller';

const router = Router();

router.use(authMiddleware);

// Rutas de Categorías
router.get('/categorias', menuController.getCategorias);
router.post('/categorias', menuController.createCategoria);
router.put('/categorias/:id', menuController.updateCategoria);
router.delete('/categorias/:id', menuController.deleteCategoria);

// Rutas de Productos
router.get('/productos', menuController.getProductos);
router.post('/productos', menuController.createProducto);
router.patch('/productos/:id', menuController.updateProducto);
router.patch('/productos/:id/estado', menuController.updateEstadoProducto);
router.delete('/productos/:id', menuController.deleteProducto);

export default router;
