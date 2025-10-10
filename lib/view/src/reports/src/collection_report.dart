import 'package:aj_maintain/service/service.dart';
import 'package:aj_maintain/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class CollectionReport extends StatefulWidget {
  const CollectionReport({super.key});

  @override
  State<CollectionReport> createState() => _CollectionReportState();
}

class _CollectionReportState extends State<CollectionReport> {
  final ReportService _service = ReportService();
  List<Map<String, dynamic>> collectionList = [];
  bool isLoading = false;
  DateTime filterFromDate = DateTime.now().subtract(const Duration(days: 7));
  DateTime filterToDate = DateTime.now();
  double total = 0;
  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    setState(() {
      isLoading = true;
    });
    collectionList = await _service.getCollectionList(
      filterFromDate,
      filterToDate,
    );
    double totalAmount = collectionList.fold(
      0,
      (sum, item) => sum + (item['amount'] ?? 0),
    );
    setState(() {
      isLoading = false;
      total = totalAmount;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: IconThemeData(color: AppTheme.appTheme.indicatorColor),
        backgroundColor: AppTheme.appTheme.primaryColor,
        title: Text(
          "Collections",
          style: TextStyle(color: AppTheme.appTheme.indicatorColor),
        ),
      ),
      body: Column(
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
          isLoading
              ? Center(child: CircularProgressIndicator())
              : collectionList.isEmpty
              ? const Center(child: Text("No Collection found"))
              : Expanded(
                  child: ListView.builder(
                    itemCount: collectionList.length,
                    itemBuilder: (context, index) {
                      final item = collectionList[index];

                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        child: ListTile(
                          title: Text(
                            "Bill No : ${item['bill_no']}\nRetailer : ${item['retailer_name']}\nDate : ${DateFormat('dd-MM-yyyy').format(DateTime.parse(item['date']))}",
                            style: const TextStyle(fontWeight: FontWeight.w300),
                          ),
                          trailing: Text(
                            "₹${item['amount']}",
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
          isLoading
              ? SizedBox(height: 10)
              : Column(
                  children: [
                    const Divider(color: Colors.black),
                    Padding(
                      padding: const EdgeInsets.only(
                        bottom: 60,
                        left: 20,
                        right: 20,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            "Total :",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            "₹$total",
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
        ],
      ),
    );
  }
}
