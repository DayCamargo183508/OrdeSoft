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
exports.separarMesa = exports.juntarMesas = exports.deleteMesa = exports.updateEstado = exports.createMesa = exports.getMesas = void 0;
const MesasRepository = __importStar(require("./mesas.repository"));
const getMesas = async (req, res) => {
    try {
        const mesas = await MesasRepository.getMesas();
        res.json(mesas);
    }
    catch (error) {
        console.error('Error obteniendo mesas:', error);
        res.status(500).json({ message: error.message || 'Error al obtener las mesas' });
    }
};
exports.getMesas = getMesas;
const createMesa = async (req, res) => {
    try {
        if (req.user?.rol !== 'admin' && req.user?.rol !== 'mesero') {
            res.status(403).json({ error: 'No tienes permisos para crear mesas. Se requiere rol admin o mesero.' });
            return;
        }
        const { capacidad } = req.body;
        const nuevaMesa = await MesasRepository.createMesa(capacidad || 4);
        res.status(201).json(nuevaMesa);
    }
    catch (error) {
        console.error('[ERROR] createMesa:', error);
        res.status(500).json({ message: error.message || 'Error interno al crear mesa' });
    }
};
exports.createMesa = createMesa;
const updateEstado = async (req, res) => {
    try {
        const { id } = req.params;
        const { estado } = req.body;
        const estadosValidos = ['libre', 'ocupada', 'atendida', 'reservada'];
        if (!estadosValidos.includes(estado)) {
            res.status(400).json({ message: 'Estado inválido.' });
            return;
        }
        const mesaActualizada = await MesasRepository.updateEstadoMesa(Number(id), estado);
        if (!mesaActualizada) {
            res.status(404).json({ error: 'Mesa no encontrada.' });
            return;
        }
        res.json(mesaActualizada);
    }
    catch (error) {
        console.error('Error actualizando estado de mesa:', error);
        res.status(500).json({ message: error.message || 'Error al actualizar estado de la mesa' });
    }
};
exports.updateEstado = updateEstado;
const deleteMesa = async (req, res) => {
    try {
        if (req.user?.rol !== 'admin' && req.user?.rol !== 'mesero') {
            res.status(403).json({ message: 'No tienes permisos para eliminar mesas. Se requiere rol admin o mesero.' });
            return;
        }
        const mesaEliminada = await MesasRepository.deleteUltimaMesa();
        if (!mesaEliminada) {
            res.status(404).json({ message: 'No hay mesas para eliminar.' });
            return;
        }
        res.json({ message: 'Mesa eliminada con éxito', mesa: mesaEliminada });
    }
    catch (error) {
        console.error('[ERROR] deleteMesa:', error);
        // Return 400 if it's the known validation error from the repo, otherwise 500
        if (error.message.includes("mínimo permitido") || error.message.includes("pedido activo")) {
            res.status(400).json({ message: error.message });
        }
        else {
            res.status(500).json({ message: error.message || 'Error interno al eliminar mesa' });
        }
    }
};
exports.deleteMesa = deleteMesa;
const juntarMesas = async (req, res) => {
    try {
        const { mesa_hija_id, mesa_padre_id } = req.body;
        if (!mesa_hija_id || !mesa_padre_id) {
            res.status(400).json({ message: 'Faltan datos: mesa_hija_id o mesa_padre_id.' });
            return;
        }
        const mesaActualizada = await MesasRepository.juntarMesas(Number(mesa_hija_id), Number(mesa_padre_id));
        if (!mesaActualizada) {
            res.status(404).json({ message: 'Mesa hija no encontrada.' });
            return;
        }
        res.status(200).json({ message: 'Mesas juntadas con éxito', mesa: mesaActualizada });
    }
    catch (error) {
        console.error('Error juntando mesas:', error);
        res.status(500).json({ message: error.message || 'Error al juntar las mesas' });
    }
};
exports.juntarMesas = juntarMesas;
const separarMesa = async (req, res) => {
    try {
        const { mesa_id } = req.body;
        if (!mesa_id) {
            res.status(400).json({ message: 'El mesa_id es requerido.' });
            return;
        }
        const mesaActualizada = await MesasRepository.separarMesa(Number(mesa_id));
        if (!mesaActualizada) {
            res.status(404).json({ error: 'Mesa no encontrada.' });
            return;
        }
        res.status(200).json({ message: 'Mesa separada con éxito', mesa: mesaActualizada });
    }
    catch (error) {
        console.error('Error separando mesa:', error);
        res.status(500).json({ message: error.message || 'Error al separar la mesa' });
    }
};
exports.separarMesa = separarMesa;
//# sourceMappingURL=mesas.controller.js.map