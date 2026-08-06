import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui';
import '../../data/models/comanda_model.dart';
import '../../data/models/categoria_model.dart';
import '../../data/models/producto_model.dart';
import '../../data/repositories/productos_repository.dart';
import '../../data/repositories/comandas_repository.dart';
import '../../core/services/cola_impresion_service.dart';
import '../../data/repositories/admin_repository.dart';
import '../../data/models/admin_models.dart';
import 'cobrar_comanda_screen.dart';

class TomarComandaScreen extends StatefulWidget {
  final int mesaId;
  final String mesaNumero;
  final String? nombreCliente;
  final String tipoOrden;
  final ComandaMesa? comandaPreexistente;
  const TomarComandaScreen({
    super.key, 
    required this.mesaId, 
    required this.mesaNumero, 
    this.nombreCliente,
    this.tipoOrden = 'MESA',
    this.comandaPreexistente,
  });

  @override
  State<TomarComandaScreen> createState() => _TomarComandaScreenState();
}

class _TomarComandaScreenState extends State<TomarComandaScreen> {
  late ComandaMesa _comanda;
  int _cantidadSeleccionada = 1;
  String? _categoriaSeleccionada;
  bool _isEnviando = false;

  bool _cargandoCatalogo = true;
  String? _errorCatalogo;
  List<Categoria> _categorias = [];
  List<Producto> _productos = [];
  final ProductosRepository _productosRepository = ProductosRepository();
  final ComandasRepository _comandasRepository = ComandasRepository();
  final ColaImpresionService _colaImpresionService = ColaImpresionService();
  final AdminRepository _adminRepo = AdminRepository();
  List<NotaRapida> _notasRapidas = [];

  double _totalAnterior = 0.0;

  @override
  void initState() {
    super.initState();
    if (widget.comandaPreexistente != null) {
      _totalAnterior = widget.comandaPreexistente!.totalApi;
      // Creamos una comanda vacía pero que mantenga el idBackend
      _comanda = ComandaMesa(
        mesaId: widget.mesaId,
        idBackend: widget.comandaPreexistente!.idBackend,
        nombreCliente: widget.comandaPreexistente!.nombreCliente,
        tipoOrden: widget.comandaPreexistente!.tipoOrden,
      );
    } else {
      _comanda = ComandaMesa(
        mesaId: widget.mesaId, 
        nombreCliente: widget.nombreCliente,
        tipoOrden: widget.tipoOrden,
      );
    }
    _cargarCatalogo();
    _cargarNotasRapidas();
  }

  Future<void> _cargarNotasRapidas() async {
    try {
      final notas = await _adminRepo.obtenerNotasRapidas();
      print('>>> NOTAS CARGADAS DESDE API: ${notas.length} elementos');
      for (var n in notas) {
        print('>>> Nota: ID=${n.id}, Texto=${n.texto}, Activa=${n.activa}');
      }
      setState(() {
        _notasRapidas = notas;
      });
    } catch (e) {
      print('>>> ERROR AL CARGAR NOTAS: $e');
    }
  }

  Future<void> _cargarCatalogo() async {
    setState(() {
      _cargandoCatalogo = true;
      _errorCatalogo = null;
    });
    try {
      final results = await Future.wait([
        _productosRepository.getCategorias(),
        _productosRepository.getProductos(),
      ]);
      setState(() {
        _categorias = results[0] as List<Categoria>;
        _productos = (results[1] as List<Producto>).where((p) => p.disponible).toList();
        _cargandoCatalogo = false;
        if (_categorias.isNotEmpty) {
           _categoriaSeleccionada = _categorias.first.id;
        }
      });
    } catch (e) {
      setState(() {
        _errorCatalogo = e.toString();
        _cargandoCatalogo = false;
      });
    }
  }

  String _generateId() => DateTime.now().millisecondsSinceEpoch.toString();

  void _onNumpadTap(String value) {
    setState(() {
      if (value == 'C') {
        _cantidadSeleccionada = 1;
      } else {
        if (_cantidadSeleccionada == 1) {
          if (value == '0') {
            _cantidadSeleccionada = 10;
          } else {
            _cantidadSeleccionada = int.tryParse(value) ?? 1;
          }
        } else {
          String newValue = '$_cantidadSeleccionada$value';
          _cantidadSeleccionada = int.tryParse(newValue) ?? 1;
        }
      }
    });
  }

