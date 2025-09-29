// ignore_for_file: use_build_context_synchronously, deprecated_member_use

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:aj_maintain/theme/theme.dart';
import 'package:aj_maintain/constant/constant.dart';
import 'package:random_string/random_string.dart';

class RetailerCreate extends StatefulWidget {
  const RetailerCreate({super.key});

  @override
  State<RetailerCreate> createState() => _RetailerCreateState();
}

class _RetailerCreateState extends State<RetailerCreate> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _percentageController = TextEditingController();
  FirebaseFirestore firebase = FirebaseFirestore.instance;

  bool _isLoading = false;



  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
    });

    

    try {
      await firebase.collection(Constants.retailer_table).add({
        "name": _nameController.text,
        "phone": _phoneController.text,
        "password": _passwordController.text,
        "percentage": _percentageController.text,
        "retailerId": randomAlphaNumeric(10),
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

    Navigator.pop(context, true);
    
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar( iconTheme: IconThemeData(
          color: AppTheme
              .appTheme.indicatorColor, // ✅ This changes the back button color
        ),
        backgroundColor: AppTheme.appTheme.primaryColor,
        title: Text(
          'Add Retailer',
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
                        validator: (v) => v == null || v.isEmpty ? 'Enter name' : null,
                      ),
                      
                      TextFormField(
                        controller: _phoneController,
                        decoration: const InputDecoration(labelText: 'Phone'),
                        validator: (v) => v == null || v.isEmpty ? 'Enter phone' : null,
                      ),
                      TextFormField(
                        controller: _passwordController,
                        decoration: const InputDecoration(labelText: 'Password'),
                        obscureText: true,
                        validator: (v) => v == null || v.isEmpty ? 'Enter password' : null,
                      ),
                        TextFormField(
                          controller: _percentageController,
                          decoration: const InputDecoration(labelText: 'Percentage'),
                          keyboardType: TextInputType.number,
                          validator: (v) => (v == null || v.isEmpty)
                                  ? 'Enter percentage'
                                  : null,
                        ),
                      
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _submit,
                        child: const Text('Add Retailer'),
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}
