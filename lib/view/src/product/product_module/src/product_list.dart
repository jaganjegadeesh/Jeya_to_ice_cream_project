// ignore_for_file: deprecated_member_use, use_build_context_synchronously

import 'package:aj_maintain/view/view.dart';
import 'package:flutter/material.dart';
import 'package:aj_maintain/model/model.dart';
import 'package:aj_maintain/service/service.dart';
import 'package:aj_maintain/theme/src/theme.dart';

class ProductList extends StatefulWidget {
  const ProductList({super.key});

  @override
  State<ProductList> createState() => _ProductListState();
}

class _ProductListState extends State<ProductList> {
  final ProductService _service = ProductService();
  late Future<List<Product>> _futureProducts;

  @override
  void initState() {
    super.initState();
    setState(() {
      _futureProducts = _service.getProducts();
    });
  }

  void _refreshProducts() {
    setState(() {
      _futureProducts = _service.getProducts();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: IconThemeData(color: AppTheme.appTheme.indicatorColor),
        backgroundColor: AppTheme.appTheme.primaryColor,
        title: Text(
          'Products',
          style: TextStyle(color: AppTheme.appTheme.indicatorColor),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.add, color: AppTheme.appTheme.indicatorColor),
            onPressed: () async {
              // Navigate to Add Screen, wait for result, refresh list if needed
              final result = await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProductCreate()),
              );
              if (result == true) {
                _refreshProducts();
              }
            },
          ),
        ],
      ),
      body: FutureBuilder<List<Product>>(
        future: _futureProducts,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            final products = snapshot.data!;
            return products.isEmpty
                ? const Center(child: Text("No Product Found"))
                : ListView.builder(
                    itemCount: products.length,
                    itemBuilder: (context, index) {
                      final p = products[index];
                      return ListTile(
                        leading: const Icon(Icons.image),
                        title: Text(p.name),
                        subtitle: Text('₹ ${p.price}'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              onPressed: () async {
                                final result = await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => ProductUpdate(product: p),
                                  ),
                                );
                                if (result == true) {
                                  _refreshProducts();
                                }
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () async {
                                final canDelete = await _service
                                    .getProductStatus(p.productId);
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text('Delete Product'),
                                    content: Text(
                                      canDelete == 1
                                          ? 'Are you sure you want to delete this Product?'
                                          : "Can not Delete This Product",
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(context, false),
                                        child: Text(
                                          canDelete == 1 ? 'Cancel' : "Ok",
                                        ),
                                      ),
                                      if (canDelete == 1)
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(context, true),
                                          child: const Text('Delete'),
                                        ),
                                    ],
                                  ),
                                );
                                if (confirm == true) {
                                  await _service.deleteProduct(p.productId);
                                  setState(() {
                                    _futureProducts = _service.getProducts();
                                  });
                                }
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