  void _agregarProducto(Producto producto) {
    setState(() {
      final cliente = _comanda.clienteActivo;
      
      final existingItemIndex = cliente.items.indexWhere((i) => i.producto == producto.nombre && i.notas.isEmpty);
      if (existingItemIndex >= 0) {
        cliente.items[existingItemIndex].cantidad += _cantidadSeleccionada;
      } else {
        cliente.items.add(
          ItemComanda(
            id: _generateId(),
            productoId: producto.id,
            producto: producto.nombre,
            cantidad: _cantidadSeleccionada,
            precioUnitario: producto.precio,
          ),
        );
      }
      _cantidadSeleccionada = 1; 
    });
  }

  void _agregarCliente({int? cuentaId}) {
    setState(() {
      final nuevoId = _generateId();
      final nuevoNumero = _comanda.clientes.length + 1;
      final cId = cuentaId ?? (_comanda.clientes.isNotEmpty ? _comanda.clientes.last.cuentaId : 1);
      _comanda.clientes.add(ClienteSubCuenta(id: nuevoId, nombre: 'Cliente $nuevoNumero', cuentaId: cId));
      _comanda.clienteActivoIndex = _comanda.clientes.length - 1;
    });
  }

  void _eliminarCliente(int index) {
    final cliente = _comanda.clientes[index];
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('¿Eliminar cliente?', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
        content: Text('¿Eliminar a ${cliente.nombre}${cliente.items.isNotEmpty ? ' y todos sus platillos' : ''}?', style: GoogleFonts.inter()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancelar', style: GoogleFonts.inter()),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _comanda.clientes.removeAt(index);
                if (_comanda.clientes.isEmpty) {
                  _agregarCliente(cuentaId: 1);
                } else if (_comanda.clienteActivoIndex >= _comanda.clientes.length) {
                  _comanda.clienteActivoIndex = _comanda.clientes.length - 1;
                } else if (_comanda.clienteActivoIndex > index) {
                  _comanda.clienteActivoIndex--;
                }
              });
              Navigator.pop(ctx);
            },
            child: Text('Eliminar', style: GoogleFonts.inter(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _cambiarCliente(int index) {
    setState(() {
      _comanda.clienteActivoIndex = index;
    });
  }

  void _mostrarModalMoverItem(ItemComanda item, int clienteOrigenIndex) {
    if (_comanda.clientes.length <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Crea otro cliente primero para poder mover ítems', style: GoogleFonts.inter())),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text('Mover "${item.producto}"', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _comanda.clientes.length,
              itemBuilder: (context, index) {
                if (index == clienteOrigenIndex) return const SizedBox.shrink();
                final clienteDestino = _comanda.clientes[index];
                return ListTile(
                  leading: const Icon(Icons.person),
                  title: Text(clienteDestino.nombre, style: GoogleFonts.inter()),
                  onTap: () {
                    setState(() {
                      _comanda.clientes[clienteOrigenIndex].items.remove(item);
                      
                      final existingIndex = clienteDestino.items.indexWhere((i) => i.producto == item.producto && i.precioUnitario == item.precioUnitario && i.notasString == item.notasString);
                      if (existingIndex >= 0) {
                        clienteDestino.items[existingIndex].cantidad += item.cantidad;
                      } else {
                        clienteDestino.items.add(item);
                      }
                    });
                    Navigator.pop(ctx);
                  },
                );
              },
            ),
          ),
        );
      },
    );
  }

  void _mostrarModalNotas(ItemComanda item) {
    List<NotaAplicada> currentNotes = List.from(item.notas);
    final TextEditingController _notasController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setStateModal) {
            return AlertDialog(
              title: Text('Notas para "${item.producto}"', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_notasRapidas.isNotEmpty)
                      Wrap(
                        spacing: 8.0,
                        runSpacing: 4.0,
                        children: _notasRapidas.map((nota) {
                          final label = nota.precioExtra > 0 ? '${nota.texto} (+\$${nota.precioExtra.toStringAsFixed(2)})' : nota.texto;
                          return ActionChip(
                            label: Text(label, style: GoogleFonts.inter(fontSize: 12)),
                            onPressed: () {
                              setStateModal(() {
                                if (!currentNotes.any((n) => n.texto == nota.texto)) {
                                  currentNotes.add(NotaAplicada(nota.texto, nota.precioExtra));
                                }
                              });
                            },
                          );
                        }).toList(),
                      ),
                    const Divider(),
                    if (currentNotes.isNotEmpty)
                      Wrap(
                        spacing: 8,
                        children: currentNotes.map((nota) {
                          final label = nota.precioExtra > 0 ? '${nota.texto} (+\$${nota.precioExtra.toStringAsFixed(2)})' : nota.texto;
                          return InputChip(
                            label: Text(label, style: GoogleFonts.inter(fontSize: 12)),
                            deleteIcon: const Icon(Icons.close, size: 16),
                            onDeleted: () {
                              setStateModal(() {
                                currentNotes.remove(nota);
                              });
                            },
                          );
                        }).toList(),
                      ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _notasController,
                            decoration: const InputDecoration(
                              hintText: 'Otra nota...',
                              isDense: true,
                            ),
                            onSubmitted: (val) {
                              if (val.trim().isNotEmpty) {
                                setStateModal(() {
                                  currentNotes.add(NotaAplicada(val.trim(), 0.0));
                                  _notasController.clear();
                                });
                              }
                            },
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add_circle, color: Colors.blueAccent),
                          onPressed: () {
                            if (_notasController.text.trim().isNotEmpty) {
                              setStateModal(() {
                                currentNotes.add(NotaAplicada(_notasController.text.trim(), 0.0));
                                _notasController.clear();
                              });
                            }
                          },
                        )
                      ],
                    )
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text('Cancelar', style: GoogleFonts.inter()),
                ),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      item.notas = currentNotes;
                    });
                    Navigator.pop(ctx);
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent, foregroundColor: Colors.white),
                  child: Text('Guardar', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
                ),
              ],
            );
          }
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final titleText = widget.tipoOrden == 'PARA_LLEVAR' 
      ? 'Pedido Para Llevar: ${widget.nombreCliente ?? ''}' 
      : 'Comanda Mesa ${widget.mesaNumero}';

    if (_cargandoCatalogo) {
      return Scaffold(
        appBar: AppBar(title: Text(titleText, style: GoogleFonts.inter(fontWeight: FontWeight.bold)), backgroundColor: Colors.blueAccent, foregroundColor: Colors.white),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_errorCatalogo != null) {
      return Scaffold(
        appBar: AppBar(title: Text(titleText, style: GoogleFonts.inter(fontWeight: FontWeight.bold)), backgroundColor: Colors.blueAccent, foregroundColor: Colors.white),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text('Error al cargar el catálogo', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(_errorCatalogo!, textAlign: TextAlign.center, style: GoogleFonts.inter(color: Colors.grey.shade700)),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _cargarCatalogo,
                icon: const Icon(Icons.refresh),
                label: Text('Reintentar', style: GoogleFonts.inter()),
              )
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(titleText, style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
      ),
      body: Row(
        children: [
          // PANEL IZQUIERDO (Toma Veloz)
          Expanded(
            flex: 6,
            child: Column(
              children: [
                _buildCategorias(),
                Expanded(child: _buildProductosGrid()),
                _buildNumpad(),
              ],
            ),
          ),
          // SEPARADOR VERTICAL
          const VerticalDivider(width: 1, thickness: 1),
          // PANEL DERECHO (Cuentas Divididas)
          Expanded(
            flex: 4,
            child: Container(
              color: Colors.grey.shade50,
              child: Column(
                children: [
                  _buildTabsClientes(),
                  Expanded(child: _buildListaItems()),
                  _buildResumenTotal(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategorias() {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      color: Colors.white,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _categorias.length,
        itemBuilder: (context, index) {
          final cat = _categorias[index];
          final isSelected = cat.id == _categoriaSeleccionada;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            child: ChoiceChip(
              label: Text(cat.nombre, style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: isSelected ? Colors.white : Colors.black87)),
              selected: isSelected,
              selectedColor: Colors.blueAccent,
              onSelected: (val) {
                setState(() => _categoriaSeleccionada = cat.id);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildProductosGrid() {
    final productosFiltrados = _productos.where((p) => p.categoriaId == _categoriaSeleccionada).toList();
    
    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.1,
      ),
      itemCount: productosFiltrados.length,
      itemBuilder: (context, index) {
        final p = productosFiltrados[index];
        return InkWell(
          onTap: () => _agregarProducto(p),
          borderRadius: BorderRadius.circular(12),
          child: Card(
            elevation: 3,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (p.imagenUrl != null && p.imagenUrl!.isNotEmpty)
                   Expanded(
                     child: Padding(
                       padding: const EdgeInsets.all(8.0),
                       child: Image.network(p.imagenUrl!, fit: BoxFit.contain,
                         errorBuilder: (context, error, stackTrace) => const Icon(Icons.fastfood, size: 32, color: Colors.grey),
                       ),
                     ),
                   )
                else
                   const Icon(Icons.fastfood, size: 32, color: Colors.grey),
                
                const SizedBox(height: 8),
                Text(p.nombre, textAlign: TextAlign.center, style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14)),
                const SizedBox(height: 4),
                Text('\$${p.precio.toStringAsFixed(2)}', style: GoogleFonts.inter(color: Colors.green.shade700, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildNumpad() {
    final keys = ['1','2','3','4','5','6','7','8','9','0','C'];
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blueAccent.shade100)
            ),
            child: Text(
              'Cant: $_cantidadSeleccionada',
              style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blueAccent),
            ),
          ),
          ...keys.map((k) {
            return InkWell(
              onTap: () => _onNumpadTap(k),
              child: Container(
                width: 48,
                height: 48,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: k == 'C' ? Colors.redAccent.shade100 : Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Text(k, style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.bold)),
              ),
            );
          }),
        ],
      ),
    );
  }

  Color _getColorForCuenta(int cuentaId) {
    final colors = [
      Colors.blueAccent,
      Colors.green,
      Colors.purple,
      Colors.orange,
      Colors.teal,
      Colors.redAccent
    ];
    return colors[(cuentaId - 1) % colors.length];
  }

  Widget _buildTabsClientes() {
    List<Widget> tabs = [];
    int? lastCuentaId;

    for (int i = 0; i < _comanda.clientes.length; i++) {
      final cliente = _comanda.clientes[i];

      if (lastCuentaId != null && lastCuentaId != cliente.cuentaId) {
        tabs.add(const Padding(
          padding: EdgeInsets.symmetric(vertical: 8.0),
          child: VerticalDivider(width: 20, thickness: 2, color: Colors.grey),
        ));
      }
      lastCuentaId = cliente.cuentaId;

      final isActive = _comanda.clienteActivoIndex == i;
      final colorCuenta = _getColorForCuenta(cliente.cuentaId);

      tabs.add(
        InkWell(
          onTap: () => _cambiarCliente(i),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: isActive ? colorCuenta : Colors.transparent,
                  width: 3
                )
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  cliente.nombre,
                  style: GoogleFonts.inter(
                    fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                    color: isActive ? colorCuenta : Colors.black54,
                  ),
                ),
                if (isActive)
                  IconButton(
                    icon: const Icon(Icons.close, size: 18, color: Colors.redAccent),
                    onPressed: () => _eliminarCliente(i),
                    padding: const EdgeInsets.only(left: 4),
                    constraints: const BoxConstraints(),
                  ),
              ],
            ),
          ),
        )
      );
    }

    tabs.add(
      IconButton(
        icon: const Icon(Icons.person_add, color: Colors.blueAccent),
        onPressed: () => _agregarCliente(),
        tooltip: 'Agregar Cliente en cuenta actual',
      )
    );

    tabs.add(
      TextButton.icon(
        icon: const Icon(Icons.add_circle_outline, color: Colors.green),
        label: Text('Nueva Cuenta', style: GoogleFonts.inter(color: Colors.green, fontWeight: FontWeight.bold)),
        onPressed: () {
          final maxCuentaId = _comanda.clientes.fold<int>(0, (max, c) => c.cuentaId > max ? c.cuentaId : max);
          _agregarCliente(cuentaId: maxCuentaId + 1);
        },
      )
    );

    return Container(
      height: 50,
      color: Colors.white,
      child: ScrollConfiguration(
        behavior: ScrollConfiguration.of(context).copyWith(
          dragDevices: {
            PointerDeviceKind.touch,
            PointerDeviceKind.mouse,
          },
        ),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: tabs,
          ),
        ),
      ),
    );
  }

  Widget _buildListaItems() {
    final cliente = _comanda.clienteActivo;
    if (cliente.items.isEmpty) {
      return Center(
        child: Text('Sin ítems aún', style: GoogleFonts.inter(color: Colors.grey)),
      );
    }
    return ListView.builder(
      itemCount: cliente.items.length,
      itemBuilder: (context, index) {
        final item = cliente.items[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: ListTile(
            title: Text(item.producto, style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('\$${item.precioUnitarioFinal.toStringAsFixed(2)} x ${item.cantidad} = \$${item.total.toStringAsFixed(2)}', style: GoogleFonts.inter(color: Colors.green.shade700)),
                if (item.notas.isNotEmpty)
                  ...item.notas.map((n) => Text(n.precioExtra > 0 ? 'Nota: ${n.texto} (+\$${n.precioExtra.toStringAsFixed(2)})' : 'Nota: ${n.texto}', style: GoogleFonts.inter(color: Colors.grey.shade600, fontStyle: FontStyle.italic))),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit_note, color: Colors.blueGrey),
                  tooltip: 'Agregar nota',
                  onPressed: () => _mostrarModalNotas(item),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  tooltip: 'Eliminar platillo',
                  onPressed: () {
                    setState(() {
                      cliente.items.removeAt(index);
                    });
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.remove_circle_outline, color: Colors.orange),
                  onPressed: () {
                    setState(() {
                      if (item.cantidad > 1) {
                        item.cantidad--;
                      } else {
                        cliente.items.removeAt(index);
                      }
                    });
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline, color: Colors.blueAccent),
                  onPressed: () {
                    setState(() => item.cantidad++);
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.move_up, color: Colors.deepPurple),
                  tooltip: 'Mover a otro cliente',
                  onPressed: () => _mostrarModalMoverItem(item, _comanda.clienteActivoIndex),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildResumenTotal() {
    final cliente = _comanda.clienteActivo;
    
    // Contamos solo los items isNew para deshabilitar boton de enviar a cocina
    final int nuevosItemsCount = _comanda.clientes.fold(0, (sum, c) => sum + c.items.where((i) => i.isNew).length);
    final int totalItems = _comanda.clientes.fold(0, (sum, c) => sum + c.items.length);
    
    final bool canEnviarCocina = nuevosItemsCount > 0;
    // Permitimos cobrar si hay items en pantalla, o si hay un total anterior, o si es mesa real (podría haber consumo histórico)
    final bool canCobrar = totalItems > 0 || _totalAnterior > 0 || widget.mesaId != 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, -2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Subtotal ${cliente.nombre}:', style: GoogleFonts.inter(fontSize: 16)),
              Text('\$${cliente.subtotal.toStringAsFixed(2)}', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
          const Divider(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('TOTAL MESA:', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold)),
              Text('\$${(_totalAnterior + _comanda.totalGeneral).toStringAsFixed(2)}', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blueAccent)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: (!canEnviarCocina || _isEnviando) ? null : () async {
                    setState(() => _isEnviando = true);
                    
                    try {
                      await _comandasRepository.crearComanda(_comanda);
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Comanda registrada e impresa con éxito.', style: GoogleFonts.inter(color: Colors.white)), backgroundColor: Colors.green),
                        );
                        Navigator.popUntil(context, (route) => route.isFirst);
                      }
                    } catch (e) {
                      await _colaImpresionService.encolarComanda(_comanda);
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Error de red. Comanda guardada localmente y encolada para envío.', style: GoogleFonts.inter(color: Colors.white)), backgroundColor: Colors.orange),
                        );
                        Navigator.popUntil(context, (route) => route.isFirst);
                      }
                    } finally {
                      if (mounted) {
                        setState(() => _isEnviando = false);
                      }
                    }
                  },
                  icon: _isEnviando 
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
                      : const Icon(Icons.print),
                  label: Text(_isEnviando ? 'Enviando...' : 'Cocina', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: !canCobrar ? null : () async {
                    ComandaMesa comandaFinal = _comanda;

                    // Si es mesa real y no hay items, O incluso si hay items, queremos traer el historial
                    // para hacer merge, pero si la app lo manda a cocina primero, debería guardar? 
                    // El usuario dijo "el botón 'Cobrar' debe cargar y consolidar el historial acumulado".
                    // Si ya se enviaron ítems antes, se cargan. Si hay ítems locales sin mandar a cocina, ¿se pierden? 
                    // No, los locales se envían a cobrar directamente.
                    
                    if (widget.mesaId != 0) {
                      // Mostramos spinner
                      showDialog(context: context, barrierDismissible: false, builder: (_) => const Center(child: CircularProgressIndicator()));
                      final historial = await _comandasRepository.obtenerComandaActivaPorMesa(widget.mesaId);
                      if (mounted) Navigator.pop(context); // cerrar spinner

                      if (historial != null) {
                        // Consolidar (merge)
                        for (var c in _comanda.clientes) {
                          if (c.items.isNotEmpty) {
                            historial.clientes.add(c);
                          }
                        }
                        comandaFinal = historial;
                      } else if (totalItems == 0) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('No hay consumos en esta mesa para cobrar.', style: GoogleFonts.inter()), backgroundColor: Colors.orange));
                        }
                        return;
                      }
                    }

                    if (mounted) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CobrarComandaScreen(comanda: comandaFinal),
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.credit_card),
                  label: Text('Cobrar', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Colors.blueAccent,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
