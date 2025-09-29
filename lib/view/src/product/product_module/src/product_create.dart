// ignore_for_file: use_build_context_synchronously, deprecated_member_use

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:aj_maintain/theme/theme.dart';
import 'package:aj_maintain/constant/constant.dart';
import 'package:random_string/random_string.dart';

class ProductCreate extends StatefulWidget {
  const ProductCreate({super.key});

  @override
  State<ProductCreate> createState() => _ProductCreateState();
}

class _ProductCreateState extends State<ProductCreate> {
  final _formKey = GlobalKey<FormState>();
  FirebaseFirestore firebase = FirebaseFirestore.instance;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();

  bool _isLoading = false;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final headerRef = firebase.collection(Constants.product_table);

      // 🔁 Generate next bill number
      final snapshot = await headerRef.orderBy("product_no", descending: true).limit(1).get();
      int nextNumber = 1;
      if (snapshot.docs.isNotEmpty) {
        final lastBillNo = snapshot.docs.first.data()["product_no"];
        final prefix = "AJ_P_";
        final num = int.parse(lastBillNo.replaceFirst(prefix, ""));
        nextNumber = num + 1;
      }
      final billNo = "AJ_P_${nextNumber.toString().padLeft(3, "0")}";

      await firebase.collection(Constants.product_table).add({
        "name": _nameController.text,
        "price": _priceController.text,
        "productId": randomAlphaNumeric(10),
        "product_no": billNo,
        "createdDateTime": DateTime.now().toString().substring(0, 19),
        "updateDateTime" : DateTime.now().toString().substring(0, 19),
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Align(
            alignment: Alignment.center,
            child: Text("creation Successful"),
          ),
        ),
      );

      Navigator.pop(context, true);

    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Registration failed: $e")));
    }
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
          'Add Product',
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
                      decoration: const InputDecoration(
                        labelText: 'Product Name',
                      ),
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
                      child: const Text('Add Product'),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
