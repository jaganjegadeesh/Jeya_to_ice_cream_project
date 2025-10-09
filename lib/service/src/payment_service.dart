// ignore_for_file: unused_local_variable

import 'package:aj_maintain/constant/constant.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class PaymentService {
  FirebaseFirestore firebase = FirebaseFirestore.instance;

  Future<List<Map<String, dynamic>>> getReceiptList(DateTime filterFromDate, DateTime filterToDate) async {
    final querySnapshot = await firebase
        .collection(Constants.receipt_table)
        .where(
          "date",
          isGreaterThanOrEqualTo: DateFormat(
            'yyyy-MM-dd',
          ).format(filterFromDate),
        )
        .where(
          "date",
          isLessThanOrEqualTo: DateFormat('yyyy-MM-dd').format(filterToDate),
        )
        .orderBy("date")
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
        "status": headerData['status'],
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
        "retailer_name": retailerName,
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

  Future<Map<String, dynamic>> getReceiptDetail(String billNo) async {
    try {
      final receiptCollection = firebase.collection(Constants.receipt_table);

      final query = await receiptCollection.doc(billNo).get();

      if (!query.exists) {
        return {
          "success": false,
          "error": "No return found for bill_no $billNo",
        };
      }

      final receiptDoc = query;

      return {
        "status": true,
        "header": {
          "id": receiptDoc.id,
          "bill_no": receiptDoc["bill_no"],
          "retailer_id": receiptDoc["retailer_id"],
          "retailer_name": receiptDoc['retailer_name'],
          "date": receiptDoc["date"],
          "amount": receiptDoc["amount"],
          "status": receiptDoc["status"],
        },
      };
    } catch (e) {
      return {"status": false, "error": e.toString()};
    }
  }

  Future<bool> updateReceipt({
    required String receiptId,
    required String retailerId,
    required String date,
    required int amount,
  }) async {
    try {
      final headerCollection = firebase.collection(Constants.receipt_table);
      if (receiptId.isNotEmpty) {
        var retailerSnap = await firebase
            .collection(Constants.retailer_table)
            .where("retailerId", isEqualTo: retailerId)
            .get();

        String retailerName = retailerSnap.docs.isNotEmpty
            ? retailerSnap.docs.first.data()["name"] ?? ""
            : "";
        // 🔄 Update existing return
        await headerCollection.doc(receiptId).update({
          "retailer_id": retailerId,
          "date": date,
          "retailer_name": retailerName,
          "amount": amount,
          "updateDateTime": DateTime.now().toString().substring(0, 19),
        });
        return true;
      } else {
        return false;
      }
    } catch (e) {
      return false;
    }
  }
  Future<bool> deleteReceipt(String billNo) async {
    try {
      final querySnapshot = await firebase
          .collection(Constants.receipt_table)
          .where('bill_no', isEqualTo: billNo)
          .get();

      for (var doc in querySnapshot.docs) {
        // Then delete the header document
        await doc.reference.delete();
      }
      return true;
    } catch (e) {
      return false;
    }
  }
}
