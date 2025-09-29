// ignore_for_file: use_build_context_synchronously, deprecated_member_use

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:aj_maintain/model/model.dart';
import 'package:aj_maintain/theme/theme.dart';
import 'package:aj_maintain/constant/constant.dart';

class ProductUpdate extends StatefulWidget {
  final Product product;

  const ProductUpdate({super.key, required this.product});

  @override
  State<ProductUpdate> createState() => _ProductUpdateState();
}

class _ProductUpdateState extends State<ProductUpdate> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _priceController;
  FirebaseFirestore firebase = FirebaseFirestore.instance;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.product.name);
    _priceController = TextEditingController(text: widget.product.price);
  }


  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    final querySnapshot = await firebase
        .collection(Constants.product_table)
        .where('productId', isEqualTo: widget.product.productId)
        .get();

    for (var doc in querySnapshot.docs) {
      await doc.reference.update({
        "name": _nameController.text,
        "price": _priceController.text,
        "updateDateTime" : DateTime.now().toString().substring(0, 19),
      });
    }

    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });

    Navigator.pop(context, true);
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
        title: Text(
          'Edit Product',
          style: TextStyle(color: AppTheme.appTheme.indicatorColor),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _nameController,
                      decoration:
                          const InputDecoration(labelText: 'Product Name'),
                      validator: (value) =>
                          value == null || value.isEmpty ? 'Enter name' : null,
                    ),
                    TextFormField(
                      controller: _priceController,
                      decoration: const InputDecoration(labelText: 'Price'),
                      keyboardType: TextInputType.number,
                      validator: (value) =>
                          value == null || value.isEmpty ? 'Enter price' : null,
                    ),
                    const SizedBox(height: 16),
                   
                    ElevatedButton(
                      onPressed: _submit,
                      child: const Text('Update Product'),
                    )
                  ],
                ),
              ),
      ),
    );
  }
}
