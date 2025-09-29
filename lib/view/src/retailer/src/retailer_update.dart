// ignore_for_file: use_build_context_synchronously, deprecated_member_use

import 'package:flutter/material.dart';
import 'package:aj_maintain/model/model.dart';
import 'package:aj_maintain/theme/theme.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:aj_maintain/constant/constant.dart';

class RetailerUpdate extends StatefulWidget {
  final RetailerModel retailerModel;

  const RetailerUpdate({super.key, required this.retailerModel});

  @override
  State<RetailerUpdate> createState() => _RetailerUpdateState();
}

class _RetailerUpdateState extends State<RetailerUpdate> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _passwordController;
  late TextEditingController _percentageController;
  FirebaseFirestore firebase = FirebaseFirestore.instance;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.retailerModel.name);
    _phoneController = TextEditingController(text: widget.retailerModel.phone);
    _passwordController = TextEditingController();
    _percentageController =
        TextEditingController(text: widget.retailerModel.percentage);
  }


  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });
    final querySnapshot = await firebase
        .collection(Constants.retailer_table)
        .where('retailerId', isEqualTo: widget.retailerModel.retailerId)
        .get();

    for (var doc in querySnapshot.docs) {
      await doc.reference.update({
        "name": _nameController.text,
        "phone": _phoneController.text,
        "password": _passwordController.text,
        "percentage": _percentageController.text,
        "updateDateTime" : DateTime.now().toString().substring(0, 19),
      });
    }

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
          'Edit Retailer',
          style: TextStyle(color: AppTheme.appTheme.indicatorColor),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(labelText: 'Name'),
                        validator: (v) =>
                            v == null || v.isEmpty ? 'Enter name' : null,
                      ),
                      TextFormField(
                        controller: _phoneController,
                        decoration: const InputDecoration(labelText: 'Phone'),
                        validator: (v) =>
                            v == null || v.isEmpty ? 'Enter phone' : null,
                      ),
                      TextFormField(
                        controller: _passwordController,
                        decoration:
                            const InputDecoration(labelText: 'Password'),
                        obscureText: true,
                        validator: (v) =>
                            v == null || v.isEmpty ? 'Enter password' : null,
                      ),
                      TextFormField(
                        controller: _percentageController,
                        decoration:
                            const InputDecoration(labelText: 'Percentage'),
                        keyboardType: TextInputType.number,
                        validator: (v) => v == null || v.isEmpty
                            ? 'Enter percentage'
                            : null,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _submit,
                        child: const Text('Update Staff'),
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}
