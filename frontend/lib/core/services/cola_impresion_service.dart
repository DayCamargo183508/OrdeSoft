import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/models/comanda_model.dart';
import '../../data/repositories/comandas_repository.dart';

class ColaImpresionService {
  static const String _colaKey = 'cola_comandas_fallidas';
  static final ColaImpresionService _instance = ColaImpresionService._internal();

  factory ColaImpresionService() => _instance;

  ColaImpresionService._internal();

  Future<void> encolarComanda(ComandaMesa comanda) async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> colaJson = prefs.getStringList(_colaKey) ?? [];

    final payload = comanda.toJson();
    // Identificador de timestamp para reintentos
    payload['_timestamp'] = DateTime.now().toIso8601String();
    
    colaJson.add(jsonEncode(payload));
    await prefs.setStringList(_colaKey, colaJson);
  }

  Future<void> procesarCola(ComandasRepository repository) async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> colaJson = prefs.getStringList(_colaKey) ?? [];
    
    if (colaJson.isEmpty) return;

    final List<String> comandasFallidas = [];

    for (final strJson in colaJson) {
      try {
        final Map<String, dynamic> map = jsonDecode(strJson);
        final comanda = ComandaMesa.fromJson(map);
        // Intentar enviar al backend
        await repository.crearComanda(comanda);
        print('Comanda encolada de mesa ${comanda.mesaId} enviada con éxito.');
      } catch (e) {
        // Si falla de nuevo, se retiene en la cola
        print('Fallo al reintentar envío de comanda: $e');
        comandasFallidas.add(strJson);
      }
    }

    // Actualizar la cola solo con las que fallaron
    await prefs.setStringList(_colaKey, comandasFallidas);
  }
}
