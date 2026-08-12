import 'package:dio/dio.dart';
import '../../core/network/api_client.dart';
import '../models/menu_admin_models.dart';

class MenuAdminRepository {
  final ApiClient _apiClient = ApiClient();

  // --- CATEGORÍAS ---
  Future<List<CategoriaAdmin>> obtenerCategorias() async {
    try {
      final response = await _apiClient.dio.get('/menu/categorias');
      final data = response.data;
      final List<dynamic> listData = data is List ? data : (data['data'] ?? data['categorias'] ?? []);
      return listData.map((c) => CategoriaAdmin.fromJson(c)).toList();
    } catch (e) {
      _handleError(e, 'Error al cargar categorías');
      rethrow;
    }
  }

  Future<CategoriaAdmin> crearCategoria(String nombre) async {
    try {
      final response = await _apiClient.dio.post('/menu/categorias', data: {
        'nombre': nombre,
        'activo': true, // Asumimos true por defecto
      });
      return CategoriaAdmin.fromJson(response.data);
    } catch (e) {
      _handleError(e, 'Error al crear categoría');
      rethrow;
    }
  }

  Future<CategoriaAdmin> actualizarCategoria(int id, String nombre) async {
    try {
      final response = await _apiClient.dio.put('/menu/categorias/$id', data: {
        'nombre': nombre,
      });
      return CategoriaAdmin.fromJson(response.data);
    } catch (e) {
      _handleError(e, 'Error al actualizar categoría');
      rethrow;
    }
  }

  Future<void> eliminarCategoria(int id) async {
    try {
      await _apiClient.dio.delete('/menu/categorias/$id');
    } catch (e) {
      _handleError(e, 'Error al eliminar categoría');
      rethrow;
    }
  }

  // --- PRODUCTOS ---
  Future<List<ProductoAdmin>> obtenerProductos() async {
    try {
      final response = await _apiClient.dio.get('/menu/productos?incluirInactivos=true');
      final data = response.data;
      final List<dynamic> listData = data is List ? data : (data['data'] ?? data['productos'] ?? []);
      return listData.map((p) => ProductoAdmin.fromJson(p)).toList();
    } catch (e) {
      _handleError(e, 'Error al cargar productos');
      rethrow;
    }
  }

  Future<ProductoAdmin> crearProducto(Map<String, dynamic> datos) async {
    try {
      final response = await _apiClient.dio.post('/menu/productos', data: datos);
      return ProductoAdmin.fromJson(response.data);
    } catch (e) {
      _handleError(e, 'Error al crear producto');
      rethrow;
    }
  }

  Future<bool> actualizarProducto(String id, String nombre, double precio, int categoriaId) async {
    final url = '/menu/productos/$id';
    print('>>> ENVIANDO PATCH A URL: ${_apiClient.dio.options.baseUrl}$url');

    try {
      final response = await _apiClient.dio.patch(
        url,
        data: {
          'nombre': nombre,
          'precio': precio,
          'categoria_id': categoriaId,
        },
      );
      
      print('>>> STATUS PATCH PRODUCTO: ${response.statusCode}');
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      }
      return false;
    } catch (e) {
      print('>>> ERROR EN PATCH PRODUCTO: $e');
      _handleError(e, 'Error al actualizar producto');
      return false;
    }
  }

  Future<bool> actualizarDisponibilidadProducto(String id, bool disponible) async {
    final url = '/menu/productos/$id/estado';
    try {
      final response = await _apiClient.dio.patch(
        url,
        data: {
          'disponible': disponible,
        },
      );
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      print('>>> ERROR EN PATCH ESTADO PRODUCTO: $e');
      _handleError(e, 'Error al actualizar disponibilidad');
      return false;
    }
  }

  Future<void> eliminarProducto(String id) async {
    try {
      await _apiClient.dio.delete('/menu/productos/$id');
    } catch (e) {
      _handleError(e, 'Error al eliminar producto');
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
