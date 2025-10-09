import 'package:aj_maintain/view/view.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:aj_maintain/theme/theme.dart';
import 'package:aj_maintain/service/service.dart';

class AssignProductList extends StatefulWidget {
  const AssignProductList({super.key});

  @override
  State<AssignProductList> createState() => _AssignProductListState();
}

class _AssignProductListState extends State<AssignProductList> {
  final ProductService _service = ProductService();
  List<Map<String, dynamic>> assignedList = [];
  bool isLoading = false;
  DateTime filterFromDate = DateTime.now().subtract(const Duration(days: 7));
  DateTime filterToDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    loadAssigned();
  }

  Future<void> loadAssigned() async {
    setState(() {
      isLoading = true;
    });
    assignedList = await _service.getAssignedList(filterFromDate, filterToDate);
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
              .indicatorColor, // ✅ This changes the back button color
        ),
        backgroundColor: AppTheme.appTheme.primaryColor,
        title: Text(
          "Assigned Products",
          style: TextStyle(color: AppTheme.appTheme.indicatorColor),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.add, color: AppTheme.appTheme.indicatorColor),
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AssignProductCreate()),
              );

              if (result == true) {
                loadAssigned();
              }
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
                                loadAssigned();
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
                                loadAssigned();
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
                SizedBox(height: 10),
                assignedList.isEmpty
                    ? const Center(child: Text("No assignments found"))
                    : Expanded(
                        child: ListView.builder(
                          itemCount: assignedList.length,
                          itemBuilder: (context, index) {
                            final item = assignedList[index];
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
                                        Text("₹${item['total_amount']}"),
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
                                          await _service.deleteAssignProduct(
                                            item['bill_no'],
                                          );
                                          await loadAssigned();
                                        }
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
                      ),
              ],
            ),
    );
  }
}
