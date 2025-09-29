import 'dart:typed_data';
import 'package:intl/intl.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';

class PdfService {
  static Future<Uint8List> generateReturnReceiptPdf(
    Map<String, dynamic>? header,
    List<Map<String, dynamic>> details,
  ) async {
    final pdf = pw.Document();
    final formatter = NumberFormat.currency(locale: 'en_IN', symbol: 'Rs.');

    double subtotal = details.fold(
      0.0,
      (sum, item) => sum + ((item['amount'] ?? 0.0) as double),
    );
    double percent =
        double.tryParse(header?['percentage']?.toString() ?? '0') ?? 0.0;
    double percentageAmount = subtotal * percent / 100;
    double total = subtotal - percentageAmount;
    double advance =
        double.tryParse(header?['advance']?.toString() ?? '0') ?? 0;
    double balance = total - advance;

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat(226, double.infinity, marginAll: 5),
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Center(
              child: pw.Text(
                "Return Receipt",
                style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
            pw.SizedBox(height: 5),
            pw.Text("Retailer: ${header?['retailer_name'] ?? ''}"),
            pw.Text("Date: ${header?['date'] ?? ''}"),
            pw.Text("Bill No: ${header?['bill_no'] ?? ''}"),
            pw.Divider(),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text("Product", style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                pw.Text("Qty", style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                pw.Text("Ret", style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                pw.Text("Bal", style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                pw.Text("Amt", style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              ],
            ),
            pw.Divider(),
            ...details.map((item) {
              final qty = int.tryParse(item['quantity'].toString()) ?? 0;
              final ret = int.tryParse(item['return_quantity'].toString()) ?? 0;
              final price = double.tryParse(item['price'].toString()) ?? 0.0;
              final bal = qty - ret;
              final amt = bal * price;

              return pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Expanded(flex: 2, child: pw.Text(item['name'], maxLines: 1)),
                  pw.SizedBox(width: 25, child: pw.Text("$qty")),
                  pw.SizedBox(width: 25, child: pw.Text("$ret")),
                  pw.SizedBox(width: 25, child: pw.Text("$bal")),
                  pw.SizedBox(width: 40, child: pw.Text(formatter.format(amt))),
                ],
              );
            }),
            pw.Divider(),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text("Subtotal:", style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                pw.Text(formatter.format(subtotal)),
              ],
            ),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text("Retailer Cut (${header?['percentage']}%):",
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                pw.Text(formatter.format(percentageAmount)),
              ],
            ),
            pw.Divider(),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text("Total:", style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                pw.Text(formatter.format(total)),
              ],
            ),
            if (advance != 0) ...[
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text("Received:", style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  pw.Text(formatter.format(advance)),
                ],
              ),
              pw.Divider(),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text("Balance:", style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  pw.Text(formatter.format(balance)),
                ],
              ),
            ],
            pw.SizedBox(height: 15),
            pw.Center(child: pw.Text("Thank you!", style: pw.TextStyle(fontSize: 12))),
          ],
        ),
      ),
    );

    return pdf.save();
  }
}
