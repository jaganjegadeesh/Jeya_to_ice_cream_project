// ignore_for_file: use_build_context_synchronously

import 'package:aj_maintain/view/view.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:aj_maintain/theme/theme.dart';
import 'package:aj_maintain/service/service.dart';

class ReceiptList extends StatefulWidget {
  const ReceiptList({super.key});

  @override
  State<ReceiptList> createState() => _ReceiptListState();
}

class _ReceiptListState extends State<ReceiptList> {
  final PaymentService _service = PaymentService();
  List<Map<String, dynamic>> receiptList = [];
  bool isLoading = false;
  DateTime filterFromDate = DateTime.now().subtract(const Duration(days: 7));
  DateTime filterToDate = DateTime.now();
  @override
  void initState() {
    super.initState();
    loadReceipt();
  }

  Future<void> loadReceipt() async {
    setState(() {
      isLoading = true;
    });
    receiptList = await _service.getReceiptList(filterFromDate,filterToDate);
    setState(() {
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: IconThemeData(
          color: AppTheme
              .appTheme
              .indicatorColor,
        ),
        backgroundColor: AppTheme.appTheme.primaryColor,
        title: Text(
          "Receipt",
          style: TextStyle(color: AppTheme.appTheme.indicatorColor),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.add, color: AppTheme.appTheme.indicatorColor),
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ReceiptCreate()),
              );

              if (result == true) {
                loadReceipt();
              }
            },
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
            children: [
              SizedBox(height: 20,),
              Row(
                  children: [
                    SizedBox(width: 10,),
                    Expanded(
                      child: TextFormField(
                        readOnly: true,
                        decoration: InputDecoration(
                          labelText: 'From Date',
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.calendar_today),
                            onPressed: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: filterFromDate,
                                firstDate: DateTime(2025),
                                lastDate: filterToDate,
                              );
                              if (picked != null) {
                                setState(() {
                                  filterFromDate = picked;
                                });
                                loadReceipt();
                              }
                            },
                          ),
                        ),
                        controller: TextEditingController(
                          text: DateFormat('yyyy-MM-dd').format(filterFromDate),
                        ),
                      ),
                    ),
                    SizedBox(width: 10,),
                    Expanded(
                      child: TextFormField(
                        readOnly: true,
                        decoration: InputDecoration(
                          labelText: 'To Date',
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.calendar_today),
                            onPressed: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: filterToDate,
                                firstDate: filterFromDate,
                                lastDate: DateTime.now(),
                              );
                              if (picked != null) {
                                setState(() {
                                  filterToDate = picked;
                                });
                                loadReceipt();
                              }
                            },
                          ),
                        ),
                        controller: TextEditingController(
                          text: DateFormat('yyyy-MM-dd').format(filterToDate),
                        ),
                      ),
                    ),
                    SizedBox(width: 10,),
                  ],
                ),
              SizedBox(height: 20,),
              receiptList.isEmpty
              ? const Center(child: Text("No Receipt found"))
              : Expanded(
                child: ListView.builder(
                    itemCount: receiptList.length,
                    itemBuilder: (context, index) {
                      final item = receiptList[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        child: ListTile(
                          title: Text("Bill No: ${item['bill_no']}"),
                          subtitle: Text("Retailer: ${item['retailer_name']}"),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text("₹${item['total_amount']}"),
                                  Text(
                                    DateFormat(
                                      'dd-MM-yyyy',
                                    ).format(DateTime.parse(item['date'])),
                                  ),
                                ],
                              ),
                              IconButton(
                                icon: Icon(Icons.delete, color: Colors.red),
                                onPressed: () async {
                                  // Confirm before deleting
                                  await showDialog<bool>(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: const Text('Delete Recepit'),
                                      content: Text(
                                        item['status'] == '0' ?
                                        'Are you sure you want to delete this receipt?' : "Can't Delete This",
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(context, false),
                                          child: Text(item['status'] == '0' ? 'Cancel' : 'ok'),
                                        ),
                                        if(item['status'] == '0' )
                                        TextButton(
                                          onPressed: () async => {
                                            await _service.deleteReceipt(
                                              item['bill_no'],
                                            ),
                                            await loadReceipt(),
                                              Navigator.pop(context, true),
                                          },
                                          child: const Text('Delete'),
                                        ),
                                      ],
                                    ),
                                  );
                                 
                                },
                              ),
                            ],
                          ),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    ReceiptUpdate(receiptId: item['id']),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
              ),
            ],
          ),
    );
  }
}
