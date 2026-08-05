class Categoria {
  final String id;
  final String nombre;
  final String? descripcion;
  final String? iconoUrl;

  Categoria({
    required this.id,
    required this.nombre,
    this.descripcion,
    this.iconoUrl,
  });

  factory Categoria.fromJson(Map<String, dynamic> json) {
    return Categoria(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      nombre: json['nombre']?.toString() ?? 'Sin Nombre',
      descripcion: json['descripcion']?.toString(),
      iconoUrl: json['iconoUrl']?.toString(),
    );
  }
}
