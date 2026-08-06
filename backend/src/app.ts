import express, { Request, Response } from 'express';
import cors from 'cors';
import dotenv from 'dotenv';
import os from 'os';
import pool from './config/db';
import authRoutes from './packages/auth/auth.routes';
import mesasRoutes from './packages/mesas/mesas.routes';
import menuRoutes from './packages/menu/menu.routes';
import comandasRoutes from './packages/comandas/comandas.routes';
import reportesRoutes from './packages/reportes/reportes.routes';
import adminRoutes from './packages/admin/admin.routes';

// Cargar las variables de entorno
dotenv.config();

const app = express();
const PORT = Number(process.env.PORT) || 3500;
const HOST = '127.0.0.1';

// Configurar Middlewares Globales
app.use(cors());
app.use(express.json());

// Rutas Modulares
app.use('/api/auth', authRoutes);
app.use('/api/mesas', mesasRoutes);
app.use('/api/menu', menuRoutes);
app.use('/api/comandas', comandasRoutes);
app.use('/api/reportes', reportesRoutes);
app.use('/api/admin', adminRoutes);

// Ruta Health Check
app.get('/api/health', async (req: Request, res: Response) => {
  try {
    // Intenta hacer un query rápido a la base de datos
    const dbResult = await pool.query('SELECT NOW()');
    
    // Si la conexión es exitosa, responde el estado 200 con la hora
    res.json({
      status: 'success',
      message: 'Servidor y base de datos funcionando correctamente.',
      databaseTime: dbResult.rows[0].now,
    });
  } catch (error: any) {
    // Si la base de datos falla, registra el error y responde con 500
    console.error('Error en Health Check (Database):', error);
    res.status(500).json({
      status: 'error',
      message: 'Error de conexión a la base de datos PostgreSQL.',
      details: error.message,
    });
  }
});

// Listener del servidor
const server = app.listen(PORT, HOST, () => {
  const networkInterfaces = os.networkInterfaces();
  let localIp = '127.0.0.1';

  for (const name in networkInterfaces) {
    for (const net of networkInterfaces[name] || []) {
      if (net.family === 'IPv4' && !net.internal) {
        localIp = net.address;
        break;
      }
    }
  }

  console.log(`\n🚀 SERVIDOR ONLINE Y LISTO EN LA RED:`);
  console.log(`🔗 Conexión Windows / Localhost: http://127.0.0.1:${PORT}`);
  console.log(`📱 Conexión Android / Módem LAN: http://${localIp}:${PORT}/api\n`);
});

server.on('error', (err: any) => {
  if (err.code === 'EADDRINUSE') {
    console.error(`❌ ERROR CRÍTICO: El puerto ${PORT} ya está siendo usado por otro proceso en Windows.`);
  } else {
    console.error(`❌ ERROR AL INICIAR SERVIDOR:`, err);
  }
});
