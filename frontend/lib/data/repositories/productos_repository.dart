import '../models/categoria_model.dart';
import '../models/producto_model.dart';
import '../../core/network/api_client.dart';

class ProductosRepository {
  final ApiClient _apiClient = ApiClient();

  Future<List<Categoria>> getCategorias() async {
    try {
      final response = await _apiClient.dio.get('/menu/categorias');
      // Asegurar parseo seguro independientemente de si viene en 'data' o arreglo directo
      final data = response.data;
      final List<dynamic> listData = data is List ? data : (data['data'] ?? data['categorias'] ?? []);
      
      return listData.map((c) => Categoria.fromJson(c)).toList();
    } catch (e) {
      throw Exception('Error al cargar categorías: $e');
    }
  }

  Future<List<Producto>> getProductos() async {
    try {
      final response = await _apiClient.dio.get('/menu/productos');
      final data = response.data;
      final List<dynamic> listData = data is List ? data : (data['data'] ?? data['productos'] ?? []);
      
      return listData.map((p) => Producto.fromJson(p)).toList();
    } catch (e) {
      throw Exception('Error al cargar productos: $e');
    }
  }
}
