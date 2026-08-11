export declare const getCategorias: () => Promise<any[]>;
export declare const createCategoria: (nombre: string) => Promise<any>;
export declare const deleteCategoria: (id: number) => Promise<any>;
export declare const updateCategoria: (id: number, nombre: string) => Promise<any>;
export declare const getProductos: (incluirInactivos?: boolean) => Promise<any[]>;
export declare const getProductosByCategoria: (categoria_id: number) => Promise<any[]>;
export declare const createProducto: (categoria_id: number, nombre: string, descripcion: string, precio: number) => Promise<any>;
export declare const updateProducto: (id: number, data: {
    categoria_id?: number;
    nombre?: string;
    descripcion?: string;
    precio?: number;
    disponible?: boolean;
}) => Promise<any>;
export declare const deleteProducto: (id: number) => Promise<any>;
export declare const updateEstadoProducto: (id: number, disponible: boolean) => Promise<any>;
//# sourceMappingURL=menu.repository.d.ts.map