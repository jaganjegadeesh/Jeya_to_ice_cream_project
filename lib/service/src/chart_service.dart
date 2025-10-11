import 'package:aj_maintain/constant/constant.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class ChartService {
  FirebaseFirestore firebase = FirebaseFirestore.instance;
  DateTime filterFromDate = DateTime.now().subtract(const Duration(days: 7));
  DateTime filterToDate = DateTime.now();

  Future<List<Map<String, dynamic>>> getLastSevenDaysCollections() async {
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

    // Group by date and sum amounts
    Map<String, double> dateTotals = {};

    for (var item in collectionList) {
      final date = item['date']?.toString() ?? '';
      final amount = double.tryParse(item['amount'].toString()) ?? 0.0;

      if (date.isNotEmpty) {
        dateTotals[date] = (dateTotals[date] ?? 0) + amount;
      }
    }

    // ✅ Build list for each of the last 7 days
    List<Map<String, dynamic>> totalByDateList = [];

    for (int i = 0; i < 7; i++) {
      DateTime currentDate = filterFromDate.add(Duration(days: i));
      String formattedDate = DateFormat('yyyy-MM-dd').format(currentDate);
      double total = dateTotals[formattedDate] ?? 0.0;

      totalByDateList.add({"date": formattedDate, "total_amount": total});
    }
    print(totalByDateList);
    return totalByDateList;
  }
}
