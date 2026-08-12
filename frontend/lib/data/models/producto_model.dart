class Producto {
  final String id;
  final String nombre;
  final double precio;
  final bool disponible;
  final String categoriaId;
  final String categoria;
  final String? imagenUrl;

  Producto({
    required this.id,
    required this.nombre,
    required this.precio,
    required this.disponible,
    required this.categoriaId,
    required this.categoria,
    this.imagenUrl,
  });

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  factory Producto.fromJson(Map<String, dynamic> json) {
    return Producto(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      nombre: json['nombre']?.toString() ?? 'Sin Nombre',
      precio: _parseDouble(json['precio']),
      disponible: json['disponible'] as bool? ?? true,
      categoriaId: json['categoriaId']?.toString() ?? json['categoria_id']?.toString() ?? json['categoria']?.toString() ?? '',
      categoria: json['categoria_nombre']?.toString() ?? json['categoria']?.toString() ?? 'Sin categoría',
      imagenUrl: json['imagenUrl']?.toString(),
    );
  }
}
