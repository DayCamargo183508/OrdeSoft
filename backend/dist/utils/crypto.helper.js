"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.encryptPin = encryptPin;
exports.decryptPin = decryptPin;
const crypto_1 = __importDefault(require("crypto"));
const ALGORITHM = 'aes-256-cbc';
const SECRET = 'OrderSoftSecretKey2026_FixedKey_32'; // Clave fija para prevenir problemas de carga asíncrona de .env
const ENCRYPTION_KEY = crypto_1.default.scryptSync(SECRET, 'salt_ordersoft', 32);
function encryptPin(text) {
    const iv = crypto_1.default.randomBytes(16);
    const cipher = crypto_1.default.createCipheriv(ALGORITHM, ENCRYPTION_KEY, iv);
    let encrypted = cipher.update(text, 'utf8', 'hex');
    encrypted += cipher.final('hex');
    return `${iv.toString('hex')}:${encrypted}`;
}
function decryptPin(text) {
    try {
        const [ivHex, encryptedText] = text.split(':');
        if (!ivHex || !encryptedText)
            return text; // Retorno preventivo si viene en texto plano antiguo
        const iv = Buffer.from(ivHex, 'hex');
        const decipher = crypto_1.default.createDecipheriv(ALGORITHM, ENCRYPTION_KEY, iv);
        let decrypted = decipher.update(encryptedText, 'hex', 'utf8');
        decrypted += decipher.final('utf8');
        return decrypted;
    }
    catch (error) {
        return text; // Fallback
    }
}
//# sourceMappingURL=crypto.helper.js.map