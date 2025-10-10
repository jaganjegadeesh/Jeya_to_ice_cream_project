import 'package:aj_maintain/constant/constant.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class ReportService {
  FirebaseFirestore firebase = FirebaseFirestore.instance;
  Future<List<Map<String, dynamic>>> getCollectionList(
    DateTime filterFromDate,
    DateTime filterToDate,
  ) async {
    List<Map<String, dynamic>> collectionList = [];
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
        "bill_no": headerData["bill_no"],
        "date": headerData["date"],
        "amount": headerData["amount"],
        "retailer_name": headerData['retailer_name'],
        "createdDateTime": headerData['createdDateTime'],
      });
    }

    final snapshot = await firebase
        .collection(Constants.return_header_table)
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
        .orderBy("createdDateTime", descending: true)
        .get();

    final List<Map<String, dynamic>> returnedList = [];

    for (final doc in snapshot.docs) {
      final data = doc.data();
      var retailerSnap = await firebase
          .collection(Constants.retailer_table)
          .where("retailerId", isEqualTo: data["retailer_id"])
          .get();
      String retailerName = retailerSnap.docs.isNotEmpty
          ? retailerSnap.docs.first.data()["name"] ?? ""
          : "";

      returnedList.add({
        "bill_no": data["bill_no"] ?? "",
        "retailer_name": retailerName,
        "amount": data["final_amount"] ?? 0,
        "date": data["date"] ?? "",
        "createdDateTime": data['createdDateTime'],
      });
    }

    collectionList = [...receiptList, ...returnedList];

    collectionList.sort((a, b) {
      final dateA = DateTime.parse(a['createdDateTime']);
      final dateB = DateTime.parse(b['createdDateTime']);
      return dateB.compareTo(dateA); // descending (latest first)
    });

    return collectionList;
  }
}
