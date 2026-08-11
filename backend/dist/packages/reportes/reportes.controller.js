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
Object.defineProperty(exports, "__esModule", { value: true });
exports.getVentasHoy = void 0;
const ReportesRepository = __importStar(require("./reportes.repository"));
const getVentasHoy = async (req, res) => {
    try {
        if (req.user?.rol !== 'admin') {
            res.status(403).json({ error: 'Se requiere rol admin.' });
            return;
        }
        const ventas = await ReportesRepository.getVentasHoy();
        const productosMasVendidos = await ReportesRepository.getProductosMasVendidosHoy();
        res.json({
            ingresos_hoy: Number(ventas.total_ingresos),
            comandas_completadas: Number(ventas.total_comandas),
            productos_top: productosMasVendidos.map(p => ({
                producto: p.nombre,
                cantidad: Number(p.total_vendido)
            }))
        });
    }
    catch (error) {
        console.error('Error generando reporte de ventas:', error);
        res.status(500).json({ error: 'Error al generar reporte de ventas' });
    }
};
exports.getVentasHoy = getVentasHoy;
//# sourceMappingURL=reportes.controller.js.map