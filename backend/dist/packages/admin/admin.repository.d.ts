export declare const AdminRepository: {
    obtenerMeseros(incluirInactivos?: boolean): Promise<any[]>;
    crearMesero(nombre: string, pin_hash: string): Promise<any>;
    updateEstadoMesero(id: number, activo: boolean): Promise<any>;
    actualizarMesero(id: number, nombre?: string, activo?: boolean, pin_hash?: string): Promise<any>;
    validarPinMesero(pinEnviado: string): Promise<any>;
    eliminarMesero(id: number, hard?: boolean): Promise<any>;
    obtenerConfiguracion(): Promise<any>;
    actualizarConfiguracion(min_mesas: number, max_mesas: number): Promise<any>;
    obtenerNotasRapidas(): Promise<any[]>;
    crearNotaRapida(texto: string, precio_extra?: number): Promise<any>;
    actualizarNotaRapida(id: number, texto: string, precio_extra?: number): Promise<any>;
    eliminarNotaRapida(id: number): Promise<void>;
    obtenerReporteDiario(): Promise<{
        total_cobrado_efectivo: number;
        total_comandas_completadas: number;
        ticket_promedio_general: number;
        desglose_por_mesero: any[];
        articulos_vendidos: {
            total_cantidad: any;
            desglose: any[];
        };
        comandas_detalle: any[];
    }>;
};
//# sourceMappingURL=admin.repository.d.ts.map