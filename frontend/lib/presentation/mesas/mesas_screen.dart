import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/models/mesa_model.dart';
import '../../data/models/comanda_model.dart';
import '../../data/repositories/mesas_repository.dart';
import '../../data/repositories/comandas_repository.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/app_animations.dart';
import '../comandas/tomar_comanda_screen.dart';
import '../comandas/cobrar_comanda_screen.dart';
import '../auth/login_screen.dart';

class MesasScreen extends StatefulWidget {
  const MesasScreen({super.key});

  @override
  State<MesasScreen> createState() => _MesasScreenState();
}

class _MesasScreenState extends State<MesasScreen> with SingleTickerProviderStateMixin {
  final MesasRepository _mesasRepository = MesasRepository();
  final ComandasRepository _comandasRepository = ComandasRepository();
  List<Mesa> _mesas = [];
  List<ComandaMesa> _comandasParaLlevar = [];
  Map<int, double> _totalesMesasOcupadas = {};
  bool _isLoading = true;
  String? _errorMessage;
  int _minMesas = 1;
  int _maxMesas = 50;

  bool _modoJuntarActivo = false;
  int? _mesaSeleccionadaId;

  Timer? _pollingTimer;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() => setState(() {}));
    _cargarConfiguracion();
    _cargarMesas();
    _pollingTimer = Timer.periodic(const Duration(seconds: 5), (_) => _cargarMesas(silencioso: true));
  }

  @override
  void dispose() {
    _tabController.dispose();
    _pollingTimer?.cancel();
    super.dispose();
  }

  Future<void> _cargarConfiguracion() async {
    try {
      final config = await _mesasRepository.obtenerConfiguracion();
      if (mounted) {
        setState(() {
          _minMesas = int.tryParse(config['min_mesas']?.toString() ?? '1') ?? 1;
          _maxMesas = int.tryParse(config['max_mesas']?.toString() ?? '50') ?? 50;
        });
      }
    } catch (_) {
      // Fallback a valores por defecto
    }
  }

  Future<void> _cargarMesas({bool silencioso = false}) async {
    if (!silencioso) setState(() { _isLoading = true; _errorMessage = null; });
    try {
      final results = await Future.wait([
        _mesasRepository.obtenerMesas(),
        _comandasRepository.obtenerComandasParaLlevar(),
        _comandasRepository.obtenerTotalesMesasOcupadas(),
      ]);
      if (mounted) {
        setState(() {
          _mesas = results[0] as List<Mesa>;
          _comandasParaLlevar = results[1] as List<ComandaMesa>;
          _totalesMesasOcupadas = results[2] as Map<int, double>;
          if (!silencioso) _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        if (!silencioso) setState(() { _errorMessage = e.toString(); _isLoading = false; });
        if (!silencioso) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al cargar mesas: $e')));
        }
      }
    }
  }

  void _cerrarSesion() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        FadeSlidePageRoute(page: const LoginScreen()),
        (route) => false,
      );
    }
  }

  void _toggleModoJuntar() {
    setState(() { _modoJuntarActivo = !_modoJuntarActivo; _mesaSeleccionadaId = null; });
  }

  Future<void> _onMesaTap(Mesa mesa) async {
    if (_modoJuntarActivo) {
      if (_mesaSeleccionadaId == null) {
        setState(() => _mesaSeleccionadaId = mesa.id);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Mesa ${mesa.numero} seleccionada. Toca la mesa a fusionar.'),
          backgroundColor: AppColors.info,
          duration: const Duration(seconds: 3),
        ));
      } else {
        if (_mesaSeleccionadaId == mesa.id) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Selecciona una mesa diferente.'),
            backgroundColor: AppColors.warning,
            duration: Duration(seconds: 2),
          ));
          return;
        }
        await _juntarMesas(mesa.id, _mesaSeleccionadaId!);
      }
    } else {
      final bool estaOcupada = mesa.estado.toLowerCase() != 'libre';
      ComandaMesa? comandaExistente;
      if (estaOcupada) {
        showDialog(context: context, barrierDismissible: false, builder: (_) => const Center(child: CircularProgressIndicator()));
        comandaExistente = await _comandasRepository.obtenerComandaActivaPorMesa(mesa.id);
        if (mounted) Navigator.pop(context);
      }
      if (mounted) {
        final result = await Navigator.push(context, FadeSlidePageRoute(
          page: TomarComandaScreen(
            mesaId: mesa.id,
            mesaNumero: mesa.numero.toString(),
            comandaPreexistente: comandaExistente,
          ),
        ));
        if (result == true && mounted) {
          _cargarMesas();
        }
      }
    }
  }

  Future<void> _juntarMesas(int mesaHijaId, int mesaPadreId) async {
    try {
      await _mesasRepository.juntarMesas(mesaHijaId, mesaPadreId);
      await _cargarMesas();
      setState(() => _mesaSeleccionadaId = null);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Mesa unida al grupo.'),
          backgroundColor: AppColors.success,
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error al fusionar: $e'),
          backgroundColor: AppColors.error,
        ));
      }
    }
  }

  Future<void> _separarMesa(int mesaId) async {
    try {
      await _mesasRepository.separarMesa(mesaId);
      await _cargarMesas();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Mesa separada exitosamente'),
          backgroundColor: AppColors.success,
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error al separar: $e'),
          backgroundColor: AppColors.error,
        ));
      }
    }
  }

  Future<void> _crearMesa() async {
    try {
      await _mesasRepository.crearMesa();
      await _cargarMesas(silencioso: true);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Mesa agregada'),
          backgroundColor: AppColors.success,
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error al crear: $e'),
          backgroundColor: AppColors.error,
        ));
      }
    }
  }

  Future<void> _eliminarUltimaMesa() async {
    try {
      await _mesasRepository.eliminarUltimaMesa();
      await _cargarMesas(silencioso: true);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Mesa eliminada'),
          backgroundColor: AppColors.warning,
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: AppColors.error,
        ));
      }
    }
  }

  void _irParaLlevar() {
    final TextEditingController controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Pedido Para Llevar'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'Nombre del cliente'),
          textCapitalization: TextCapitalization.words,
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () async {
              final nombre = controller.text.trim();
              if (nombre.isEmpty) return;
              Navigator.pop(ctx);
              final result = await Navigator.push(context, FadeSlidePageRoute(
                page: TomarComandaScreen(
                  mesaId: 0,
                  mesaNumero: 'Para Llevar',
                  nombreCliente: nombre,
                  tipoOrden: 'PARA_LLEVAR',
                ),
              ));
              if (result == true && mounted) _cargarMesas();
            },
            child: const Text('Crear Orden'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Pedidos y Mesas'),
          actions: [
            IconButton(
              icon: const Icon(Icons.add_shopping_cart),
              tooltip: 'Nuevo Para Llevar',
              onPressed: _irParaLlevar,
            ),
            IconButton(
              icon: Icon(
                Icons.link,
                color: _modoJuntarActivo ? AppColors.accent : null,
              ),
              tooltip: 'Modo Fusion de Mesas',
              onPressed: _toggleModoJuntar,
            ),
            IconButton(icon: const Icon(Icons.refresh), onPressed: _cargarMesas),
            IconButton(icon: const Icon(Icons.logout), onPressed: _cerrarSesion),
          ],
          bottom: TabBar(
            controller: _tabController,
            tabs: const [
              Tab(icon: Icon(Icons.table_restaurant), text: 'Mesas'),
              Tab(icon: Icon(Icons.shopping_bag), text: 'Para Llevar'),
            ],
          ),
        ),
        body: _isLoading
            ? _buildSkeletonLoader()
            : _errorMessage != null
                ? _buildErrorView()
                : TabBarView(
                    controller: _tabController,
                    children: [
                      Column(children: [
                        if (_modoJuntarActivo) _buildModoJuntarBanner(),
                        Expanded(child: _buildGridView()),
                      ]),
                      _buildParaLlevarView(),
                    ],
                  ),
        floatingActionButton: _tabController.index == 0
            ? _buildMesasFAB()
            : FloatingActionButton.extended(
                heroTag: 'btnParaLlevarFAB',
                onPressed: _irParaLlevar,
                icon: const Icon(Icons.add),
                label: const Text('Nuevo Para Llevar'),
              ),
      ),
    );
  }

  Widget _buildModoJuntarBanner() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: double.infinity,
      color: AppColors.warning.withOpacity(0.15),
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      child: Row(
        children: [
          const Icon(Icons.link, color: AppColors.warning, size: 20),
          const SizedBox(width: 8),
          Text(
            _mesaSeleccionadaId == null
                ? 'Modo Fusion: Toca la primera mesa'
                : 'Modo Fusion: Toca la mesa a unir',
            style: AppTextStyles.labelMedium.copyWith(color: AppColors.warning, fontWeight: FontWeight.w600),
          ),
          const Spacer(),
          GestureDetector(
            onTap: _toggleModoJuntar,
            child: const Icon(Icons.close, color: AppColors.warning, size: 18),
          ),
        ],
      ),
    );
  }

  Widget _buildGridView() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        int crossAxisCount;
        double childAspectRatio;

        if (width < AppBreakpoints.mobile) {
          crossAxisCount = 2;
          childAspectRatio = 1.15;
        } else if (width < AppBreakpoints.tablet) {
          crossAxisCount = 3;
          childAspectRatio = 1.2;
        } else {
          crossAxisCount = (width / 200).floor().clamp(4, 6);
          childAspectRatio = 1.1;
        }

        return Padding(
          padding: const EdgeInsets.all(12),
          child: GridView.builder(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: childAspectRatio,
            ),
            itemCount: _mesas.length,
            itemBuilder: (context, index) => _buildMesaCard(_mesas[index], index),
          ),
        );
      },
    );
  }

  Widget _buildMesaCard(Mesa mesa, int index) {
    final bool estaUnida = mesa.mesaPadreId != null || _mesas.any((m) => m.mesaPadreId == mesa.id);
    final bool estaLibre = mesa.estado.toLowerCase() == 'libre';
    final bool estaSeleccionada = _mesaSeleccionadaId == mesa.id;

    Color colorA, colorB;
    String textoEstado;
    IconData iconoEstado;

    if (estaSeleccionada) {
      colorA = AppColors.mesaSeleccionada;
      colorB = AppColors.mesaSeleccionada.withBlue(200);
      textoEstado = 'Seleccionada';
      iconoEstado = Icons.touch_app;
    } else if (estaUnida) {
      colorA = AppColors.mesaUnida;
      colorB = const Color(0xFF6C3483);
      
      final double totalIndiv = _totalesMesasOcupadas[mesa.id] ?? 0.0;
      final int grupoId = mesa.mesaPadreId ?? mesa.id;
      final double totalGrupo = _mesas.where((m) => m.id == grupoId || m.mesaPadreId == grupoId).fold(0.0, (sum, m) => sum + (_totalesMesasOcupadas[m.id] ?? 0.0));
      
      textoEstado = 'Grupo M${mesa.numeroPadre ?? mesa.numero}';
      textoEstado += '\n\$${totalIndiv.toStringAsFixed(2)}';
      if (totalGrupo != totalIndiv) {
        textoEstado += '\n(Tot: \$${totalGrupo.toStringAsFixed(2)})';
      }
      
      iconoEstado = Icons.link;
    } else if (estaLibre) {
      colorA = AppColors.mesaLibre;
      colorB = const Color(0xFF1E8449);
      textoEstado = 'Disponible';
      iconoEstado = Icons.check_circle_outline;
    } else {
      colorA = AppColors.mesaOcupada;
      colorB = const Color(0xFFC0392B);
      final double total = _totalesMesasOcupadas[mesa.id] ?? 0.0;
      textoEstado = '\$${total.toStringAsFixed(2)}';
      iconoEstado = Icons.restaurant;
    }

    return PressAnimated(
      onTap: () => _onMesaTap(mesa),
      borderRadius: AppRadius.cardRadius,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(
          borderRadius: AppRadius.cardRadius,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [colorA, colorB],
          ),
          boxShadow: estaSeleccionada
              ? [BoxShadow(color: colorA.withOpacity(0.5), blurRadius: 12, offset: const Offset(0, 4))]
              : AppShadows.card,
          border: estaSeleccionada
              ? Border.all(color: Colors.white, width: 2.5)
              : null,
        ),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(iconoEstado, color: Colors.white.withOpacity(0.9), size: 26),
                  const SizedBox(height: 8),
                  Text('Mesa ${index + 1}', style: AppTextStyles.mesaNumero),
                  const SizedBox(height: 4),
                  Text(
                    textoEstado,
                    textAlign: TextAlign.center,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.mesaEstado,
                  ),
                ],
              ),
            ),
            if (estaUnida)
              Positioned(
                top: 4, right: 4,
                child: IconButton(
                  icon: const Icon(Icons.link_off, color: Colors.white70, size: 18),
                  onPressed: () => _separarMesa(mesa.id),
                  tooltip: 'Separar mesa',
                  padding: const EdgeInsets.all(6),
                  constraints: const BoxConstraints(),
                ),
              ),
            if (!estaLibre && !estaSeleccionada)
              Positioned(
                bottom: 8, right: 8,
                child: GestureDetector(
                  onTap: () async {
                    showDialog(context: context, barrierDismissible: false, builder: (_) => const Center(child: CircularProgressIndicator()));
                    
                    ComandaMesa? comandaResult;
                    
                    if (estaUnida) {
                      final int grupoId = mesa.mesaPadreId ?? mesa.id;
                      final mesasDelGrupo = _mesas.where((m) => m.id == grupoId || m.mesaPadreId == grupoId).toList();
                      
                      List<String> idsBackend = [];
                      List<ClienteSubCuenta> clientesMerged = [];
                      double totalApiMerged = 0.0;
                      int itemsApiCountMerged = 0;
                      
                      for (var m in mesasDelGrupo) {
                        final c = await _comandasRepository.obtenerComandaActivaPorMesa(m.id);
                        if (c != null) {
                          if (c.idBackend != null) idsBackend.add(c.idBackend!);
                          
                          // Prefix client names with table number to distinguish them
                          for (var cli in c.clientes) {
                            if (cli.items.isNotEmpty) {
                              cli.nombre = 'M${m.numero} - ${cli.nombre}';
                              clientesMerged.add(cli);
                            }
                          }
                          totalApiMerged += c.totalApi;
                          itemsApiCountMerged += c.itemsApiCount;
                        }
                      }
                      
                      if (idsBackend.isNotEmpty) {
                        comandaResult = ComandaMesa(
                          mesaId: grupoId,
                          idBackend: idsBackend.first,
                          idsBackendGrupo: idsBackend,
                          clientes: clientesMerged,
                          totalApi: totalApiMerged,
                          itemsApiCount: itemsApiCountMerged,
                        );
                      }
                    } else {
                      comandaResult = await _comandasRepository.obtenerComandaActivaPorMesa(mesa.id);
                    }

                    if (mounted) {
                      Navigator.pop(context);
                      if (comandaResult != null) {
                        Navigator.push(context, FadeSlidePageRoute(page: CobrarComandaScreen(comanda: comandaResult)));
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                          content: Text('No hay historial en esta mesa'),
                          backgroundColor: AppColors.warning,
                        ));
                      }
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: AppRadius.chipRadius,
                      border: Border.all(color: Colors.white.withOpacity(0.5)),
                    ),
                    child: Text('Pagar',
                      style: AppTextStyles.labelSmall.copyWith(color: Colors.white, fontWeight: FontWeight.w700)),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMesasFAB() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            FloatingActionButton(
              heroTag: 'btnCrearMesa',
              onPressed: _mesas.length >= _maxMesas ? null : _crearMesa,
              backgroundColor: _mesas.length >= _maxMesas ? AppColors.border : AppColors.success,
              child: const Icon(Icons.add),
            ),
            const SizedBox(width: 12),
            FloatingActionButton(
              heroTag: 'btnEliminarMesa',
              onPressed: _mesas.length <= _minMesas ? null : _eliminarUltimaMesa,
              backgroundColor: _mesas.length <= _minMesas ? AppColors.border : AppColors.error,
              child: const Icon(Icons.remove),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildParaLlevarView() {
    if (_comandasParaLlevar.isEmpty) {
      return EmptyStateWidget(
        icon: Icons.shopping_bag_outlined,
        title: 'Sin pedidos para llevar',
        subtitle: 'Los pedidos para llevar activos aparecen aqui.',
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _comandasParaLlevar.length,
      itemBuilder: (context, index) {
        final comanda = _comandasParaLlevar[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.surfaceCard,
              borderRadius: AppRadius.cardRadius,
              border: const Border(left: BorderSide(color: AppColors.accent, width: 4)),
              boxShadow: AppShadows.card,
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 48, height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.accent.withOpacity(0.1),
                      borderRadius: AppRadius.buttonRadius,
                    ),
                    child: const Icon(Icons.shopping_bag, color: AppColors.accent, size: 24),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(comanda.nombreCliente ?? 'Sin Nombre',
                          style: AppTextStyles.headingSmall),
                        const SizedBox(height: 2),
                        Text('${comanda.itemsApiCount} items  •  \$${comanda.totalApi.toStringAsFixed(2)}',
                          style: AppTextStyles.bodySmall),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      OutlinedButton.icon(
                        onPressed: () async {
                          final result = await Navigator.push(context, FadeSlidePageRoute(
                            page: TomarComandaScreen(mesaId: 0, mesaNumero: 'Para Llevar', comandaPreexistente: comanda),
                          ));
                          if (result == true && mounted) _cargarMesas();
                        },
                        icon: const Icon(Icons.add, size: 16),
                        label: const Text('Agregar'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton.icon(
                        onPressed: () => Navigator.push(context, FadeSlidePageRoute(page: CobrarComandaScreen(comanda: comanda))),
                        icon: const Icon(Icons.payment, size: 16),
                        label: const Text('Cobrar'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSkeletonLoader() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cols = constraints.maxWidth < AppBreakpoints.mobile ? 2 : 3;
        return Padding(
          padding: const EdgeInsets.all(12),
          child: GridView.builder(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: cols, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 1.15,
            ),
            itemCount: 8,
            itemBuilder: (_, __) => SkeletonBox(
              width: double.infinity, height: double.infinity,
              borderRadius: AppRadius.cardRadius,
            ),
          ),
        );
      },
    );
  }

  Widget _buildErrorView() {
    return EmptyStateWidget(
      icon: Icons.wifi_off_outlined,
      title: 'Error al cargar mesas',
      subtitle: _errorMessage,
      action: ElevatedButton.icon(
        onPressed: _cargarMesas,
        icon: const Icon(Icons.refresh),
        label: const Text('Reintentar'),
      ),
    );
  }
}
