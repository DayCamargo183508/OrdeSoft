"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const firebase_1 = require("../config/firebase");
const firestore_1 = require("firebase-admin/firestore");
const categorias = [
    { id: 1, nombre: 'Entradas' },
    { id: 2, nombre: 'Tacos y Antojitos' },
    { id: 3, nombre: 'Platillos Fuertes' },
    { id: 4, nombre: 'Hamburguesas y Pizzas' },
    { id: 5, nombre: 'Bebidas' },
    { id: 6, nombre: 'Cervezas y Licores' },
    { id: 7, nombre: 'Postres' },
    { id: 8, nombre: 'Extras' }
];
const nombresBase = {
    1: ['Guacamole', 'Nachos con Queso', 'Quesadillas', 'Papas Fritas', 'Aros de Cebolla', 'Alitas BBQ', 'Dedos de Queso', 'Empanadas', 'Totopos'],
    2: ['Taco de Asada', 'Taco al Pastor', 'Taco de Pollo', 'Gringa de Pastor', 'Sope de Asada', 'Tostada de Ceviche', 'Flautas de Pollo', 'Burrito de Asada'],
    3: ['Carne Asada', 'Fajitas de Pollo', 'Enchiladas Suizas', 'Milanesa de Res', 'Pechuga a la Plancha', 'Salmón al Ajillo', 'Costillas BBQ', 'Tampiqueña'],
    4: ['Hamburguesa Sencilla', 'Hamburguesa Doble', 'Hamburguesa BBQ', 'Pizza Pepperoni', 'Pizza Hawaiana', 'Pizza Mexicana', 'Pizza Vegetariana'],
    5: ['Refresco Cola 600ml', 'Limonada Mineral', 'Naranjada', 'Agua de Horchata', 'Agua de Jamaica', 'Jugo de Naranja', 'Café Americano', 'Té Helado'],
    6: ['Cerveza Artesanal 355ml', 'Cerveza Clara', 'Cerveza Oscura', 'Margarita Tradicional', 'Mojito', 'Tequila Blanco', 'Mezcal Joven', 'Piña Colada'],
    7: ['Pastel de Chocolate', 'Flan Napolitano', 'Cheesecake', 'Helado de Vainilla', 'Crepas Dulces', 'Brownie con Helado', 'Churros'],
    8: ['Porción de Guacamole', 'Extra Queso', 'Orden de Tortillas', 'Aderezo Ranch', 'Extra Tocino', 'Salsa Habanero']
};
const generarProductos = (cantidad) => {
    const productos = [];
    for (let i = 1; i <= cantidad; i++) {
        // Seleccionar categoría aleatoria
        const catRandom = categorias[Math.floor(Math.random() * categorias.length)];
        const idCat = catRandom.id;
        // Seleccionar nombre base aleatorio
        const nombresDisp = nombresBase[idCat];
        const nombreAleatorio = nombresDisp[Math.floor(Math.random() * nombresDisp.length)];
        // Modificadores para hacerlo único
        const nombreFinal = `${nombreAleatorio} V${Math.floor(Math.random() * 10) + 1} (${i})`;
        // Precio aleatorio entre 15.00 y 450.00
        const precioRandom = Math.floor(Math.random() * (450 - 15 + 1) + 15) + 0.99;
        // 90% probabilidad de estar disponible
        const disponible = Math.random() > 0.1;
        productos.push({
            _tempId: String(i), // ID temporal
            categoria_id: idCat,
            categoria: catRandom.nombre, // String para facilidad del Frontend
            nombre: nombreFinal,
            precio: parseFloat(precioRandom.toFixed(2)),
            descripcion: `Delicioso platillo categoría ${catRandom.nombre} preparado al momento.`,
            disponible: disponible,
            created_at: new Date().toISOString(), // Usamos ISOString en lugar de ServerTimestamp para asegurar ordenamiento si el backend ya usa strings
            timestamp: firestore_1.FieldValue.serverTimestamp() // Añadimos el FieldValue por si lo requiere el Frontend
        });
    }
    return productos;
};
async function borrarColeccion(coleccionRef, batchSize = 100) {
    const query = coleccionRef.limit(batchSize);
    return new Promise((resolve, reject) => {
        deleteQueryBatch(query, resolve).catch(reject);
    });
}
async function deleteQueryBatch(query, resolve) {
    const snapshot = await query.get();
    if (snapshot.size === 0) {
        resolve();
        return;
    }
    const batch = firebase_1.firestore.batch();
    snapshot.docs.forEach((doc) => {
        batch.delete(doc.ref);
    });
    await batch.commit();
    process.nextTick(() => {
        deleteQueryBatch(query, resolve);
    });
}
const runSeeder = async () => {
    console.log('🚀 Iniciando Seeder de Productos en Firestore...');
    if (!firebase_1.firestore) {
        console.error('❌ La instancia de Firestore no está inicializada. Revisa src/config/firebase.ts');
        process.exit(1);
    }
    const coleccionRef = firebase_1.firestore.collection('productos');
    console.log('🧹 Borrando productos existentes...');
    await borrarColeccion(coleccionRef);
    const productosNuevos = generarProductos(200);
    // Firestore permite hasta 500 operaciones por batch.
    const tamañoLote = 100;
    let batch = firebase_1.firestore.batch();
    let contadorLote = 0;
    let lotesEnviados = 0;
    try {
        for (const prod of productosNuevos) {
            const docRef = coleccionRef.doc(prod._tempId);
            const { _tempId, ...restoProducto } = prod; // Eliminamos la llave temporal
            batch.set(docRef, restoProducto);
            contadorLote++;
            if (contadorLote === tamañoLote) {
                console.log(`[SEEDER] Insertando lote ${lotesEnviados + 1} (${tamañoLote} productos)...`);
                await batch.commit();
                lotesEnviados++;
                contadorLote = 0;
                batch = firebase_1.firestore.batch(); // Iniciar nuevo batch
            }
        }
        // Insertar restantes si los hay
        if (contadorLote > 0) {
            console.log(`[SEEDER] Insertando lote ${lotesEnviados + 1} (${contadorLote} productos)...`);
            await batch.commit();
        }
        console.log(`✅ [SEEDER] ¡${productosNuevos.length} productos insertados exitosamente en Firestore!`);
        process.exit(0);
    }
    catch (error) {
        console.error('❌ Error al insertar productos:', error);
        process.exit(1);
    }
};
runSeeder();
//# sourceMappingURL=productos.seeder.js.map