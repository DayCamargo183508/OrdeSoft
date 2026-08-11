"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.separarMesa = exports.juntarMesas = exports.deleteUltimaMesa = exports.getTotalMesas = exports.updateEstadoMesa = exports.createMesa = exports.getMesas = void 0;
const db_1 = __importDefault(require("../../config/db"));
const getMesas = async () => {
    const result = await db_1.default.query(`
    SELECT 
        m.id, 
        m.numero, 
        m.capacidad, 
        m.estado, 
        m.mesa_padre_id,
        (SELECT numero FROM mesas WHERE id = m.mesa_padre_id) as numero_padre,
        COALESCE(m.mesa_padre_id, m.id) as grupo_id
    FROM mesas m 
    ORDER BY m.numero ASC
  `);
    return result.rows;
};
exports.getMesas = getMesas;
const createMesa = async (capacidad) => {
    const configRes = await db_1.default.query('SELECT max_mesas FROM configuraciones LIMIT 1');
    const maxMesas = configRes.rows.length > 0 ? parseInt(configRes.rows[0].max_mesas, 10) : 30;
    const queryResult = await db_1.default.query('SELECT numero FROM mesas;');
    if (queryResult.rows.length >= maxMesas) {
        throw new Error(`No se pueden crear más mesas. El máximo permitido es ${maxMesas}.`);
    }
    const numeros = queryResult.rows
        .map(r => parseInt(String(r.numero).replace(/\D/g, ''), 10))
        .filter(n => !isNaN(n));
    const maxNumero = numeros.length > 0 ? Math.max(...numeros) : 0;
    const siguienteNumero = maxNumero + 1;
    const result = await db_1.default.query(`INSERT INTO mesas (numero, estado, capacidad, mesa_padre_id)
     VALUES ($1, $2, $3, NULL)
     RETURNING *;`, [siguienteNumero.toString(), 'libre', capacidad]);
    return result.rows[0];
};
exports.createMesa = createMesa;
const updateEstadoMesa = async (id, estado) => {
    const result = await db_1.default.query('UPDATE mesas SET estado = $1 WHERE id = $2 RETURNING *', [estado, id]);
    return result.rows[0];
};
exports.updateEstadoMesa = updateEstadoMesa;
const getTotalMesas = async () => {
    const result = await db_1.default.query('SELECT COUNT(*) FROM mesas');
    return parseInt(result.rows[0].count, 10);
};
exports.getTotalMesas = getTotalMesas;
const deleteUltimaMesa = async () => {
    const configRes = await db_1.default.query('SELECT min_mesas FROM configuraciones LIMIT 1');
    const minMesas = configRes.rows.length > 0 ? parseInt(configRes.rows[0].min_mesas, 10) : 1;
    const queryResult = await db_1.default.query('SELECT id, numero FROM mesas;');
    const filas = queryResult.rows;
    if (filas.length <= minMesas) {
        throw new Error(`No se pueden eliminar más mesas. El mínimo permitido es ${minMesas}.`);
    }
    let maxNumero = -1;
    let idToDelete = null;
    for (const fila of filas) {
        const num = parseInt(String(fila.numero).replace(/\\D/g, ''), 10);
        if (!isNaN(num) && num > maxNumero) {
            maxNumero = num;
            idToDelete = fila.id;
        }
    }
    if (idToDelete === null)
        return null;
    // 1. Validar si hay comandas activas en la mesa a eliminar
    const comandasActivas = await db_1.default.query("SELECT id FROM comandas WHERE mesa_id = $1 AND estado IN ('abierta', 'pendiente', 'en_proceso') LIMIT 1", [idToDelete]);
    if (comandasActivas.rows.length > 0) {
        throw new Error('No se puede eliminar la mesa porque tiene un pedido activo.');
    }
    // 2. Transacción: desvincular histórico y eliminar mesa
    await db_1.default.query('BEGIN');
    try {
        await db_1.default.query('UPDATE mesas SET mesa_padre_id = NULL WHERE mesa_padre_id = $1;', [idToDelete]);
        await db_1.default.query('UPDATE comandas SET mesa_id = NULL WHERE mesa_id = $1;', [idToDelete]);
        const result = await db_1.default.query('DELETE FROM mesas WHERE id = $1 RETURNING *;', [idToDelete]);
        await db_1.default.query('COMMIT');
        return result.rows[0];
    }
    catch (error) {
        await db_1.default.query('ROLLBACK');
        throw error;
    }
};
exports.deleteUltimaMesa = deleteUltimaMesa;
const juntarMesas = async (mesaHijaId, mesaPadreId) => {
    const padreResult = await db_1.default.query('SELECT mesa_padre_id FROM mesas WHERE id = $1', [mesaPadreId]);
    let rootPadreId = mesaPadreId;
    if (padreResult.rows.length > 0 && padreResult.rows[0].mesa_padre_id) {
        rootPadreId = padreResult.rows[0].mesa_padre_id;
    }
    const result = await db_1.default.query(`UPDATE mesas SET mesa_padre_id = $1, estado = 'ocupada' WHERE id = $2 RETURNING *`, [rootPadreId, mesaHijaId]);
    return result.rows[0];
};
exports.juntarMesas = juntarMesas;
const separarMesa = async (mesaId) => {
    const result = await db_1.default.query(`UPDATE mesas SET mesa_padre_id = NULL, estado = 'libre' WHERE id = $1 RETURNING *`, [mesaId]);
    await db_1.default.query(`UPDATE mesas SET mesa_padre_id = NULL, estado = 'libre' WHERE mesa_padre_id = $1`, [mesaId]);
    return result.rows[0];
};
exports.separarMesa = separarMesa;
//# sourceMappingURL=mesas.repository.js.map