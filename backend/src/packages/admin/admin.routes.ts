import { Router } from 'express';
import {
  obtenerMeseros,
  crearMesero,
  actualizarMesero,
  loginPin,
  obtenerConfig,
  actualizarConfig,
  obtenerNotasRapidas,
  crearNotaRapida,
  actualizarNotaRapida,
  eliminarNotaRapida,
  obtenerReporteDiario,
  eliminarMesero,
  updateEstadoMesero
} from './admin.controller';

const router = Router();

// Meseros
router.get('/meseros', obtenerMeseros);
router.post('/meseros', crearMesero);
router.put('/meseros/:id', actualizarMesero);
router.patch('/meseros/:id/estado', updateEstadoMesero);
router.delete('/meseros/:id', eliminarMesero);

// Login por PIN
router.post('/auth/login-pin', loginPin);

// Configuraciones
router.get('/config', obtenerConfig);
router.put('/config', actualizarConfig);

// Notas Rápidas
router.get('/notas', obtenerNotasRapidas);
router.post('/notas', crearNotaRapida);
router.put('/notas/:id', actualizarNotaRapida);
router.delete('/notas/:id', eliminarNotaRapida);

// Reportes
router.get('/reportes/diario', obtenerReporteDiario);

export default router;
