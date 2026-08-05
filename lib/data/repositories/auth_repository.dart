import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/network/api_client.dart';
import '../models/usuario_model.dart';

class AuthRepository {
  final ApiClient _apiClient = ApiClient();

  Future<Usuario> login(String pin) async {
    try {
      final payload = {'pin': pin.toString()};
      print('>>> [FLUTTER] ENVIANDO LOGIN A: ${_apiClient.dio.options.baseUrl}/auth/login');
      print('>>> [FLUTTER] PAYLOAD: $payload');

      final response = await _apiClient.dio.post(
        '/auth/login',
        data: payload,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (response.data != null && response.data['user'] != null) {
          final token = response.data['token'];
          final usuarioMap = response.data['user'] as Map<String, dynamic>;

          // Guardar token en SharedPreferences
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('auth_token', token);

          return Usuario.fromJson(usuarioMap);
        } else {
          throw Exception('La respuesta del servidor no contiene los datos del usuario.');
        }
      } else {
        throw Exception('Error al iniciar sesión');
      }
    } on DioException catch (e) {
      if (e.response != null && e.response?.statusCode == 401) {
         throw Exception('PIN incorrecto');
      }
      throw Exception('Error de conexión: ${e.message}');
    } catch (e) {
      throw Exception('Error inesperado: $e');
    }
  }
}
