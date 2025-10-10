// ignore_for_file: avoid_print

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:aj_maintain/constant/constant.dart';
import 'package:aj_maintain/model/model.dart';

class RetailerService {
  FirebaseFirestore firebase = FirebaseFirestore.instance;

  /// Fetch all staff
  Future<List<RetailerModel>> getRetailer() async {
    final querySnapshot = await firebase
        .collection(Constants.retailer_table)
        .get();
    final retailer = querySnapshot.docs
        .map((doc) => RetailerModel.fromJson(doc.data()))
        .toList();
    return retailer;
  }

  Future getRetailersPercentage(String retailerId) async {
    try {
      final querySnapshot = await firebase
          .collection(Constants.retailer_table)
          .where('retailerId', isEqualTo: retailerId)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        var percent = querySnapshot.docs.first.data()['percentage'];
        return {'percentage': percent};
      } else {
        return {'percentage': 0};
      }
    } catch (e) {
      return {'percentage': 0};
    }
  }

  Future<List<RetailerModel>> getReturnRetailer() async {
    final querySnapshot = await firebase
        .collection(Constants.assign_header_table)
        .where('status', isEqualTo: 'assigned')
        .get();

    // collect retailer IDs from assign_header_table
    final retailerIds = querySnapshot.docs
        .map((doc) => doc.data()['retailer_id'] as String?)
        .toList();

    if (retailerIds.isEmpty) {
      return [];
    }

    // query retailer_table with those IDs
    final retailerQuery = await firebase
        .collection(Constants.retailer_table)
        .where('retailerId', whereIn: retailerIds)
        .get();

    // build retailer models from retailer_table
    final retailers = retailerQuery.docs
        .map((doc) => RetailerModel.fromJson(doc.data()))
        .toList();

    return retailers;
  }

  Future<Map<String, dynamic>> getRetailerAdvance(String retailerId) async {
    String ids = '';
    double total = 0;
    try {
      final querySnapshot = await firebase
          .collection(Constants.receipt_table)
          .where('status', isEqualTo: '0')
          .where('retailer_id', isEqualTo: retailerId)
          .get();
      if (querySnapshot.docs.isNotEmpty) {
        for (var doc in querySnapshot.docs) {
          final amount = double.tryParse(doc.data()['amount'].toString()) ?? 0;
          if (ids.isEmpty) {
            ids = doc.id;
          } else {
            ids = "$ids,${doc.id}";
          }
          total += amount;
        }

        return {'total': total, 'ids': ids};
      } else {
        return {'total': total, 'ids': ids};
      }
    } catch (e) {
      return {'total': total, 'ids': ids};
    }
  }

  Future<bool> deleteRetailer(id) async {
    try {
      final querySnapshot = await firebase
          .collection(Constants.retailer_table)
          .where('retailerId', isEqualTo: id)
          .get();

      for (var doc in querySnapshot.docs) {
        await doc.reference.delete();
      }
      return true;
    } catch (e) {
      return false;
    }
  }

  Future getRetailerStatus(String retailerId) async {
    final querySnapshot = await firebase
        .collection(Constants.assign_header_table)
        .where("retailer_id", isEqualTo: retailerId)
        .get();
    if (querySnapshot.docs.isNotEmpty) {
      return 0;
    } else {
      return 1;
    }
  }
}
