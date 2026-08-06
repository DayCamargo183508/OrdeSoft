import { Request, Response } from 'express';
import jwt from 'jsonwebtoken';
import pool from '../../config/db';
import { decryptPin } from '../../utils/crypto.helper';

export const loginWithPin = async (req: Request, res: Response): Promise<void> => {
  try {
    console.log('>>> [HTTP /auth/login] PETICIÓN RECIBIDA:', req.body);
    const { pin } = req.body;

    // 1. Validar que venga el PIN
    const pinString = String(pin).trim();
    if (!pinString || pinString.length !== 4) {
      res.status(400).json({ error: 'Se requiere un PIN numérico válido de 4 dígitos.' });
      return;
    }

    // 2. Consultar todos los usuarios activos
    const result = await pool.query(
      "SELECT id, nombre, rol, pin_hash FROM usuarios WHERE activo = true AND LOWER(rol) IN ('mesero', 'admin')"
    );
    const users = result.rows;

    console.log(`>>> [LOGIN] USUARIOS ACTIVOS ENCONTRADOS EN BD: ${users.length}`);

    let matchedUser = null;

    // 3. Comparar el PIN recibido contra el 'pin_hash' de cada usuario
    for (const user of users) {
      if (user.pin_hash) {
        const pinDesencriptado = decryptPin(user.pin_hash);
        console.log(`>>> [LOGIN] EVALUANDO ID ${user.id} (${user.nombre}): DB_PIN="${pinDesencriptado}" VS INGRESADO="${pinString}"`);
        
        if (pinDesencriptado === pinString) {
          console.log(`>>> [LOGIN] ¡COINCIDENCIA EXITOSA CON ${user.nombre}!`);
          matchedUser = user;
          break; // Encontramos al usuario, detenemos el bucle
        }
      }
    }

    // 4. Si no hay coincidencias
    if (!matchedUser) {
      console.log('>>> [LOGIN] NINGÚN PIN COINCIDIÓ');
      res.status(401).json({ error: 'PIN incorrecto. Acceso denegado.' });
      return;
    }

    // 5. Si coincide, generar token JWT
    const secret = process.env.JWT_SECRET || 'secret_de_respaldo';
    const token = jwt.sign(
      { id: matchedUser.id, rol: matchedUser.rol },
      secret,
      { expiresIn: '12h' }
    );

    // 6. Retornar status 200 con token y objeto limpio
    res.status(200).json({
      token,
      user: {
        id: matchedUser.id,
        nombre: matchedUser.nombre,
        rol: matchedUser.rol,
      }
    });

  } catch (error) {
    console.error('Error en loginWithPin:', error);
    res.status(500).json({ error: 'Error interno del servidor.' });
  }
};
