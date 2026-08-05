import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class PrinterConfig {
  String ipImpresora;
  int puerto;
  String anchoPapel; // '80mm' o '58mm'
  List<int> categoriasCocina;
  bool imprimirAutomatico;

  PrinterConfig({
    this.ipImpresora = '192.168.1.200',
    this.puerto = 9100,
    this.anchoPapel = '80mm',
    this.categoriasCocina = const [],
    this.imprimirAutomatico = false,
  });

  Map<String, dynamic> toJson() => {
        'ipImpresora': ipImpresora,
        'puerto': puerto,
        'anchoPapel': anchoPapel,
        'categoriasCocina': categoriasCocina,
        'imprimirAutomatico': imprimirAutomatico,
      };

  factory PrinterConfig.fromJson(Map<String, dynamic> json) => PrinterConfig(
        ipImpresora: json['ipImpresora']?.toString() ?? '192.168.1.200',
        puerto: int.tryParse(json['puerto']?.toString() ?? '9100') ?? 9100,
        anchoPapel: json['anchoPapel']?.toString() ?? '80mm',
        categoriasCocina: (json['categoriasCocina'] as List<dynamic>?)?.map((e) => int.tryParse(e.toString()) ?? 0).toList() ?? [],
        imprimirAutomatico: json['imprimirAutomatico'] == true,
      );

  static Future<PrinterConfig> load() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString('printer_config');
    if (data != null) {
      try {
        return PrinterConfig.fromJson(jsonDecode(data));
      } catch (e) {
        // Ignorar y retornar por defecto
      }
    }
    return PrinterConfig();
  }

  Future<void> save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('printer_config', jsonEncode(toJson()));
  }
}
