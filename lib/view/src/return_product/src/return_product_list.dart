import 'package:aj_maintain/view/view.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:aj_maintain/service/service.dart';
import 'package:aj_maintain/theme/theme.dart';

class ReturnProductList extends StatefulWidget {
  const ReturnProductList({super.key});

  @override
  State<ReturnProductList> createState() => _ReturnProductListState();
}

class _ReturnProductListState extends State<ReturnProductList> {
  final ProductService _service = ProductService();
  List<Map<String, dynamic>> items = [];
  bool isLoading = false;
  DateTime filterFromDate = DateTime.now().subtract(const Duration(days: 7));
  DateTime filterToDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    setState(() => isLoading = true);
    items = await _service.getReturnedList(filterFromDate, filterToDate);
    setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: IconThemeData(color: AppTheme.appTheme.indicatorColor),
        backgroundColor: AppTheme.appTheme.primaryColor,
        title: Text(
          'Returned Products',
          style: TextStyle(color: AppTheme.appTheme.indicatorColor),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () async {
              // Navigate to Add screen and refresh after return
              final result = await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ReturnProductCreate()),
              );
              if (result == true) loadData();
            },
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                SizedBox(height: 20),
                Row(
                  children: [
                    SizedBox(width: 10),
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
                                loadData();
                              }
                            },
                          ),
                        ),
                        controller: TextEditingController(
                          text: DateFormat('yyyy-MM-dd').format(filterFromDate),
                        ),
                      ),
                    ),
                    SizedBox(width: 10),
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
                                loadData();
                              }
                            },
                          ),
                        ),
                        controller: TextEditingController(
                          text: DateFormat('yyyy-MM-dd').format(filterToDate),
                        ),
                      ),
                    ),
                    SizedBox(width: 10),
                  ],
                ),
                SizedBox(height: 20),
                items.isEmpty
                    ? const Center(child: Text("No return records found"))
                    : Expanded(
                        child: ListView.builder(
                          itemCount: items.length,
                          itemBuilder: (context, index) {
                            final item = items[index];
                            return Card(
                              margin: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              child: ListTile(
                                title: Text("Bill No: ${item['bill_no']}"),
                                subtitle: Text(
                                  "Retailer: ${item['retailer_name']}",
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text("₹${item['final_amount']}"),
                                        Text(
                                          DateFormat('dd-MM-yyyy').format(
                                            DateTime.parse(item['date']),
                                          ),
                                        ),
                                      ],
                                    ),
                                    IconButton(
                                      icon: Icon(
                                        Icons.delete,
                                        color: Colors.red,
                                      ),
                                      onPressed: () async {
                                        // Confirm before deleting
                                        final confirm = await showDialog<bool>(
                                          context: context,
                                          builder: (context) => AlertDialog(
                                            title: const Text(
                                              'Delete Assignment',
                                            ),
                                            content: const Text(
                                              'Are you sure you want to delete this assignment?',
                                            ),
                                            actions: [
                                              TextButton(
                                                onPressed: () => Navigator.pop(
                                                  context,
                                                  false,
                                                ),
                                                child: const Text('Cancel'),
                                              ),
                                              TextButton(
                                                onPressed: () => Navigator.pop(
                                                  context,
                                                  true,
                                                ),
                                                child: const Text('Delete'),
                                              ),
                                            ],
                                          ),
                                        );
                                        if (confirm == true) {
                                          await _service.deleteReturnProduct(
                                            item['bill_no'],
                                          );
                                          await loadData();
                                        }
                                      },
                                    ),
                                  ],
                                ),
                                onTap: () async {
                                  final result = await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => ReturnProductUpdate(
                                        headerId: item['id'].toString(),
                                      ),
                                    ),
                                  );
                                  if (result == true) loadData();
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
