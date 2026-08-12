import '../../data/models/comanda_model.dart';
import '../../data/models/printer_config.dart';
import '../../data/models/menu_admin_models.dart';

class KitchenTicketService {
  /// Genera el string ASCII del ticket de cocina filtrando por las categorías permitidas
  /// Retorna null si después de filtrar no queda ningún ítem de cocina.
  static String? generarTicketCocina(
    ComandaMesa comanda,
    PrinterConfig config,
    List<ProductoAdmin> catalogoProductos,
  ) {
    // 1. Clonar y filtrar la comanda
    final clientesFiltrados = <ClienteSubCuenta>[];
    int totalItemsCocina = 0;
    
    // Mapa para sumar tipos de producto al final
    final sumatoriaProductos = <String, int>{};

    for (var cliente in comanda.clientes) {
      final itemsFiltrados = <ItemComanda>[];
      
      for (var item in cliente.items) {
        // Buscar el producto en el catálogo para saber su categoría
        final productoCat = catalogoProductos.firstWhere(
          (p) => p.id.toString() == item.productoId,
          orElse: () => ProductoAdmin(
            id: '0',
            nombre: 'Desconocido',
            precio: 0,
            categoriaId: 0,
            disponible: false,
          ),
        );

        if (config.categoriasCocina.contains(productoCat.categoriaId)) {
          itemsFiltrados.add(item);
          totalItemsCocina += item.cantidad;
          
          if (sumatoriaProductos.containsKey(item.producto)) {
            sumatoriaProductos[item.producto] = sumatoriaProductos[item.producto]! + item.cantidad;
          } else {
            sumatoriaProductos[item.producto] = item.cantidad;
          }
        }
      }

      if (itemsFiltrados.isNotEmpty) {
        // Clonamos el cliente pero solo con los ítems filtrados
        clientesFiltrados.add(
          ClienteSubCuenta(
            id: cliente.id,
            nombre: cliente.nombre,
            items: itemsFiltrados,
            cuentaId: cliente.cuentaId,
          )
        );
      }
    }

    if (totalItemsCocina == 0) {
      return null; // Nada que imprimir para cocina
    }

    // 2. Generar el texto
    final anchoMax = config.anchoPapel == '80mm' ? 40 : 32;
    final buffer = StringBuffer();
    
    // Función de ayuda para centrar texto
    String centrar(String texto) {
      if (texto.length >= anchoMax) return texto;
      final padding = (anchoMax - texto.length) ~/ 2;
      return texto.padLeft(texto.length + padding).padRight(anchoMax);
    }
    
    final separadorGrueso = '=' * anchoMax;
    final separadorFino = '-' * anchoMax;

    buffer.writeln(separadorGrueso);
    buffer.writeln(centrar('COMANDA DE COCINA'));
    buffer.writeln(separadorGrueso);

    for (var cliente in clientesFiltrados) {
      for (var item in cliente.items) {
        // Formato: " 3 Suadero               Todo"
        final cantNombre = ' ${item.cantidad} ${item.producto}';
        String notas = item.notasString.trim();
        if (notas.isEmpty) notas = 'Todo';

        // Si la combinación es más larga que el ancho, se pone en otra línea,
        // de lo contrario se alinea a la derecha.
        if (cantNombre.length + notas.length + 2 > anchoMax) {
          buffer.writeln(cantNombre);
          buffer.writeln(notas.padLeft(anchoMax));
        } else {
          final espacios = anchoMax - cantNombre.length - notas.length;
          buffer.writeln('$cantNombre${' ' * espacios}$notas');
        }
      }
      buffer.writeln(separadorFino);
    }

    // Pie de página
    // "# 1   Dairon"
    String identificador = comanda.tipoOrden == 'PARA_LLEVAR'
        ? 'Para Llevar'
        : '${comanda.mesaId}';
        
    if (comanda.nombreCliente != null && comanda.nombreCliente!.isNotEmpty) {
      if (comanda.tipoOrden == 'PARA_LLEVAR') {
         identificador = 'Para Llevar (${comanda.nombreCliente})';
      } else {
         identificador = '${comanda.mesaId} (${comanda.nombreCliente})';
      }
    }
    
    // Como el mesero a veces no está en la comanda de UI (porque depende del login),
    // podemos dejar 'Mesero' o si existiese, usarlo. 
    // Usaremos un string genérico si no lo tenemos, o podemos extender ComandaMesa.
    // Asumiremos que el app actual tiene al mesero autenticado en algún state, 
    // pero para el ticket ponemos el formato sugerido.
    buffer.writeln('# $identificador');
    
    // Resumen final (ej: "12 Tacos 1 Hamburguesa 1 Papas")
    final resumenArr = sumatoriaProductos.entries.map((e) => '${e.value} ${e.key}').toList();
    buffer.writeln(resumenArr.join(' '));
    buffer.writeln(separadorGrueso);
    
    // Dejar espacio para corte
    buffer.writeln('');
    buffer.writeln('');
    buffer.writeln('');

    return buffer.toString();
  }
}
