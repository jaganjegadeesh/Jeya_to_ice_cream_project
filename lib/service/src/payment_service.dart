// ignore_for_file: unused_local_variable

import 'package:aj_maintain/constant/constant.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PaymentService {
  FirebaseFirestore firebase = FirebaseFirestore.instance;

  Future<List<Map<String, dynamic>>> getReceiptList() async {
    final querySnapshot = await firebase
        .collection(Constants.receipt_table)
        .orderBy("bill_no", descending: true)
        .get();

    List<Map<String, dynamic>> receiptList = [];

    for (var doc in querySnapshot.docs) {
      var headerData = doc.data();

      receiptList.add({
        "id": doc.id,
        "bill_no": headerData["bill_no"],
        "date": headerData["date"],
        "total_amount": headerData["amount"],
        "retailer_name": headerData['retailer_name'],
      });
    }

    return receiptList;
  }

  Future<bool> createReceipt({
    required String retailerId,
    required String date,
    required int amount,
  }) async {
    try {
      final headerRef = firebase.collection(Constants.receipt_table);

      // 🔁 Generate next bill number
      final snapshot = await headerRef
          .orderBy("bill_no", descending: true)
          .limit(1)
          .get();
      int nextNumber = 1;
      if (snapshot.docs.isNotEmpty) {
        final lastBillNo = snapshot.docs.first.data()["bill_no"];
        final prefix = "AJ_R_";
        final num = int.parse(lastBillNo.replaceFirst(prefix, ""));
        nextNumber = num + 1;
      }
      final billNo = "AJ_R_${nextNumber.toString().padLeft(3, "0")}";
      var retailerSnap = await firebase
          .collection(Constants.retailer_table)
          .where("retailerId", isEqualTo: retailerId)
          .get();

      String retailerName = retailerSnap.docs.isNotEmpty
          ? retailerSnap.docs.first.data()["name"] ?? ""
          : "";

      final newHeader = await headerRef.add({
        "bill_no": billNo,
        "retailer_id": retailerId,
        "retailer_name" : retailerName,
        "date": date,
        "amount": amount,
        "status": "0",
        "createdDateTime": DateTime.now().toString().substring(0, 19),
        "updateDateTime": DateTime.now().toString().substring(0, 19),
      });
     

      return true;
    } catch (e) {
      return false;
    }
  }
}