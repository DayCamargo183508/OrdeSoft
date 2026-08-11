import { Request, Response } from 'express';
import * as ComandasRepository from './comandas.repository';
import pool from '../../config/db';
import { firestore } from '../../config/firebase';

export const obtenerActivas = async (req: Request, res: Response) => {
  try {
    const comandas = await ComandasRepository.obtenerComandasActivas();
    res.json(comandas);
  } catch (error) {
    console.error('Error obteniendo comandas activas:', error);
    res.status(500).json({ error: 'Error al obtener comandas activas' });
  }
};

export const obtenerParaLlevar = async (req: Request, res: Response) => {
  try {
    const comandas = await ComandasRepository.obtenerComandasParaLlevar();
    res.json(comandas);
  } catch (error) {
    console.error('Error obteniendo comandas para llevar:', error);
    res.status(500).json({ error: 'Error al obtener comandas para llevar' });
  }
};

export const obtenerPorId = async (req: Request, res: Response) => {
  try {
    const { id } = req.params;
    const comanda = await ComandasRepository.obtenerComandaPorId(Number(id));
    if (!comanda) {
      res.status(404).json({ error: 'Comanda no encontrada.' });
      return;
    }
    res.json(comanda);
  } catch (error) {
    console.error('Error obteniendo detalle de comanda:', error);
    res.status(500).json({ error: 'Error al obtener detalle de la comanda' });
  }
};

export const crearComanda = async (req: Request, res: Response) => {
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
    } else { // Asumimos MESA
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
      const mesaQuery = await pool.query('SELECT estado FROM mesas WHERE id = $1', [mesa_id]);
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
    const detallesFormateados: ComandasRepository.DetalleComandaInput[] = [];
    for (const d of detalles) {
      if (!d.producto_id || d.cantidad <= 0) {
        res.status(400).json({ error: 'Formato de detalle inválido.' });
        return;
      }
      // Obtener el precio base y nombre si el frontend no envió un precio unitario final
      const prodRef = await firestore.collection('productos').doc(d.producto_id).get();
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
    } else {
      nuevaComanda = await ComandasRepository.crearComandaTransaccional(
        mesaIdParaDB, 
        tipo_orden, 
        nombreParaDB, 
        usuario_id, 
        detallesFormateados
      );
      res.status(201).json({ message: 'Comanda creada con éxito', comanda: nuevaComanda });
    }
  } catch (error) {
    console.error('Error creando comanda:', error);
    res.status(500).json({ error: 'Error interno al crear comanda.' });
  }
};

export const pagarComanda = async (req: Request, res: Response) => {
  try {
    const { id } = req.params;
    const comandaPagada = await ComandasRepository.pagarComanda(Number(id));
    res.json({ message: 'Comanda pagada exitosamente', comanda: comandaPagada });
  } catch (error: any) {
    console.error('Error al pagar comanda:', error);
    if (error.message === 'Comanda no encontrada') {
      res.status(404).json({ error: error.message });
      return;
    }
    res.status(500).json({ error: 'Error al procesar el pago de la comanda.' });
  }
};

export const pagarCuenta = async (req: Request, res: Response) => {
  try {
    const { id } = req.params;
    const { cuenta_id } = req.body;
    
    if (cuenta_id === undefined) {
      res.status(400).json({ error: 'cuenta_id es requerido' });
      return;
    }
    
    const resultado = await ComandasRepository.pagarCuenta(Number(id), Number(cuenta_id));
    res.json({ message: 'Cuenta pagada exitosamente', ...resultado });
  } catch (error: any) {
    console.error('Error al pagar cuenta:', error);
    res.status(500).json({ error: 'Error al procesar el pago de la cuenta.' });
  }
};

export const obtenerTicketCocina = async (req: Request, res: Response) => {
  try {
    const { id } = req.params;
    const ticketData = await ComandasRepository.obtenerTicketCocina(Number(id));
    
    if (!ticketData) {
      res.status(404).json({ error: 'Comanda no encontrada.' });
      return;
    }

    const { cabecera, detalles } = ticketData;

    const gruposMap: Record<string, any[]> = {};
    const totalesMap: Record<string, number> = {};

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
      gruposMap[instruccion]!.push({ cantidad: d.cantidad, producto: d.producto });

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
  } catch (error) {
    console.error('Error generando ticket:', error);
    res.status(500).json({ error: 'Error al generar el ticket de cocina.' });
  }
};
