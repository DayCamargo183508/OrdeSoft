import 'package:dio/dio.dart';
import '../models/comanda_model.dart';
import '../../core/network/api_client.dart';

class ComandasRepository {
  final ApiClient _apiClient = ApiClient();

  Future<void> crearComanda(ComandaMesa comanda) async {
    try {
      final List<Map<String, dynamic>> detallesPlanos = [];

      for (var cliente in comanda.clientes) {
        for (var item in cliente.items) {
          if (!item.isNew) continue; // SOLO enviar ítems nuevos

          String notaFinal = item.notasString;
          if (comanda.clientes.length > 1) {
             final prefix = '[${cliente.nombre}]';
             if (notaFinal.trim().isEmpty) {
                notaFinal = prefix;
             } else {
                notaFinal = '$prefix ${notaFinal.trim()}';
             }
          }

          detallesPlanos.add({
            'producto_id': item.productoId,
            'cantidad': item.cantidad,
            'notas': notaFinal,
            'precio_unitario': item.precioUnitarioFinal,
            'cuenta_id': cliente.cuentaId,
            'cliente_nombre': cliente.nombre,
          });
        }
      }

      final payload = {
        'comanda_id': comanda.idBackend,
        'mesa_id': comanda.tipoOrden == 'PARA_LLEVAR' ? null : comanda.mesaId,
        'tipo_orden': comanda.tipoOrden,
        'nombre_cliente': comanda.nombreCliente,
        'detalles': detallesPlanos,
      };

      await _apiClient.dio.post('/comandas', data: payload);
    } catch (e) {
      if (e is DioException) {
        if (e.type == DioExceptionType.connectionError || 
            e.type == DioExceptionType.connectionTimeout || 
            e.type == DioExceptionType.receiveTimeout || 
            e.type == DioExceptionType.sendTimeout) {
            throw Exception('CONNECTION_ERROR');
        }
        print('❌ ERROR AL GUARDAR COMANDA: Status ${e.response?.statusCode} - ${e.response?.data}');
        final errorMessage = e.response?.data?['message'] ?? e.response?.data?['error'] ?? 'Error interno al crear comanda.';
        throw Exception('SERVER_ERROR: $errorMessage');
      }
      throw Exception('CONNECTION_ERROR: $e');
    }
  }

