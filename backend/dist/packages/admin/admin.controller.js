"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.obtenerReporteDiario = exports.eliminarNotaRapida = exports.actualizarNotaRapida = exports.crearNotaRapida = exports.obtenerNotasRapidas = exports.actualizarConfig = exports.obtenerConfig = exports.loginPin = exports.eliminarMesero = exports.updateEstadoMesero = exports.actualizarMesero = exports.crearMesero = exports.obtenerMeseros = void 0;
const crypto_helper_1 = require("../../utils/crypto.helper");
const admin_repository_1 = require("./admin.repository");
const obtenerMeseros = async (req, res) => {
    try {
        const incluirInactivos = req.query.incluirInactivos !== 'false';
        const meseros = await admin_repository_1.AdminRepository.obtenerMeseros(incluirInactivos);
        const meserosMapeados = meseros.map(m => ({
            ...m,
            pin: (0, crypto_helper_1.decryptPin)(m.pin)
        }));
        res.json(meserosMapeados);
    }
    catch (error) {
        console.error('Error al obtener meseros:', error);
        res.status(500).json({ error: 'Error interno del servidor' });
    }
};
exports.obtenerMeseros = obtenerMeseros;
const crearMesero = async (req, res) => {
    try {
        const { nombre } = req.body;
        const rawPin = req.body.pin || req.body.pin_hash;
        if (!nombre || !rawPin) {
            res.status(400).json({ error: 'Nombre y PIN son obligatorios.' });
            return;
        }
        const pinString = String(rawPin).trim();
        // Validación PIN numérico de 4 dígitos
        if (!/^\d{4}$/.test(pinString)) {
            res.status(400).json({ error: 'El PIN debe ser un número exacto de 4 dígitos.' });
            return;
        }
        const pinHash = (0, crypto_helper_1.encryptPin)(pinString);
        const nuevoMesero = await admin_repository_1.AdminRepository.crearMesero(nombre, pinHash);
        res.status(201).json(nuevoMesero);
    }
    catch (error) {
        console.error('Error al crear mesero:', error);
        res.status(500).json({ error: 'Error interno del servidor' });
    }
};
exports.crearMesero = crearMesero;
const actualizarMesero = async (req, res) => {
    try {
        const { id } = req.params;
        const { nombre, activo } = req.body;
        const rawPin = req.body.pin || req.body.pin_hash;
        let pinHash = undefined;
        if (rawPin !== undefined && rawPin !== null && rawPin !== '') {
            const pinString = String(rawPin).trim();
            if (!/^\d{4}$/.test(pinString)) {
                res.status(400).json({ error: 'El PIN debe ser un número exacto de 4 dígitos.' });
                return;
            }
            pinHash = (0, crypto_helper_1.encryptPin)(pinString);
        }
        // Convert string "true"/"false" if passed from form-data, otherwise boolean
        let activoBool = undefined;
        if (activo !== undefined) {
            activoBool = typeof activo === 'string' ? activo === 'true' : Boolean(activo);
        }
        const meseroActualizado = await admin_repository_1.AdminRepository.actualizarMesero(parseInt(id, 10), nombre, activoBool, pinHash);
        res.json(meseroActualizado);
    }
    catch (error) {
        console.error('Error al actualizar mesero:', error);
        res.status(500).json({ error: 'Error interno del servidor' });
    }
};
exports.actualizarMesero = actualizarMesero;
const updateEstadoMesero = async (req, res) => {
    try {
        const { id } = req.params;
        const { activo } = req.body;
        if (activo === undefined) {
            res.status(400).json({ error: 'El campo activo es obligatorio.' });
            return;
        }
        const mesero = await admin_repository_1.AdminRepository.updateEstadoMesero(parseInt(id, 10), Boolean(activo));
        if (!mesero) {
            res.status(404).json({ error: 'Mesero no encontrado.' });
            return;
        }
        res.json({ message: 'Estado del mesero actualizado correctamente', mesero });
    }
    catch (error) {
        console.error('Error al actualizar estado del mesero:', error);
        res.status(500).json({ error: 'Error interno del servidor' });
    }
};
exports.updateEstadoMesero = updateEstadoMesero;
const eliminarMesero = async (req, res) => {
    try {
        const { id } = req.params;
        const hard = req.query.hard === 'true';
        const mesero = await admin_repository_1.AdminRepository.eliminarMesero(parseInt(id, 10), hard);
        res.json({ message: 'Mesero procesado correctamente', mesero });
    }
    catch (error) {
        console.error('Error al eliminar mesero:', error);
        if (error.code === '23503' || error.message.includes('comandas asociadas')) {
            res.status(400).json({ error: error.message });
            return;
        }
        if (error.message.includes('comandas activas')) {
            res.status(400).json({ error: error.message });
            return;
        }
        res.status(500).json({ error: 'Error interno del servidor' });
    }
};
exports.eliminarMesero = eliminarMesero;
const loginPin = async (req, res) => {
    try {
        console.log('>>> [HTTP] PETICIÓN DE LOGIN CON PIN RECIBIDA', req.body);
        const { pin } = req.body;
        if (!pin || !/^\d{4}$/.test(pin)) {
            res.status(400).json({ error: 'Debe proporcionar un PIN válido de 4 dígitos.' });
            return;
        }
        const mesero = await admin_repository_1.AdminRepository.validarPinMesero(pin);
        if (!mesero) {
            res.status(401).json({ error: 'PIN incorrecto o mesero inactivo.' });
            return;
        }
        // Retorna los datos básicos del usuario para guardarlos en sesión local
        res.json({ success: true, usuario: mesero });
    }
    catch (error) {
        console.error('Error en login con PIN:', error);
        res.status(500).json({ error: 'Error interno del servidor' });
    }
};
exports.loginPin = loginPin;
const obtenerConfig = async (req, res) => {
    try {
        const config = await admin_repository_1.AdminRepository.obtenerConfiguracion();
        res.json(config);
    }
    catch (error) {
        console.error('Error al obtener configuración:', error);
        res.status(500).json({ error: 'Error interno del servidor' });
    }
};
exports.obtenerConfig = obtenerConfig;
const actualizarConfig = async (req, res) => {
    try {
        const { min_mesas, max_mesas } = req.body;
        if (min_mesas === undefined || max_mesas === undefined) {
            res.status(400).json({ error: 'Debe proveer min_mesas y max_mesas.' });
            return;
        }
        const configActualizada = await admin_repository_1.AdminRepository.actualizarConfiguracion(min_mesas, max_mesas);
        res.json(configActualizada);
    }
    catch (error) {
        console.error('Error al actualizar configuración:', error);
        res.status(500).json({ error: 'Error interno del servidor' });
    }
};
exports.actualizarConfig = actualizarConfig;
const obtenerNotasRapidas = async (req, res) => {
    try {
        const notas = await admin_repository_1.AdminRepository.obtenerNotasRapidas();
        res.json(notas);
    }
    catch (error) {
        console.error('Error al obtener notas rápidas:', error);
        res.status(500).json({ error: 'Error interno del servidor' });
    }
};
exports.obtenerNotasRapidas = obtenerNotasRapidas;
const crearNotaRapida = async (req, res) => {
    try {
        const { texto, precio_extra } = req.body;
        if (!texto || texto.trim().length === 0) {
            res.status(400).json({ error: 'El texto de la nota rápida es obligatorio.' });
            return;
        }
        const precio = precio_extra != null ? Number(precio_extra) : 0;
        const nuevaNota = await admin_repository_1.AdminRepository.crearNotaRapida(texto.trim(), precio);
        res.status(201).json(nuevaNota);
    }
    catch (error) {
        console.error('Error al crear nota rápida:', error);
        res.status(500).json({ error: 'Error interno del servidor' });
    }
};
exports.crearNotaRapida = crearNotaRapida;
const actualizarNotaRapida = async (req, res) => {
    try {
        const { id } = req.params;
        const { texto, precio_extra } = req.body;
        if (!texto || texto.trim().length === 0) {
            res.status(400).json({ error: 'El texto de la nota rápida es obligatorio.' });
            return;
        }
        const precio = precio_extra != null ? Number(precio_extra) : 0;
        const notaActualizada = await admin_repository_1.AdminRepository.actualizarNotaRapida(Number(id), texto.trim(), precio);
        res.json(notaActualizada);
    }
    catch (error) {
        console.error('Error al actualizar nota rápida:', error);
        res.status(500).json({ error: 'Error interno del servidor' });
    }
};
exports.actualizarNotaRapida = actualizarNotaRapida;
const eliminarNotaRapida = async (req, res) => {
    try {
        const { id } = req.params;
        await admin_repository_1.AdminRepository.eliminarNotaRapida(parseInt(id, 10));
        res.json({ message: 'Nota eliminada correctamente' });
    }
    catch (error) {
        console.error('Error al eliminar nota rápida:', error);
        res.status(500).json({ error: 'Error interno del servidor' });
    }
};
exports.eliminarNotaRapida = eliminarNotaRapida;
const obtenerReporteDiario = async (req, res) => {
    try {
        const reporte = await admin_repository_1.AdminRepository.obtenerReporteDiario();
        res.json(reporte);
    }
    catch (error) {
        console.error('Error al generar reporte diario:', error);
        res.status(500).json({ error: 'Error interno del servidor' });
    }
};
exports.obtenerReporteDiario = obtenerReporteDiario;
//# sourceMappingURL=admin.controller.js.map