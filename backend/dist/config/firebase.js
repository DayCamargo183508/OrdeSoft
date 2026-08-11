"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.firestore = void 0;
const app_1 = require("firebase-admin/app");
const firestore_1 = require("firebase-admin/firestore");
const path_1 = __importDefault(require("path"));
const fs_1 = __importDefault(require("fs"));
const keyPath = path_1.default.resolve(process.cwd(), 'firebase-key.json');
if (!fs_1.default.existsSync(keyPath)) {
    console.error(`❌ ERROR: No se encontró el archivo en: ${keyPath}`);
    console.error(`Verifica que 'firebase-key.json' esté en la raíz de la carpeta backend.`);
}
else {
    try {
        const serviceAccount = JSON.parse(fs_1.default.readFileSync(keyPath, 'utf8'));
        if (!(0, app_1.getApps)().length) {
            (0, app_1.initializeApp)({
                credential: (0, app_1.cert)(serviceAccount),
            });
            console.log('🔥 Firebase Admin SDK conectado correctamente');
        }
    }
    catch (error) {
        console.error('❌ Error al inicializar Firebase Admin:', error);
    }
}
exports.firestore = (0, app_1.getApps)().length ? (0, firestore_1.getFirestore)() : null;
//# sourceMappingURL=firebase.js.map