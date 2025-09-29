// ignore_for_file: must_be_immutable, non_constant_identifier_names, unused_import, use_build_context_synchronously
import 'dart:io';
import 'package:aj_maintain/model/model.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
// ignore: depend_on_referenced_packages
import 'package:aj_maintain/theme/theme.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:intl/intl.dart';
import 'package:aj_maintain/view/view.dart';
import 'package:aj_maintain/constant/constant.dart';

class UserUpdate extends StatefulWidget {
  String userId;

  UserUpdate({super.key, required this.userId});
  @override
  State<UserUpdate> createState() => _UserUpdateState();
}

class _UserUpdateState extends State<UserUpdate> {
  bool _isLoading = false;
  Map<String, String>? user_data;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _name = TextEditingController();
  final TextEditingController _email = TextEditingController();
  final TextEditingController _phone = TextEditingController();
  FirebaseFirestore firebase = FirebaseFirestore.instance;
  final TextEditingController _gender = TextEditingController();
  final TextEditingController _role = TextEditingController();
  final TextEditingController _dob = TextEditingController();
  bool _formSubmitted = false;
  UserModel? user;
  String? login_user_role;

  @override
  void initState() {
    initaialfun();

    super.initState();
  }

  void fetchData() async {
    login_user_role = await Constants.login_user_role;
    setState(() {});
    var doc = await firebase
        .collection(Constants.user_table)
        .where('userId', isEqualTo: widget.userId)
        .get();

    if (doc.docs.isNotEmpty) {
      user = UserModel.fromJson(doc.docs.first.data());
    }
    if (user != null) {
      setState(() {
        _name.text = (user?.name ?? '');
        _email.text = (user?.email ?? '');
        _phone.text = (user?.phone ?? '');
        _dob.text = (user?.dob ?? '');
        _gender.text = (user?.gender ?? '');
        _role.text = (user?.role ?? '');
      });
    }
  }

  void initaialfun() {
    fetchData();
  }

