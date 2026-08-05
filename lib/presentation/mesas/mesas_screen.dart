import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import '../../data/models/mesa_model.dart';
import '../../data/models/comanda_model.dart';
import '../../data/repositories/mesas_repository.dart';
import '../../data/repositories/comandas_repository.dart';
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

  // Estados del Modo Fusión
  bool _modoJuntarActivo = false;
  int? _mesaSeleccionadaId;
  
  Timer? _pollingTimer;

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      setState(() {});
    });
    _cargarConfiguracion();
    _cargarMesas();
    _pollingTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      _cargarMesas(silencioso: true);
    });
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
    } catch (e) {
      // Fallback a defecto
    }
  }

  Future<void> _cargarMesas({bool silencioso = false}) async {
    if (!silencioso) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }
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
        setState(() {
          if (!silencioso) {
            _errorMessage = e.toString();
            _isLoading = false;
          }
        });
        if (!silencioso) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e', style: GoogleFonts.inter())),
          );
        }
      }
    }
  }

  void _cerrarSesion() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  void _toggleModoJuntar() {
    setState(() {
      _modoJuntarActivo = !_modoJuntarActivo;
      _mesaSeleccionadaId = null; // Reiniciamos selección si se apaga o enciende
    });
  }

  Future<void> _onMesaTap(Mesa mesa) async {
    final bool estaUnida = mesa.mesaPadreId != null || _mesas.any((m) => m.mesaPadreId == mesa.id);

    if (_modoJuntarActivo) {
      if (_mesaSeleccionadaId == null) {
        // Primera mesa seleccionada
        setState(() {
          _mesaSeleccionadaId = mesa.id;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Mesa ${mesa.numero} seleccionada. Ahora toca la mesa con la que deseas fusionarla.', style: GoogleFonts.inter()),
            backgroundColor: Colors.blueAccent,
            duration: const Duration(seconds: 3),
          ),
        );
      } else {
        // Segunda mesa seleccionada
        if (_mesaSeleccionadaId == mesa.id) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Debes seleccionar una mesa diferente.', style: GoogleFonts.inter()),
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 2),
            ),
          );
          return;
        }

        // Ejecutar fusión
        await _juntarMesas(mesa.id, _mesaSeleccionadaId!);

      }
    } else {
      // Modo normal: Ir a tomar comanda
      final bool estaOcupada = mesa.estado.toLowerCase() != 'libre';
      
      ComandaMesa? comandaExistente;
      if (estaOcupada) {
        showDialog(
          context: context, 
          barrierDismissible: false, 
          builder: (_) => const Center(child: CircularProgressIndicator())
        );
        
        comandaExistente = await _comandasRepository.obtenerComandaActivaPorMesa(mesa.id);
        
        if (mounted) {
          Navigator.pop(context); // cerrar loading
        }
      }

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TomarComandaScreen(
              mesaId: mesa.id,
              mesaNumero: mesa.numero.toString(),
              comandaPreexistente: comandaExistente,
            ),
          ),
        );
      }
    }
  }

  Future<void> _juntarMesas(int mesaHijaId, int mesaPadreId) async {
    try {
      await _mesasRepository.juntarMesas(mesaHijaId, mesaPadreId);
      await _cargarMesas();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Mesa unida al grupo. Puedes tocar otra mesa para sumarla', style: GoogleFonts.inter(color: Colors.white)), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al fusionar: $e', style: GoogleFonts.inter(color: Colors.white)), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _separarMesa(int mesaId) async {
    try {
      await _mesasRepository.separarMesa(mesaId);
      await _cargarMesas();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Mesa separada exitosamente', style: GoogleFonts.inter(color: Colors.white)), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al separar: $e', style: GoogleFonts.inter(color: Colors.white)), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _crearMesa() async {
    try {
      await _mesasRepository.crearMesa();
      await _cargarMesas(silencioso: true);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Mesa agregada', style: GoogleFonts.inter(color: Colors.white)),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al crear: $e', style: GoogleFonts.inter(color: Colors.white)),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _eliminarUltimaMesa() async {
    try {
      await _mesasRepository.eliminarUltimaMesa();
      await _cargarMesas(silencioso: true);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Mesa eliminada', style: GoogleFonts.inter(color: Colors.white)),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', ''), style: GoogleFonts.inter(color: Colors.white)),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _irParaLlevar() {
    final TextEditingController controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Pedido Para Llevar', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Nombre del cliente',
            border: OutlineInputBorder()
          ),
          textCapitalization: TextCapitalization.words,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Cancelar', style: GoogleFonts.inter())),
          ElevatedButton(
            onPressed: () {
              final nombre = controller.text.trim();
              if (nombre.isEmpty) return;
              Navigator.pop(ctx);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => TomarComandaScreen(
                    mesaId: 0,
                    mesaNumero: 'Para Llevar',
                    nombreCliente: nombre,
                    tipoOrden: 'PARA_LLEVAR',
                  ),
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent, foregroundColor: Colors.white),
            child: Text('Crear Orden', style: GoogleFonts.inter()),
          )
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
          title: Text('Pedidos y Mesas', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
          actions: [
            IconButton(
              icon: const Icon(Icons.add_shopping_cart, color: Colors.orange),
              tooltip: 'Nuevo Para Llevar',
              onPressed: _irParaLlevar,
            ),
            IconButton(
              icon: Icon(Icons.ads_click, color: _modoJuntarActivo ? Colors.amberAccent : null),
              tooltip: 'Modo Fusión',
              onPressed: _toggleModoJuntar,
            ),
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _cargarMesas,
            ),
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: _cerrarSesion,
            )
          ],
          bottom: TabBar(
            controller: _tabController,
            tabs: const [
              Tab(icon: Icon(Icons.table_restaurant), text: '🪑 Mesas'),
              Tab(icon: Icon(Icons.shopping_bag), text: '🛍️ Para Llevar'),
            ],
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.amberAccent,
          ),
        ),
        body: _isLoading
            ? const Center(
                child: SpinKitFadingCube(
                  color: Colors.blueAccent,
                  size: 50.0,
                ),
              )
            : _errorMessage != null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('Hubo un error', style: GoogleFonts.inter(fontSize: 18, color: Colors.redAccent)),
                        const SizedBox(height: 8),
                        ElevatedButton(
                          onPressed: _cargarMesas,
                          child: Text('Reintentar', style: GoogleFonts.inter()),
                        )
                      ],
                    ),
                  )
                : TabBarView(
                    controller: _tabController,
                    children: [
                      Column(
                        children: [
                          if (_modoJuntarActivo)
                            Container(
                              width: double.infinity,
                              color: Colors.amberAccent.withOpacity(0.8),
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Text(
                                _mesaSeleccionadaId == null 
                                  ? 'Modo Fusión Activo: Toca la primera mesa' 
                                  : 'Modo Fusión Activo: Toca la mesa a unir',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.black87),
                              ),
                            ),
                          Expanded(child: _buildGridView()),
                        ],
                      ),
                      _buildParaLlevarView(),
                    ],
                  ),
        floatingActionButton: _tabController.index == 0
            ? Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      FloatingActionButton(
                        heroTag: 'btnCrearMesa',
                        onPressed: _mesas.length >= _maxMesas ? null : _crearMesa,
                        backgroundColor: _mesas.length >= _maxMesas ? Colors.grey : Colors.blueAccent,
                        child: const Icon(Icons.add),
                      ),
                      const SizedBox(width: 16),
                      FloatingActionButton(
                        heroTag: 'btnEliminarMesa',
                        onPressed: _mesas.length <= _minMesas ? null : _eliminarUltimaMesa,
                        backgroundColor: _mesas.length <= _minMesas ? Colors.grey : Colors.redAccent,
                        child: const Icon(Icons.remove),
                      ),
                    ],
                  )
                ],
              )
            : FloatingActionButton.extended(
                heroTag: 'btnParaLlevarFAB',
                onPressed: _irParaLlevar,
                backgroundColor: Colors.orange,
                icon: const Icon(Icons.add_shopping_cart, color: Colors.white),
                label: Text('Nuevo Para Llevar', style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.white)),
              ),
      ),
    );
  }

  Widget _buildGridView() {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2, 
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.2,
        ),
        itemCount: _mesas.length,
        itemBuilder: (context, index) {
          final mesa = _mesas[index];
          // Consideramos unida si es hija o es padre de otra
          final bool estaUnida = mesa.mesaPadreId != null || _mesas.any((m) => m.mesaPadreId == mesa.id);
          final bool estaLibre = mesa.estado.toLowerCase() == 'libre';
          final bool estaSeleccionada = _mesaSeleccionadaId == mesa.id;

          Color colorFondo;
          String textoEstado;

          if (estaSeleccionada) {
            colorFondo = Colors.blueAccent;
            textoEstado = 'Seleccionada';
          } else if (estaUnida) {
            colorFondo = Colors.deepPurple.shade400;
            textoEstado = 'Grupo M${mesa.numeroPadre ?? mesa.numero}';
          } else if (estaLibre) {
            colorFondo = Colors.green.shade400;
            textoEstado = 'Disponible';
          } else {
            colorFondo = Colors.redAccent.shade200;
            final double total = _totalesMesasOcupadas[mesa.id] ?? 0.0;
            textoEstado = 'Ocupada\nTotal: \$${total.toStringAsFixed(2)}';
          }

          return InkWell(
            onTap: () => _onMesaTap(mesa),
            borderRadius: BorderRadius.circular(16),
            child: Card(
              elevation: estaSeleccionada ? 8 : 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: estaSeleccionada ? const BorderSide(color: Colors.white, width: 3) : BorderSide.none,
              ),
              color: colorFondo,
              child: Stack(
                children: [
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (estaUnida)
                            const Icon(Icons.link, color: Colors.white, size: 28),
                          if (!estaUnida && !estaSeleccionada)
                            Icon(estaLibre ? Icons.check_circle_outline : Icons.restaurant, color: Colors.white, size: 28),
                          if (estaSeleccionada)
                            const Icon(Icons.touch_app, color: Colors.white, size: 28),
                          const SizedBox(height: 8),
                          Text(
                            'Mesa ${index + 1}',
                            style: GoogleFonts.inter(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            textoEstado,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (estaUnida)
                    Positioned(
                      top: 4,
                      right: 4,
                      child: IconButton(
                        icon: const Icon(Icons.link_off, color: Colors.redAccent),
                        onPressed: () => _separarMesa(mesa.id),
                        tooltip: 'Separar Mesa',
                        constraints: const BoxConstraints(),
                        padding: const EdgeInsets.all(8),
                      ),
                    ),
                  if (!estaLibre && !estaUnida && !estaSeleccionada)
                    Positioned(
                      bottom: 8,
                      right: 8,
                      child: ElevatedButton(
                        onPressed: () async {
                          // Mostrar loading
                          showDialog(context: context, barrierDismissible: false, builder: (_) => const Center(child: CircularProgressIndicator()));
                          
                          final comanda = await _comandasRepository.obtenerComandaActivaPorMesa(mesa.id);
                          if (mounted) {
                            Navigator.pop(context); // cerrar loading
                            if (comanda != null) {
                              Navigator.push(context, MaterialPageRoute(builder: (_) => CobrarComandaScreen(comanda: comanda)));
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('No hay historial en esta mesa', style: GoogleFonts.inter()), backgroundColor: Colors.orange));
                            }
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white.withOpacity(0.9),
                          foregroundColor: Colors.blueAccent,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text('Pagar', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildParaLlevarView() {
    if (_comandasParaLlevar.isEmpty) {
      return Center(
        child: Text('No hay pedidos para llevar activos', style: GoogleFonts.inter(fontSize: 18, color: Colors.grey)),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _comandasParaLlevar.length,
      itemBuilder: (context, index) {
        final comanda = _comandasParaLlevar[index];
        final totalItems = comanda.clientes.fold(0, (sum, c) => sum + c.items.length);
        
        return Card(
          elevation: 4,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Icon(Icons.shopping_bag, size: 40, color: Colors.orange),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(comanda.nombreCliente ?? 'Sin Nombre', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text('Ítems: ${comanda.itemsApiCount}  •  Subtotal: \$${comanda.totalApi.toStringAsFixed(2)}', style: GoogleFonts.inter(color: Colors.grey.shade700)),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => TomarComandaScreen(
                              mesaId: 0,
                              mesaNumero: 'Para Llevar',
                              comandaPreexistente: comanda,
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.add_shopping_cart, size: 16),
                      label: Text('Agregar', style: GoogleFonts.inter()),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange.shade50,
                        foregroundColor: Colors.orange.shade800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => CobrarComandaScreen(comanda: comanda)),
                        );
                      },
                      icon: const Icon(Icons.credit_card, size: 16),
                      label: Text('Cobrar', style: GoogleFonts.inter()),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                )
              ],
            ),
          ),
        );
      },
    );
  }
}
