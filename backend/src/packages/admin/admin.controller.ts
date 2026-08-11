import { Request, Response } from 'express';
import { encryptPin, decryptPin } from '../../utils/crypto.helper';
import { AdminRepository } from './admin.repository';

export const obtenerMeseros = async (req: Request, res: Response): Promise<void> => {
  try {
    const incluirInactivos = req.query.incluirInactivos !== 'false';
    const meseros = await AdminRepository.obtenerMeseros(incluirInactivos);
    const meserosMapeados = meseros.map(m => ({
      ...m,
      pin: decryptPin(m.pin)
    }));
    res.json(meserosMapeados);
  } catch (error) {
    console.error('Error al obtener meseros:', error);
    res.status(500).json({ message: (error as Error).message || 'Error interno del servidor' });
  }
};

export const crearMesero = async (req: Request, res: Response): Promise<void> => {
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

    const pinHash = encryptPin(pinString);

    const nuevoMesero = await AdminRepository.crearMesero(nombre, pinHash);
    res.status(201).json(nuevoMesero);
  } catch (error) {
    console.error('Error al crear mesero:', error);
    res.status(500).json({ message: (error as Error).message || 'Error interno del servidor' });
  }
};

export const actualizarMesero = async (req: Request, res: Response): Promise<void> => {
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
      pinHash = encryptPin(pinString);
    }

    // Convert string "true"/"false" if passed from form-data, otherwise boolean
    let activoBool: boolean | undefined = undefined;
    if (activo !== undefined) {
      activoBool = typeof activo === 'string' ? activo === 'true' : Boolean(activo);
    }

    const meseroActualizado = await AdminRepository.actualizarMesero(parseInt(id as string, 10), nombre, activoBool, pinHash);
    res.json(meseroActualizado);
  } catch (error) {
    console.error('Error al actualizar mesero:', error);
    res.status(500).json({ message: (error as Error).message || 'Error interno del servidor' });
  }
};

export const updateEstadoMesero = async (req: Request, res: Response): Promise<void> => {
  try {
    const { id } = req.params;
    const { activo } = req.body;
    if (activo === undefined) {
      res.status(400).json({ error: 'El campo activo es obligatorio.' });
      return;
    }
    const mesero = await AdminRepository.updateEstadoMesero(parseInt(id as string, 10), Boolean(activo));
    if (!mesero) {
      res.status(404).json({ error: 'Mesero no encontrado.' });
      return;
    }
    res.json({ message: 'Estado del mesero actualizado correctamente', mesero });
  } catch (error) {
    console.error('Error al actualizar estado del mesero:', error);
    res.status(500).json({ message: (error as Error).message || 'Error interno del servidor' });
  }
};

export const eliminarMesero = async (req: Request, res: Response): Promise<void> => {
  try {
    const { id } = req.params;
    const hard = req.query.hard === 'true';
    const mesero = await AdminRepository.eliminarMesero(parseInt(id as string, 10), hard);
    res.json({ message: 'Mesero procesado correctamente', mesero });
  } catch (error: any) {
    console.error('Error al eliminar mesero:', error);
    if (error.code === '23503' || error.message.includes('comandas asociadas')) {
      res.status(400).json({ error: error.message });
      return;
    }
    if (error.message.includes('comandas activas')) {
      res.status(400).json({ error: error.message });
      return;
    }
    res.status(500).json({ message: error.message || 'Error interno del servidor' });
  }
};

export const loginPin = async (req: Request, res: Response): Promise<void> => {
  try {
    console.log('>>> [HTTP] PETICIÓN DE LOGIN CON PIN RECIBIDA', req.body);
    const { pin } = req.body;
    if (!pin || !/^\d{4}$/.test(pin)) {
      res.status(400).json({ error: 'Debe proporcionar un PIN válido de 4 dígitos.' });
      return;
    }

    const mesero = await AdminRepository.validarPinMesero(pin);
    if (!mesero) {
      res.status(401).json({ error: 'PIN incorrecto o mesero inactivo.' });
      return;
    }

    // Retorna los datos básicos del usuario para guardarlos en sesión local
    res.json({ success: true, usuario: mesero });
  } catch (error) {
    console.error('Error en login con PIN:', error);
    res.status(500).json({ message: (error as Error).message || 'Error interno del servidor' });
  }
};

