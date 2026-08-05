import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import '../../data/models/admin_models.dart';

class PdfGenerator {
  static Future<void> generarReporte(ReporteDiario reporte) async {
    final pdf = pw.Document();
    
    final formatter = NumberFormat.currency(symbol: '\$');
    final dateStr = DateFormat('dd/MM/yyyy hh:mm a').format(DateTime.now());

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => [
          pw.Header(
            level: 0,
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('OrderSoft POS', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
                pw.Text(dateStr, style: const pw.TextStyle(fontSize: 14)),
              ],
            ),
          ),
          pw.SizedBox(height: 10),
          pw.Text('Sucursal Principal', style: const pw.TextStyle(fontSize: 16)),
          pw.Divider(),
          
          // KPIs
          pw.SizedBox(height: 10),
          pw.Text('Resumen del Día', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 10),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              _buildKpiCard('Total Efectivo', formatter.format(reporte.totalCobradoEfectivo)),
              _buildKpiCard('Comandas', reporte.totalComandasCompletadas.toString()),
              _buildKpiCard('Ticket Promedio', formatter.format(reporte.ticketPromedioGeneral)),
            ],
          ),
          
          pw.SizedBox(height: 20),
          pw.Text('Rendimiento por Mesero', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 10),
          pw.TableHelper.fromTextArray(
            context: context,
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            data: <List<String>>[
              ['Mesero', 'Comandas', 'Ticket Promedio', 'Total Vendido'],
              ...reporte.desglosePorMesero.map((m) => [
                    m.meseroNombre,
                    m.comandasTomadas.toString(),
                    formatter.format(m.ticketPromedio),
                    formatter.format(m.totalVendido),
                  ])
            ],
          ),

          pw.SizedBox(height: 20),
          pw.Text('Detalle de Comandas', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 10),
          pw.TableHelper.fromTextArray(
            context: context,
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            data: <List<String>>[
              ['Mesa', 'Mesero', 'Hora Cierre', 'Total'],
              ...reporte.comandasDetalle.map((c) => [
                    c.numeroMesa.toString(),
                    c.meseroNombre,
                    c.horaCierre ?? 'N/A',
                    formatter.format(c.total),
                  ])
            ],
          ),
        ],
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Reporte_Diario_OrderSoft.pdf',
    );
  }

  static pw.Widget _buildKpiCard(String title, String value) {
    return pw.Container(
      width: 150,
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
      ),
      child: pw.Column(
        children: [
          pw.Text(title, style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey700)),
          pw.SizedBox(height: 5),
          pw.Text(value, style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
        ],
      ),
    );
  }
}
