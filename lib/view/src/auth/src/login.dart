// ignore_for_file: use_build_context_synchronously, deprecated_member_use

import 'dart:io';
import 'package:aj_maintain/constant/constant.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:aj_maintain/model/model.dart';
import 'package:aj_maintain/service/service.dart';
import 'package:aj_maintain/view/view.dart';

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  FirebaseFirestore firebase = FirebaseFirestore.instance;

  bool _isLoading = false;
  bool _rememberMe = false;
  bool _obscureText = true;

  String email = "";
  String password = "";

  /// 🔹 Firestore Login Validation
  validation() async {
    setState(() {
      _isLoading = true;
    });

    UserModel? user;
    var id = "";

    var data = await firebase
        .collection(Constants.user_table)
        .where('email', isEqualTo: email)
        .get();

    if (data.docs.isNotEmpty) {
      for (var i in data.docs) {
        user = UserModel.fromJson(i.data());
        id = i.id;
      }
    }

    if (user?.password != password) {
      setState(() {
        _isLoading = false;
      });
      return ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Invalid Email or Password")),
      );
    } else {
      LoginModel model = LoginModel(
        id: id,
        userId: user?.userId,
        email: email,
        password: password,
        name: user?.name,
        phone: user?.phone,
        dob: user?.dob,
        gender: user?.gender,
        role: user?.role,
      );
      await Db.setLogin(model: model);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Align(
            alignment: Alignment.center,
            child: Text("Login Successful"),
          ),
        ),
      );

      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const AdminDashboard()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (!didPop) exit(0);
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFFF6F61),
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                flex: 3,
                child: Container(
                  color: const Color(0xFFFF6F61),
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: Container(
                      height: 80,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(60),
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // 🔹 White form section
              Expanded(
                flex: 10,
                child: Container(
                  width: double.infinity,
                  color: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 30,
                    vertical: 20,
                  ),
                  child: SingleChildScrollView(
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Sign in",
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Container(
                            height: 2,
                            width: 60,
                            color: Color(0xFFFF6F61),
                            margin: const EdgeInsets.only(top: 4, bottom: 30),
                          ),

                          // Email
                          const Text(
                            "Email",
                            style: TextStyle(fontWeight: FontWeight.w500),
                          ),
                          TextFormField(
                            decoration: const InputDecoration(
                              prefixIcon: Icon(Icons.email_outlined),
                              hintText: "demo@email.com",
                              border: UnderlineInputBorder(),
                              fillColor: Colors.transparent
                            ),
                            validator: (String? value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your email';
                              } else {
                                email = value;
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

                          // Password
                          const Text(
                            "Password",
                            style: TextStyle(fontWeight: FontWeight.w500),
                          ),
                          TextFormField(
                            obscureText: _obscureText,
                            decoration: InputDecoration(
                              prefixIcon: const Icon(Icons.lock_outline),
                              hintText: "Enter your password",
                              border: const UnderlineInputBorder(),
                              fillColor: Colors.transparent,
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscureText
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscureText = !_obscureText;
                                  });
                                },
                              ),
                            ),
                            validator: (String? value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your password';
                              } else {
                                password = value;
                                return null;
                              }
                            },
                          ),
                          const SizedBox(height: 10),

                          // Remember Me + Forgot
                          Row(
                            children: [
                              Checkbox(
                                value: _rememberMe,
                                onChanged: (val) {
                                  setState(() {
                                    _rememberMe = val ?? false;
                                  });
                                },
                                activeColor: const Color(0xFFFF6F61),
                              ),
                              const Text("Remember Me"),
                            ],
                          ),
                          const SizedBox(height: 20),

                          // Login Button with loader
                          _isLoading
                              ? Center(
                                  child:
                                      LoadingAnimationWidget.threeArchedCircle(
                                        color: const Color(0xFFFF6F61),
                                        size: 50,
                                      ),
                                )
                              : SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFFFF6F61),
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 16,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    onPressed: () {
                                      if (_formKey.currentState!.validate()) {
                                        validation();
                                      }
                                    },
                                    child: const Text(
                                      "Login",
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                          const SizedBox(height: 20),

                          // Google Button
                        ],
                      ),
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
