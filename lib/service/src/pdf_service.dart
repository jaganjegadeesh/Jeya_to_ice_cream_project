// ignore_for_file: use_build_context_synchronously

import 'dart:typed_data';
import 'package:flutter/services.dart';
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

    if (connected != true) {
      List<BluetoothDevice> devices = await printer.getBondedDevices();
      if (devices.isEmpty) {
        await printer.openSettings;
        return;
      }

      BluetoothDevice? selected = await showDialog<BluetoothDevice>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text("Select Printer"),
          content: SingleChildScrollView(
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

    // 🔹 Load and resize logo (smaller = safer)
    ByteData logoBytes = await rootBundle.load('assets/icons/aj_low_icon.png');
    Uint8List logoData = logoBytes.buffer.asUint8List();

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

    try {
      await printer.printNewLine();
      await printer.printImageBytes(logoData);
      await printer.printNewLine();
      await printer.printCustom("JEYA TODAY ICE CREAM ", 2, 1);
      await printer.printCustom("COMPANY, Sivakasi", 1, 1);
      await printer.printNewLine();

      String left(String label, String value) {
        const totalWidth = 32;
        return (label.padRight(35) + value).padRight(totalWidth);
      }

      await printer.printCustom(
        left("Retailer:", header['retailer_name'] ?? ""),
        1,
        0,
      );
      await printer.printCustom(left("Date:", header['date'] ?? ""), 1, 0);
      await printer.printCustom(
        left("Bill No:", header['bill_no'] ?? ""),
        1,
        0,
      );
      await printer.printNewLine();

      await printer.printCustom(
        "--------------------------------------------",
        1,
        1,
      );
      await printer.printCustom(
        "Product                Qty Ret Bal  Amt  ",
        1,
        1,
      );
      await printer.printCustom(
        "--------------------------------------------",
        1,
        1,
      );

      for (final item in details) {
        final qty = int.tryParse(item['quantity'].toString()) ?? 0;
        final ret = int.tryParse(item['return_quantity'].toString()) ?? 0;
        final price = double.tryParse(item['price'].toString()) ?? 0.0;
        final bal = qty - ret;
        final amt = bal * price;

        final maxNameLen = 20; // Adjust for 80mm printer
        final shortName = item['name'].length > maxNameLen
            ? item['name'].substring(0, maxNameLen - 1)
            : item['name'].padRight(maxNameLen);

        // 🔹 Format line to stay aligned
        final line =
            "$shortName ${qty.toString().padLeft(3)} ${ret.toString().padLeft(3)} ${bal.toString().padLeft(3)} ${amt.toStringAsFixed(2).padLeft(7)}";

        await printer.printCustom(line, 1, 1);
      }

      await printer.printCustom(
        "--------------------------------------------",
        1,
        1,
      );
      await printer.printCustom(
        left("Subtotal:", formatter.format(subtotal)),
        1,
        0,
      );
      await printer.printCustom(
        left(
          "Retailer Cut (${header['percentage']}%):",
          formatter.format(percentageAmount),
        ),
        1,
        0,
      );
      await printer.printCustom(left("  ", "-----------"), 1, 0);
      await printer.printCustom(left("Total:", formatter.format(total)), 1, 0);

      if (advance != 0) {
        await printer.printCustom(
          left("Received:", formatter.format(advance)),
          1,
          0,
        );
        await printer.printCustom(left("  ", "-----------"), 1, 0);
        await printer.printCustom(
          left("Balance:", formatter.format(balance)),
          1,
          0,
        );
      }

      await printer.printNewLine();
      await printer.printCustom("Thank You!", 1, 1);
      await printer.printNewLine();

      // ⚠️ Some printers crash on paperCut() — comment it out
      // await printer.paperCut();

      // Wait a bit before disconnecting (ensure all data sent)
      await Future.delayed(const Duration(seconds: 2));

      await printer.disconnect();
    } catch (e) {
      debugPrint("Thermal print error: $e");
    }
  }
}
