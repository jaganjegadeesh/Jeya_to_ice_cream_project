// ignore_for_file: use_build_context_synchronously

import 'package:aj_maintain/model/model.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:aj_maintain/service/service.dart';
import 'package:aj_maintain/theme/theme.dart';

class ReturnProductCreate extends StatefulWidget {
  const ReturnProductCreate({super.key});

  @override
  State<ReturnProductCreate> createState() => _ReturnProductCreateState();
}

class _ReturnProductCreateState extends State<ReturnProductCreate> {
  final ProductService _returnService = ProductService();
  final RetailerService _retailerService = RetailerService();

  List<RetailerModel> retailers = [];
  List<Map<String, dynamic>> assignedProducts = [];
  List<Map<String, dynamic>> selectedProducts = [];

  String? selectedRetailerId;
  String billNo = '';
  String receiptIds = '';
  String assignIds = '';
  DateTime selectedDate = DateTime.now();
  bool isLoading = false;
  bool ischangeRetailer = false;
  double percent = 0.0;
  double? advance;
  bool isSubmit = false;

  @override
  void initState() {
    super.initState();
    loadRetailers();
  }

  Future<void> loadRetailers() async {
    final result = await _retailerService.getReturnRetailer();
    setState(() {
      retailers = result;
    });
  }

  Future<void> loadAssignedProducts(String retailerId) async {
    setState(() => ischangeRetailer = true);
    assignedProducts = await _returnService.getAssignedProductsForRetailer(
      retailerId,
    );
    // Get percentage value via API call
    final percentageData = await _retailerService.getRetailersPercentage(
      retailerId,
    );
    percent = double.tryParse(percentageData['percentage'].toString()) ?? 0.0;
    Map<String, Map<String, dynamic>> productMap = {};

    final recivedList = await _retailerService.getRetailerAdvance(retailerId);
    final recived = recivedList['total'];
    receiptIds = recivedList['ids'];
    var ids = '';
    for (var item in assignedProducts) {
      var details = item['details'] as List<dynamic>;
      for (var detail in details) {
        final id = detail['productId'].toString();
        final name = detail['name'];
        final quantity = int.tryParse(detail['quantity'].toString()) ?? 0;
        final price = double.tryParse(detail['price'].toString()) ?? 0.0;
        if(quantity > 0) {
          if (productMap.containsKey(id)) {
            productMap[id]!['quantity'] += quantity;
          } else {
            productMap[id] = {
              'product_id': id,
              'name': name,
              'quantity': quantity,
              'price': price,
              'return_quantity': 0,
              'amount': 0.0,
            };
          }
        }
        ids = item['assignIds'];
      }
    }

    selectedProducts = productMap.values.toList();
    calculateTotal();
    setState(() {
      assignIds = ids;
    });
    setState(() => ischangeRetailer = false);
    setState(() => advance = recived);

  }

  void calculateTotal() {
    for (var item in selectedProducts) {
      final returnQty = item['return_quantity'];
      final quantity = item['quantity'];
      final price = item['price'];
      final balance = quantity - returnQty;
      item['amount'] = balance * price;
    }
  }

  double get subtotal =>
      selectedProducts.fold(0.0, (sum, item) => sum + item['amount']);
  double get percentageAmount => subtotal * percent / 100;
  double get total => subtotal - percentageAmount;
  double get advanceTotal => total - advance!;

