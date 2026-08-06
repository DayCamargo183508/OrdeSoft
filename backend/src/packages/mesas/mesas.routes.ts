import { Router } from 'express';
import { authMiddleware } from '../auth/auth.middleware';
import * as mesasController from './mesas.controller';

const router = Router();

// Todas las rutas de mesas requerirán autenticación
router.use(authMiddleware);

router.get('/', mesasController.getMesas);
router.post('/', mesasController.createMesa);
router.patch('/:id/estado', mesasController.updateEstado);
router.delete('/', mesasController.deleteMesa);

// Nuevas funciones comerciales para el mapa interactivo
router.post('/juntar', mesasController.juntarMesas);
router.post('/separar', mesasController.separarMesa);

export default router;
