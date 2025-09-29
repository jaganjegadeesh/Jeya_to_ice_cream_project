// ignore_for_file: avoid_print

import 'package:aj_maintain/constant/constant.dart';
import 'package:aj_maintain/model/model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserService {
  FirebaseFirestore firebase = FirebaseFirestore.instance;

  /// Fetch all User
  Future<List<UserModel>> getUser() async {
    final querySnapshot = await firebase.collection(Constants.user_table).get();
    final user = querySnapshot.docs
    .map((doc) => UserModel.fromFirestore(doc))
    .toList();
    return user;
  }



  // /// Delete User
  Future<bool> deleteUser(String id) async {
    try {
      final querySnapshot = await firebase
          .collection(Constants.user_table)
          .where('userId', isEqualTo: id)
          .get();

      for (var doc in querySnapshot.docs) {
        await doc.reference.delete();
      }
      return true;
    } catch (e) {
      print('Error deleting user: $e');
      return false;
    }
  }
}
