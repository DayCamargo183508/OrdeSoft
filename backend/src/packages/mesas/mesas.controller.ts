import { Request, Response } from 'express';
import * as MesasRepository from './mesas.repository';

export const getMesas = async (req: Request, res: Response) => {
  try {
    const mesas = await MesasRepository.getMesas();
    res.json(mesas);
  } catch (error) {
    console.error('[DATABASE ERROR]:', error);
    console.error('Error obteniendo mesas:', error);
    res.status(500).json({ message: (error as Error).message || 'Error al obtener las mesas' });
  }
};

export const createMesa = async (req: Request, res: Response) => {
  try {
    if (req.user?.rol !== 'admin' && req.user?.rol !== 'mesero') {
      res.status(403).json({ error: 'No tienes permisos para crear mesas. Se requiere rol admin o mesero.' });
      return;
    }
    const { capacidad } = req.body;
    const nuevaMesa = await MesasRepository.createMesa(capacidad || 4);
    res.status(201).json(nuevaMesa);
  } catch (error: any) {
    console.error('[DATABASE ERROR]:', error);
    console.error('[ERROR] createMesa:', error);
    res.status(500).json({ message: error.message || 'Error interno al crear mesa' });
  }
};

export const updateEstado = async (req: Request, res: Response) => {
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
  } catch (error) {
    console.error('[DATABASE ERROR]:', error);
    console.error('Error actualizando estado de mesa:', error);
    res.status(500).json({ message: (error as Error).message || 'Error al actualizar estado de la mesa' });
  }
};

export const deleteMesa = async (req: Request, res: Response) => {
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
  } catch (error: any) {
    console.error('[DATABASE ERROR]:', error);
    console.error('[ERROR] deleteMesa:', error);
    // Return 400 if it's the known validation error from the repo, otherwise 500
    if (error.message.includes("mínimo permitido") || error.message.includes("pedido activo")) {
      res.status(400).json({ message: error.message });
    } else {
      res.status(500).json({ message: error.message || 'Error interno al eliminar mesa' });
    }
  }
};

export const juntarMesas = async (req: Request, res: Response) => {
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
  } catch (error) {
    console.error('[DATABASE ERROR]:', error);
    console.error('Error juntando mesas:', error);
    res.status(500).json({ message: (error as Error).message || 'Error al juntar las mesas' });
  }
};

export const separarMesa = async (req: Request, res: Response) => {
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
  } catch (error) {
    console.error('[DATABASE ERROR]:', error);
    console.error('Error separando mesa:', error);
    res.status(500).json({ message: (error as Error).message || 'Error al separar la mesa' });
  }
};
