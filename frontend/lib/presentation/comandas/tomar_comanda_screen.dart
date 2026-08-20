import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'dart:ui';
import '../../data/models/comanda_model.dart';
import '../../data/models/categoria_model.dart';
import '../../data/models/producto_model.dart';
import '../../data/repositories/productos_repository.dart';
import '../../data/repositories/comandas_repository.dart';
import '../../core/services/cola_impresion_service.dart';
import '../../data/repositories/admin_repository.dart';
import '../../data/models/admin_models.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/app_animations.dart';
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
  final PageController _pageController = PageController();
  int _pageIndex = 0;
  final ScrollController _categoriasScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    if (widget.comandaPreexistente != null) {
      _totalAnterior = widget.comandaPreexistente!.totalApi;
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

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _cargarNotasRapidas() async {
    try {
      final notas = await _adminRepo.obtenerNotasRapidas();
      setState(() => _notasRapidas = notas);
    } catch (_) {}
  }

  Future<void> _cargarCatalogo() async {
    setState(() { _cargandoCatalogo = true; _errorCatalogo = null; });
    try {
      final results = await Future.wait([
        _productosRepository.getCategorias(),
        _productosRepository.getProductos(),
      ]);
      setState(() {
        _categorias = results[0] as List<Categoria>;
        _productos = (results[1] as List<Producto>).where((p) => p.disponible).toList();
        _cargandoCatalogo = false;
        if (_categorias.isNotEmpty) _categoriaSeleccionada = _categorias.first.id;
      });
    } catch (e) {
      setState(() { _errorCatalogo = e.toString(); _cargandoCatalogo = false; });
    }
  }

  String _generateId() => DateTime.now().millisecondsSinceEpoch.toString();

  void _onNumpadTap(String value) {
    setState(() {
      if (value == 'C') {
        _cantidadSeleccionada = 1;
      } else {
        if (_cantidadSeleccionada == 1) {
          _cantidadSeleccionada = value == '0' ? 10 : (int.tryParse(value) ?? 1);
        } else {
          _cantidadSeleccionada = int.tryParse('$_cantidadSeleccionada$value') ?? 1;
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
        cliente.items.add(ItemComanda(
          id: _generateId(), productoId: producto.id,
          producto: producto.nombre, cantidad: _cantidadSeleccionada, precioUnitario: producto.precio,
        ));
      }
      _cantidadSeleccionada = 1;
    });
    if (_pageController.hasClients && _pageIndex == 0) {
      Future.delayed(const Duration(milliseconds: 150), () {
        if (mounted) _pageController.animateToPage(1, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
      });
    }
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
        title: const Text('Eliminar cliente'),
        content: Text('Eliminar a ${cliente.nombre}${cliente.items.isNotEmpty ? ' y todos sus platillos' : ''}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
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
            child: Text('Eliminar', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _cambiarCliente(int index) => setState(() => _comanda.clienteActivoIndex = index);

  void _mostrarModalMoverItem(ItemComanda item, int clienteOrigenIndex) {
    if (_comanda.clientes.length <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Crea otro cliente para mover items')));
      return;
    }
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Mover "${item.producto}"'),
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
                title: Text(clienteDestino.nombre),
                onTap: () {
                  setState(() {
                    _comanda.clientes[clienteOrigenIndex].items.remove(item);
                    final existingIndex = clienteDestino.items.indexWhere(
                      (i) => i.producto == item.producto && i.precioUnitario == item.precioUnitario && i.notasString == item.notasString);
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
      ),
    );
  }

  void _mostrarModalNotas(ItemComanda item) {
    List<NotaAplicada> currentNotes = List.from(item.notas);
    final TextEditingController notasController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setStateModal) => AlertDialog(
          title: Text('Notas para "${item.producto}"'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_notasRapidas.isNotEmpty)
                  Wrap(
                    spacing: 8, runSpacing: 4,
                    children: _notasRapidas.map((nota) {
                      final label = nota.precioExtra > 0 ? '${nota.texto} (+\$${nota.precioExtra.toStringAsFixed(2)})' : nota.texto;
                      return ActionChip(label: Text(label), onPressed: () {
                        setStateModal(() {
                          if (!currentNotes.any((n) => n.texto == nota.texto)) {
                            currentNotes.add(NotaAplicada(nota.texto, nota.precioExtra));
                          }
                        });
                      });
                    }).toList(),
                  ),
                const Divider(),
                if (currentNotes.isNotEmpty)
                  Wrap(
                    spacing: 8,
                    children: currentNotes.map((nota) {
                      final label = nota.precioExtra > 0 ? '${nota.texto} (+\$${nota.precioExtra.toStringAsFixed(2)})' : nota.texto;
                      return InputChip(label: Text(label), deleteIcon: const Icon(Icons.close, size: 16),
                          onDeleted: () => setStateModal(() => currentNotes.remove(nota)));
                    }).toList(),
                  ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: notasController,
                        decoration: const InputDecoration(hintText: 'Otra nota...', isDense: true),
                        onSubmitted: (val) {
                          if (val.trim().isNotEmpty) setStateModal(() { currentNotes.add(NotaAplicada(val.trim(), 0.0)); notasController.clear(); });
                        },
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add_circle, color: AppColors.accent),
                      onPressed: () {
                        if (notasController.text.trim().isNotEmpty) {
                          setStateModal(() { currentNotes.add(NotaAplicada(notasController.text.trim(), 0.0)); notasController.clear(); });
                        }
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
            ElevatedButton(
              onPressed: () { setState(() => item.notas = currentNotes); Navigator.pop(ctx); },
              child: const Text('Guardar'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final titleText = widget.tipoOrden == 'PARA_LLEVAR'
        ? 'Para Llevar: ${widget.nombreCliente ?? ''}'
        : 'Mesa ${widget.mesaNumero}';

    if (_cargandoCatalogo) {
      return Scaffold(
        appBar: AppBar(title: Text(titleText), backgroundColor: AppColors.accent),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    if (_errorCatalogo != null) {
      return Scaffold(
        appBar: AppBar(title: Text(titleText), backgroundColor: AppColors.accent),
        body: EmptyStateWidget(
          icon: Icons.error_outline, title: 'Error al cargar el catalogo', subtitle: _errorCatalogo,
          action: ElevatedButton.icon(onPressed: _cargarCatalogo, icon: const Icon(Icons.refresh), label: const Text('Reintentar')),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(titleText), backgroundColor: AppColors.accent, foregroundColor: AppColors.textOnDark),
      body: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < AppBreakpoints.mobile) return _buildMobileLayout();
          return _buildDesktopLayout();
        },
      ),
    );
  }

  Widget _buildMobileLayout() {
    return Column(
      children: [
        _buildMobileTabBar(),
        Expanded(
          child: PageView(
            controller: _pageController,
            onPageChanged: (i) => setState(() => _pageIndex = i),
            children: [
              Column(children: [_buildCategorias(), Expanded(child: _buildProductosGrid()), _buildNumpad()]),
              Container(color: AppColors.surfacePanel, child: Column(children: [_buildTabsClientes(), Expanded(child: _buildListaItems()), _buildResumenTotal()])),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMobileTabBar() {
    return Container(
      color: AppColors.primary,
      child: Row(
        children: [
          Expanded(child: GestureDetector(
            onTap: () { _pageController.animateToPage(0, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut); setState(() => _pageIndex = 0); },
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(border: Border(bottom: BorderSide(color: _pageIndex == 0 ? AppColors.accent : Colors.transparent, width: 3))),
              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(Icons.menu_book, size: 18, color: _pageIndex == 0 ? AppColors.accent : Colors.white70),
                const SizedBox(width: 6),
                Text('Catalogo', style: AppTextStyles.labelMedium.copyWith(color: _pageIndex == 0 ? AppColors.accent : Colors.white70)),
              ]),
            ),
          )),
          Expanded(child: GestureDetector(
            onTap: () { _pageController.animateToPage(1, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut); setState(() => _pageIndex = 1); },
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(border: Border(bottom: BorderSide(color: _pageIndex == 1 ? AppColors.accent : Colors.transparent, width: 3))),
              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(Icons.receipt_long, size: 18, color: _pageIndex == 1 ? AppColors.accent : Colors.white70),
                const SizedBox(width: 6),
                Text('Comanda', style: AppTextStyles.labelMedium.copyWith(color: _pageIndex == 1 ? AppColors.accent : Colors.white70)),
                if (_comanda.totalGeneral > 0)
                  Container(
                    margin: const EdgeInsets.only(left: 6), padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(color: AppColors.accent, borderRadius: AppRadius.chipRadius),
                    child: Text('\$${_comanda.totalGeneral.toStringAsFixed(0)}', style: AppTextStyles.labelSmall.copyWith(color: Colors.white)),
                  ),
              ]),
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildDesktopLayout() {
    return Row(
      children: [
        Expanded(flex: 6, child: Column(children: [_buildCategorias(), Expanded(child: _buildProductosGrid()), _buildNumpad()])),
        const VerticalDivider(width: 1, thickness: 1),
        Expanded(flex: 4, child: Container(color: AppColors.surfacePanel,
          child: Column(children: [_buildTabsClientes(), Expanded(child: _buildListaItems()), _buildResumenTotal()]))),
      ],
    );
  }

  Widget _buildCategorias() {
    return Container(
      height: 56, padding: const EdgeInsets.symmetric(horizontal: 8), color: AppColors.surfaceCard,
      child: Listener(
        onPointerSignal: (pointerSignal) {
          if (pointerSignal is PointerScrollEvent) {
            final offset = _categoriasScrollController.offset + pointerSignal.scrollDelta.dy;
            _categoriasScrollController.jumpTo(
              offset.clamp(0.0, _categoriasScrollController.position.maxScrollExtent),
            );
          }
        },
        child: ListView.builder(
          controller: _categoriasScrollController,
          scrollDirection: Axis.horizontal, itemCount: _categorias.length,
          itemBuilder: (context, index) {
            final cat = _categorias[index];
            final isSelected = cat.id == _categoriaSeleccionada;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
              child: ChoiceChip(
                label: Text(cat.nombre, style: AppTextStyles.labelMedium.copyWith(
                    color: isSelected ? AppColors.textOnDark : AppColors.textPrimary, fontWeight: FontWeight.w600)),
                selected: isSelected, selectedColor: AppColors.primary,
                onSelected: (_) => setState(() => _categoriaSeleccionada = cat.id),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildProductosGrid() {
    final productosFiltrados = _productos.where((p) => p.categoriaId == _categoriaSeleccionada).toList();
    if (productosFiltrados.isEmpty) return EmptyStateWidget(icon: Icons.no_food, title: 'Sin productos');
    return LayoutBuilder(
      builder: (context, constraints) {
        final cols = constraints.maxWidth < 380 ? 2 : 3;
        return GridView.builder(
          padding: const EdgeInsets.all(10),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: cols, crossAxisSpacing: 10, mainAxisSpacing: 10, childAspectRatio: 1.0),
          itemCount: productosFiltrados.length,
          itemBuilder: (context, index) {
            final p = productosFiltrados[index];
            return PressAnimated(
              onTap: () => _agregarProducto(p),
              borderRadius: AppRadius.cardRadius,
              child: Container(
                decoration: BoxDecoration(color: AppColors.surfaceCard, borderRadius: AppRadius.cardRadius,
                  border: const Border.fromBorderSide(BorderSide(color: AppColors.border)), boxShadow: AppShadows.card),
                child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  if (p.imagenUrl != null && p.imagenUrl!.isNotEmpty)
                    Expanded(child: Padding(padding: const EdgeInsets.all(8),
                      child: Image.network(p.imagenUrl!, fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => const Icon(Icons.fastfood, size: 28, color: AppColors.textMuted))))
                  else
                    const Icon(Icons.fastfood, size: 28, color: AppColors.textMuted),
                  const SizedBox(height: 4),
                  Padding(padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: Text(p.nombre, textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.labelMedium.copyWith(fontWeight: FontWeight.w600))),
                  Text('\$${p.precio.toStringAsFixed(2)}', style: AppTextStyles.priceSmall),
                  const SizedBox(height: 4),
                ]),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildNumpad() {
    final keys = ['1','2','3','4','5','6','7','8','9','0','C'];
    return Container(
      color: AppColors.surfaceCard, padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(color: AppColors.infoLight, borderRadius: AppRadius.buttonRadius,
            border: const Border.fromBorderSide(BorderSide(color: AppColors.info, width: 1.5))),
          child: Text('x$_cantidadSeleccionada', style: AppTextStyles.headingSmall.copyWith(color: AppColors.info)),
        ),
        ...keys.map((k) => GestureDetector(
          onTap: () => _onNumpadTap(k),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 80), width: 42, height: 42, alignment: Alignment.center,
            decoration: BoxDecoration(
              color: k == 'C' ? AppColors.errorLight : AppColors.surfacePanel,
              borderRadius: const BorderRadius.all(Radius.circular(21)),
              border: Border.fromBorderSide(BorderSide(color: k == 'C' ? AppColors.error.withOpacity(0.3) : AppColors.border)),
            ),
            child: Text(k, style: AppTextStyles.labelLarge.copyWith(color: k == 'C' ? AppColors.error : AppColors.textPrimary)),
          ),
        )),
      ]),
    );
  }

  Color _getColorForCuenta(int cuentaId) {
    const colors = [AppColors.info, AppColors.success, AppColors.mesaUnida, AppColors.warning, AppColors.mesaOcupada];
    return colors[(cuentaId - 1) % colors.length];
  }

  Widget _buildTabsClientes() {
    List<Widget> tabs = [];
    int? lastCuentaId;
    for (int i = 0; i < _comanda.clientes.length; i++) {
      final cliente = _comanda.clientes[i];
      if (lastCuentaId != null && lastCuentaId != cliente.cuentaId) {
        tabs.add(const Padding(padding: EdgeInsets.symmetric(vertical: 8),
          child: VerticalDivider(width: 20, thickness: 2, color: AppColors.border)));
      }
      lastCuentaId = cliente.cuentaId;
      final isActive = _comanda.clienteActivoIndex == i;
      final colorCuenta = _getColorForCuenta(cliente.cuentaId);
      tabs.add(GestureDetector(
        onTap: () => _cambiarCliente(i),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(border: Border(bottom: BorderSide(color: isActive ? colorCuenta : Colors.transparent, width: 3))),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Text(cliente.nombre, style: AppTextStyles.labelMedium.copyWith(
                fontWeight: isActive ? FontWeight.w700 : FontWeight.normal,
                color: isActive ? colorCuenta : AppColors.textSecondary)),
            if (isActive) Padding(padding: const EdgeInsets.only(left: 4),
              child: GestureDetector(onTap: () => _eliminarCliente(i),
                child: const Icon(Icons.close, size: 16, color: AppColors.error))),
          ]),
        ),
      ));
    }
    tabs.add(IconButton(icon: const Icon(Icons.person_add, color: AppColors.info, size: 20),
      onPressed: _agregarCliente, tooltip: 'Agregar cliente',
      padding: const EdgeInsets.symmetric(horizontal: 8), constraints: const BoxConstraints()));
    tabs.add(TextButton.icon(
      icon: const Icon(Icons.add_circle_outline, color: AppColors.success, size: 18),
      label: Text('Nueva Cuenta', style: AppTextStyles.labelMedium.copyWith(color: AppColors.success, fontWeight: FontWeight.w700)),
      onPressed: () {
        final maxCuentaId = _comanda.clientes.fold<int>(0, (max, c) => c.cuentaId > max ? c.cuentaId : max);
        _agregarCliente(cuentaId: maxCuentaId + 1);
      },
      style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 8)),
    ));
    return Container(
      height: 48, color: AppColors.surfaceCard,
      child: ScrollConfiguration(
        behavior: ScrollConfiguration.of(context).copyWith(dragDevices: {PointerDeviceKind.touch, PointerDeviceKind.mouse}),
        child: SingleChildScrollView(scrollDirection: Axis.horizontal, physics: const BouncingScrollPhysics(),
          child: Row(mainAxisSize: MainAxisSize.min, children: tabs)),
      ),
    );
  }

  Widget _buildListaItems() {
    final cliente = _comanda.clienteActivo;
    if (cliente.items.isEmpty) {
      return EmptyStateWidget(icon: Icons.receipt_long_outlined, title: 'Sin platillos aun',
        subtitle: 'Toca un producto para agregar');
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 4),
      itemCount: cliente.items.length,
      itemBuilder: (context, index) {
        final item = cliente.items[index];
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(children: [
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(item.producto, style: AppTextStyles.labelLarge),
                  Text('\$${item.precioUnitario.toStringAsFixed(2)} x ${item.cantidad} = \$${item.total.toStringAsFixed(2)}',
                    style: AppTextStyles.priceSmall),
                  if (item.notas.isNotEmpty)
                    ...item.notas.map((n) => Text(
                      n.precioExtra > 0 ? '+ ${n.texto} (+\$${n.precioExtra.toStringAsFixed(2)})' : '+ ${n.texto}',
                      style: AppTextStyles.bodySmall.copyWith(fontStyle: FontStyle.italic))),
                ])),
                Row(mainAxisSize: MainAxisSize.min, children: [
                  _iconBtn(Icons.edit_note, AppColors.info, () => _mostrarModalNotas(item)),
                  _iconBtn(Icons.remove, AppColors.warning, () => setState(() { if (item.cantidad > 1) item.cantidad--; else cliente.items.removeAt(index); })),
                  Padding(padding: const EdgeInsets.symmetric(horizontal: 4), child: Text('${item.cantidad}', style: AppTextStyles.headingSmall)),
                  _iconBtn(Icons.add, AppColors.success, () => setState(() => item.cantidad++)),
                  _iconBtn(Icons.delete_outline, AppColors.error, () => setState(() => cliente.items.removeAt(index))),
                  _iconBtn(Icons.swap_horiz, AppColors.mesaUnida, () => _mostrarModalMoverItem(item, _comanda.clienteActivoIndex)),
                ]),
              ]),
            ),
          ),
        );
      },
    );
  }

  Widget _iconBtn(IconData icon, Color color, VoidCallback onTap) {
    return IconButton(icon: Icon(icon, size: 18, color: color), onPressed: onTap, padding: const EdgeInsets.all(4), constraints: const BoxConstraints());
  }

  Widget _buildResumenTotal() {
    final cliente = _comanda.clienteActivo;
    final int nuevosItemsCount = _comanda.clientes.fold(0, (sum, c) => sum + c.items.where((i) => i.isNew).length);
    final int totalItems = _comanda.clientes.fold(0, (sum, c) => sum + c.items.length);
    final bool canEnviarCocina = nuevosItemsCount > 0;
    final bool canCobrar = totalItems > 0 || _totalAnterior > 0 || widget.mesaId != 0;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: const BoxDecoration(color: AppColors.surfaceCard, boxShadow: AppShadows.bottomBar),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('Subtotal ${cliente.nombre}:', style: AppTextStyles.bodyMedium),
          Text('\$${cliente.subtotal.toStringAsFixed(2)}', style: AppTextStyles.labelLarge),
        ]),
        const SizedBox(height: 4),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('TOTAL MESA:', style: AppTextStyles.headingSmall),
          Text('\$${(_totalAnterior + _comanda.totalGeneral).toStringAsFixed(2)}', style: AppTextStyles.priceMedium),
        ]),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: (!canEnviarCocina || _isEnviando) ? null : () async {
                setState(() => _isEnviando = true);
                try {
                  await _comandasRepository.crearComanda(_comanda);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Comanda enviada a cocina.'), backgroundColor: AppColors.success));
                    Navigator.pop(context, true);
                  }
                } catch (e) {
                  final errorMsg = e.toString();
                  if (errorMsg.contains('CONNECTION_ERROR')) {
                    await _colaImpresionService.encolarComanda(_comanda);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sin conexion. Comanda guardada localmente.'), backgroundColor: AppColors.warning));
                      Navigator.pop(context, true);
                    }
                  } else {
                    if (mounted) {
                      final cleanError = errorMsg.replaceAll('Exception: SERVER_ERROR:', '').trim();
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(cleanError), backgroundColor: AppColors.error));
                    }
                  }
                } finally {
                  if (mounted) setState(() => _isEnviando = false);
                }
              },
              icon: _isEnviando
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.send),
              label: Text(_isEnviando ? 'Enviando...' : 'A Cocina'),
              style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14), backgroundColor: AppColors.warning, foregroundColor: AppColors.textOnDark),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: !canCobrar ? null : () async {
                ComandaMesa comandaFinal = _comanda;
                if (widget.mesaId != 0) {
                  showDialog(context: context, barrierDismissible: false, builder: (_) => const Center(child: CircularProgressIndicator()));
                  final historial = await _comandasRepository.obtenerComandaActivaPorMesa(widget.mesaId);
                  if (mounted) Navigator.pop(context);
                  if (historial != null) {
                    for (var c in _comanda.clientes) { if (c.items.isNotEmpty) historial.clientes.add(c); }
                    comandaFinal = historial;
                  } else if (totalItems == 0) {
                    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No hay consumos en esta mesa.'), backgroundColor: AppColors.warning));
                    return;
                  }
                }
                if (mounted) Navigator.push(context, FadeSlidePageRoute(page: CobrarComandaScreen(comanda: comandaFinal)));
              },
              icon: const Icon(Icons.payment),
              label: const Text('Cobrar'),
              style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14), backgroundColor: AppColors.primary, foregroundColor: AppColors.textOnDark),
            ),
          ),
        ]),
      ]),
    );
  }
}