  Future<void> updatevalidation(BuildContext context) async {
    setState(() {
      _isLoading = true;
    });
    final querySnapshot = await firebase
        .collection(Constants.user_table)
        .where('userId', isEqualTo: widget.userId)
        .get();

    for (var doc in querySnapshot.docs) {
      await doc.reference.update({
        "email": _email.text,
        "phone": _phone.text,
        "name": _name.text,
        "dob": _dob.text,
        "gender": _gender.text,
        "role": _role.text,
        "updateDateTime": DateTime.now().toString().substring(0, 19),
        "createdDateTime": DateTime.now().toString().substring(0, 19),
      });
    }

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Align(
          alignment: Alignment.center,
          child: Text("Changes Success"),
        ),
      ),
    );

    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Update User",
          style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
        ),
      ),
      body: Container(
        alignment: Alignment.centerLeft,
        child: SingleChildScrollView(
          child: Column(
            children: [
              Form(
                key: _formKey,
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.all(Radius.circular(50)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.only(left: 20, right: 20),
                    child: Column(
                      children: [
                        const SizedBox(height: 25),
                        TextFormField(
                          controller: _name,
                          decoration: const InputDecoration(
                            label: Text("Name"),
                            enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: Colors.black12),
                              borderRadius: BorderRadius.all(
                                Radius.circular(12),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: Colors.blue),
                              borderRadius: BorderRadius.all(
                                Radius.circular(12),
                              ),
                            ),
                            errorBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: Colors.red),
                              borderRadius: BorderRadius.all(
                                Radius.circular(12),
                              ),
                            ),
                            border: OutlineInputBorder(
                              borderSide: BorderSide(color: Colors.black),
                              borderRadius: BorderRadius.all(
                                Radius.circular(12),
                              ),
                            ),
                          ),
                          validator: (String? value) {
                            if (value == null || value.isEmpty) {
                              return 'Enter the Name';
                            } else {
                              return null;
                            }
                          },
                        ),
                        const SizedBox(height: 20),
                        TextFormField(
                          controller: _email,
                          decoration: const InputDecoration(
                            label: Text("E-mail"),
                            enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: Colors.black12),
                              borderRadius: BorderRadius.all(
                                Radius.circular(12),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: Colors.blue),
                              borderRadius: BorderRadius.all(
                                Radius.circular(12),
                              ),
                            ),
                            errorBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: Colors.red),
                              borderRadius: BorderRadius.all(
                                Radius.circular(12),
                              ),
                            ),
                            border: OutlineInputBorder(
                              borderSide: BorderSide(color: Colors.black),
                              borderRadius: BorderRadius.all(
                                Radius.circular(12),
                              ),
                            ),
                          ),
                          validator: (String? value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your email';
                            } else {
                              final regexEmail = RegExp(
                                r"^[a-zA-Z0-9._%-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,4}$",
                              );

                              if (!regexEmail.hasMatch(value)) {
                                return 'Invalid email';
                              } else {
                                return null;
                              }
                            }
                          },
                        ),
                        const SizedBox(height: 20),
                        TextFormField(
                          controller: _phone,
                          decoration: const InputDecoration(
                            label: Text("Phone"),
                            enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: Colors.black12),
                              borderRadius: BorderRadius.all(
                                Radius.circular(12),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: Colors.blue),
                              borderRadius: BorderRadius.all(
                                Radius.circular(12),
                              ),
                            ),
                            border: OutlineInputBorder(
                              borderSide: BorderSide(color: Colors.black),
                              borderRadius: BorderRadius.all(
                                Radius.circular(12),
                              ),
                            ),
                            errorBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: Colors.red),
                              borderRadius: BorderRadius.all(
                                Radius.circular(12),
                              ),
                            ),
                          ),
                          validator: (String? value) {
                            if (value == null || value.isEmpty) {
                              return 'Enter the Phone';
                            } else {
                              return null;
                            }
                          },
                        ),
                        const SizedBox(height: 15),
                        TextFormField(
                          controller: _dob,
                          readOnly: true,
                          onTap: () async {
                            DateTime? pickedDate = await showDatePicker(
                              context: context,
                              initialDate: DateTime.now(),
                              firstDate: DateTime(1900),
                              lastDate: DateTime(2100),
                            );

                            if (pickedDate != null) {
                              _dob.text = DateFormat(
                                'dd-MM-yyyy',
                              ).format(pickedDate);
                            }
                          },
                          decoration: const InputDecoration(
                            label: Text("Date of birth"),
                            enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: Colors.black12),
                              borderRadius: BorderRadius.all(
                                Radius.circular(12),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: Colors.blue),
                              borderRadius: BorderRadius.all(
                                Radius.circular(12),
                              ),
                            ),
                            errorBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: Colors.red),
                              borderRadius: BorderRadius.all(
                                Radius.circular(12),
                              ),
                            ),
                            border: OutlineInputBorder(
                              borderSide: BorderSide(color: Colors.black),
                              borderRadius: BorderRadius.all(
                                Radius.circular(12),
                              ),
                            ),
                          ),
                          validator: (String? value) {
                            if (value == null || value.isEmpty) {
                              return 'Select a Date';
                            } else {
                              return null;
                            }
                          },
                        ),
                        const SizedBox(height: 15),
                        SizedBox(
                          width: double.infinity,
                          child: SegmentedButton<String>(
                            style: SegmentedButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                              side: const BorderSide(
                                color: Colors.grey,
                              ), // optional: adds border
                              backgroundColor: Colors
                                  .grey[200], // optional: background color
                            ),
                            segments: const <ButtonSegment<String>>[
                              ButtonSegment<String>(
                                value: 'Male',
                                label: Text('Male'),
                                icon: Icon(Icons.man_outlined),
                              ),
                              ButtonSegment<String>(
                                value: 'Female',
                                label: Text('Female'),
                                icon: Icon(Icons.woman_2_rounded),
                              ),
                            ],
                            selected: <String>{_gender.text},
                            onSelectionChanged: (Set<String> newSelection) {
                              setState(() {
                                _gender.text = newSelection.first;
                              });
                            },
                          ),
                        ),
                        if (_gender.text.isEmpty && _formSubmitted)
                          const Align(
                            alignment: Alignment.topLeft,
                            child: Padding(
                              padding: EdgeInsets.only(top: 5.0),
                              child: Text(
                                'Please select your gender.',
                                style: TextStyle(color: Colors.red),
                              ),
                            ),
                          ),
                        const SizedBox(height: 15),
                        DropdownButtonFormField<String>(
                          initialValue: _role.text.isNotEmpty
                              ? _role.text
                              : null,
                          decoration: InputDecoration(
                            labelText: "Role",
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                          ),
                          items: [
                          if (_role.text != 'Super Admin')
                            const DropdownMenuItem(
                              value: "",
                              child: Row(
                                children: [
                                  SizedBox(width: 8),
                                  Text("Select Role"),
                                ],
                              ),
                            ),
                            if (_role.text == 'Super Admin')
                              const DropdownMenuItem(
                                value: "Super Admin",
                                child: Row(
                                  children: [
                                    SizedBox(width: 8),
                                    Text("Super Admin"),
                                  ],
                                ),
                              ),
                            if (login_user_role == 'Super Admin' && _role.text != 'Super Admin')
                              const DropdownMenuItem(
                                value: "Admin",
                                child: Row(
                                  children: [SizedBox(width: 8), Text("Admin")],
                                ),
                              ),
                            if ((login_user_role == 'Admin' ||
                                login_user_role == 'Super Admin') && _role.text != 'Super Admin')
                              const DropdownMenuItem(
                                value: "Staff",
                                child: Row(
                                  children: [SizedBox(width: 8), Text("Staff")],
                                ),
                              ),
                          ],
                          onChanged: (String? newValue) {
                            setState(() {
                              _role.text = newValue ?? "";
                            });
                          },
                        ),
                        if (_role.text.isEmpty && _formSubmitted)
                          const Align(
                            alignment: Alignment.topLeft,
                            child: Padding(
                              padding: EdgeInsets.only(top: 5.0),
                              child: Text(
                                'Please select your Role.',
                                style: TextStyle(color: Colors.red),
                              ),
                            ),
                          ),
                        const SizedBox(height: 30),
                        _isLoading
                            ? Center(
                                child: LoadingAnimationWidget.fallingDot(
                                  color: const Color.fromARGB(255, 252, 75, 75),
                                  size: 50,
                                ),
                              )
                            : ElevatedButton(
                                statesController: WidgetStatesController(),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primaryColor,
                                  shadowColor: const Color.fromARGB(
                                    255,
                                    224,
                                    224,
                                    167,
                                  ),
                                  shape: const RoundedRectangleBorder(
                                    borderRadius: BorderRadius.all(
                                      Radius.circular(10),
                                    ),
                                  ),
                                ),
                                onPressed: () {
                                  setState(() {
                                    _formSubmitted = true;
                                  });

                                  if (_formKey.currentState!.validate() &&
                                      _gender.text.isNotEmpty) {
                                    updatevalidation(context);
                                  }
                                },
                                child: Text(
                                  "Confirm",
                                  style: TextStyle(
                                    color: AppColors.secondaryColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                        const SizedBox(height: 30),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
