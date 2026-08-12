"use strict";
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    var desc = Object.getOwnPropertyDescriptor(m, k);
    if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
      desc = { enumerable: true, get: function() { return m[k]; } };
    }
    Object.defineProperty(o, k2, desc);
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __setModuleDefault = (this && this.__setModuleDefault) || (Object.create ? (function(o, v) {
    Object.defineProperty(o, "default", { enumerable: true, value: v });
}) : function(o, v) {
    o["default"] = v;
});
var __importStar = (this && this.__importStar) || (function () {
    var ownKeys = function(o) {
        ownKeys = Object.getOwnPropertyNames || function (o) {
            var ar = [];
            for (var k in o) if (Object.prototype.hasOwnProperty.call(o, k)) ar[ar.length] = k;
            return ar;
        };
        return ownKeys(o);
    };
    return function (mod) {
        if (mod && mod.__esModule) return mod;
        var result = {};
        if (mod != null) for (var k = ownKeys(mod), i = 0; i < k.length; i++) if (k[i] !== "default") __createBinding(result, mod, k[i]);
        __setModuleDefault(result, mod);
        return result;
    };
})();
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
const db_1 = __importDefault(require("./config/db"));
const ComandasRepository = __importStar(require("./packages/comandas/comandas.repository"));
async function testComanda() {
    try {
        const mesaId = 1;
        // Verificar si la mesa existe
        const mesaQuery = await db_1.default.query('SELECT * FROM mesas LIMIT 1');
        if (mesaQuery.rows.length === 0) {
            console.log("No hay mesas.");
            process.exit();
        }
        const realMesaId = mesaQuery.rows[0].id;
        // Verificar si usuario existe
        const userQuery = await db_1.default.query('SELECT * FROM usuarios LIMIT 1');
        const realUserId = userQuery.rows[0]?.id || 1;
        const detalles = [
            {
                producto_id: '1',
                producto_nombre: 'Test Producto',
                cantidad: 1,
                precio_unitario: 10,
                notas: '',
                cuenta_id: 1,
                cliente_nombre: 'Cliente 1'
            }
        ];
        console.log("Insertando comanda transaccional con mesa " + realMesaId + " y usuario " + realUserId);
        const result = await ComandasRepository.crearComandaTransaccional(realMesaId, 'MESA', null, realUserId, detalles);
        console.log("EXITO:", result);
    }
    catch (error) {
        console.error("ERROR CREANDO COMANDA:", error);
    }
    finally {
        process.exit();
    }
}
testComanda();
//# sourceMappingURL=testComanda.js.map