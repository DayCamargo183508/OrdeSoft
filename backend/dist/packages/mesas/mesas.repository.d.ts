export declare const getMesas: () => Promise<any[]>;
export declare const createMesa: (capacidad: number) => Promise<any>;
export declare const updateEstadoMesa: (id: number, estado: string) => Promise<any>;
export declare const getTotalMesas: () => Promise<number>;
export declare const deleteUltimaMesa: () => Promise<any>;
export declare const juntarMesas: (mesaHijaId: number, mesaPadreId: number) => Promise<any>;
export declare const separarMesa: (mesaId: number) => Promise<any>;
//# sourceMappingURL=mesas.repository.d.ts.map