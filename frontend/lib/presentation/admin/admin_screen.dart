import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/repositories/admin_repository.dart';
import '../../data/models/admin_models.dart';
import '../../data/repositories/menu_admin_repository.dart';
import '../../data/models/menu_admin_models.dart';
import '../../core/utils/pdf_generator.dart';
import '../auth/login_screen.dart';
import '../../data/models/printer_config.dart';
import '../../core/services/kitchen_ticket_service.dart';
import '../../data/models/comanda_model.dart';
import '../widgets/ticket_preview_dialog.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/app_animations.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  int _selectedIndex = 0;
  final AdminRepository _adminRepo = AdminRepository();
  final MenuAdminRepository _menuRepo = MenuAdminRepository();

  // Estados de datos
  ReporteDiario? _reporte;
  List<Mesero> _meseros = [];
  ConfigMesa? _config;
  List<NotaRapida> _notas = [];
  List<CategoriaAdmin> _categorias = [];
  List<ProductoAdmin> _productos = [];
  PrinterConfig? _printerConfig;
  bool _isLoading = true;

  // Estados de UI
  final TextEditingController _buscarComandaCtrl = TextEditingController();
  final TextEditingController _buscarMenuCtrl = TextEditingController();
  String _filtroComanda = '';
  String _filtroMenu = '';
  Map<int, bool> _mostrarPin = {};
  int? _categoriaSeleccionadaId;
  final ScrollController _categoriasScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _cargarTodo();
  }


  Future<void> _cargarTodo() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        _adminRepo.obtenerReporteDiario(),
        _adminRepo.obtenerMeseros(),
        _adminRepo.obtenerConfiguracion(),
        _adminRepo.obtenerNotasRapidas(),
        _menuRepo.obtenerCategorias(),
        _menuRepo.obtenerProductos(),
        PrinterConfig.load(),
      ]);
      if (mounted) {
        setState(() {
          _reporte = results[0] as ReporteDiario;
          _meseros = results[1] as List<Mesero>;
          _config = results[2] as ConfigMesa;
          _notas = results[3] as List<NotaRapida>;
          _categorias = results[4] as List<CategoriaAdmin>;
          _productos = results[5] as List<ProductoAdmin>;
          _printerConfig = results[6] as PrinterConfig;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString(), style: GoogleFonts.inter())));
        setState(() => _isLoading = false);
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

  // ── Navegación compartida ─────────────────────────────────────────
  static const _destinations = [
    (icon: Icons.bar_chart_outlined, selectedIcon: Icons.bar_chart, label: 'Reporte'),
    (icon: Icons.group_outlined, selectedIcon: Icons.group, label: 'Meseros'),
    (icon: Icons.table_bar_outlined, selectedIcon: Icons.table_bar, label: 'Mesas'),
    (icon: Icons.note_alt_outlined, selectedIcon: Icons.note_alt, label: 'Notas'),
    (icon: Icons.fastfood_outlined, selectedIcon: Icons.fastfood, label: 'Menu'),
    (icon: Icons.print_outlined, selectedIcon: Icons.print, label: 'Impresora'),
  ];

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= AppBreakpoints.mobile;

    if (isDesktop) {
      return _buildDesktopLayout();
    }
    return _buildMobileLayout();
  }

  Widget _buildDesktopLayout() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Panel de Administracion'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _cargarTodo, tooltip: 'Recargar'),
          IconButton(icon: const Icon(Icons.logout, color: AppColors.error), onPressed: _cerrarSesion, tooltip: 'Cerrar Sesion'),
        ],
      ),
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: _selectedIndex,
            onDestinationSelected: (index) => setState(() => _selectedIndex = index),
            labelType: NavigationRailLabelType.all,
            destinations: _destinations.map((d) => NavigationRailDestination(
              icon: Icon(d.icon), selectedIcon: Icon(d.selectedIcon), label: Text(d.label),
            )).toList(),
          ),
          const VerticalDivider(thickness: 1, width: 1),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _buildContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileLayout() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Panel de Administracion'),
        leading: Builder(
          builder: (ctx) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(ctx).openDrawer(),
          ),
        ),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _cargarTodo),
        ],
      ),
      drawer: Drawer(
        backgroundColor: AppColors.surfacePanel,
        child: SafeArea(
          child: Column(
            children: [
              Padding(padding: const EdgeInsets.all(16),
                child: Text('OrderSoft Admin', style: AppTextStyles.headingMedium)),
              const Divider(),
              Expanded(
                child: ListView(
                  children: _destinations.asMap().entries.map((e) {
                    final isSelected = _selectedIndex == e.key;
                    return ListTile(
                      leading: Icon(isSelected ? e.value.selectedIcon : e.value.icon,
                        color: isSelected ? AppColors.accent : AppColors.textSecondary),
                      title: Text(e.value.label, style: AppTextStyles.labelMedium.copyWith(
                          color: isSelected ? AppColors.accent : AppColors.textPrimary,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.normal)),
                      selected: isSelected,
                      selectedTileColor: AppColors.accent.withOpacity(0.08),
                      shape: const RoundedRectangleBorder(borderRadius: AppRadius.buttonRadius),
                      onTap: () { setState(() => _selectedIndex = e.key); Navigator.pop(context); },
                    );
                  }).toList(),
                ),
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.logout, color: AppColors.error),
                title: Text('Cerrar Sesion', style: AppTextStyles.labelMedium.copyWith(color: AppColors.error)),
                onTap: _cerrarSesion,
              ),
            ],
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildContent(),
    );
  }


  Widget _buildContent() {
    switch (_selectedIndex) {
      case 0:
        return _buildReporteTab();
      case 1:
        return _buildMeserosTab();
      case 2:
        return _buildConfigTab();
      case 3:
        return _buildNotasTab();
      case 4:
        return _buildMenuTab();
      case 5:
        return _buildImpresoraTab();
      default:
        return const Center(child: Text('Seleccione una opción'));
    }
  }

  // --- REPORTES ---
  Widget _buildReporteTab() {
    if (_reporte == null) return const SizedBox.shrink();
    
    final comandasFiltradas = _reporte!.comandasDetalle.where((c) {
      final query = _filtroComanda.toLowerCase();
      return c.numeroMesa.toString().contains(query) || c.meseroNombre.toLowerCase().contains(query);
    }).toList();

    final isDesktop = MediaQuery.of(context).size.width >= AppBreakpoints.mobile;

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 16,
            runSpacing: 16,
            children: [
              Text('Resumen del Día', style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.bold)),
              ElevatedButton.icon(
                onPressed: () => PdfGenerator.generarReporte(_reporte!),
                icon: const Icon(Icons.picture_as_pdf),
                label: const Text('Exportar PDF'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
              )
            ],
          ),
          const SizedBox(height: 24),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 16,
            runSpacing: 16,
            children: [
              _buildMetricCard('Total Efectivo', '\$${_reporte!.totalCobradoEfectivo.toStringAsFixed(2)}', Icons.attach_money, Colors.green),
              _buildMetricCard('Comandas', '${_reporte!.totalComandasCompletadas}', Icons.receipt_long, Colors.blue),
              _buildMetricCard('Ticket Promedio', '\$${_reporte!.ticketPromedioGeneral.toStringAsFixed(2)}', Icons.calculate, Colors.orange),
            ],
          ),
          const SizedBox(height: 32),
          Text('Rendimiento por Mesero', style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Expanded(
            flex: 1,
            child: Card(
              child: ListView.builder(
                itemCount: _reporte!.desglosePorMesero.length,
                itemBuilder: (context, index) {
                  final m = _reporte!.desglosePorMesero[index];
                  return ListTile(
                    leading: CircleAvatar(child: Text(m.meseroNombre[0])),
                    title: Text(m.meseroNombre, style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
                    subtitle: Text('Comandas: ${m.comandasTomadas} | Promedio: \$${m.ticketPromedio.toStringAsFixed(2)}'),
                    trailing: Text('\$${m.totalVendido.toStringAsFixed(2)}', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green.shade700)),
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 24),
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 16,
            runSpacing: 16,
            children: [
              Text('Detalle de Comandas', style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.bold)),
              SizedBox(
                width: isDesktop ? 300 : MediaQuery.of(context).size.width - 48,
                child: TextField(
                  controller: _buscarComandaCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Buscar mesa o mesero...',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  onChanged: (val) => setState(() => _filtroComanda = val),
                ),
              )
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            flex: 2,
            child: Card(
              child: ListView.builder(
                itemCount: comandasFiltradas.length,
                itemBuilder: (context, index) {
                  final c = comandasFiltradas[index];
                  String fechaFormateada = 'N/A';
                  if (c.horaCierre != null) {
                    try {
                      DateTime fechaUtc = DateTime.parse(c.horaCierre!);
                      DateTime fechaLocal = fechaUtc.toLocal();
                      fechaFormateada = DateFormat('hh:mm a').format(fechaLocal);
                    } catch (e) {
                      fechaFormateada = c.horaCierre!;
                    }
                  }

                  return ExpansionTile(
                    leading: const CircleAvatar(backgroundColor: Colors.blueAccent, child: Icon(Icons.receipt, color: Colors.white)),
                    title: Text('${c.identificadorVista ?? 'Mesa ${c.numeroMesa}'} - Mesero: ${c.meseroNombre}', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
                    subtitle: Text('Hora Cierre: $fechaFormateada'),
                    trailing: Text('\$${c.total.toStringAsFixed(2)}', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green.shade700)),
                    children: c.items != null && c.items!.isNotEmpty 
                        ? c.items!.map((item) => ListTile(
                            dense: true,
                            title: Text(item.producto),
                            trailing: Text('${item.cantidad} x \$${(item.subtotal / item.cantidad).toStringAsFixed(2)} = \$${item.subtotal.toStringAsFixed(2)}'),
                          )).toList()
                        : [const ListTile(title: Text('Sin ítems detallados.'))],
                  );
                },
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildMetricCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 200,
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(icon, size: 48, color: color),
            const SizedBox(height: 16),
            Text(title, style: GoogleFonts.inter(fontSize: 16, color: Colors.grey.shade600)),
            const SizedBox(height: 8),
            Text(value, style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87)),
          ],
        ),
      ),
    );
  }

  // --- MESEROS ---
  Widget _buildMeserosTab() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Gestión de Meseros', style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.bold)),
              ElevatedButton.icon(
                onPressed: _mostrarDialogoCrearMesero,
                icon: const Icon(Icons.person_add),
                label: const Text('Nuevo Mesero'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent, foregroundColor: Colors.white),
              )
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: _meseros.isEmpty
                ? EmptyStateWidget(
                    icon: Icons.group_off,
                    title: 'No hay meseros registrados',
                    subtitle: 'Crea tu primer mesero para que puedan acceder al sistema.',
                    action: ElevatedButton.icon(
                      onPressed: _mostrarDialogoCrearMesero,
                      icon: const Icon(Icons.person_add),
                      label: const Text('Nuevo Mesero'),
                    ),
                  )
                : ListView.builder(
              itemCount: _meseros.length,
              itemBuilder: (context, index) {
                final m = _meseros[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: m.activo ? Colors.green.shade100 : Colors.red.shade100,
                              child: Icon(Icons.person, color: m.activo ? Colors.green : Colors.red),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(m.nombre, style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16)),
                                  Text('Rol: ${m.rol.toUpperCase()}'),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          alignment: WrapAlignment.end,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 4,
                          children: [
                            if (m.pin != null)
                              IconButton(
                                icon: Icon(_mostrarPin[m.id] == true ? Icons.visibility_off : Icons.visibility, color: Colors.grey),
                                tooltip: 'Mostrar PIN',
                                onPressed: () => setState(() => _mostrarPin[m.id] = !(_mostrarPin[m.id] == true)),
                              ),
                            if (_mostrarPin[m.id] == true && m.pin != null)
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                                child: Text(m.pin!, style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 2)),
                              ),
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blueAccent),
                              tooltip: 'Editar',
                              onPressed: () => _mostrarDialogoEditarMesero(m),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.redAccent),
                              tooltip: 'Eliminar',
                              onPressed: () => _mostrarDialogoEliminarMesero(m),
                            ),
                            Switch(
                              value: m.activo,
                              onChanged: m.rol == 'admin' ? null : (val) async {
                                try {
                                  setState(() => m.activo = val);
                                  final exito = await _adminRepo.actualizarEstadoMesero(m.id, val);
                                  if (!exito) {
                                    setState(() => m.activo = !val);
                                    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error al actualizar estado')));
                                  }
                                } catch (e) {
                                  setState(() => m.activo = !val);
                                  if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
                                }
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          )
        ],
      ),
    );
  }

  void _mostrarDialogoEliminarMesero(Mesero m) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar Mesero'),
        content: Text('¿Cómo desea eliminar a ${m.nombre}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white),
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await _adminRepo.eliminarMesero(m.id, hard: false);
                _cargarTodo();
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Mesero ocultado')));
              } catch (e) {
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
              }
            },
            child: const Text('Ocultar de la pantalla (Mantener historial)'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await _adminRepo.eliminarMesero(m.id, hard: true);
                _cargarTodo();
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Mesero eliminado permanentemente')));
              } catch (e) {
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
              }
            },
            child: const Text('Eliminar definitivamente toda la información'),
          )
        ],
      )
    );
  }

  void _mostrarDialogoEditarMesero(Mesero m) {
    final nombreCtrl = TextEditingController(text: m.nombre);
    final pinCtrl = TextEditingController();
    
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Editar Mesero', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nombreCtrl, decoration: const InputDecoration(labelText: 'Nombre Completo')),
            const SizedBox(height: 16),
            TextField(
              controller: pinCtrl,
              decoration: const InputDecoration(labelText: 'Nuevo PIN (dejar vacío para no cambiar)', counterText: ''),
              keyboardType: TextInputType.number,
              obscureText: true,
              maxLength: 4,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () async {
              if (nombreCtrl.text.trim().isEmpty || (pinCtrl.text.isNotEmpty && pinCtrl.text.length != 4)) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Datos inválidos.')));
                return;
              }
              try {
                await _adminRepo.actualizarMesero(m.id, nombre: nombreCtrl.text.trim(), pin: pinCtrl.text.trim());
                Navigator.pop(ctx);
                _cargarTodo();
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
              }
            },
            child: const Text('Guardar'),
          )
        ],
      ),
    );
  }

  void _mostrarDialogoCrearMesero() {
    final nombreCtrl = TextEditingController();
    final pinCtrl = TextEditingController();
    
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Nuevo Mesero', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nombreCtrl, decoration: const InputDecoration(labelText: 'Nombre Completo')),
            const SizedBox(height: 16),
            TextField(
              controller: pinCtrl,
              decoration: const InputDecoration(labelText: 'PIN (4 dígitos)', counterText: ''),
              keyboardType: TextInputType.number,
              obscureText: true,
              maxLength: 4,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () async {
              if (nombreCtrl.text.trim().isEmpty || pinCtrl.text.trim().length != 4) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Datos inválidos. El PIN debe tener 4 dígitos.')));
                return;
              }
              try {
                await _adminRepo.crearMesero(nombreCtrl.text.trim(), pinCtrl.text.trim());
                Navigator.pop(ctx);
                _cargarTodo();
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
              }
            },
            child: const Text('Guardar'),
          )
        ],
      ),
    );
  }

  // --- CONFIG ---
  Widget _buildConfigTab() {
    if (_config == null) return const SizedBox.shrink();
    int minM = _config!.minMesas;
    int maxM = _config!.maxMesas;

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Configuración de Mesas', style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: StatefulBuilder(
                builder: (context, setStateConfig) {
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Mínimo de mesas: $minM', style: GoogleFonts.inter(fontSize: 16)),
                          Slider(
                            value: minM.toDouble(),
                            min: 1,
                            max: 50,
                            divisions: 49,
                            onChanged: (val) {
                              setStateConfig(() {
                                minM = val.toInt();
                                if (minM > maxM) maxM = minM;
                              });
                            },
                          )
                        ],
                      ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Máximo de mesas: $maxM', style: GoogleFonts.inter(fontSize: 16)),
                          Slider(
                            value: maxM.toDouble(),
                            min: 1,
                            max: 50,
                            divisions: 49,
                            onChanged: (val) {
                              setStateConfig(() {
                                maxM = val.toInt();
                                if (maxM < minM) minM = maxM;
                              });
                            },
                          )
                        ],
                      ),
                      const SizedBox(height: 32),
                      ElevatedButton.icon(
                        onPressed: () async {
                          try {
                            await _adminRepo.actualizarConfiguracion(minM, maxM);
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Configuración guardada')));
                            _cargarTodo();
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
                          }
                        },
                        icon: const Icon(Icons.save),
                        label: const Text('Guardar Cambios'),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent, foregroundColor: Colors.white),
                      )
                    ],
                  );
                }
              ),
            ),
          )
        ],
      ),
    );
  }

  // --- NOTAS ---
  Widget _buildNotasTab() {
    final txtCtrl = TextEditingController();
    final precioCtrl = TextEditingController();
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Notas Rápidas de Cocina', style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(flex: 2, child: TextField(controller: txtCtrl, decoration: const InputDecoration(labelText: 'Nueva nota rápida', border: OutlineInputBorder()))),
              const SizedBox(width: 16),
              Expanded(flex: 1, child: TextField(controller: precioCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Precio Extra (\$)', hintText: 'Ej. 5.00', border: OutlineInputBorder()))),
              const SizedBox(width: 16),
              ElevatedButton(
                onPressed: () async {
                  if (txtCtrl.text.trim().isNotEmpty) {
                    try {
                      final precio = double.tryParse(precioCtrl.text.trim()) ?? 0.0;
                      await _adminRepo.crearNotaRapida(txtCtrl.text.trim(), precioExtra: precio);
                      txtCtrl.clear();
                      precioCtrl.clear();
                      _cargarTodo();
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
                    }
                  }
                },
                style: ElevatedButton.styleFrom(padding: const EdgeInsets.all(20), backgroundColor: Colors.blueAccent, foregroundColor: Colors.white),
                child: const Text('Agregar'),
              )
            ],
          ),
          const SizedBox(height: 32),
          Wrap(
            spacing: 24,
            runSpacing: 24,
            children: _notas.map((n) {
              final labelText = n.precioExtra > 0 ? '${n.texto} (+\$${n.precioExtra.toStringAsFixed(2)})' : n.texto;
              return Badge(
                isLabelVisible: n.activa == true,
                label: const Text('En uso'),
                offset: const Offset(5, -5),
                backgroundColor: Colors.orangeAccent,
                child: InputChip(
                  label: Text(labelText, style: GoogleFonts.inter()),
                  deleteIcon: const Icon(Icons.close, size: 18),
                  onPressed: () => _mostrarDialogoEditarNota(n),
                  onDeleted: () async {
                    try {
                      await _adminRepo.eliminarNotaRapida(n.id);
                      _cargarTodo();
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
                    }
                  },
                ),
              );
            }).toList(),
          )
        ],
      ),
    );
  }

  void _mostrarDialogoEditarNota(NotaRapida n) {
    final txtCtrl = TextEditingController(text: n.texto);
    final precioCtrl = TextEditingController(text: n.precioExtra > 0 ? n.precioExtra.toString() : '');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Editar Nota', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: txtCtrl,
              decoration: const InputDecoration(labelText: 'Texto de la nota'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: precioCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Precio Extra (\$)'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () async {
              if (txtCtrl.text.trim().isNotEmpty) {
                try {
                  final precio = double.tryParse(precioCtrl.text.trim()) ?? 0.0;
                  await _adminRepo.actualizarNotaRapida(n.id, txtCtrl.text.trim(), precioExtra: precio);
                  Navigator.pop(ctx);
                  _cargarTodo();
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
                }
              }
            },
            child: const Text('Guardar'),
          )
        ],
      ),
    );
  }

  // --- MENU Y CATÁLOGO ---
  Widget _buildMenuTab() {
    var prodsFiltrados = _categoriaSeleccionadaId == null 
        ? _productos 
        : _productos.where((p) => p.categoriaId == _categoriaSeleccionadaId).toList();
        
    if (_filtroMenu.isNotEmpty) {
      final query = _filtroMenu.toLowerCase();
      prodsFiltrados = prodsFiltrados.where((p) => p.nombre.toLowerCase().contains(query)).toList();
    }

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Menú y Catálogo', style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.bold)),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: TextField(
                    controller: _buscarMenuCtrl,
                    onChanged: (val) => setState(() => _filtroMenu = val),
                    decoration: InputDecoration(
                      hintText: 'Buscar producto...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _filtroMenu.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _buscarMenuCtrl.clear();
                                setState(() => _filtroMenu = '');
                              },
                            )
                          : null,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                    ),
                  ),
                ),
              ),
              Row(
                children: [
                  ElevatedButton.icon(
                    onPressed: _mostrarDialogoCategoria,
                    icon: const Icon(Icons.category),
                    label: const Text('Nueva Categoría'),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton.icon(
                    onPressed: () => _mostrarDialogoProducto(null),
                    icon: const Icon(Icons.fastfood),
                    label: const Text('Nuevo Producto'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent, foregroundColor: Colors.white),
                  )
                ],
              )
            ],
          ),
          const SizedBox(height: 24),
          Listener(
            behavior: HitTestBehavior.opaque,
            onPointerSignal: (pointerSignal) {
              if (pointerSignal is PointerScrollEvent) {
                if (_categoriasScrollController.hasClients) {
                  final double delta = pointerSignal.scrollDelta.dy != 0 
                      ? pointerSignal.scrollDelta.dy 
                      : pointerSignal.scrollDelta.dx;
                  final offset = _categoriasScrollController.offset + delta;
                  _categoriasScrollController.jumpTo(
                    offset.clamp(0.0, _categoriasScrollController.position.maxScrollExtent),
                  );
                }
              }
            },
            child: SingleChildScrollView(
              controller: _categoriasScrollController,
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                ChoiceChip(
                  label: const Text('Todas'),
                  selected: _categoriaSeleccionadaId == null,
                  onSelected: (val) => setState(() => _categoriaSeleccionadaId = null),
                ),
                const SizedBox(width: 8),
                ..._categorias.map((c) => Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ChoiceChip(
                        label: Text(c.nombre),
                        selected: _categoriaSeleccionadaId == c.id,
                        onSelected: (val) => setState(() => _categoriaSeleccionadaId = val ? c.id : null),
                      ),
                      PopupMenuButton<String>(
                        icon: const Icon(Icons.more_vert, size: 20),
                        tooltip: 'Opciones',
                        onSelected: (val) {
                          if (val == 'edit') {
                            _mostrarDialogoEditarCategoria(c);
                          } else if (val == 'delete') {
                            _eliminarCategoria(c.id);
                          }
                        },
                        itemBuilder: (ctx) => [
                          const PopupMenuItem(
                            value: 'edit',
                            child: Row(
                              children: [
                                Icon(Icons.edit, color: Colors.blueAccent, size: 20),
                                SizedBox(width: 8),
                                Text('Editar')
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(Icons.delete, color: Colors.redAccent, size: 20),
                                SizedBox(width: 8),
                                Text('Eliminar', style: TextStyle(color: Colors.redAccent))
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ))
              ],
            ),
          ),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: prodsFiltrados.isEmpty
                ? EmptyStateWidget(
                    icon: Icons.fastfood_outlined,
                    title: 'No hay productos',
                    subtitle: 'Aún no hay productos registrados en esta categoría.',
                    action: ElevatedButton.icon(
                      onPressed: () => _mostrarDialogoProducto(null),
                      icon: const Icon(Icons.add),
                      label: const Text('Nuevo Producto'),
                    ),
                  )
                : (MediaQuery.of(context).size.width >= AppBreakpoints.mobile)
                    ? GridView.builder(
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3, 
                          childAspectRatio: 3,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                        ),
                        itemCount: prodsFiltrados.length,
                        itemBuilder: (ctx, index) => _buildProductoCard(prodsFiltrados[index]),
                      )
                    : ListView.builder(
                        itemCount: prodsFiltrados.length,
                        itemBuilder: (ctx, index) => Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: _buildProductoCard(prodsFiltrados[index]),
                        ),
                      ),
          )
        ],
      ),
    );
  }

  Widget _buildProductoCard(ProductoAdmin p) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(p.nombre, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 4),
            Text('\$${p.precio.toStringAsFixed(2)} - ${p.categoriaNombre ?? ""}'),
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Switch(
                  value: p.disponible,
                  onChanged: (val) async {
                    try {
                      setState(() => p.disponible = val);
                      final exito = await _menuRepo.actualizarDisponibilidadProducto(p.id, val);
                      if (!exito) {
                        setState(() => p.disponible = !val);
                        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error al actualizar disponibilidad')));
                      }
                    } catch (e) {
                      setState(() => p.disponible = !val);
                      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
                    }
                  },
                ),
                IconButton(icon: const Icon(Icons.edit, color: Colors.blue), onPressed: () => _mostrarDialogoProducto(p)),
                IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => _eliminarProducto(p.id)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _mostrarDialogoCategoria() {
    final nombreCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Nueva Categoría'),
        content: TextField(controller: nombreCtrl, decoration: const InputDecoration(labelText: 'Nombre de la categoría')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () async {
              if (nombreCtrl.text.trim().isNotEmpty) {
                try {
                  await _menuRepo.crearCategoria(nombreCtrl.text.trim());
                  Navigator.pop(ctx);
                  _cargarTodo();
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
                }
              }
            },
            child: const Text('Guardar'),
          )
        ],
      )
    );
  }
  void _mostrarDialogoEditarCategoria(CategoriaAdmin c) {
    final nombreCtrl = TextEditingController(text: c.nombre);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Editar Categoría'),
        content: TextField(controller: nombreCtrl, decoration: const InputDecoration(labelText: 'Nombre de la categoría')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () async {
              if (nombreCtrl.text.trim().isNotEmpty) {
                try {
                  await _menuRepo.actualizarCategoria(c.id, nombreCtrl.text.trim());
                  Navigator.pop(ctx);
                  _cargarTodo();
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
                }
              }
            },
            child: const Text('Guardar'),
          )
        ],
      )
    );
  }

  void _eliminarCategoria(int id) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('¿Deshabilitar categoría?'),
        content: const Text('Al deshabilitar esta categoría, sus productos vinculados también dejarán de estar disponibles para las comandas. El historial de ventas pasadas se mantendrá protegido.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await _menuRepo.eliminarCategoria(id);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Categoría y sus productos deshabilitados')));
                await _cargarTodo();
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
              }
            },
            child: const Text('Deshabilitar'),
          )
        ],
      )
    );
  }

  void _mostrarDialogoProducto(ProductoAdmin? p) {
    final nombreCtrl = TextEditingController(text: p?.nombre ?? '');
    final precioCtrl = TextEditingController(text: p != null ? p.precio.toString() : '');
    int? catId = p?.categoriaId;
    if (catId != null && !_categorias.any((c) => c.id == catId)) {
      catId = null;
    }
    catId ??= _categorias.isNotEmpty ? _categorias.first.id : null;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (modalCtx, setModalState) {
            return AlertDialog(
              title: Text(p == null ? 'Nuevo Producto' : 'Editar Producto'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(controller: nombreCtrl, decoration: const InputDecoration(labelText: 'Nombre del producto')),
                  const SizedBox(height: 16),
                  TextField(controller: precioCtrl, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Precio')),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<int>(
                    value: catId,
                    decoration: const InputDecoration(labelText: 'Categoría'),
                    items: _categorias.map((c) => DropdownMenuItem(value: c.id, child: Text(c.nombre))).toList(),
                    onChanged: (val) => setModalState(() => catId = val),
                  )
                ],
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
                ElevatedButton(
                  onPressed: () async {
                    if (nombreCtrl.text.trim().isNotEmpty && precioCtrl.text.isNotEmpty && catId != null) {
                      try {
                        final data = {
                          'nombre': nombreCtrl.text.trim(),
                          'precio': double.tryParse(precioCtrl.text.trim()) ?? 0.0,
                          'categoria_id': catId,
                          'disponible': p?.disponible ?? true,
                        };
                        if (p == null) {
                          await _menuRepo.crearProducto(data);
                          Navigator.pop(ctx);
                          _cargarTodo();
                        } else {
                          final double precioParsed = double.tryParse(precioCtrl.text.trim()) ?? 0.0;
                          try {
                            final exito = await _menuRepo.actualizarProducto(
                              p.id, 
                              nombreCtrl.text.trim(), 
                              precioParsed, 
                              catId ?? p.categoriaId
                            );
                            
                            if (exito) {
                              Navigator.pop(ctx);
                              await _cargarTodo();
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Producto actualizado con éxito')));
                              }
                            }
                          } catch (e, stack) {
                            print('>>> EXCEPCIÓN AL GUARDAR DIÁLOGO: $e');
                            print('>>> STACK TRACE COMPLETO:\n$stack');
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
                            }
                          }
                        }
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
                      }
                    }
                  },
                  child: const Text('Guardar'),
                )
              ],
            );
          }
        );
      }
    );
  }

  void _eliminarProducto(String id) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar Producto'),
        content: const Text('¿Estás seguro de eliminar este producto definitivamente?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await _menuRepo.eliminarProducto(id);
                if (mounted) {
                  setState(() => _productos.removeWhere((p) => p.id == id));
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Producto eliminado con éxito')));
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
              }
            },
            child: const Text('Eliminar'),
          )
        ],
      )
    );
  }

  // --- IMPRESORA ---
  Widget _buildImpresoraTab() {
    if (_printerConfig == null) return const SizedBox.shrink();
    final config = _printerConfig!;
    
    final ipCtrl = TextEditingController(text: config.ipImpresora);
    final puertoCtrl = TextEditingController(text: config.puerto.toString());

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Configuración de Impresora de Cocina', style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.bold)),
              Row(
                children: [
                  ElevatedButton.icon(
                    onPressed: () {
                      _simularTicket(config);
                    },
                    icon: const Icon(Icons.remove_red_eye),
                    label: const Text('Probar Ticket (Simulador)'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton.icon(
                    onPressed: () async {
                      config.ipImpresora = ipCtrl.text.trim();
                      config.puerto = int.tryParse(puertoCtrl.text.trim()) ?? 9100;
                      await config.save();
                      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Configuración guardada exitosamente')));
                    },
                    icon: const Icon(Icons.save),
                    label: const Text('Guardar Configuración'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent, foregroundColor: Colors.white),
                  ),
                ],
              )
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: SingleChildScrollView(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: StatefulBuilder(
                    builder: (context, setStatePrinter) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Conexión de Red (TCP 9100)', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: ipCtrl,
                                  decoration: const InputDecoration(labelText: 'Dirección IP de la Impresora', border: OutlineInputBorder()),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: TextField(
                                  controller: puertoCtrl,
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(labelText: 'Puerto TCP', border: OutlineInputBorder()),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 32),
                          Text('Ancho de Papel', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Radio<String>(
                                value: '80mm',
                                groupValue: config.anchoPapel,
                                onChanged: (val) => setStatePrinter(() { if (val != null) config.anchoPapel = val; }),
                              ),
                              const Text('80 mm (Estándar)'),
                              const SizedBox(width: 24),
                              Radio<String>(
                                value: '58mm',
                                groupValue: config.anchoPapel,
                                onChanged: (val) => setStatePrinter(() { if (val != null) config.anchoPapel = val; }),
                              ),
                              const Text('58 mm (Pequeño)'),
                            ],
                          ),
                          const SizedBox(height: 32),
                          Text('Filtro de Categorías para Cocina', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold)),
                          const Text('Seleccione las categorías que se deben enviar a cocina. Las categorías no marcadas (ej. bebidas preparadas en barra) no saldrán en este ticket.', style: TextStyle(color: Colors.grey)),
                          const SizedBox(height: 16),
                          Wrap(
                            spacing: 12,
                            runSpacing: 12,
                            children: _categorias.map((cat) {
                              final isSelected = config.categoriasCocina.contains(cat.id);
                              return FilterChip(
                                label: Text(cat.nombre),
                                selected: isSelected,
                                selectedColor: Colors.blue.shade100,
                                checkmarkColor: Colors.blueAccent,
                                onSelected: (val) {
                                  setStatePrinter(() {
                                    if (val) {
                                      config.categoriasCocina.add(cat.id);
                                    } else {
                                      config.categoriasCocina.remove(cat.id);
                                    }
                                  });
                                },
                              );
                            }).toList(),
                          )
                        ],
                      );
                    }
                  ),
                ),
              ),
            ),
          )
        ],
      ),
    );
  }

  void _simularTicket(PrinterConfig config) {
    // 1. Crear una comanda de prueba Dummy con varios ítems
    if (_productos.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Necesita agregar productos al catálogo primero.')));
      return;
    }

    final dummyComanda = ComandaMesa(
      mesaId: 1,
      nombreCliente: 'Dairon',
      clientes: [
        ClienteSubCuenta(
          id: '1',
          nombre: 'Cliente 1',
          items: [
            ItemComanda(
              id: '1',
              productoId: _productos.first.id.toString(),
              producto: 'Suadero',
              cantidad: 3,
              precioUnitario: 0,
              notas: [NotaAplicada('Todo', 0)]
            ),
            ItemComanda(
              id: '2',
              productoId: _productos.first.id.toString(),
              producto: 'Bistec',
              cantidad: 3,
              precioUnitario: 0,
              notas: [NotaAplicada('Cebolla', 0)]
            ),
          ]
        ),
        ClienteSubCuenta(
          id: '2',
          nombre: 'Cliente 2',
          items: [
            ItemComanda(
              id: '3',
              productoId: _productos.length > 1 ? _productos[1].id.toString() : _productos.first.id.toString(),
              producto: 'Hamburguesa',
              cantidad: 1,
              precioUnitario: 0,
            ),
            ItemComanda(
              id: '4',
              productoId: _productos.length > 2 ? _productos[2].id.toString() : _productos.first.id.toString(),
              producto: 'Papas',
              cantidad: 1,
              precioUnitario: 0,
            )
          ]
        ),
      ]
    );

    // Forzamos temporalmente a que las categorías de los primeros productos
    // estén en el config solo para la simulación si no hay ninguna.
    final List<int> originalCategories = List.from(config.categoriasCocina);
    if (config.categoriasCocina.isEmpty) {
      for (var p in _productos.take(3)) {
        if (!config.categoriasCocina.contains(p.categoriaId)) {
          config.categoriasCocina.add(p.categoriaId);
        }
      }
    }

    final ticketStr = KitchenTicketService.generarTicketCocina(dummyComanda, config, _productos);

    // Restauramos
    config.categoriasCocina = originalCategories;

    if (ticketStr == null) {
       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No hay ítems configurados para enviar a cocina.')));
       return;
    }

    showDialog(
      context: context,
      builder: (ctx) => TicketPreviewDialog(ticketText: ticketStr)
    );
  }
}
