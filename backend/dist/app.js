"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
const express_1 = __importDefault(require("express"));
const cors_1 = __importDefault(require("cors"));
const dotenv_1 = __importDefault(require("dotenv"));
const os_1 = __importDefault(require("os"));
const db_1 = __importDefault(require("./config/db"));
const auth_routes_1 = __importDefault(require("./packages/auth/auth.routes"));
const mesas_routes_1 = __importDefault(require("./packages/mesas/mesas.routes"));
const menu_routes_1 = __importDefault(require("./packages/menu/menu.routes"));
const comandas_routes_1 = __importDefault(require("./packages/comandas/comandas.routes"));
const reportes_routes_1 = __importDefault(require("./packages/reportes/reportes.routes"));
const admin_routes_1 = __importDefault(require("./packages/admin/admin.routes"));
// Cargar las variables de entorno
dotenv_1.default.config();
const app = (0, express_1.default)();
const PORT = Number(process.env.PORT) || 3000;
const HOST = '0.0.0.0';
// Configurar Middlewares Globales
app.use((0, cors_1.default)());
app.use(express_1.default.json());
// Rutas Modulares
app.use('/api/auth', auth_routes_1.default);
app.use('/api/mesas', mesas_routes_1.default);
app.use('/api/menu', menu_routes_1.default);
app.use('/api/comandas', comandas_routes_1.default);
app.use('/api/reportes', reportes_routes_1.default);
app.use('/api/admin', admin_routes_1.default);
// Ruta Health Check
app.get('/api/health', async (req, res) => {
    try {
        // Intenta hacer un query rápido a la base de datos
        const dbResult = await db_1.default.query('SELECT NOW()');
        // Si la conexión es exitosa, responde el estado 200 con la hora
        res.json({
            status: 'success',
            message: 'Servidor y base de datos funcionando correctamente.',
            databaseTime: dbResult.rows[0].now,
        });
    }
    catch (error) {
        // Si la base de datos falla, registra el error y responde con 500
        console.error('Error en Health Check (Database):', error);
        res.status(500).json({
            status: 'error',
            message: 'Error de conexión a la base de datos PostgreSQL.',
            details: error.message,
        });
    }
});
// Middleware Global de Manejo de Errores (debe ir después de todas las rutas)
app.use((err, req, res, next) => {
    console.error('[Global Error Middleware]', err.stack || err);
    res.status(500).json({
        status: 'error',
        message: err.message || 'Error interno del servidor',
        // Ocultar stacktrace en producción si existiera entorno
        ...(process.env.NODE_ENV !== 'production' && { stack: err.stack })
    });
});
// Listener del servidor
const server = app.listen(PORT, HOST, () => {
    const networkInterfaces = os_1.default.networkInterfaces();
    let localIp = '127.0.0.1';
    for (const name in networkInterfaces) {
        for (const net of networkInterfaces[name] || []) {
            if (net.family === 'IPv4' && !net.internal) {
                localIp = net.address;
                break;
            }
        }
    }
    console.log(`\n[SERVER] Servidor en linea:`);
    console.log(`  > Localhost:  http://127.0.0.1:${PORT}`);
    console.log(`  > Red local:  http://${localIp}:${PORT}/api\n`);
});
server.on('error', (err) => {
    if (err.code === 'EADDRINUSE') {
        console.error(`[ERROR] Puerto ${PORT} ya esta en uso por otro proceso.`);
    }
    else {
        console.error(`[ERROR] Fallo al iniciar el servidor:`, err);
    }
});
//# sourceMappingURL=app.js.map