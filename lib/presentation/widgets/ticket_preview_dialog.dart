import 'package:flutter/material.dart';

class TicketPreviewDialog extends StatelessWidget {
  final String ticketText;

  const TicketPreviewDialog({super.key, required this.ticketText});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: 350,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white, // Color del papel térmico
          borderRadius: BorderRadius.circular(4),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 15,
              offset: const Offset(0, 5),
            )
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Bordes dentados superiores (visual)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(30, (index) => const Icon(Icons.change_history, size: 8, color: Colors.grey)),
            ),
            const SizedBox(height: 16),
            const Text(
              'VISTA PREVIA TICKET',
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey, fontSize: 12),
            ),
            const SizedBox(height: 16),
            Flexible(
              child: SingleChildScrollView(
                child: Text(
                  ticketText,
                  style: const TextStyle(
                    fontFamily: 'Courier', // Fuente monoespaciada esencial para tickets
                    fontSize: 14,
                    color: Colors.black,
                    height: 1.2,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Bordes dentados inferiores (visual)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(30, (index) => RotatedBox(quarterTurns: 2, child: const Icon(Icons.change_history, size: 8, color: Colors.grey))),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                foregroundColor: Colors.white,
              ),
              child: const Text('Cerrar Simulador'),
            )
          ],
        ),
      ),
    );
  }
}
