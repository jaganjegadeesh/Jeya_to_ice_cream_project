// ignore_for_file: deprecated_member_use

import 'package:aj_maintain/view/view.dart';
import 'package:flutter/material.dart';
import 'package:aj_maintain/model/model.dart';
import 'package:aj_maintain/service/service.dart';
import 'package:aj_maintain/theme/theme.dart';

class RetailerList extends StatefulWidget {
  const RetailerList({super.key});

  @override
  State<RetailerList> createState() => _RetailerListState();
}

class _RetailerListState extends State<RetailerList> {
  final RetailerService _service = RetailerService();
  late Future<List<RetailerModel>> _futureRetailer;

  @override
  void initState() {
    super.initState();
    _futureRetailer = _service.getRetailer();
  }

  void _refresh() {
    setState(() {
      _futureRetailer = _service.getRetailer();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: IconThemeData(
          color: AppTheme
              .appTheme.indicatorColor,
        ),
        backgroundColor: AppTheme.appTheme.primaryColor,
        title: Text('Retailer',
            style: TextStyle(color: AppTheme.appTheme.indicatorColor)),
        actions: [
          IconButton(
            icon: Icon(
              Icons.add,
              color: AppTheme.appTheme.indicatorColor,
            ),
            onPressed: () async {
              // Navigate to Add Screen, wait for result, refresh list if needed
              final result = await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const RetailerCreate()),
              );
              if (result == true) {
                _refresh();
              }
            },
          )
        ],
      ),
      body: FutureBuilder<List<RetailerModel>>(
        future: _futureRetailer,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            final retailerList = snapshot.data!;
            return ListView.builder(
              itemCount: retailerList.length,
              itemBuilder: (context, index) {
                final s = retailerList[index];
                return ListTile(
                  leading: const Icon(Icons.person),
                  title: Text(s.name),
                  subtitle: Text('Phone: ${s.phone} | %: ${s.percentage}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => RetailerUpdate(retailerModel: s),
                            ),
                          );
                          if (result == true) _refresh();
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () async {
                          // await _service.deleteRetailer(s.id);
                          // _refresh();
                        },
                      ),
                    ],
                  ),
                );
              },
            );
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          return const Center(child: CircularProgressIndicator());
        },
      ),
    );
  }
}
