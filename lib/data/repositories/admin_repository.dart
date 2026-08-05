import 'package:dio/dio.dart';
import '../../core/network/api_client.dart';
import '../models/admin_models.dart';

class AdminRepository {
  final ApiClient _apiClient = ApiClient();

  // --- MESEROS ---
  Future<List<Mesero>> obtenerMeseros() async {
    try {
      final response = await _apiClient.dio.get('/admin/meseros?incluirInactivos=true');
      final List<dynamic> data = response.data;
      return data.map((m) => Mesero.fromJson(m)).toList();
    } catch (e) {
      _handleError(e, 'Error al cargar meseros');
      rethrow;
    }
  }

  Future<Mesero> crearMesero(String nombre, String pin) async {
    try {
      final response = await _apiClient.dio.post('/admin/meseros', data: {
        'nombre': nombre,
        'pin': pin.toString(),
        'rol': 'MESERO',
      });
      return Mesero.fromJson(response.data);
    } catch (e) {
      _handleError(e, 'Error al crear mesero');
      rethrow;
    }
  }

  Future<Mesero> actualizarMesero(int id, {String? nombre, bool? activo, String? pin}) async {
    try {
      final data = <String, dynamic>{};
      if (nombre != null) data['nombre'] = nombre;
      if (activo != null) data['activo'] = activo;
      if (pin != null && pin.isNotEmpty) data['pin'] = pin.toString();
      data['rol'] = 'MESERO';
      
      final response = await _apiClient.dio.put('/admin/meseros/$id', data: data);
      return Mesero.fromJson(response.data);
    } catch (e) {
      _handleError(e, 'Error al actualizar mesero');
      rethrow;
    }
  }

  Future<bool> actualizarEstadoMesero(int id, bool activo) async {
    try {
      final response = await _apiClient.dio.patch('/admin/meseros/$id/estado', data: {
        'activo': activo,
      });
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      print('>>> ERROR EN PATCH ESTADO MESERO: $e');
      return false;
    }
  }

  Future<void> eliminarMesero(int id, {bool hard = false}) async {
    try {
      await _apiClient.dio.delete('/admin/meseros/$id${hard ? '?hard=true' : ''}');
    } catch (e) {
      _handleError(e, 'Error al eliminar mesero');
      rethrow;
    }
  }

  // --- AUTH PIN ---
  Future<Mesero> loginPin(String pin) async {
    try {
      final response = await _apiClient.dio.post('/admin/auth/login-pin', data: {
        'pin': pin,
      });
      return Mesero.fromJson(response.data['usuario']);
    } catch (e) {
      _handleError(e, 'PIN incorrecto o inactivo');
      rethrow;
    }
  }

  // --- CONFIGURACION ---
  Future<ConfigMesa> obtenerConfiguracion() async {
    try {
      final response = await _apiClient.dio.get('/admin/config');
      return ConfigMesa.fromJson(response.data);
    } catch (e) {
      _handleError(e, 'Error al cargar configuración');
      rethrow;
    }
  }

  Future<ConfigMesa> actualizarConfiguracion(int minMesas, int maxMesas) async {
    try {
      final response = await _apiClient.dio.put('/admin/config', data: {
        'min_mesas': minMesas,
        'max_mesas': maxMesas,
      });
      return ConfigMesa.fromJson(response.data);
    } catch (e) {
      _handleError(e, 'Error al actualizar configuración');
      rethrow;
    }
  }

  // --- NOTAS RAPIDAS ---
  Future<List<NotaRapida>> obtenerNotasRapidas() async {
    try {
      final response = await _apiClient.dio.get('/admin/notas');
      final List<dynamic> data = response.data;
      return data.map((n) => NotaRapida.fromJson(n)).toList();
    } catch (e) {
      _handleError(e, 'Error al cargar notas rápidas');
      rethrow;
    }
  }

  Future<NotaRapida> crearNotaRapida(String texto, {double precioExtra = 0.0}) async {
    try {
      final response = await _apiClient.dio.post('/admin/notas', data: {
        'texto': texto,
        'precio_extra': precioExtra,
      });
      return NotaRapida.fromJson(response.data);
    } catch (e) {
      _handleError(e, 'Error al crear nota rápida');
      rethrow;
    }
  }

  Future<NotaRapida> actualizarNotaRapida(int id, String texto, {double precioExtra = 0.0}) async {
    try {
      final response = await _apiClient.dio.put('/admin/notas/$id', data: {
        'texto': texto,
        'precio_extra': precioExtra,
      });
      return NotaRapida.fromJson(response.data);
    } catch (e) {
      _handleError(e, 'Error al actualizar nota rápida');
      rethrow;
    }
  }

  Future<void> eliminarNotaRapida(int id) async {
    try {
      await _apiClient.dio.delete('/admin/notas/$id');
    } catch (e) {
      _handleError(e, 'Error al eliminar nota rápida');
      rethrow;
    }
  }

  // --- REPORTE DIARIO ---
  Future<ReporteDiario> obtenerReporteDiario() async {
    try {
      final response = await _apiClient.dio.get('/admin/reportes/diario');
      return ReporteDiario.fromJson(response.data);
    } catch (e) {
      _handleError(e, 'Error al generar reporte diario');
      rethrow;
    }
  }

  void _handleError(dynamic e, String defaultMessage) {
    if (e is DioException) {
      final apiMessage = e.response?.data?['error'] ?? e.response?.data?['message'];
      final statusCode = e.response?.statusCode;
      print('HTTP $statusCode - $defaultMessage: $apiMessage');
      if (apiMessage != null) {
        throw Exception('[$statusCode] $apiMessage');
      }
      throw Exception('[$statusCode] $defaultMessage');
    }
    print('$defaultMessage: $e');
    throw Exception(defaultMessage);
  }
}