  Future<ComandaMesa?> obtenerComandaActivaPorMesa(int mesaId) async {
    try {
      final response = await _apiClient.dio.get('/comandas');
      final List<dynamic> comandasActivas = response.data;
      
      // Encontrar TODAS las comandas de la mesa actual
      final comandasDeMesa = comandasActivas.where((c) => c['mesa_id'] == mesaId).toList();

      if (comandasDeMesa.isEmpty) return null;

      List<String> idsBackendGrupo = [];
      Map<String, ClienteSubCuenta> clientesMap = {};
      int itemsTotales = 0;
      double totalApiTotal = 0.0;
      String? mesaNumeroStr;

      for (var comandaMap in comandasDeMesa) {
        final comandaId = comandaMap['id'];
        idsBackendGrupo.add(comandaId.toString());
        totalApiTotal += double.tryParse(comandaMap['total']?.toString() ?? '0') ?? 0.0;
        if (comandaMap['mesa_numero'] != null) {
          mesaNumeroStr = comandaMap['mesa_numero'].toString();
        }

        final detalleResponse = await _apiClient.dio.get('/comandas/$comandaId');
        final detalleData = detalleResponse.data;

        for (var d in (detalleData['detalles'] as List<dynamic>)) {
          final notasStr = d['notas']?.toString() ?? '';
          final listNotas = notasStr.isEmpty 
              ? <NotaAplicada>[] 
              : notasStr.split(',').map((e) => NotaAplicada(e.trim(), 0.0)).toList();

          final item = ItemComanda(
            id: d['id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
            productoId: d['producto_id'].toString(),
            producto: d['producto_nombre'] ?? 'Producto',
            cantidad: d['cantidad'],
            precioUnitario: double.tryParse(d['precio_unitario']?.toString() ?? '0') ?? 0.0,
            notas: listNotas,
            isNew: false,
          );

          itemsTotales += item.cantidad;
          
          final cuentaId = d['cuenta_id'] as int? ?? 1;
          final clienteNombre = d['cliente_nombre']?.toString() ?? 'Cliente 1';
          // Se incluye el comandaId en la key para evitar colisiones accidentales de cuentas con el mismo nombre entre distintas comandas fantasma
          final key = '${comandaId}_${cuentaId}_$clienteNombre';

          if (!clientesMap.containsKey(key)) {
            clientesMap[key] = ClienteSubCuenta(
              id: key,
              nombre: clienteNombre,
              cuentaId: cuentaId,
              items: [],
            );
          }
          clientesMap[key]!.items.add(item);
        }
      }

      final clientesFinales = clientesMap.values.toList();
      clientesFinales.sort((a, b) => a.cuentaId.compareTo(b.cuentaId));

      return ComandaMesa(
        mesaId: mesaId,
        idBackend: comandasDeMesa.first['id'].toString(), // Tomamos la mas reciente como principal
        idsBackendGrupo: idsBackendGrupo,
        clientes: clientesFinales,
        totalApi: totalApiTotal,
        itemsApiCount: itemsTotales,
        mesaNumero: mesaNumeroStr,
      );
    } catch (e) {
      print('❌ Error al obtener comanda activa: $e');
      return null;
    }
  }

  Future<void> pagarComanda(String comandaId) async {
    try {
      await _apiClient.dio.patch('/comandas/$comandaId/pagar');
    } catch (e) {
      if (e is DioException) {
        final errorMessage = e.response?.data?['message'] ?? e.response?.data?['error'] ?? 'Error interno al pagar comanda.';
        throw Exception(errorMessage);
      }
      throw Exception('Error de red al pagar la comanda: $e');
    }
  }

  Future<bool> pagarCuentaComanda(String comandaId, int cuentaId) async {
    try {
      final response = await _apiClient.dio.patch('/comandas/$comandaId/pagar-cuenta', data: {'cuenta_id': cuentaId});
      return response.data['mesaDesocupada'] ?? false;
    } catch (e) {
      if (e is DioException) {
        final errorMessage = e.response?.data?['message'] ?? e.response?.data?['error'] ?? 'Error interno al pagar cuenta.';
        throw Exception(errorMessage);
      }
      throw Exception('Error de red al pagar la cuenta: $e');
    }
  }

  Future<List<ComandaMesa>> obtenerComandasParaLlevar() async {
    try {
      final response = await _apiClient.dio.get('/comandas/para-llevar');
      final List<dynamic> comandasData = response.data;

      List<ComandaMesa> comandas = [];
      for (var c in comandasData) {
        final comandaId = c['id'];
        final nombre = c['nombre_cliente'] ?? 'Sin nombre';

        // Fetch detalles for each comanda if needed, or if the endpoint already returns them.
        // Assuming the endpoint returns basic details or we need to map them from `detalles` if included.
        // Agrupar por cuenta_id y cliente_nombre devueltos
        Map<String, ClienteSubCuenta> clientesMap = {};
        int itemsTotales = 0;

        if (c['detalles'] != null) {
          for (var d in (c['detalles'] as List<dynamic>)) {
            final notasStr = d['notas']?.toString() ?? '';
            final listNotas = notasStr.isEmpty 
                ? <NotaAplicada>[] 
                : notasStr.split(',').map((e) => NotaAplicada(e.trim(), 0.0)).toList();

            final item = ItemComanda(
              id: d['id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
              productoId: d['producto_id'].toString(),
              producto: d['producto_nombre'] ?? 'Producto',
              cantidad: d['cantidad'],
              precioUnitario: double.tryParse(d['precio_unitario']?.toString() ?? '0') ?? 0.0,
              notas: listNotas,
              isNew: false, // ítems recuperados del servidor
            );

            itemsTotales += item.cantidad;
            
            final cuentaId = d['cuenta_id'] as int? ?? 1;
            final clienteNombre = d['cliente_nombre']?.toString() ?? 'Cliente 1';
            final key = '${cuentaId}_$clienteNombre';

            if (!clientesMap.containsKey(key)) {
              clientesMap[key] = ClienteSubCuenta(
                id: key,
                nombre: clienteNombre,
                cuentaId: cuentaId,
                items: [],
              );
            }
            clientesMap[key]!.items.add(item);
          }
        }

        final clientesFinales = clientesMap.values.toList();
        clientesFinales.sort((a, b) => a.cuentaId.compareTo(b.cuentaId));

        comandas.add(
          ComandaMesa(
            mesaId: 0,
            idBackend: comandaId.toString(),
            nombreCliente: nombre,
            tipoOrden: 'PARA_LLEVAR',
            clientes: clientesFinales,
            totalApi: double.tryParse(c['total']?.toString() ?? '0') ?? 0.0,
            itemsApiCount: itemsTotales,
          ),
        );
      }
      return comandas;
    } catch (e) {
      print('❌ Error al obtener comandas para llevar: $e');
      if (e is DioException) {
        throw Exception(e.response?.data?['message'] ?? 'Error al cargar comandas para llevar.');
      }
      throw Exception('Fallo de red: $e');
    }
  }

  Future<Map<int, double>> obtenerTotalesMesasOcupadas() async {
    try {
      final response = await _apiClient.dio.get('/comandas');
      final List<dynamic> comandasActivas = response.data;
      
      Map<int, double> totales = {};
      for (var c in comandasActivas) {
        if (c['mesa_id'] != null) {
           final double total = double.tryParse(c['total']?.toString() ?? '0') ?? 0.0;
           totales[c['mesa_id'] as int] = (totales[c['mesa_id'] as int] ?? 0.0) + total;
        }
      }
      return totales;
    } catch (e) {
      print('❌ Error al obtener totales de mesas ocupadas: $e');
      return {};
    }
  }
}
