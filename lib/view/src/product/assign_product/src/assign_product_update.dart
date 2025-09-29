// ignore_for_file: avoid_print, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:aj_maintain/theme/theme.dart';
import 'package:aj_maintain/service/service.dart';

class AssignProductUpdate extends StatefulWidget {
  final String id;
  const AssignProductUpdate({super.key, required this.id});

  @override
  State<AssignProductUpdate> createState() => _AssignProductUpdateState();
}

class _AssignProductUpdateState extends State<AssignProductUpdate> {
  final ProductService _service = ProductService();
  Map<String, dynamic>? data;
  bool isLoading = true;
  bool isEditMode = false;
  bool issave = false;

  @override
  void initState() {
    super.initState();
    loadDetail();
  }

  Future<void> loadDetail() async {
    data = await _service.getAssignDetail(widget.id);

    // Deep copy and calculate subtotal
    data!['details'] = (data!['details'] as List).map((item) {
      final quantity = int.tryParse(item['quantity'].toString()) ?? 0;
      final price = double.tryParse(item['price'].toString()) ?? 0.0;
      return {
        'productId': item['productId'],
        'name': item['name'],
        'price': price,
        'quantity': quantity,
        'subtotal': quantity * price,
      };
    }).toList();
    print(data!['details']);
    _recalculateTotal();
    setState(() => isLoading = false);

  }

  void _recalculateTotal() {
    final List<Map<String, dynamic>> details = List<Map<String, dynamic>>.from(
      data!['details'],
    );

    double total = details.fold(0.0, (double sum, Map<String, dynamic> item) {
      return sum + (item['subtotal'] as num).toDouble();
    });

    data!['header']['total_amount'] = total;
  }

  @override
  Widget build(BuildContext context) {
    final header = data?['header'];
    final details = data?['details'] ?? [];

    return Scaffold(
      appBar: AppBar(
        iconTheme: IconThemeData(color: AppTheme.appTheme.indicatorColor),
        backgroundColor: AppTheme.appTheme.primaryColor,
        title: Text(
          "Assigned Bill Detail",
          style: TextStyle(color: AppTheme.appTheme.indicatorColor),
        ),
        actions: [
          if(!isLoading && !issave)
          IconButton(
            icon: Icon(
              isEditMode ? Icons.save : Icons.edit,
              color: AppTheme.appTheme.indicatorColor,
            ),
            onPressed: () async {
              if (isEditMode) {
                // Save all updated rows to backend
                bool allSuccess = true;
                setState(() => issave = true);
                for (var item in data!['details']) {
                  final res = await _service.updateQuantity(
                    headerId: header['id'],
                    productId: item['productId'].toString(),
                    quantity: item['quantity'],
                  );
                  if (res['status'] != true) {
                    allSuccess = false;
                    break;
                  }
                }

                if (allSuccess) {
                  _recalculateTotal();
                  setState(() => isEditMode = false);
                  setState(() => issave = false);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Bill updated successfully')),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Update failed')),
                  );
                }
              } else {
                setState(() => isEditMode = true);
              }
            },
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                Column(
                  children: [
                    ListTile(
                      title: Text("Bill No: ${header['bill_no']}"),
                      subtitle: Text("Retailer: ${header['retailer_name']}"),
                      trailing: Text(
                        DateFormat(
                          'dd-MM-yyyy',
                        ).format(DateTime.parse(header['date'])),
                      ),
                    ),
                    const Divider(),
                    Expanded(
                      child: ListView.separated(
                        itemCount: details.length,
                        separatorBuilder: (_, __) => const Divider(),
                        itemBuilder: (context, index) {
                          final item = details[index];

                          return Padding(
                            key: ValueKey(item['id']),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8.0,
                              vertical: 6,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item['name'],
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Row(
                                  children: [
                                    Expanded(
                                      child: Padding(
                                        padding: const EdgeInsets.only(
                                          top: 10.0,
                                        ),
                                        child: TextFormField(
                                          initialValue: item['quantity']
                                              .toString(),
                                          enabled: isEditMode,
                                          keyboardType: TextInputType.number,
                                          decoration: const InputDecoration(
                                            labelText: 'Quantity',
                                          ),
                                          onChanged: (val) {
                                            final qty = int.tryParse(val) ?? 0;
                                            final price = item['price'] ?? 0.0;
                                            setState(() {
                                              item['quantity'] = qty;
                                              item['subtotal'] = qty * price;
                                              _recalculateTotal();
                                            });
                                          },
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      '₹${item['subtotal'].toStringAsFixed(2)}',
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                    const Divider(),
                    Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            "Total:",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            "₹${header['total_amount'].toStringAsFixed(2)}",
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (issave)
                  Center(
                    child: Container(
                      color: Colors.black.withOpacity(0.5),
                      child: const Center(child: CircularProgressIndicator()),
                    ),
                  ),
              ],
            ),
    );
  }
}