  Future<void> submitReturn() async {
    setState(() => isSubmit = true);
    if (selectedRetailerId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Please select a retailer")));
      setState(() => isSubmit = false);
      return;
    }
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Confirm"),
        content: const Text("Are you sure you want to submit this return?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text("Yes, Submit"),
          ),
        ],
      ),
    );

    if (confirm != true) {
      setState(() => isSubmit = false);
      return;
    }
    final response = await _returnService.saveReturn(
      retailerId: selectedRetailerId!,
      date: DateFormat('yyyy-MM-dd').format(selectedDate),
      total: subtotal,
      billTotal: total,
      advance: advance!,
      finalAmount: advanceTotal,
      percentage: percent,
      products: selectedProducts,
      receiptIds: receiptIds,
      assignIds : assignIds
    );

    if (response['success'] == true) {
      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Return submitted successfully')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(response['error'] ?? 'Submission failed')),
      );
      setState(() => isSubmit = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: IconThemeData(
          color: AppTheme
              .appTheme
              .indicatorColor, // ✅ This changes the back button color
        ),
        backgroundColor: AppTheme.appTheme.primaryColor,
        title: Text(
          'Add Return',
          style: TextStyle(color: AppTheme.appTheme.indicatorColor),
        ),
        actions: [
          isSubmit
              ? const Center(child: CircularProgressIndicator())
              : IconButton(
                  icon: const Icon(Icons.check),
                  onPressed: submitReturn,
                ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            DropdownButtonFormField<String>(
              value: (retailers.any((r) => r.retailerId == selectedRetailerId))
                  ? selectedRetailerId
                  : null, // prevents mismatch crash
              decoration: const InputDecoration(labelText: 'Retailer'),
              items: retailers
                  .map(
                    (r) => DropdownMenuItem<String>(
                      value: r.retailerId,
                      child: Text("${r.name} - ${r.phone}"),
                    ),
                  )
                  .toList(),
              onChanged: (value) async {
                setState(() {
                  selectedRetailerId = value;
                });
                await loadAssignedProducts(value!);
              },
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Text("Date: "),
                Text(DateFormat('dd-MM-yyyy').format(selectedDate)),
                IconButton(
                  icon: const Icon(Icons.calendar_today),
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2100),
                    );
                    if (picked != null) {
                      setState(() => selectedDate = picked);
                    }
                  },
                ),
              ],
            ),
            const Divider(),
            ischangeRetailer
                ? const Center(child: CircularProgressIndicator())
                : Expanded(
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
                            rows: selectedProducts.map((item) {
                              final qty = item['quantity'];
                              final returnQty = item['return_quantity'];
                              final balance = qty - returnQty;
                              return DataRow(
                                cells: [
                                  DataCell(Text(item['name'])),
                                  DataCell(Text(qty.toString())),
                                  DataCell(
                                    SizedBox(
                                      width: 50,
                                      child: StatefulBuilder(
                                        builder: (context, setInnerState) {
                                          int currentQty =
                                              item['return_quantity'] ??
                                              returnQty;
                          
                                          return TextFormField(
                                            initialValue: currentQty
                                                .toString(),
                                            keyboardType:
                                                TextInputType.number,
                                            style: TextStyle(
                                              color: currentQty >= qty
                                                  ? Colors.red
                                                  : Colors
                                                        .black, // text color
                                            ),
                                            decoration: InputDecoration(
                                              isDense: true,
                                              contentPadding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                    vertical: 8,
                                                  ),
                                              enabledBorder: OutlineInputBorder(
                                                borderSide: BorderSide(
                                                  color: currentQty >= qty
                                                      ? Colors.red
                                                      : Colors
                                                            .grey, // normal border
                                                ),
                                              ),
                                              focusedBorder: OutlineInputBorder(
                                                borderSide: BorderSide(
                                                  color: currentQty >= qty
                                                      ? Colors.red
                                                      : Colors
                                                            .blue, // focus border
                                                  width: 2,
                                                ),
                                              ),
                                            ),
                                            onChanged: (val) {
                                              final newQty =
                                                  int.tryParse(val) ?? 0;
                                              setState(() {
                                                item['return_quantity'] =
                                                    newQty;
                                                calculateTotal();
                                              });
                                              setInnerState(
                                                () {},
                                              ); // rebuild inner state to refresh color & border
                                            },
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                                  DataCell(Text(balance.toString())),
                                  DataCell(
                                    Text(
                                      "₹${item['price'].toStringAsFixed(2)}",
                                    ),
                                  ),
                                  DataCell(
                                    Text(
                                      "₹${item['amount'].toStringAsFixed(2)}",
                                    ),
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
                                    "Retailer % Cut ($percent%):",
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
                              if (advance != 0 && advance != null) ...[
                                const Divider(),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      "Recived:",
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 17,
                                      ),
                                    ),
                                    Text(
                                      "₹${advance?.toStringAsFixed(2)}",
                                      style: TextStyle(fontSize: 17),
                                    ),
                                  ],
                                ),
                                const Divider(),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
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
