import 'package:dio/dio.dart';
import '../../core/network/api_client.dart';
import '../models/mesa_model.dart';

class MesasRepository {
  final ApiClient _apiClient = ApiClient();

  Future<List<Mesa>> obtenerMesas() async {
    try {
      final response = await _apiClient.dio.get('/mesas');
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data.map((json) => Mesa.fromJson(json)).toList();
      } else {
        throw Exception('Error al obtener mesas: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Fallo de red al obtener mesas: $e');
    }
  }

  Future<void> juntarMesas(int mesaHijaId, int mesaPadreId) async {
    try {
      final response = await _apiClient.dio.post(
        '/mesas/juntar',
        data: {
          'mesa_hija_id': mesaHijaId,
          'mesa_padre_id': mesaPadreId,
        },
      );
      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception('Error al juntar mesas: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Fallo de red al juntar mesas: $e');
    }
  }

  Future<void> separarMesa(int mesaId) async {
    try {
      final response = await _apiClient.dio.post(
        '/mesas/separar',
        data: {
          'mesa_id': mesaId,
        },
      );
      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception('Error al separar mesa: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Fallo de red al separar mesa: $e');
    }
  }

  Future<void> crearMesa() async {
    try {
      final response = await _apiClient.dio.post('/mesas');
      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception('Error al crear mesa: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Fallo de red al crear mesa: $e');
    }
  }

  Future<void> eliminarUltimaMesa() async {
    try {
      final response = await _apiClient.dio.delete('/mesas');
      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception('Error al eliminar mesa: ${response.statusCode}');
      }
    } on DioException catch (e) {
      final message = e.response?.data?['message'] ?? e.response?.data?['error'];
      if (message != null) {
        throw Exception(message);
      }
      throw Exception('Error al eliminar mesa: ${e.response?.statusCode ?? e.message}');
    } catch (e) {
      throw Exception('Error inesperado al eliminar mesa: $e');
    }
  }

  Future<Map<String, dynamic>> obtenerConfiguracion() async {
    try {
      final response = await _apiClient.dio.get('/admin/config');
      return response.data as Map<String, dynamic>;
    } catch (e) {
      throw Exception('Fallo al obtener configuración: $e');
    }
  }
}
