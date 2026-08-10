import 'package:flutter/material.dart';
import '../../data/models/comanda_model.dart';
import '../../data/repositories/comandas_repository.dart';
import '../../core/theme/app_theme.dart';

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
        grupos.putIfAbsent(c.cuentaId, () => []).add(c);
      }
    }
    return grupos;
  }

  void _desocuparMesa() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Desocupar Mesa'),
        content: const Text('Esto cerrara la cuenta y marcara la mesa como libre.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              if (widget.comanda.idBackend != null) {
                showDialog(context: context, barrierDismissible: false, builder: (_) => const Center(child: CircularProgressIndicator()));
                try {
                  await _comandasRepository.pagarComanda(widget.comanda.idBackend!);
                  if (mounted) {
                    Navigator.pop(context);
                    Navigator.popUntil(context, (route) => route.isFirst);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Mesa liberada exitosamente.'), backgroundColor: AppColors.success),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error al pagar: $e'), backgroundColor: AppColors.error),
                    );
                  }
                }
              } else {
                Navigator.popUntil(context, (route) => route.isFirst);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Mesa liberada localmente.'), backgroundColor: AppColors.success),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
  }

  Color _colorForCuenta(int cuentaId, bool isPagado) {
    if (isPagado) return AppColors.success;
    const colors = [AppColors.info, AppColors.mesaUnida, AppColors.warning, AppColors.accent];
    return colors[(cuentaId - 1) % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    final grupos = _agruparPorCuenta();
    final titleText = widget.comanda.mesaId == 0
        ? 'Cobro — Para Llevar'
        : 'Cobro — Mesa ${widget.comanda.mesaId}';

    return Scaffold(
      appBar: AppBar(title: Text(titleText)),
      body: Column(
        children: [
          Expanded(
            child: grupos.isEmpty
                ? const Center(child: Text('No hay cuentas con items por cobrar.'))
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: grupos.keys.length,
                    itemBuilder: (context, index) {
                      final cuentaId = grupos.keys.elementAt(index);
                      final clientesEnCuenta = grupos[cuentaId]!;
                      final subtotalCuenta = clientesEnCuenta.fold<double>(0, (sum, c) => sum + c.subtotal);
                      final isPagado = _cuentasPagadas[cuentaId] ?? false;
                      final colorCuenta = _colorForCuenta(cuentaId, isPagado);

                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 400),
                        curve: Curves.easeOutCubic,
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceCard,
                          borderRadius: AppRadius.cardRadius,
                          border: Border(left: BorderSide(color: colorCuenta, width: 5)),
                          boxShadow: AppShadows.card,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(children: [
                                    Container(
                                      width: 36, height: 36,
                                      decoration: BoxDecoration(color: colorCuenta.withOpacity(0.15), borderRadius: AppRadius.buttonRadius),
                                      child: Icon(isPagado ? Icons.check_circle : Icons.receipt, color: colorCuenta, size: 20),
                                    ),
                                    const SizedBox(width: 12),
                                    Text('Cuenta $cuentaId',
                                      style: AppTextStyles.headingSmall.copyWith(color: colorCuenta)),
                                  ]),
                                  AnimatedSwitcher(
                                    duration: const Duration(milliseconds: 300),
                                    child: isPagado
                                        ? const Icon(Icons.check_circle, color: AppColors.success, size: 28, key: ValueKey('check'))
                                        : Text('\$${subtotalCuenta.toStringAsFixed(2)}',
                                            style: AppTextStyles.priceMedium, key: const ValueKey('price')),
                                  ),
                                ],
                              ),
                              const Divider(height: 20),
                              ...clientesEnCuenta.map((c) => Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(children: [
                                    Container(
                                      width: 24, height: 24,
                                      decoration: BoxDecoration(color: colorCuenta.withOpacity(0.15), shape: BoxShape.circle),
                                      child: Center(child: Text(c.nombre[0].toUpperCase(),
                                        style: AppTextStyles.labelSmall.copyWith(color: colorCuenta, fontWeight: FontWeight.w700))),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(c.nombre, style: AppTextStyles.labelMedium.copyWith(fontWeight: FontWeight.w600)),
                                  ]),
                                  const SizedBox(height: 6),
                                  ...c.items.map((i) => Padding(
                                    padding: const EdgeInsets.only(left: 32, bottom: 3),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(child: Text('${i.cantidad}x ${i.producto}', style: AppTextStyles.bodyMedium, overflow: TextOverflow.ellipsis)),
                                        Text('\$${i.total.toStringAsFixed(2)}', style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
                                      ],
                                    ),
                                  )),
                                  const SizedBox(height: 8),
                                ],
                              )),
                              const Divider(),
                              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                                Text('Subtotal:', style: AppTextStyles.labelLarge),
                                Text('\$${subtotalCuenta.toStringAsFixed(2)}', style: AppTextStyles.priceMedium),
                              ]),
                              const SizedBox(height: 12),
                              ElevatedButton.icon(
                                onPressed: isPagado ? null : () async {
                                  if (widget.comanda.idBackend == null) {
                                    setState(() => _cuentasPagadas[cuentaId] = true);
                                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Cuenta $cuentaId pagada.'), backgroundColor: AppColors.success));
                                    return;
                                  }
                                  showDialog(context: context, barrierDismissible: false, builder: (_) => const Center(child: CircularProgressIndicator()));
                                  try {
                                    final mesaDesocupada = await _comandasRepository.pagarCuentaComanda(widget.comanda.idBackend!, cuentaId);
                                    if (mounted) {
                                      Navigator.pop(context);
                                      if (mesaDesocupada) {
                                        Navigator.popUntil(context, (route) => route.isFirst);
                                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Todas las cuentas pagadas. Mesa liberada.'), backgroundColor: AppColors.success));
                                      } else {
                                        setState(() => _cuentasPagadas[cuentaId] = true);
                                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Cuenta $cuentaId pagada.'), backgroundColor: AppColors.success));
                                      }
                                    }
                                  } catch (e) {
                                    if (mounted) {
                                      Navigator.pop(context);
                                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al pagar cuenta: $e'), backgroundColor: AppColors.error));
                                    }
                                  }
                                },
                                icon: Icon(isPagado ? Icons.check : Icons.credit_card),
                                label: Text(isPagado ? 'Pagada' : 'Pagar \$${subtotalCuenta.toStringAsFixed(2)}'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: isPagado ? AppColors.border : AppColors.success,
                                  foregroundColor: isPagado ? AppColors.textMuted : AppColors.textOnDark,
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
          // Bottom bar total + botón pago total
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(color: AppColors.surfaceCard, boxShadow: AppShadows.bottomBar),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Text('TOTAL GENERAL:', style: AppTextStyles.headingMedium),
                  Text('\$${widget.comanda.totalGeneral.toStringAsFixed(2)}', style: AppTextStyles.priceLarge),
                ]),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: _desocuparMesa,
                  icon: const Icon(Icons.done_all),
                  label: const Text('Pagar Todo y Desocupar Mesa'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.textOnDark,
                    textStyle: AppTextStyles.labelLarge.copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