export const obtenerConfig = async (req: Request, res: Response): Promise<void> => {
  try {
    const config = await AdminRepository.obtenerConfiguracion();
    res.json(config);
  } catch (error) {
    console.error('Error al obtener configuración:', error);
    res.status(500).json({ message: (error as Error).message || 'Error interno del servidor' });
  }
};

export const actualizarConfig = async (req: Request, res: Response): Promise<void> => {
  try {
    const { min_mesas, max_mesas } = req.body;
    if (min_mesas === undefined || max_mesas === undefined) {
      res.status(400).json({ error: 'Debe proveer min_mesas y max_mesas.' });
      return;
    }
    
    const configActualizada = await AdminRepository.actualizarConfiguracion(min_mesas, max_mesas);
    res.json(configActualizada);
  } catch (error) {
    console.error('Error al actualizar configuración:', error);
    res.status(500).json({ message: (error as Error).message || 'Error interno del servidor' });
  }
};

export const obtenerNotasRapidas = async (req: Request, res: Response): Promise<void> => {
  try {
    const notas = await AdminRepository.obtenerNotasRapidas();
    res.json(notas);
  } catch (error) {
    console.error('Error al obtener notas rápidas:', error);
    res.status(500).json({ message: (error as Error).message || 'Error interno del servidor' });
  }
};

export const crearNotaRapida = async (req: Request, res: Response): Promise<void> => {
  try {
    const { texto, precio_extra } = req.body;
    if (!texto || texto.trim().length === 0) {
      res.status(400).json({ error: 'El texto de la nota rápida es obligatorio.' });
      return;
    }
    
    const precio = precio_extra != null ? Number(precio_extra) : 0;
    const nuevaNota = await AdminRepository.crearNotaRapida(texto.trim(), precio);
    res.status(201).json(nuevaNota);
  } catch (error) {
    console.error('Error al crear nota rápida:', error);
    res.status(500).json({ message: (error as Error).message || 'Error interno del servidor' });
  }
};

export const actualizarNotaRapida = async (req: Request, res: Response): Promise<void> => {
  try {
    const { id } = req.params;
    const { texto, precio_extra } = req.body;
    if (!texto || texto.trim().length === 0) {
      res.status(400).json({ error: 'El texto de la nota rápida es obligatorio.' });
      return;
    }
    
    const precio = precio_extra != null ? Number(precio_extra) : 0;
    const notaActualizada = await AdminRepository.actualizarNotaRapida(Number(id), texto.trim(), precio);
    res.json(notaActualizada);
  } catch (error) {
    console.error('Error al actualizar nota rápida:', error);
    res.status(500).json({ message: (error as Error).message || 'Error interno del servidor' });
  }
};

export const eliminarNotaRapida = async (req: Request, res: Response): Promise<void> => {
  try {
    const { id } = req.params;
    await AdminRepository.eliminarNotaRapida(parseInt(id as string, 10));
    res.json({ message: 'Nota eliminada correctamente' });
  } catch (error) {
    console.error('Error al eliminar nota rápida:', error);
    res.status(500).json({ message: (error as Error).message || 'Error interno del servidor' });
  }
};

export const obtenerReporteDiario = async (req: Request, res: Response): Promise<void> => {
  try {
    const reporte = await AdminRepository.obtenerReporteDiario();
    res.json(reporte);
  } catch (error) {
    console.error('Error al generar reporte diario:', error);
    res.status(500).json({ message: (error as Error).message || 'Error interno del servidor' });
  }
};
