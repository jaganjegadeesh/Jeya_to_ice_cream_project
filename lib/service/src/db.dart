// ignore_for_file: unused_import

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:aj_maintain/model/model.dart';

class Db {
  static Future<SharedPreferences> connect() async {
    return await SharedPreferences.getInstance();
  }

  static Future<bool> checkLogin() async {
    var cn = await connect();
    bool? r = cn.getBool('login');
    return r ?? false;
  }

  static Future setLogin({required LoginModel model}) async {
    var cn = await connect();
    cn.setString('email', model.email ?? "");
    cn.setString('password', model.password ?? "");
    cn.setString('name', model.name ?? "");
    cn.setString('phone', model.phone ?? "");
    cn.setString('dob', model.dob ?? "");
    cn.setString('role', model.role ?? "");
    cn.setString('gender', model.gender ?? "");
    cn.setString('userId', model.userId ?? "");
    cn.setBool('login', true);

  }

  static Future<Map<String, String>?> getData() async {
    var cn = await connect();
    final String? email = cn.getString('email');
    final String? name = cn.getString('name');
    final String? phone = cn.getString('phone');
    final String? dob = cn.getString('dob');
    final String? gender = cn.getString('gender');
    final String? role = cn.getString('role');
    final String? userId = cn.getString('userId');
    if (email != null &&
        name != null &&
        phone != null &&
        userId != null &&
        gender != null &&
        dob != null &&
        role != null) {
      return {
        'email': email,
        'name': name,
        'phone': phone,
        'userId': userId,
        'gender': gender,
        'role': role,
        'dob': dob,
      };
    } else {
      return null;
    }
  }

  static Future<bool> clearDb() async {
    var cn = await connect();
    return cn.clear();
  }
}
