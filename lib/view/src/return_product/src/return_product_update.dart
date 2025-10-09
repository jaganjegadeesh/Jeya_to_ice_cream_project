// ignore_for_file: deprecated_member_use, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:aj_maintain/theme/theme.dart';
import 'package:aj_maintain/service/service.dart';
// import 'package:printing/printing.dart';
import 'package:blue_thermal_printer/blue_thermal_printer.dart';

class ReturnProductUpdate extends StatefulWidget {
  final String headerId;
  const ReturnProductUpdate({super.key, required this.headerId});

  @override
  State<ReturnProductUpdate> createState() => _ReturnProductUpdateState();
}

class _ReturnProductUpdateState extends State<ReturnProductUpdate> {
  final ProductService _service = ProductService();
  BlueThermalPrinter printer = BlueThermalPrinter.instance;

  Map<String, dynamic>? header;
  List<Map<String, dynamic>> details = [];

  bool isLoading = true;
  double? advance;
  String? receiptIds;
  @override
  void initState() {
    super.initState();

    loadDetail();
  }

  Future<void> loadDetail() async {
    final res = await _service.getReturnDetail(widget.headerId);
    if (res['status']) {
      header = res['header'];
      details = List<Map<String, dynamic>>.from(res['details']);
    }

    // try {
    //   bool? isConnected = await printer.isConnected;
    //   if (!isConnected!) {
    //     List<BluetoothDevice> devices = await printer.getBondedDevices();
    //     BluetoothDevice? targetPrinter = devices.firstWhere(
    //       (d) => d.name!.contains("KP306A-UB"),
    //       orElse: () => devices.first,
    //     );
    //     await printer.connect(targetPrinter);
    //   }
    // } catch (e) {
    //   ScaffoldMessenger.of(
    //     context,
    //   ).showSnackBar(SnackBar(content: Text("Cannot connect to printer")));
    // }
    setState(() => isLoading = false);
  }

  // Future<void> previewReturnReceipt(
  //   Map<String, dynamic>? header,
  //   List<Map<String, dynamic>> details,
  // ) async {
  //   final pdfBytes = await PdfService.generateReturnReceiptPdf(header, details);
  //   await Printing.layoutPdf(onLayout: (format) async => pdfBytes);
  // }

  Future<void> printReturnReceipt(
    BuildContext context,
    Map<String, dynamic>? header,
    List<Map<String, dynamic>> details,
  ) async {
    // 🟩 OPTION 1: Direct Thermal (faster)
    await PdfService.printThermalReceipt(
      context: context,
      header: header!,
      details: details,
    );
  }

  Future<void> updateReturn() async {
    double total = details.fold(
      0.0,
      (sum, item) => sum + (item['amount'] ?? 0.0),
    );
    double percent =
        double.tryParse(header?['percentage'].toString() ?? '0') ?? 0.0;
    double finalAmount = total - (total * percent / 100);

    final result = await _service.saveReturn(
      id: widget.headerId,
      retailerId: header?['retailer_id'].toString() ?? '',
      date: header?['date'] ?? '',
      total: total,
      advance: header?['advance'],
      finalAmount: finalAmount,
      percentage: percent,
      products: details,
      receiptIds : receiptIds!
    );

    if (result['success']) {
      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Return updated successfully')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message'] ?? 'Update failed')),
      );
    }
  }

  double get subtotal =>
      details.fold(0.0, (sum, item) => sum + (item['amount'] ?? 0.0));
  double get percentageAmount {
    final percent =
        double.tryParse(header?['percentage'].toString() ?? '0') ?? 0.0;
    return subtotal * percent / 100;
  }

  double get total => subtotal - percentageAmount;
  double get advanceTotal => total - header?['advance'];

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Edit Return',
          style: TextStyle(color: AppTheme.appTheme.indicatorColor),
        ),
        iconTheme: IconThemeData(color: AppTheme.appTheme.indicatorColor),
        backgroundColor: AppTheme.appTheme.primaryColor,
        actions: [
          IconButton(
            icon: Icon(Icons.print, color: AppTheme.appTheme.indicatorColor),
            onPressed: () async {
              await printReturnReceipt(context, header, details);
            },
          ),
          IconButton(icon: const Icon(Icons.check), onPressed: updateReturn),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Retailer Name: ${header?['retailer_name']}'),
            Text('Date: ${header?['date']}'),
            Text('Bill No: ${header?['bill_no']}'),
            const Divider(),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    DataTable(
                      columnSpacing: 10,
                      columns: const [
                        DataColumn(label: Text('Product')),
                        DataColumn(label: Text('Qty')),
                        DataColumn(label: Text('Return')),
                        DataColumn(label: Text('Balance')),
                        DataColumn(label: Text('Price')),
                        DataColumn(label: Text('Amount')),
                      ],
                      rows: details.map((item) {
                        final qty =
                            int.tryParse(item['quantity'].toString()) ?? 0;
                        final returnQty =
                            int.tryParse(item['return_quantity'].toString()) ??
                            0;
                        final price =
                            double.tryParse(item['price'].toString()) ?? 0.0;
                        final balance = qty - returnQty;
                        item['amount'] = balance * price;
                    
                        return DataRow(
                          cells: [
                            DataCell(Text(item['name'])),
                            DataCell(Text(qty.toString())),
                            DataCell(
                              SizedBox(
                                width: 70,
                                child: TextFormField(
                                  initialValue: returnQty.toString(),
                                  keyboardType: TextInputType.number,
                                  onChanged: (val) {
                                    setState(() {
                                      item['return_quantity'] =
                                          int.tryParse(val) ?? 0;
                                    });
                                  },
                                ),
                              ),
                            ),
                            DataCell(Text(balance.toString())),
                            DataCell(Text("₹${price.toStringAsFixed(2)}")),
                            DataCell(
                              Text("₹${item['amount'].toStringAsFixed(2)}"),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                    const Divider(),
                    Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "Subtotal:",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 17,
                              ),
                            ),
                            Text(
                              "₹${subtotal.toStringAsFixed(2)}",
                              style: TextStyle(fontSize: 17),
                            ),
                          ],
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "Retailer % Cut (${header?['percentage']}%): ₹${percentageAmount.toStringAsFixed(2)}",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 17,
                              ),
                            ),
                            Text(
                              "₹${percentageAmount.toStringAsFixed(2)}",
                              style: TextStyle(fontSize: 17),
                            ),
                          ],
                        ),
                        const Divider(),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "Total:",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 17,
                              ),
                            ),
                            Text(
                              "₹${total.toStringAsFixed(2)}",
                              style: TextStyle(fontSize: 17),
                            ),
                          ],
                        ),
                        if (header?['advance'] != 0 &&
                            header?['advance'] != null) ...[
                          const Divider(),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "Recived:",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 17,
                                ),
                              ),
                              Text(
                                "₹${header?['advance']}",
                                style: TextStyle(fontSize: 17),
                              ),
                            ],
                          ),
                          const Divider(),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "Total:",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 17,
                                ),
                              ),
                              Text(
                                "₹${advanceTotal.toStringAsFixed(2)}",
                                style: TextStyle(fontSize: 17),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
