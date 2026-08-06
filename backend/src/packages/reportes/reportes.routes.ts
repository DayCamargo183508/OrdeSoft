import { Router } from 'express';
import { authMiddleware } from '../auth/auth.middleware';
import * as reportesController from './reportes.controller';

const router = Router();

router.use(authMiddleware);

router.get('/ventas-hoy', reportesController.getVentasHoy);

export default router;
