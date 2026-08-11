"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.getProductosMasVendidosHoy = exports.getVentasHoy = void 0;
const db_1 = __importDefault(require("../../config/db"));
const getVentasHoy = async () => {
    const query = `
    SELECT COALESCE(SUM(total), 0) as total_ingresos, COUNT(id) as total_comandas
    FROM comandas
    WHERE estado = 'pagado' AND DATE(created_at) = CURRENT_DATE
  `;
    const result = await db_1.default.query(query);
    return result.rows[0];
};
exports.getVentasHoy = getVentasHoy;
const getProductosMasVendidosHoy = async () => {
    const query = `
    SELECT d.producto_nombre as nombre, SUM(d.cantidad) as total_vendido
    FROM comanda_detalles d
    JOIN comandas c ON d.comanda_id = c.id
    WHERE c.estado = 'pagado' AND DATE(c.created_at) = CURRENT_DATE
    GROUP BY d.producto_id, d.producto_nombre
    ORDER BY total_vendido DESC
    LIMIT 10
  `;
    const result = await db_1.default.query(query);
    return result.rows;
};
exports.getProductosMasVendidosHoy = getProductosMasVendidosHoy;
//# sourceMappingURL=reportes.repository.js.map