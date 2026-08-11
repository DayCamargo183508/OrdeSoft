"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const express_1 = require("express");
const auth_controller_1 = require("./auth.controller");
const auth_middleware_1 = require("./auth.middleware");
const router = (0, express_1.Router)();
// POST /login -> Ejecuta el controlador loginWithPin
router.post('/login', auth_controller_1.loginWithPin);
// GET /perfil -> Ruta de prueba protegida
router.get('/perfil', auth_middleware_1.authMiddleware, (req, res) => {
    res.status(200).json({
        message: 'Has accedido a una ruta protegida exitosamente',
        user: req.user
    });
});
exports.default = router;
//# sourceMappingURL=auth.routes.js.map