// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:aj_maintain/theme/theme.dart';
import 'package:aj_maintain/service/service.dart';
import 'package:aj_maintain/model/model.dart';

class AssignProductCreate extends StatefulWidget {
  const AssignProductCreate({super.key});

  @override
  State<AssignProductCreate> createState() => _AssignProductCreateState();
}

class _AssignProductCreateState extends State<AssignProductCreate> {
  final ProductService _service = ProductService();
  final RetailerService _retailerService = RetailerService();

  List<RetailerModel> retailers = [];
  List<Product> products = [];

  String? selectedRetailerId;
  DateTime selectedDate = DateTime.now();

  final Map<String, TextEditingController> _qtyControllers = {};

  bool isLoading = false;
  bool isSubmit = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => isLoading = true);
    retailers = await _retailerService.getRetailer();
    products = await _service.getProducts();
    // Initialize qty controllers
    for (var product in products) {
      _qtyControllers[product.productId] = TextEditingController(text: '0');
    }

    setState(() => isLoading = false);
  }

  double _calculateTotal() {
    double total = 0.0;
    for (var product in products) {
      final productId = product.productId;
      final price = double.tryParse(product.price.toString()) ?? 0.0;
      final qty = int.tryParse(_qtyControllers[productId]?.text ?? '0') ?? 0;
      total += price * qty;
    }
    return total;
  }

  Future<void> _submit() async {
    setState(() => isSubmit = true);
    if (selectedRetailerId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Please select a retailer")));
      setState(() => isSubmit = false);
      return;
    }

    List<Map<String, dynamic>> selectedProducts = [];
    for (var product in products) {
      final productId = product.productId;
      final productNo = product.product_no;
      final price = product.price;
      final qty = int.tryParse(_qtyControllers[productId]?.text ?? '0') ?? 0;
      selectedProducts.add({
        "productId": productId,
        "productNo": productNo,
        "quantity": qty.toString(),
        "price": price.toString(),
      });
    }

    if (selectedProducts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please enter quantity for at least one product"),
        ),
      );
      setState(() => isSubmit = false);
      return;
    }
    final confirmed = await _service.assignProducts(
      retailerId: selectedRetailerId!,
      date: DateFormat('yyyy-MM-dd').format(selectedDate),
      selectedProducts: selectedProducts,
    );

    if (confirmed) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Products assigned successfully!")),
      );
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to assign products")),
      );
      setState(() => isSubmit = false);
    }
  }

  @override
  void dispose() {
    for (var controller in _qtyControllers.values) {
      controller.dispose();
    }
    super.dispose();
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
          'Assign Products',
          style: TextStyle(color: AppTheme.appTheme.indicatorColor),
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                children: [
                  DropdownButtonFormField<String>(
                    value: selectedRetailerId,
                    decoration: const InputDecoration(labelText: 'Retailer'),
                    items: retailers
                        .map(
                          (r) => DropdownMenuItem<String>(
                            value: r.retailerId,
                            child: Text("${r.name} - ${r.phone}"),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedRetailerId = value!;
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    readOnly: true,
                    decoration: InputDecoration(
                      labelText: 'Date',
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.calendar_today),
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: selectedDate,
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2100),
                          );
                          if (picked != null) {
                            setState(() {
                              selectedDate = picked;
                            });
                          }
                        },
                      ),
                    ),
                    controller: TextEditingController(
                      text: DateFormat('yyyy-MM-dd').format(selectedDate),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: ListView(
                      children: products.map((product) {
                        final productId = product.productId;
                        final name = product.name;
                        final price =
                            double.tryParse(product.price.toString()) ?? 0.0;
                        final qty =
                            int.tryParse(
                              _qtyControllers[productId]?.text ?? '0',
                            ) ??
                            0;
                        final subtotal = price * qty;

                        return Card(
                          child: ListTile(
                            title: Text('$name (₹$price)'),
                            subtitle: Padding(
                              padding: const EdgeInsets.only(top: 10.0),
                              child: TextField(
                                controller: _qtyControllers[productId],
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  labelText: 'Quantity',
                                ),
                                onChanged: (_) => setState(() {}),
                              ),
                            ),
                            trailing: Text('₹${subtotal.toStringAsFixed(2)}'),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Total: ₹${_calculateTotal().toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 10),
                  isSubmit
                      ? const Center(child: CircularProgressIndicator())
                      : ElevatedButton(
                          onPressed: _submit,
                          child: const Text('Assign Products'),
                        ),
                ],
              ),
            ),
    );
  }
}
