class CategoriaAdmin {
  final int id;
  final String nombre;
  final bool activo;
  final int? orden;

  CategoriaAdmin({
    required this.id,
    required this.nombre,
    required this.activo,
    this.orden,
  });

  factory CategoriaAdmin.fromJson(Map<String, dynamic> json) => CategoriaAdmin(
        id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
        nombre: json['nombre']?.toString() ?? '',
        activo: json['activo'] == true || json['activo'] == 'true' || json['activo'] == 1,
        orden: json['orden'] != null ? int.tryParse(json['orden'].toString()) : null,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'nombre': nombre,
        'activo': activo,
        'orden': orden,
      };
}

class ProductoAdmin {
  final String id;
  final String nombre;
  final double precio;
  final int categoriaId;
  final String? categoriaNombre;
  bool disponible;
  final String? descripcion;

  ProductoAdmin({
    required this.id,
    required this.nombre,
    required this.precio,
    required this.categoriaId,
    this.categoriaNombre,
    required this.disponible,
    this.descripcion,
  });

  factory ProductoAdmin.fromJson(Map<String, dynamic> json) => ProductoAdmin(
        id: json['id']?.toString() ?? '',
        nombre: json['nombre']?.toString() ?? '',
        precio: double.tryParse(json['precio']?.toString() ?? '0') ?? 0.0,
        categoriaId: int.tryParse(json['categoria_id']?.toString() ?? json['categoriaId']?.toString() ?? '0') ?? 0,
        categoriaNombre: json['categoria_nombre']?.toString(),
        disponible: json['disponible'] == true || json['disponible'] == 'true' || json['disponible'] == 1,
        descripcion: json['descripcion']?.toString(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'nombre': nombre,
        'precio': precio,
        'categoria_id': categoriaId,
        'categoria_nombre': categoriaNombre,
        'disponible': disponible,
        'descripcion': descripcion,
      };
}
