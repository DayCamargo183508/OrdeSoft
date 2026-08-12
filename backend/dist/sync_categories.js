"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
const db_1 = __importDefault(require("./config/db"));
const firebase_1 = require("./config/firebase");
async function syncCategories() {
    try {
        // Check if connected to Postgres
        await db_1.default.query('SELECT NOW()');
        console.log("Connected to PostgreSQL");
        const snapshot = await firebase_1.firestore.collection('productos').get();
        const categoriesSet = new Set();
        snapshot.forEach(doc => {
            const data = doc.data();
            if (data.categoria && typeof data.categoria === 'string') {
                categoriesSet.add(data.categoria.trim());
            }
        });
        const uniqueCategories = Array.from(categoriesSet);
        console.log(`Found ${uniqueCategories.length} unique categories in Firebase:`, uniqueCategories);
        for (const cat of uniqueCategories) {
            await db_1.default.query("INSERT INTO categorias (nombre) VALUES ($1) ON CONFLICT (nombre) DO NOTHING", [cat]);
        }
        console.log("Categorias sync completed successfully!");
    }
    catch (error) {
        console.error("Error syncing categories:", error);
    }
    finally {
        process.exit(0);
    }
}
syncCategories();
//# sourceMappingURL=sync_categories.js.map