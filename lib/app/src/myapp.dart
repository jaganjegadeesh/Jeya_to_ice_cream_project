// ignore_for_file: unused_import

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'package:aj_maintain/model/model.dart';
import 'package:aj_maintain/firebase_options.dart';
import 'package:aj_maintain/service/service.dart';
import 'package:aj_maintain/theme/theme.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:aj_maintain/view/view.dart';
import 'package:aj_maintain/constant/constant.dart';

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _login = false;
  bool _loading = true;
  UserModel? user;
  FirebaseFirestore firebase = FirebaseFirestore.instance;
  String? role = "user";

  @override
  void initState() {
    super.initState();
    initaialfun();
  }

  void fetchData() async {
    _login = await Db.checkLogin();


    if (_login == true) {
      dynamic userData = await Db.getData();
      var doc = await firebase
          .collection(Constants.user_table)
          .doc(userData?['userId'])
          .get();

      if (doc.exists) {
        user = UserModel.fromJson(doc.data()!);
      }
      setState(() {
        role = user?.role;
      });
    }
    setState(() {
      _loading = false;
    });
  }

  void initaialfun() {
    fetchData();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Jeya ToDay',
      theme: AppTheme.appTheme,
      debugShowCheckedModeBanner: false,
      home: _loading
          ? Scaffold(
              body: Center(
                child: LoadingAnimationWidget.threeArchedCircle(
                  color: const Color.fromARGB(255, 252, 75, 75),
                  size: 60,
                ),
              ),
            )
          : _login
          ? AdminDashboard()
          : const Login(),
    );
  }
}
