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
exports.obtenerTicketCocina = exports.pagarCuenta = exports.pagarComanda = exports.crearComanda = exports.obtenerPorId = exports.obtenerParaLlevar = exports.obtenerActivas = void 0;
const ComandasRepository = __importStar(require("./comandas.repository"));
const db_1 = __importDefault(require("../../config/db"));
const firebase_1 = require("../../config/firebase");
const obtenerActivas = async (req, res) => {
    try {
        const comandas = await ComandasRepository.obtenerComandasActivas();
        res.json(comandas);
    }
    catch (error) {
        console.error('Error obteniendo comandas activas:', error);
        res.status(500).json({ message: error.message || 'Error al obtener comandas activas' });
    }
};
exports.obtenerActivas = obtenerActivas;
const obtenerParaLlevar = async (req, res) => {
    try {
        const comandas = await ComandasRepository.obtenerComandasParaLlevar();
        res.json(comandas);
    }
    catch (error) {
        console.error('Error obteniendo comandas para llevar:', error);
        res.status(500).json({ message: error.message || 'Error al obtener comandas para llevar' });
    }
};
exports.obtenerParaLlevar = obtenerParaLlevar;
const obtenerPorId = async (req, res) => {
    try {
        const { id } = req.params;
        const comanda = await ComandasRepository.obtenerComandaPorId(Number(id));
        if (!comanda) {
            res.status(404).json({ error: 'Comanda no encontrada.' });
            return;
        }
        res.json(comanda);
    }
    catch (error) {
        console.error('Error obteniendo detalle de comanda:', error);
        res.status(500).json({ message: error.message || 'Error al obtener detalle de la comanda' });
    }
};
exports.obtenerPorId = obtenerPorId;
const crearComanda = async (req, res) => {
    try {
        const { mesa_id, detalles, tipo_orden = 'MESA', nombre_cliente, comanda_id } = req.body;
        // Validación base
        if (!detalles || !Array.isArray(detalles) || detalles.length === 0) {
            res.status(400).json({ error: 'Un arreglo de detalles es requerido.' });
            return;
        }
        // Validación por tipo_orden
        if (tipo_orden === 'PARA_LLEVAR') {
            if (!nombre_cliente || typeof nombre_cliente !== 'string' || nombre_cliente.trim() === '') {
                res.status(400).json({ error: 'nombre_cliente es obligatorio para pedidos PARA_LLEVAR.' });
                return;
            }
        }
        else { // Asumimos MESA
            if (!mesa_id) {
                res.status(400).json({ error: 'mesa_id es obligatorio para pedidos en mesa.' });
                return;
            }
        }
        // El ID de usuario se extrae del token validado por authMiddleware
        const usuario_id = req.user?.id;
        if (!usuario_id) {
            res.status(401).json({ error: 'Usuario no autenticado correctamente.' });
            return;
        }
        // Verificar mesa si está libre (solo si es pedido de mesa)
        if (tipo_orden !== 'PARA_LLEVAR' && mesa_id && !comanda_id) {
            const mesaQuery = await db_1.default.query('SELECT estado FROM mesas WHERE id = $1', [mesa_id]);
            if (mesaQuery.rows.length === 0) {
                res.status(404).json({ error: 'La mesa indicada no existe.' });
                return;
            }
            if (mesaQuery.rows[0].estado !== 'libre') {
                res.status(400).json({ error: 'La mesa no está libre.' });
                return;
            }
        }
        // Formateamos los detalles extrayendo el precio unitario del producto para evitar precios manipulados por cliente
        const detallesFormateados = [];
        for (const d of detalles) {
            if (!d.producto_id || d.cantidad <= 0) {
                res.status(400).json({ error: 'Formato de detalle inválido.' });
                return;
            }
            // Obtener el precio base y nombre si el frontend no envió un precio unitario final
            if (!firebase_1.firestore) {
                res.status(500).json({ message: 'Firestore no está inicializado. Verifica firebase-key.json' });
                return;
            }
            const prodRef = await firebase_1.firestore.collection('productos').doc(d.producto_id).get();
            if (!prodRef.exists || !prodRef.data()?.disponible) {
                res.status(400).json({ error: `El producto con ID ${d.producto_id} no existe o no está disponible.` });
                return;
            }
            const prodData = prodRef.data();
            const precioUnitario = d.precio_unitario !== undefined && d.precio_unitario !== null
                ? Number(d.precio_unitario)
                : Number(prodData?.precio);
            detallesFormateados.push({
                producto_id: d.producto_id,
                producto_nombre: prodData?.nombre || 'Producto',
                cantidad: d.cantidad,
                precio_unitario: precioUnitario,
                notas: d.notas,
                cuenta_id: d.cuenta_id,
                cliente_nombre: d.cliente_nombre
            });
        }
        // Ejecutar la transacción
        const mesaIdParaDB = tipo_orden === 'PARA_LLEVAR' ? null : mesa_id;
        const nombreParaDB = tipo_orden === 'PARA_LLEVAR' ? nombre_cliente : null;
        let nuevaComanda;
        if (comanda_id) {
            nuevaComanda = await ComandasRepository.agregarDetallesComandaTransaccional(comanda_id, detallesFormateados);
            res.status(200).json({ message: 'Productos agregados con éxito', comanda: nuevaComanda });
        }
        else {
            nuevaComanda = await ComandasRepository.crearComandaTransaccional(mesaIdParaDB, tipo_orden, nombreParaDB, usuario_id, detallesFormateados);
            res.status(201).json({ message: 'Comanda creada con éxito', comanda: nuevaComanda });
        }
    }
    catch (error) {
        console.error('Error creando comanda:', error);
        res.status(500).json({ message: error.message || 'Error interno al crear comanda.' });
    }
};
exports.crearComanda = crearComanda;
const pagarComanda = async (req, res) => {
    try {
        const { id } = req.params;
        const comandaPagada = await ComandasRepository.pagarComanda(Number(id));
        res.json({ message: 'Comanda pagada exitosamente', comanda: comandaPagada });
    }
    catch (error) {
        console.error('Error al pagar comanda:', error);
        if (error.message === 'Comanda no encontrada') {
            res.status(404).json({ message: error.message });
            return;
        }
        res.status(500).json({ message: error.message || 'Error al procesar el pago de la comanda.' });
    }
};
exports.pagarComanda = pagarComanda;
const pagarCuenta = async (req, res) => {
    try {
        const { id } = req.params;
        const { cuenta_id } = req.body;
        if (cuenta_id === undefined) {
            res.status(400).json({ error: 'cuenta_id es requerido' });
            return;
        }
        const resultado = await ComandasRepository.pagarCuenta(Number(id), Number(cuenta_id));
        res.json({ message: 'Cuenta pagada exitosamente', ...resultado });
    }
    catch (error) {
        console.error('Error al pagar cuenta:', error);
        res.status(500).json({ message: error.message || 'Error al procesar el pago de la cuenta.' });
    }
};
exports.pagarCuenta = pagarCuenta;
const obtenerTicketCocina = async (req, res) => {
    try {
        const { id } = req.params;
        const ticketData = await ComandasRepository.obtenerTicketCocina(Number(id));
        if (!ticketData) {
            res.status(404).json({ error: 'Comanda no encontrada.' });
            return;
        }
        const { cabecera, detalles } = ticketData;
        const gruposMap = {};
        const totalesMap = {};
        for (const d of detalles) {
            // Regla de formato: si no hay notas, es "Todo"
            let instruccion = 'Todo';
            if (d.notas && d.notas.trim() !== '') {
                const notaTrimmed = d.notas.trim();
                // Capitalizamos primera letra para formato limpio
                instruccion = notaTrimmed.charAt(0).toUpperCase() + notaTrimmed.slice(1);
            }
            if (!gruposMap[instruccion]) {
                gruposMap[instruccion] = [];
            }
            gruposMap[instruccion].push({ cantidad: d.cantidad, producto: d.producto });
            if (!totalesMap[d.producto]) {
                totalesMap[d.producto] = 0;
            }
            totalesMap[d.producto] += d.cantidad;
        }
        const grupos_preparacion = Object.keys(gruposMap).map(key => ({
            instruccion: key,
            items: gruposMap[key]
        }));
        // Construcción del resumen_final: "12 Tacos 1 Hamburguesa"
        const resumenArr = Object.keys(totalesMap).map(prod => `${totalesMap[prod]} ${prod}`);
        const resumen_final = resumenArr.join(' ');
        res.json({
            mesa_numero: cabecera.mesa_numero,
            mesero_nombre: cabecera.mesero,
            grupos_preparacion,
            resumen_final
        });
    }
    catch (error) {
        console.error('Error generando ticket:', error);
        res.status(500).json({ message: error.message || 'Error al generar el ticket de cocina.' });
    }
};
exports.obtenerTicketCocina = obtenerTicketCocina;
//# sourceMappingURL=comandas.controller.js.map