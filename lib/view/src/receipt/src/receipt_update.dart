// ignore_for_file: unrelated_type_equality_checks, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:aj_maintain/service/service.dart';
import 'package:aj_maintain/model/model.dart';
import 'package:aj_maintain/theme/theme.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class ReceiptUpdate extends StatefulWidget {
  final String receiptId;
  const ReceiptUpdate({super.key, required this.receiptId});

  @override
  State<ReceiptUpdate> createState() => _ReceiptUpdateState();
}

class _ReceiptUpdateState extends State<ReceiptUpdate> {
  final RetailerService _retailerService = RetailerService();
  final PaymentService _service = PaymentService();

  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  List<Map<String, dynamic>> details = [];
  List<RetailerModel> retailers = [];
  String? selectedRetailerId;
  DateTime selectedDate = DateTime.now();
  bool isLoading = false;
  bool isSubmit = false;
  String? status;

  @override
  void initState() {
    super.initState();
    _loadData();
    _dateController.text = DateFormat('yyyy-MM-dd').format(selectedDate);
  }

  @override
  void dispose() {
    _amountController.dispose();
    _dateController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => isLoading = true);
    retailers = await _retailerService.getRetailer();
    final res = await _service.getReceiptDetail(widget.receiptId);
    setState(() {
      selectedRetailerId = res['retailer_id'];
      _dateController.text = DateFormat(
        'yyyy-MM-dd',
      ).format(DateTime.parse(res['date']));
      _amountController.text = res['amount'].toString();
      status = res['status'];
      isLoading = false;
    });
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

    if (_amountController.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Please enter amount")));
      setState(() => isSubmit = false);
      return;
    }

    final int? parsedAmount = int.tryParse(_amountController.text);
    if (parsedAmount == null || parsedAmount <= 0) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Invalid amount")));
      setState(() => isSubmit = false);
      return;
    }

    final confirmed = await _service.updateReceipt(
      receiptId: widget.receiptId,
      retailerId: selectedRetailerId!,
      date: DateFormat('yyyy-MM-dd').format(selectedDate),
      amount: parsedAmount,
    );

    if (confirmed) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Receipt Update successfully!")),
      );
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Failed to Update receipt")));
      setState(() => isSubmit = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: IconThemeData(color: AppTheme.appTheme.indicatorColor),
        backgroundColor: AppTheme.appTheme.primaryColor,
        title: Text(
          'Receipt Update',
          style: TextStyle(color: AppTheme.appTheme.indicatorColor),
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(8.0),
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
                        selectedRetailerId = value;
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _dateController,
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
                              _dateController.text = DateFormat(
                                'yyyy-MM-dd',
                              ).format(picked);
                            });
                          }
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _amountController,
                    decoration: const InputDecoration(labelText: 'Amount'),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  ),
                  const SizedBox(height: 10),
                  isSubmit
                      ? const Center(child: CircularProgressIndicator())
                      : 
                      (status == '1') ? SizedBox() : ElevatedButton(
                          onPressed: _submit,
                          child: const Text('Submit'),
                        ),
                ],
              ),
            ),
    );
  }
}
