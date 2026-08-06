class Mesero {
  final int id;
  final String nombre;
  final String rol;
  bool activo;
  final String? creadoEn;
  final String? pin;

  Mesero({
    required this.id,
    required this.nombre,
    required this.rol,
    required this.activo,
    this.creadoEn,
    this.pin,
  });

  factory Mesero.fromJson(Map<String, dynamic> json) => Mesero(
        id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
        nombre: json['nombre']?.toString() ?? '',
        rol: json['rol']?.toString() ?? 'mesero',
        activo: json['activo'] == true || json['activo'] == 'true' || json['activo'] == 1,
        creadoEn: json['creado_en']?.toString(),
        pin: json['pin']?.toString(),
      );
}

class ConfigMesa {
  final int minMesas;
  final int maxMesas;

  ConfigMesa({
    required this.minMesas,
    required this.maxMesas,
  });

  factory ConfigMesa.fromJson(Map<String, dynamic> json) => ConfigMesa(
        minMesas: int.tryParse(json['min_mesas']?.toString() ?? '1') ?? 1,
        maxMesas: int.tryParse(json['max_mesas']?.toString() ?? '20') ?? 20,
      );
}

class NotaRapida {
  final int id;
  final String texto;
  final bool? activa;
  final double precioExtra;

  NotaRapida({
    required this.id,
    required this.texto,
    this.activa,
    this.precioExtra = 0.0,
  });

  factory NotaRapida.fromJson(Map<String, dynamic> json) => NotaRapida(
        id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
        texto: json['texto']?.toString() ?? json['nombre']?.toString() ?? json['contenido']?.toString() ?? '',
        activa: json['activa'] == true || json['activa'] == 'true' || json['activa'] == 1,
        precioExtra: double.tryParse(json['precio_extra']?.toString() ?? '0') ?? 0.0,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'texto': texto,
        'activa': activa,
        'precio_extra': precioExtra,
      };
}

class DesgloseMesero {
  final int meseroId;
  final String meseroNombre;
  final int comandasTomadas;
  final double totalVendido;
  final double ticketPromedio;

  DesgloseMesero({
    required this.meseroId,
    required this.meseroNombre,
    required this.comandasTomadas,
    required this.totalVendido,
    required this.ticketPromedio,
  });

  factory DesgloseMesero.fromJson(Map<String, dynamic> json) => DesgloseMesero(
        meseroId: int.tryParse(json['mesero_id']?.toString() ?? '0') ?? 0,
        meseroNombre: json['mesero_nombre']?.toString() ?? '',
        comandasTomadas: int.tryParse(json['comandas_tomadas']?.toString() ?? '0') ?? 0,
        totalVendido: double.tryParse(json['total_vendido']?.toString() ?? '0') ?? 0.0,
        ticketPromedio: double.tryParse(json['ticket_promedio']?.toString() ?? '0') ?? 0.0,
      );
}

class ReporteDiario {
  final double totalCobradoEfectivo;
  final int totalComandasCompletadas;
  final double ticketPromedioGeneral;
  final List<DesgloseMesero> desglosePorMesero;
  final List<ComandaDetalle> comandasDetalle;

  ReporteDiario({
    required this.totalCobradoEfectivo,
    required this.totalComandasCompletadas,
    required this.ticketPromedioGeneral,
    required this.desglosePorMesero,
    required this.comandasDetalle,
  });

  factory ReporteDiario.fromJson(Map<String, dynamic> json) {
    final desgloseList = json['desglose_por_mesero'] as List<dynamic>? ?? [];
    final comandasList = json['comandas_detalle'] as List<dynamic>? ?? [];
    return ReporteDiario(
      totalCobradoEfectivo: double.tryParse(json['total_cobrado_efectivo']?.toString() ?? '0') ?? 0.0,
      totalComandasCompletadas: int.tryParse(json['total_comandas_completadas']?.toString() ?? '0') ?? 0,
      ticketPromedioGeneral: double.tryParse(json['ticket_promedio_general']?.toString() ?? '0') ?? 0.0,
      desglosePorMesero: desgloseList.map((e) => DesgloseMesero.fromJson(e as Map<String, dynamic>)).toList(),
      comandasDetalle: comandasList.map((e) => ComandaDetalle.fromJson(e as Map<String, dynamic>)).toList(),
    );
  }
}

class ComandaDetalle {
  final int id;
  final int numeroMesa;
  final String? identificadorVista;
  final String? horaCierre;
  final double total;
  final String meseroNombre;
  final List<ComandaItem>? items;

  ComandaDetalle({
    required this.id,
    required this.numeroMesa,
    this.identificadorVista,
    this.horaCierre,
    required this.total,
    required this.meseroNombre,
    this.items,
  });

  factory ComandaDetalle.fromJson(Map<String, dynamic> json) {
    final itemsList = json['items'] as List<dynamic>?;
    return ComandaDetalle(
      id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      numeroMesa: int.tryParse(json['numero_mesa']?.toString() ?? '0') ?? 0,
      identificadorVista: json['identificador_vista']?.toString(),
      horaCierre: json['fecha_cierre']?.toString() ?? json['hora_cierre']?.toString(),
      total: double.tryParse(json['total']?.toString() ?? '0') ?? 0.0,
      meseroNombre: json['mesero_nombre']?.toString() ?? '',
      items: itemsList?.map((e) => ComandaItem.fromJson(e as Map<String, dynamic>)).toList(),
    );
  }
}

class ComandaItem {
  final String producto;
  final int cantidad;
  final double subtotal;

  ComandaItem({
    required this.producto,
    required this.cantidad,
    required this.subtotal,
  });

  factory ComandaItem.fromJson(Map<String, dynamic> json) => ComandaItem(
        producto: json['producto']?.toString() ?? '',
        cantidad: int.tryParse(json['cantidad']?.toString() ?? '0') ?? 0,
        subtotal: double.tryParse(json['subtotal']?.toString() ?? '0') ?? 0.0,
      );
}
