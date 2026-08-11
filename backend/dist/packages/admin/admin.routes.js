"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const express_1 = require("express");
const admin_controller_1 = require("./admin.controller");
const router = (0, express_1.Router)();
// Meseros
router.get('/meseros', admin_controller_1.obtenerMeseros);
router.post('/meseros', admin_controller_1.crearMesero);
router.put('/meseros/:id', admin_controller_1.actualizarMesero);
router.patch('/meseros/:id/estado', admin_controller_1.updateEstadoMesero);
router.delete('/meseros/:id', admin_controller_1.eliminarMesero);
// Login por PIN
router.post('/auth/login-pin', admin_controller_1.loginPin);
// Configuraciones
router.get('/config', admin_controller_1.obtenerConfig);
router.put('/config', admin_controller_1.actualizarConfig);
// Notas Rápidas
router.get('/notas', admin_controller_1.obtenerNotasRapidas);
router.post('/notas', admin_controller_1.crearNotaRapida);
router.put('/notas/:id', admin_controller_1.actualizarNotaRapida);
router.delete('/notas/:id', admin_controller_1.eliminarNotaRapida);
// Reportes
router.get('/reportes/diario', admin_controller_1.obtenerReporteDiario);
exports.default = router;
//# sourceMappingURL=admin.routes.js.map