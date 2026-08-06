import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../data/models/comanda_model.dart';
import '../../data/repositories/comandas_repository.dart';

class CobrarComandaScreen extends StatefulWidget {
  final ComandaMesa comanda;
  
  const CobrarComandaScreen({super.key, required this.comanda});

  @override
  State<CobrarComandaScreen> createState() => _CobrarComandaScreenState();
}

class _CobrarComandaScreenState extends State<CobrarComandaScreen> {
  final Map<int, bool> _cuentasPagadas = {};
  final ComandasRepository _comandasRepository = ComandasRepository();

  @override
  void initState() {
    super.initState();
    final cuentasIds = widget.comanda.clientes.map((c) => c.cuentaId).toSet();
    for (var id in cuentasIds) {
      _cuentasPagadas[id] = false;
    }
  }

  Map<int, List<ClienteSubCuenta>> _agruparPorCuenta() {
    Map<int, List<ClienteSubCuenta>> grupos = {};
    for (var c in widget.comanda.clientes) {
      if (c.items.isNotEmpty) {
        if (!grupos.containsKey(c.cuentaId)) {
          grupos[c.cuentaId] = [];
        }
        grupos[c.cuentaId]!.add(c);
      }
    }
    return grupos;
  }

  void _desocuparMesa() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('¿Desocupar Mesa?', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
        content: Text('Esto cerrará la cuenta y marcará la mesa como libre.', style: GoogleFonts.inter()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancelar', style: GoogleFonts.inter()),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              
              if (widget.comanda.idBackend != null) {
                showDialog(context: context, barrierDismissible: false, builder: (_) => const Center(child: CircularProgressIndicator()));
                try {
                  await _comandasRepository.pagarComanda(widget.comanda.idBackend!);
                  if (mounted) {
                    Navigator.pop(context); // cerrar spinner
                    Navigator.popUntil(context, (route) => route.isFirst);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Mesa liberada exitosamente.'), backgroundColor: Colors.green)
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    Navigator.pop(context); // cerrar spinner
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error al pagar: $e'), backgroundColor: Colors.red)
                    );
                  }
                }
              } else {
                // Si no tiene idBackend es que no se guardó en BD (ej. Para llevar vacío)
                Navigator.popUntil(context, (route) => route.isFirst);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Mesa liberada localmente.'), backgroundColor: Colors.green)
                );
              }
            },
            child: Text('Confirmar', style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.green)),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final grupos = _agruparPorCuenta();
    
    return Scaffold(
      appBar: AppBar(
        title: Text('Cobro - Mesa ${widget.comanda.mesaId}', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Expanded(
            child: grupos.isEmpty
                ? Center(child: Text('No hay cuentas con ítems por cobrar.', style: GoogleFonts.inter(color: Colors.grey)))
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: grupos.keys.length,
                    itemBuilder: (context, index) {
                      final cuentaId = grupos.keys.elementAt(index);
                      final clientesEnCuenta = grupos[cuentaId]!;
                      final subtotalCuenta = clientesEnCuenta.fold<double>(0, (sum, c) => sum + c.subtotal);
                      final isPagado = _cuentasPagadas[cuentaId] ?? false;

                      return Card(
                        elevation: 4,
                        margin: const EdgeInsets.only(bottom: 16),
                        shape: RoundedRectangleBorder(
                          side: BorderSide(color: isPagado ? Colors.green : Colors.transparent, width: 2),
                          borderRadius: BorderRadius.circular(12)
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Cuenta $cuentaId',
                                    style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: isPagado ? Colors.green : Colors.black87),
                                  ),
                                  if (isPagado) 
                                    const Icon(Icons.check_circle, color: Colors.green),
                                ],
                              ),
                              const Divider(),
                              ...clientesEnCuenta.map((c) {
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(c.nombre, style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: Colors.grey.shade700)),
                                    ...c.items.map((i) => Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text('${i.cantidad}x ${i.producto}', style: GoogleFonts.inter(fontSize: 14)),
                                        Text('\$${i.total.toStringAsFixed(2)}', style: GoogleFonts.inter(fontSize: 14)),
                                      ],
                                    )),
                                    const SizedBox(height: 8),
                                  ],
                                );
                              }),
                              const Divider(),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('Subtotal Cuenta:', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold)),
                                  Text('\$${subtotalCuenta.toStringAsFixed(2)}', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blueAccent)),
                                ],
                              ),
                              const SizedBox(height: 12),
                              ElevatedButton.icon(
                                onPressed: isPagado ? null : () async {
                                  if (widget.comanda.idBackend == null) {
                                    setState(() {
                                      _cuentasPagadas[cuentaId] = true;
                                    });
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Cuenta $cuentaId pagada localmente.', style: GoogleFonts.inter()))
                                    );
                                    return;
                                  }

                                  showDialog(context: context, barrierDismissible: false, builder: (_) => const Center(child: CircularProgressIndicator()));
                                  try {
                                    final mesaDesocupada = await _comandasRepository.pagarCuentaComanda(widget.comanda.idBackend!, cuentaId);
                                    if (mounted) {
                                      Navigator.pop(context); // cerrar spinner
                                      if (mesaDesocupada) {
                                        Navigator.popUntil(context, (route) => route.isFirst);
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text('Todas las cuentas pagadas. Mesa liberada.'), backgroundColor: Colors.green)
                                        );
                                      } else {
                                        setState(() {
                                          _cuentasPagadas[cuentaId] = true;
                                        });
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text('Cuenta $cuentaId pagada exitosamente.', style: GoogleFonts.inter()), backgroundColor: Colors.green)
                                        );
                                      }
                                    }
                                  } catch (e) {
                                    if (mounted) {
                                      Navigator.pop(context); // cerrar spinner
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text('Error al pagar cuenta: $e'), backgroundColor: Colors.red)
                                      );
                                    }
                                  }
                                },
                                icon: const Icon(Icons.credit_card),
                                label: Text(isPagado ? 'Pagada' : '💳 Pagar Cuenta \$${subtotalCuenta.toStringAsFixed(2)}', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: isPagado ? Colors.grey.shade300 : Colors.green.shade600,
                                  foregroundColor: isPagado ? Colors.grey : Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 12)
                                ),
                              )
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: Colors.white,
              boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, -5))]
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('TOTAL GENERAL MESA:', style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.bold)),
                    Text('\$${widget.comanda.totalGeneral.toStringAsFixed(2)}', style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.blueAccent)),
                  ],
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: _desocuparMesa,
                  icon: const Icon(Icons.money),
                  label: Text('💵 Pagar Todo y Desocupar Mesa', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16)
                  ),
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}
