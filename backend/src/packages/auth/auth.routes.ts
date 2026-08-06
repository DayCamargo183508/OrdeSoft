import { Router, Request, Response } from 'express';
import { loginWithPin } from './auth.controller';
import { authMiddleware } from './auth.middleware';

const router = Router();

// POST /login -> Ejecuta el controlador loginWithPin
router.post('/login', loginWithPin);

// GET /perfil -> Ruta de prueba protegida
router.get('/perfil', authMiddleware, (req: Request, res: Response) => {
  res.status(200).json({
    message: 'Has accedido a una ruta protegida exitosamente',
    user: req.user
  });
});

export default router;
