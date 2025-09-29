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
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadReceipt();
  }

  Future<void> loadReceipt() async {
    receiptList = await _service.getReceiptList();
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
          : receiptList.isEmpty
          ? const Center(child: Text("No Receipt found"))
          : ListView.builder(
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
                                title: const Text('Delete Assignment'),
                                content: const Text(
                                  'Are you sure you want to delete this assignment?',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(context, false),
                                    child: const Text('Cancel'),
                                  ),
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(context, true),
                                    child: const Text('Delete'),
                                  ),
                                ],
                              ),
                            );
                            // if (confirm == true) {
                            //   await _service.deleteAssignProduct(
                            //     item['bill_no'],
                            //   );
                            //   await loadReceipt();
                            // }
                          },
                        ),
                      ],
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              AssignProductUpdate(id: item['id']),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
    );
  }
}
