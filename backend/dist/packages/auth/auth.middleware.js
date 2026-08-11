"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.authMiddleware = void 0;
const jsonwebtoken_1 = __importDefault(require("jsonwebtoken"));
const authMiddleware = (req, res, next) => {
    const authHeader = req.headers.authorization;
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
        res.status(401).json({ error: 'Acceso denegado. Token no proporcionado.' });
        return;
    }
    const token = authHeader.split(' ')[1];
    if (!token) {
        res.status(401).json({ error: 'Token malformado o ausente en el header.' });
        return;
    }
    try {
        const decoded = jsonwebtoken_1.default.verify(token, (process.env.JWT_SECRET || 'secret_de_respaldo'));
        req.user = decoded;
        next();
    }
    catch (error) {
        res.status(401).json({ error: 'Token inválido o expirado.' });
        return;
    }
};
exports.authMiddleware = authMiddleware;
//# sourceMappingURL=auth.middleware.js.map