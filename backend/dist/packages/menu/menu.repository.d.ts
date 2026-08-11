export declare const getCategorias: () => Promise<any[]>;
export declare const createCategoria: (nombre: string) => Promise<any>;
export declare const deleteCategoria: (id: number) => Promise<any>;
export declare const updateCategoria: (id: number, nombre: string) => Promise<any>;
export declare const getProductos: (incluirInactivos?: boolean) => Promise<any[]>;
export declare const getProductosByCategoria: (categoria_id: number) => Promise<any>;
export declare const createProducto: (categoria_id: number, nombre: string, descripcion: string, precio: number) => Promise<{
    categoria_id: number;
    nombre: string;
    descripcion: string;
    precio: number;
    disponible: boolean;
    created_at: string;
    id: any;
}>;
export declare const updateProducto: (id: string, data: any) => Promise<any>;
export declare const deleteProducto: (id: string) => Promise<any>;
export declare const updateEstadoProducto: (id: string, disponible: boolean) => Promise<any>;
//# sourceMappingURL=menu.repository.d.ts.map