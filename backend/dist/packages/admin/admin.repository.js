"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.AdminRepository = void 0;
const db_1 = __importDefault(require("../../config/db"));
const crypto_helper_1 = require("../../utils/crypto.helper");
exports.AdminRepository = {
    // --- MESEROS (Usuarios) ---
    async obtenerMeseros(incluirInactivos = false) {
        let query = "SELECT id, nombre, rol, activo, creado_en, pin_hash as pin FROM usuarios WHERE LOWER(rol) = 'mesero'";
        if (!incluirInactivos) {
            query += " AND activo = true";
        }
        query += " ORDER BY id ASC";
        const res = await db_1.default.query(query);
        return res.rows;
    },
    async crearMesero(nombre, pin_hash) {
        const res = await db_1.default.query("INSERT INTO usuarios (nombre, pin_hash, rol) VALUES ($1, $2, 'mesero') RETURNING id, nombre, rol, activo", [nombre, pin_hash]);
        return res.rows[0];
    },
    async updateEstadoMesero(id, activo) {
        const res = await db_1.default.query("UPDATE usuarios SET activo = $1 WHERE id = $2 RETURNING id, nombre, activo", [activo, id]);
        return res.rows[0];
    },
    async actualizarMesero(id, nombre, activo, pin_hash) {
        const res = await db_1.default.query(`UPDATE usuarios 
       SET 
         nombre = COALESCE($1, nombre),
         activo = COALESCE($2, activo),
         pin_hash = COALESCE($3, pin_hash)
       WHERE id = $4 
       RETURNING id, nombre, rol, activo`, [nombre, activo, pin_hash, id]);
        return res.rows[0];
    },
    async validarPinMesero(pinEnviado) {
        const pinBuscado = String(pinEnviado).trim();
        console.log('>>> [LOGIN] PIN INGRESADO (STRING):', `"${pinBuscado}"`);
        const res = await db_1.default.query("SELECT id, nombre, rol, pin_hash FROM usuarios WHERE activo = TRUE AND LOWER(rol) IN ('mesero', 'admin')");
        console.log(`>>> [LOGIN] MESEROS ACTIVOS ENCONTRADOS EN BD: ${res.rows.length}`);
        for (const mesero of res.rows) {
            if (mesero.pin_hash) {
                const pinDesencriptado = (0, crypto_helper_1.decryptPin)(mesero.pin_hash);
                console.log(`>>> [LOGIN] EVALUANDO ID ${mesero.id} (${mesero.nombre}): DB_PIN="${pinDesencriptado}" VS INGRESADO="${pinBuscado}"`);
                if (pinDesencriptado === pinBuscado) {
                    console.log(`>>> [LOGIN] ¡COINCIDENCIA EXITOSA CON ${mesero.nombre}!`);
                    const { pin_hash, ...usuarioLimpio } = mesero;
                    return usuarioLimpio;
                }
            }
        }
        console.log('>>> [LOGIN] NINGÚN PIN COINCIDIÓ');
        return null;
    },
    async eliminarMesero(id, hard = false) {
        if (hard) {
            try {
                const res = await db_1.default.query('DELETE FROM usuarios WHERE id = $1 RETURNING id, nombre, activo', [id]);
                return res.rows[0];
            }
            catch (error) {
                if (error.code === '23503') {
                    const softRes = await db_1.default.query("UPDATE usuarios SET activo = false WHERE id = $1 RETURNING id, nombre, activo", [id]);
                    const fallbackError = new Error('No se puede eliminar definitivamente porque el mesero tiene comandas asociadas. Se procedió a desactivarlo.');
                    fallbackError.code = '23503';
                    throw fallbackError;
                }
                throw error;
            }
        }
        // Verificar si tiene comandas abiertas (para borrado lógico default)
        const checkRes = await db_1.default.query("SELECT id FROM comandas WHERE usuario_id = $1 AND estado NOT IN ('pagado', 'cancelado') LIMIT 1", [id]);
        if (checkRes.rows.length > 0) {
            throw new Error('El mesero tiene comandas activas pendientes. Cierre o reasigne las comandas antes de eliminarlo.');
        }
        // Soft delete
        const res = await db_1.default.query("UPDATE usuarios SET activo = false WHERE id = $1 RETURNING id, nombre, activo", [id]);
        return res.rows[0];
    },
    // --- CONFIGURACIONES ---
    async obtenerConfiguracion() {
        const res = await db_1.default.query("SELECT min_mesas, max_mesas FROM configuraciones LIMIT 1");
        return res.rows[0];
    },
    async actualizarConfiguracion(min_mesas, max_mesas) {
        const res = await db_1.default.query("UPDATE configuraciones SET min_mesas = $1, max_mesas = $2 RETURNING min_mesas, max_mesas", [min_mesas, max_mesas]);
        return res.rows[0];
    },
    // --- NOTAS RAPIDAS ---
    async obtenerNotasRapidas() {
        const res = await db_1.default.query("SELECT * FROM notas_rapidas ORDER BY id ASC");
        return res.rows;
    },
    async crearNotaRapida(texto, precio_extra = 0) {
        const res = await db_1.default.query("INSERT INTO notas_rapidas (texto, precio_extra) VALUES ($1, $2) RETURNING *", [texto, precio_extra]);
        return res.rows[0];
    },
    async actualizarNotaRapida(id, texto, precio_extra = 0) {
        const res = await db_1.default.query("UPDATE notas_rapidas SET texto = $1, precio_extra = $2 WHERE id = $3 RETURNING *", [texto, precio_extra, id]);
        return res.rows[0];
    },
    async eliminarNotaRapida(id) {
        await db_1.default.query("DELETE FROM notas_rapidas WHERE id = $1", [id]);
    },
    // --- REPORTE DIARIO ---
    async obtenerReporteDiario() {
        // Agrupamos el global por día actual, contando solo estado='pagado' y sumando el efectivo
        const queryGeneral = `
      SELECT 
        COUNT(id) as total_comandas,
        COALESCE(SUM(total), 0) as total_efectivo
      FROM comandas 
      WHERE estado = 'pagado' 
        AND metodo_pago = 'EFECTIVO'
        AND DATE(created_at) = CURRENT_DATE
    `;
        // Desglose por mesero
        const queryDesglose = `
      SELECT 
        u.id as mesero_id,
        u.nombre as mesero_nombre,
        COUNT(c.id) as comandas_tomadas,
        COALESCE(SUM(c.total), 0) as total_vendido
      FROM comandas c
      JOIN usuarios u ON c.usuario_id = u.id
      WHERE c.estado = 'pagado'
        AND DATE(c.created_at) = CURRENT_DATE
      GROUP BY u.id, u.nombre
      ORDER BY total_vendido DESC
    `;
        const queryDetalle = `
      SELECT 
        c.id as id,
        FORMAT('CTA-%s', LPAD(c.id::text, 4, '0')) as numero_cuenta,
        c.tipo_orden as tipo_comanda,
        c.nombre_cliente,
        c.created_at,
        c.total,
        u.nombre as mesero_nombre,
        m.numero as numero_mesa,
        CASE 
          WHEN c.mesa_id IS NULL OR c.mesa_id = 0 THEN 
            COALESCE(NULLIF(c.nombre_cliente, ''), 'Para Llevar')
          ELSE 
            CONCAT('Mesa ', m.numero, CASE WHEN c.nombre_cliente IS NOT NULL AND c.nombre_cliente != '' THEN CONCAT(' (', c.nombre_cliente, ')') ELSE '' END)
        END AS identificador_vista,
        to_char(c.created_at AT TIME ZONE 'UTC', 'YYYY-MM-DD"T"HH24:MI:SS"Z"') as fecha_cierre,
        COALESCE(
          json_agg(
            json_build_object(
              'nombre', cd.producto_nombre,
              'cantidad', cd.cantidad,
              'precio_unitario', cd.precio_unitario,
              'subtotal', cd.subtotal
            )
          ) FILTER (WHERE cd.id IS NOT NULL),
          '[]'
        ) as items
      FROM comandas c
      LEFT JOIN mesas m ON c.mesa_id = m.id
      JOIN usuarios u ON c.usuario_id = u.id
      LEFT JOIN comanda_detalles cd ON c.id = cd.comanda_id
      WHERE c.estado = 'pagado'
        AND DATE(c.created_at) = CURRENT_DATE
      GROUP BY c.id, m.numero, u.nombre, c.tipo_orden, c.nombre_cliente, c.created_at
      ORDER BY c.created_at DESC
    `;
        const queryArticulos = `
      SELECT 
        cd.producto_id as producto_id,
        cd.producto_nombre as nombre,
        'General' as categoria,
        SUM(cd.cantidad) as cantidad_vendida,
        SUM(cd.subtotal) as total_generado
      FROM comandas c
      JOIN comanda_detalles cd ON c.id = cd.comanda_id
      WHERE c.estado = 'pagado'
        AND DATE(c.created_at) = CURRENT_DATE
      GROUP BY cd.producto_id, cd.producto_nombre
      ORDER BY cantidad_vendida DESC
    `;
        const [resGeneral, resDesglose, resDetalle, resArticulos] = await Promise.all([
            db_1.default.query(queryGeneral),
            db_1.default.query(queryDesglose),
            db_1.default.query(queryDetalle),
            db_1.default.query(queryArticulos)
        ]);
        const general = resGeneral.rows[0];
        const desglose = resDesglose.rows.map(row => {
            const comandasTomadas = parseInt(row.comandas_tomadas, 10);
            const totalVendido = parseFloat(row.total_vendido);
            return {
                ...row,
                comandas_tomadas: comandasTomadas,
                total_vendido: totalVendido,
                ticket_promedio: comandasTomadas > 0 ? parseFloat((totalVendido / comandasTomadas).toFixed(2)) : 0
            };
        });
        const totalComandas = parseInt(general.total_comandas, 10);
        const totalEfectivo = parseFloat(general.total_efectivo);
        // Calcular totales de artículos
        const totalArticulos = resArticulos.rows.reduce((acc, row) => acc + parseInt(row.cantidad_vendida, 10), 0);
        const articulosDetalle = resArticulos.rows.map(row => ({
            ...row,
            cantidad_vendida: parseInt(row.cantidad_vendida, 10),
            total_generado: parseFloat(row.total_generado)
        }));
        return {
            total_cobrado_efectivo: totalEfectivo,
            total_comandas_completadas: totalComandas,
            ticket_promedio_general: totalComandas > 0 ? parseFloat((totalEfectivo / totalComandas).toFixed(2)) : 0,
            desglose_por_mesero: desglose,
            articulos_vendidos: {
                total_cantidad: totalArticulos,
                desglose: articulosDetalle
            },
            comandas_detalle: resDetalle.rows.map(row => ({
                ...row,
                total: parseFloat(row.total)
            }))
        };
    }
};
//# sourceMappingURL=admin.repository.js.map