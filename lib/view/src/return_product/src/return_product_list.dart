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
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    items = await _service.getReturnedList();
    setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: IconThemeData(
          color: AppTheme.appTheme.indicatorColor,
        ),
        backgroundColor: AppTheme.appTheme.primaryColor,
        title: Text(
          'Returned Products',
          style: TextStyle(
            color: AppTheme.appTheme.indicatorColor,
          ),
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
          : items.isEmpty
              ? const Center(child: Text("No return records found"))
              : ListView.separated(
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const Divider(),
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return ListTile(
                      title: Text("Bill No: ${item['bill_no']}"),
                      subtitle: Text("Retailer: ${item['retailer_name']}"),
                      trailing: Text(DateFormat('dd-MM-yyyy').format(
                        DateTime.parse(item['date']),
                      )),
                      onTap: () async {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ReturnProductUpdate(
                                headerId: item['id'].toString()),
                          ),
                        );
                        if (result == true) loadData();
                      },
                    );
                  },
                ),
    );
  }
}
