class Mesa {
  final int id;
  final int numero;
  final String estado;
  final int? mesaPadreId;
  final int? grupoId;
  final int? numeroPadre;

  Mesa({
    required this.id,
    required this.numero,
    required this.estado,
    this.mesaPadreId,
    this.grupoId,
    this.numeroPadre,
  });

  factory Mesa.fromJson(Map<String, dynamic> json) {
    int? _parseInt(dynamic value) {
      if (value == null) return null;
      if (value is int) return value;
      if (value is String) return int.tryParse(value);
      return null;
    }

    return Mesa(
      id: _parseInt(json['id']) ?? 0,
      numero: _parseInt(json['numero']) ?? 0,
      estado: json['estado']?.toString() ?? 'libre',
      mesaPadreId: _parseInt(json['mesa_padre_id']),
      grupoId: _parseInt(json['grupo_id']),
      numeroPadre: _parseInt(json['numero_padre']),
    );
  }
}
