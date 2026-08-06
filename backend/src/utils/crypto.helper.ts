import crypto from 'crypto';

const ALGORITHM = 'aes-256-cbc';
const SECRET = 'OrderSoftSecretKey2026_FixedKey_32'; // Clave fija para prevenir problemas de carga asíncrona de .env
const ENCRYPTION_KEY = crypto.scryptSync(SECRET, 'salt_ordersoft', 32);

export function encryptPin(text: string): string {
  const iv = crypto.randomBytes(16);
  const cipher = crypto.createCipheriv(ALGORITHM, ENCRYPTION_KEY, iv);
  let encrypted = cipher.update(text, 'utf8', 'hex');
  encrypted += cipher.final('hex');
  return `${iv.toString('hex')}:${encrypted}`;
}

export function decryptPin(text: string): string {
  try {
    const [ivHex, encryptedText] = text.split(':');
    if (!ivHex || !encryptedText) return text; // Retorno preventivo si viene en texto plano antiguo
    const iv = Buffer.from(ivHex, 'hex');
    const decipher = crypto.createDecipheriv(ALGORITHM, ENCRYPTION_KEY, iv);
    let decrypted = decipher.update(encryptedText, 'hex', 'utf8');
    decrypted += decipher.final('utf8');
    return decrypted;
  } catch (error) {
    return text; // Fallback
  }
}
