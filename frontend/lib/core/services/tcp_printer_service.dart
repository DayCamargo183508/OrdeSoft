import 'dart:io';
import 'dart:convert';

import '../../data/models/printer_config.dart';

class TcpPrinterService {
  /// Envía un texto ASCII a la impresora térmica por Socket TCP
  /// Agrega el comando de corte (ESC/POS) al final.
  static Future<bool> imprimirTicket(PrinterConfig config, String texto) async {
    Socket? socket;
    try {
      socket = await Socket.connect(
        config.ipImpresora, 
        config.puerto, 
        timeout: const Duration(seconds: 3)
      );

      // Convertimos el texto a bytes usando ASCII (o latin1 si hay acentos básicos)
      // Muchas impresoras térmicas básicas trabajan bien con latin1 / cp850
      final List<int> bytes = latin1.encode(texto);
      
      // Comando de corte ESC/POS: GS V 0 (hex: 1D 56 00) o ESC i (hex: 1B 69)
      final List<int> cutCommand = [0x1D, 0x56, 0x00];

      // Enviar datos
      socket.add(bytes);
      socket.add(cutCommand);
      
      await socket.flush();
      return true;
    } catch (e) {
      print('❌ Error al imprimir (TCP): $e');
      return false;
    } finally {
      socket?.destroy();
    }
  }
}
