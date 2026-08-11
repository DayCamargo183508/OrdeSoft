export interface DetalleComandaInput {
    producto_id: number;
    cantidad: number;
    precio_unitario: number;
    notas?: string;
    cuenta_id?: number;
    cliente_nombre?: string;
}
export declare const crearComandaTransaccional: (mesa_id: number | null, tipo_orden: string, nombre_cliente: string | null, usuario_id: number, detalles: DetalleComandaInput[]) => Promise<any>;
export declare const agregarDetallesComandaTransaccional: (comanda_id: number, detalles: DetalleComandaInput[]) => Promise<any>;
export declare const obtenerComandaPorId: (id: number) => Promise<any>;
export declare const obtenerComandasActivas: () => Promise<any[]>;
export declare const obtenerComandasParaLlevar: () => Promise<any[]>;
export declare const pagarComanda: (comanda_id: number) => Promise<any>;
export declare const obtenerTicketCocina: (comanda_id: number) => Promise<{
    cabecera: any;
    detalles: any[];
} | null>;
export declare const pagarCuenta: (comanda_id: number, cuenta_id: number) => Promise<{
    mesaDesocupada: boolean;
    restantes: number;
}>;
//# sourceMappingURL=comandas.repository.d.ts.map