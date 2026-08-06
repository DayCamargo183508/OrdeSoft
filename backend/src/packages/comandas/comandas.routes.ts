import { Router } from 'express';
import { authMiddleware } from '../auth/auth.middleware';
import * as comandasController from './comandas.controller';

const router = Router();

// Toda interacción con comandas requiere autenticación
router.use(authMiddleware);

router.get('/', comandasController.obtenerActivas);
router.get('/para-llevar', comandasController.obtenerParaLlevar);
router.get('/:id', comandasController.obtenerPorId);
router.get('/:id/ticket-cocina', comandasController.obtenerTicketCocina);
router.post('/', comandasController.crearComanda);
router.patch('/:id/pagar', comandasController.pagarComanda);
router.patch('/:id/pagar-cuenta', comandasController.pagarCuenta);

export default router;
