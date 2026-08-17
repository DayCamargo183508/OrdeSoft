class NotaAplicada {
  final String texto;
  final double precioExtra;
  NotaAplicada(this.texto, this.precioExtra);
}

class ItemComanda {
  final String id;
  final String productoId;
  final String producto;
  int cantidad;
  final double precioUnitario;
  List<NotaAplicada> notas;
  bool isNew;

  ItemComanda({
    required this.id,
    required this.productoId,
    required this.producto,
    required this.cantidad,
    required this.precioUnitario,
    List<NotaAplicada>? notas,
    this.isNew = true,
  }) : notas = notas ?? [];

  double get precioUnitarioFinal => precioUnitario + notas.fold(0.0, (sum, n) => sum + n.precioExtra);

  double get total => cantidad * precioUnitarioFinal;

  String get notasString {
    return notas.map((n) {
      if (n.precioExtra > 0) {
        return '${n.texto} [+\$${n.precioExtra.toStringAsFixed(2)}]';
      }
      return n.texto;
    }).join(', ');
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'productoId': productoId,
        'producto': producto,
        'cantidad': cantidad,
        'precioUnitario': precioUnitario,
        'notas': notasString,
      };

  factory ItemComanda.fromJson(Map<String, dynamic> json) {
    final notasStr = json['notas'] as String? ?? '';
    final listNotas = <NotaAplicada>[];
    
    if (notasStr.isNotEmpty) {
      final parts = notasStr.split(', ');
      for (var part in parts) {
        double extra = 0.0;
        String text = part.trim();
        
        final match = RegExp(r'\[\+\$(\d+\.?\d*)\]').firstMatch(text);
        if (match != null) {
          extra = double.tryParse(match.group(1)!) ?? 0.0;
          text = text.replaceAll(match.group(0)!, '').trim();
        }
        listNotas.add(NotaAplicada(text, extra));
      }
    }
    
    return ItemComanda(
      id: json['id'] as String? ?? '',
      productoId: json['productoId']?.toString() ?? '',
      producto: json['producto'] as String? ?? '',
      cantidad: int.tryParse(json['cantidad']?.toString() ?? '1') ?? 1,
      precioUnitario: double.tryParse(json['precio_unitario']?.toString() ?? json['precioUnitario']?.toString() ?? '0') ?? 0.0,
      notas: listNotas,
      isNew: false,
    );
  }
}

class ClienteSubCuenta {
  final String id;
  String nombre;
  List<ItemComanda> items;
  int cuentaId;

  ClienteSubCuenta({
    required this.id,
    required this.nombre,
    List<ItemComanda>? items,
    this.cuentaId = 1,
  }) : items = items ?? [];

  double get subtotal => items.fold(0, (sum, item) => sum + item.total);

  Map<String, dynamic> toJson() => {
        'id': id,
        'nombre': nombre,
        'cuentaId': cuentaId,
        'items': items.map((i) => i.toJson()).toList(),
      };

  factory ClienteSubCuenta.fromJson(Map<String, dynamic> json) => ClienteSubCuenta(
        id: json['id'] as String? ?? '',
        nombre: json['nombre'] as String? ?? '',
        cuentaId: int.tryParse(json['cuentaId']?.toString() ?? '1') ?? 1,
        items: (json['items'] as List<dynamic>?)
                ?.map((i) => ItemComanda.fromJson(i as Map<String, dynamic>))
                .toList() ??
            [],
      );
}

class ComandaMesa {
  final int mesaId;
  final String? idBackend;
  final List<String> idsBackendGrupo;
  List<ClienteSubCuenta> clientes;
  int clienteActivoIndex;
  final String? nombreCliente;
  final String tipoOrden;
  final double totalApi;
  final int itemsApiCount;
  final String? mesaNumero;

  ComandaMesa({
    required this.mesaId,
    this.idBackend,
    this.idsBackendGrupo = const [],
    List<ClienteSubCuenta>? clientes,
    this.clienteActivoIndex = 0,
    this.nombreCliente,
    this.tipoOrden = 'MESA',
    this.totalApi = 0.0,
    this.itemsApiCount = 0,
    this.mesaNumero,
  }) : clientes = clientes ?? [ClienteSubCuenta(id: 'c1', nombre: (nombreCliente != null && nombreCliente.isNotEmpty) ? nombreCliente : 'Cliente 1')];

  double get totalGeneral => clientes.fold(0, (sum, cliente) => sum + cliente.subtotal);
  
  ClienteSubCuenta get clienteActivo => clientes[clienteActivoIndex];

  Map<String, dynamic> toJson() => {
        'idBackend': idBackend,
        'mesaId': mesaId,
        'nombreCliente': nombreCliente,
        'tipoOrden': tipoOrden,
        'total': totalGeneral,
        'estado_orden': 'EN_PROCESO',
        'estado_impresion': 'PENDIENTE',
        'clientes': clientes.map((c) => c.toJson()).toList(),
      };

  factory ComandaMesa.fromJson(Map<String, dynamic> json) => ComandaMesa(
        idBackend: json['idBackend']?.toString() ?? json['id']?.toString(),
        mesaId: int.tryParse((json['mesaId'] ?? json['mesa_id'])?.toString() ?? '0') ?? 0,
        nombreCliente: json['nombreCliente']?.toString() ?? json['nombre_cliente']?.toString(),
        tipoOrden: json['tipoOrden']?.toString() ?? json['tipo_orden']?.toString() ?? 'MESA',
        clientes: (json['clientes'] as List<dynamic>?)
            ?.map((c) => ClienteSubCuenta.fromJson(c as Map<String, dynamic>))
            .toList(),
        mesaNumero: json['mesaNumero']?.toString() ?? json['mesa_numero']?.toString(),
      );
}
