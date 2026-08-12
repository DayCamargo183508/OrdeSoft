import { Request, Response } from 'express';
import * as ReportesRepository from './reportes.repository';

export const getVentasHoy = async (req: Request, res: Response) => {
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
  } catch (error) {
    res.status(200).json({
      ingresos_hoy: 0,
      comandas_completadas: 0,
      productos_top: []
    });
  }
};
