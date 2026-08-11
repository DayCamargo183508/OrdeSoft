"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.loginWithPin = void 0;
const jsonwebtoken_1 = __importDefault(require("jsonwebtoken"));
const db_1 = __importDefault(require("../../config/db"));
const crypto_helper_1 = require("../../utils/crypto.helper");
const loginWithPin = async (req, res) => {
    try {
        console.log('>>> [HTTP /auth/login] PETICIÓN RECIBIDA:', req.body);
        const { pin } = req.body;
        // 1. Validar que venga el PIN
        const pinString = String(pin).trim();
        if (!pinString || pinString.length !== 4) {
            res.status(400).json({ error: 'Se requiere un PIN numérico válido de 4 dígitos.' });
            return;
        }
        // 2. Consultar todos los usuarios activos
        const result = await db_1.default.query("SELECT id, nombre, rol, pin_hash FROM usuarios WHERE activo = true AND LOWER(rol) IN ('mesero', 'admin')");
        const users = result.rows;
        console.log(`>>> [LOGIN] USUARIOS ACTIVOS ENCONTRADOS EN BD: ${users.length}`);
        let matchedUser = null;
        // 3. Comparar el PIN recibido contra el 'pin_hash' de cada usuario
        for (const user of users) {
            if (user.pin_hash) {
                const pinDesencriptado = (0, crypto_helper_1.decryptPin)(user.pin_hash);
                console.log(`>>> [LOGIN] EVALUANDO ID ${user.id} (${user.nombre}): DB_PIN="${pinDesencriptado}" VS INGRESADO="${pinString}"`);
                if (pinDesencriptado === pinString) {
                    console.log(`>>> [LOGIN] ¡COINCIDENCIA EXITOSA CON ${user.nombre}!`);
                    matchedUser = user;
                    break; // Encontramos al usuario, detenemos el bucle
                }
            }
        }
        // 4. Si no hay coincidencias
        if (!matchedUser) {
            console.log('>>> [LOGIN] NINGÚN PIN COINCIDIÓ');
            res.status(401).json({ error: 'PIN incorrecto. Acceso denegado.' });
            return;
        }
        // 5. Si coincide, generar token JWT
        const secret = process.env.JWT_SECRET || 'secret_de_respaldo';
        const token = jsonwebtoken_1.default.sign({ id: matchedUser.id, rol: matchedUser.rol }, secret, { expiresIn: '12h' });
        // 6. Retornar status 200 con token y objeto limpio
        res.status(200).json({
            token,
            user: {
                id: matchedUser.id,
                nombre: matchedUser.nombre,
                rol: matchedUser.rol,
            }
        });
    }
    catch (error) {
        console.error('Error en loginWithPin:', error);
        res.status(500).json({ error: 'Error interno del servidor.' });
    }
};
exports.loginWithPin = loginWithPin;
//# sourceMappingURL=auth.controller.js.map