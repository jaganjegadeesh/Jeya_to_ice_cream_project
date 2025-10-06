// ignore_for_file: use_build_context_synchronously

import 'package:blue_thermal_printer/blue_thermal_printer.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class PdfService {
  static final BlueThermalPrinter printer = BlueThermalPrinter.instance;

  static Future<void> printThermalReceipt({
    required BuildContext context,
    required Map<String, dynamic> header,
    required List<Map<String, dynamic>> details,
  }) async {
    bool? connected = await printer.isConnected;

    // 🔹 Ask user to connect manually if not already connected
    if (connected != true) {
      List<BluetoothDevice> devices = await printer.getBondedDevices();

      if (devices.isEmpty) {
        // Ask user to pair first
        await printer.openSettings;
        return;
      }

      BluetoothDevice? selected = await showDialog<BluetoothDevice>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text("Select Printer"),
          content: SingleChildScrollView(
            scrollDirection: Axis.vertical,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: devices
                  .map(
                    (d) => ListTile(
                      title: Text(d.name ?? "Unknown"),
                      subtitle: Text(d.address ?? ""),
                      onTap: () => Navigator.pop(ctx, d),
                    ),
                  )
                  .toList(),
            ),
          ),
        ),
      );

      if (selected == null) return;
      await printer.connect(selected);
    }

    // 🔹 Format numbers
    final formatter = NumberFormat.currency(locale: 'en_IN', symbol: 'Rs.');

    double subtotal = details.fold(
      0.0,
      (sum, item) => sum + ((item['amount'] ?? 0.0) as double),
    );
    double percent =
        double.tryParse(header['percentage']?.toString() ?? '0') ?? 0.0;
    double percentageAmount = subtotal * percent / 100;
    double total = subtotal - percentageAmount;
    double advance = double.tryParse(header['advance']?.toString() ?? '0') ?? 0;
    double balance = total - advance;

    // 🔹 Begin Printing
    await printer.printNewLine();
    await printer.printCustom("Return Receipt", 2, 1); // size=2, center
    await printer.printNewLine();

    await printer.printLeftRight(
        "Retailer:", header['retailer_name'] ?? "", 1);
    await printer.printLeftRight("Date:", header['date'] ?? "", 1);
    await printer.printLeftRight("Bill No:", header['bill_no'] ?? "", 1);
    await printer.printNewLine();

    await printer.printCustom("--------------------------------", 1, 1);
    await printer.printLeftRight("Product", "Qty Ret Bal Amt", 1);
    await printer.printCustom("--------------------------------", 1, 1);

    // 🔹 Print each item line
    for (final item in details) {
      final qty = int.tryParse(item['quantity'].toString()) ?? 0;
      final ret = int.tryParse(item['return_quantity'].toString()) ?? 0;
      final price = double.tryParse(item['price'].toString()) ?? 0.0;
      final bal = qty - ret;
      final amt = bal * price;

      final line1 = item['name'].toString().trim();
      await printer.printCustom(line1, 1, 0);
      final line2 =
          "${qty.toString().padLeft(3)} ${ret.toString().padLeft(3)} ${bal.toString().padLeft(3)} ${amt.toStringAsFixed(2).padLeft(7)}";
      await printer.printCustom(line2, 1, 2);
    }

    await printer.printCustom("--------------------------------", 1, 1);

    await printer.printLeftRight("Subtotal:", formatter.format(subtotal), 1);
    await printer.printLeftRight(
        "Retailer Cut (${header['percentage']}%):",
        formatter.format(percentageAmount),
        1);
    await printer.printLeftRight("Total:", formatter.format(total), 1);

    if (advance != 0) {
      await printer.printLeftRight("Received:", formatter.format(advance), 1);
      await printer.printLeftRight("Balance:", formatter.format(balance), 1);
    }

    await printer.printNewLine();
    await printer.printCustom("Thank You!", 1, 1);
    await printer.printNewLine();
    await printer.paperCut();

    await printer.disconnect();
  }
}
