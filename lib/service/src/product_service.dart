// ignore_for_file: avoid_print, unnecessary_null_comparison

import 'package:aj_maintain/service/service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:aj_maintain/constant/constant.dart';
import 'package:aj_maintain/model/model.dart';
import 'package:intl/intl.dart';

class ProductService {
  FirebaseFirestore firebase = FirebaseFirestore.instance;

  /// Fetch all products
  Future<List<Product>> getProducts() async {
    final querySnapshot = await firebase
        .collection(Constants.product_table)
        .orderBy("product_no", descending: false)
        .get();
    final product = querySnapshot.docs
        .map((doc) => Product.fromJson(doc.data()))
        .toList();
    return product;
  }

  Future<bool> deleteProduct(String id) async {
    try {
      final querySnapshot = await firebase
          .collection(Constants.product_table)
          .where('productId', isEqualTo: id)
          .get();

      for (var doc in querySnapshot.docs) {
        await doc.reference.delete();
      }
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> getAssignedList(
    DateTime filterFromDate,
    DateTime filterToDate,
  ) async {
    final querySnapshot = await firebase
        .collection(Constants.assign_header_table)
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
        .where("status", isEqualTo: "assigned")
        .orderBy("bill_no", descending: true)
        .get();

    List<Map<String, dynamic>> assignedList = [];

    for (var doc in querySnapshot.docs) {
      var headerData = doc.data();

      String retailerId = headerData["retailer_id"];

      var retailerSnap = await firebase
          .collection(Constants.retailer_table)
          .where("retailerId", isEqualTo: retailerId)
          .get();

      String retailerName = retailerSnap.docs.isNotEmpty
          ? retailerSnap.docs.first.data()["name"] ?? ""
          : "";

      assignedList.add({
        "id": doc.id,
        "bill_no": headerData["bill_no"],
        "date": headerData["date"],
        "total_amount": headerData["total_amount"],
        "retailer_name": retailerName,
        "details": headerData["details"] ?? [],
      });
    }

    return assignedList;
  }

  Future<bool> assignProducts({
    required String retailerId,
    required String date,
    required List<Map<String, dynamic>> selectedProducts,
  }) async {
    try {
      dynamic userData = await Db.getData();

      final headerRef = firebase.collection(Constants.assign_header_table);

      // 🔁 Generate next bill number
      final snapshot = await headerRef
          .orderBy("bill_no", descending: true)
          .limit(1)
          .get();
      int nextNumber = 1;
      if (snapshot.docs.isNotEmpty) {
        final lastBillNo = snapshot.docs.first.data()["bill_no"];
        final prefix = "AJ_B_";
        final num = int.parse(lastBillNo.replaceFirst(prefix, ""));
        nextNumber = num + 1;
      }
      final billNo = "AJ_B_${nextNumber.toString().padLeft(3, "0")}";

      double total = 0;

      // 💾 Create header document (with auto id)
      final newHeader = await headerRef.add({
        "bill_no": billNo,
        "retailer_id": retailerId,
        "date": date,
        "total_amount": 0,
        "status": "assigned",
        "createdDateTime": DateTime.now().toString().substring(0, 19),
        "updateDateTime": DateTime.now().toString().substring(0, 19),
        "creator": userData?['userId'],
        "creator_name": userData?['name'],
      });
      // 💾 Insert details
      final detailRef = newHeader.collection("details"); // subcollection
      for (var p in selectedProducts) {
        final productId = p["productId"];
        final productNo = p["productNo"];
        final qtyRaw = p["quantity"] ?? 0;
        final priceRaw = p["price"] ?? 0;

        final qty = qtyRaw is int
            ? qtyRaw
            : int.tryParse(qtyRaw.toString()) ?? 0;
        final price = priceRaw is num
            ? priceRaw
            : double.tryParse(priceRaw.toString()) ?? 0.0;

        final subTotal = price * qty;
        total += subTotal;

        await detailRef.add({
          "product_no": productNo,
          "productId": productId,
          "quantity": qty,
          "price": price,
          "sub_total": subTotal,
        });
      }

      await newHeader.update({"total_amount": total});

      return true;
    } catch (e) {
      return false;
    }
  }

  Future<Map<String, dynamic>> getAssignDetail(String id) async {
    final querySnapshot = await firebase
        .collection(Constants.assign_header_table)
        .doc(id)
        .get();

    final doc = querySnapshot;
    final headerData = doc.data();

    // 🔹 Fetch retailer info
    String retailerId = headerData?["retailer_id"];
    var retailerSnap = await firebase
        .collection(Constants.retailer_table)
        .where("retailerId", isEqualTo: retailerId)
        .get();

    String retailerName = retailerSnap.docs.isNotEmpty
        ? retailerSnap.docs.first.data()["name"] ?? ""
        : "";

    // 🔹 Fetch details from subcollection
    final detailsSnap = await firebase
        .collection(Constants.assign_header_table)
        .doc(doc.id)
        .collection("details")
        .orderBy("product_no", descending: false)
        .get();

    List<Map<String, dynamic>> details = [];
    for (var detailDoc in detailsSnap.docs) {
      var data = detailDoc.data();
      var productId = data["productId"];

      // Fetch product info
      var productSnap = await firebase
          .collection(Constants.product_table)
          .where("productId", isEqualTo: productId)
          .get();

      String productName = productSnap.docs.isNotEmpty
          ? productSnap.docs.first.data()["name"] ?? ""
          : "";

      data["name"] = productName;
      details.add(data);
    }
    return {
      "header": {
        "id": doc.id,
        "bill_no": headerData?["bill_no"],
        "date": headerData?["date"],
        "total_amount": headerData?["total_amount"],
        "retailer_name": retailerName,
      },
      "details": details,
    };
  }

  Future<Map<String, dynamic>> updateQuantity({
    required String productId,
    required String headerId,
    required int quantity,
  }) async {
    final detailsSnap = await firebase
        .collection(Constants.assign_header_table)
        .doc(headerId)
        .collection("details")
        .get();
    for (var detailDoc in detailsSnap.docs) {
      var data = detailDoc.data();
      if (data["productId"] == productId) {
        final priceRaw = data["price"] ?? 0;
        final price = priceRaw is num
            ? priceRaw
            : double.tryParse(priceRaw.toString()) ?? 0.0;
        final subTotal = price * quantity;

        await detailDoc.reference.update({
          "quantity": quantity,
          "sub_total": subTotal,
        });
        return {"status": true};
      }
    }
    // If no matching productId found, return a failure status or throw
    return {"status": false, "message": "Product not found"};
  }

  Future<bool> deleteAssignProduct(String billNo) async {
    try {
      final querySnapshot = await firebase
          .collection(Constants.assign_header_table)
          .where('bill_no', isEqualTo: billNo)
          .get();

      for (var doc in querySnapshot.docs) {
        // Delete all subcollection documents first
        final detailsSnap = await doc.reference.collection("details").get();
        for (var detailDoc in detailsSnap.docs) {
          await detailDoc.reference.delete();
        }
        // Then delete the header document
        await doc.reference.delete();
      }
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> getReturnedList(
    DateTime filterFromDate,
    DateTime filterToDate,
  ) async {
    try {
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
          .orderBy("bill_no", descending: true)
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
          "id": doc.id,
          "bill_no": data["bill_no"] ?? "",
          "retailer_id": data["retailer_id"] ?? "",
          "retailer_name": retailerName,
          "total_amount": data["total_amount"] ?? 0,
          "final_amount": data["final_amount"] ?? 0,
          "percentage": data["percentage"] ?? 0,
          "date": data["date"] ?? "",
        });
      }

      return returnedList;
    } catch (e) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getAssignedProductsForRetailer(
    String retailerId,
  ) async {
    String assignIds = '';
    final querySnapshot = await firebase
        .collection(Constants.assign_header_table)
        .where("status", isEqualTo: 'assigned')
        .where("retailer_id", isEqualTo: retailerId)
        .get();

    if (querySnapshot.docs.isEmpty) {
      return [];
    }
    List<Map<String, dynamic>> allDetails = [];

    for (final doc in querySnapshot.docs) {
      final headerData = doc.data();
      if (assignIds.isEmpty) {
        assignIds = doc.id;
      } else {
        assignIds = "$assignIds,${doc.id}";
      }
      // 🔹 Fetch details from subcollection
      final detailsSnap = await firebase
          .collection(Constants.assign_header_table)
          .doc(doc.id)
          .collection("details")
          .orderBy("product_no", descending: false)
          .get();

      // Map to aggregate products by productId
      final Map<String, Map<String, dynamic>> productMap = {};

      for (var detailDoc in detailsSnap.docs) {
        var data = detailDoc.data();
        var productId = data["productId"];

        // Fetch product info
        var productSnap = await firebase
            .collection(Constants.product_table)
            .where("productId", isEqualTo: productId)
            .get();

        String productName = productSnap.docs.isNotEmpty
            ? productSnap.docs.first.data()["name"] ?? ""
            : "";

        // Add product_name
        data["name"] = productName;

        // Aggregate quantity if product already exists
        if (productMap.containsKey(productId)) {
          productMap[productId]!["quantity"] += data["quantity"] ?? 0;
        } else {
          productMap[productId] = Map<String, dynamic>.from(data);
        }
      }

      List<Map<String, dynamic>> details = productMap.values.toList();

      allDetails.add({
        "id": doc.id,
        "assignIds": assignIds,
        "bill_no": headerData["bill_no"],
        "date": headerData["date"],
        "total_amount": headerData["total_amount"],
        "retailerId": headerData["retailer_id"],
        "details": details,
      });
    }

    return allDetails;
  }

  Future<Map<String, dynamic>> saveReturn({
    String? id,
    required String retailerId,
    required String date,
    required double total,
    required double advance,
    required double billTotal,
    required double finalAmount,
    required double percentage,
    required String receiptIds,
    required List<Map<String, dynamic>> products,
    required String assignIds,
  }) async {
    try {
      dynamic userData = await Db.getData();

      String billNo;
      double billAmount;
      final headerCollection = firebase.collection(
        Constants.return_header_table,
      );

      CollectionReference<Map<String, dynamic>>? detailCollection;
      if (advance != null && advance != 0) {
        billAmount = finalAmount;
      } else {
        billAmount = billTotal;
      }
      if (id != null && id.isNotEmpty) {
        // 🔄 Update existing return
        await headerCollection.doc(id).update({
          "retailer_id": retailerId,
          "date": date,
          "sub_total": total,
          "percentage": percentage,
          "advance": advance,
          "final_amount": billAmount,
        });

        // Use subcollection "details" under the header document
        detailCollection = headerCollection.doc(id).collection("details");

        // ❌ Remove old details
        final oldDetails = await detailCollection.get();
        for (var doc in oldDetails.docs) {
          await doc.reference.delete();
        }

        billNo =
            (await headerCollection.doc(id).get()).data()?["bill_no"] ?? "";
      } else {
        final query = await headerCollection
            .orderBy("bill_no", descending: true)
            .limit(1)
            .get();

        int nextNumber = 1;
        String prefix = "AJ_RB_";

        if (query.docs.isNotEmpty) {
          String lastBill = query.docs.first["bill_no"];
          int lastNum = int.tryParse(lastBill.replaceFirst(prefix, "")) ?? 0;
          nextNumber = lastNum + 1;
        }

        billNo = "$prefix${nextNumber.toString().padLeft(3, "0")}";

        final headerRef = await headerCollection.add({
          "retailer_id": retailerId,
          "date": date,
          "bill_no": billNo,
          "sub_total": total,
          "advance": advance,
          "final_amount": billAmount,
          "percentage": percentage,
          "receipt_ids": receiptIds,
          "assignIds": assignIds,
          "createdDateTime": DateTime.now().toString().substring(0, 19),
          "updateDateTime": DateTime.now().toString().substring(0, 19),
          "creator": userData?['userId'],
          "creator_name": userData?['name'],
        });

        id = headerRef.id;
        // Use subcollection "details" under the new header document
        detailCollection = headerCollection.doc(id).collection("details");
      }

      // ✅ Save return details
      for (final p in products) {
        // 🔹 Fetch retailer info
        var productSnap = await firebase
            .collection(Constants.product_table)
            .where("productId", isEqualTo: p["product_id"])
            .get();

        String productNo = productSnap.docs.isNotEmpty
            ? productSnap.docs.first.data()["product_no"] ?? ""
            : "";
        await detailCollection.add({
          "header_id": id,
          "product_id": p["product_id"],
          "product_no": productNo,
          "quantity": p["quantity"],
          "return_quantity": p["return_quantity"],
          "price": p["price"],
          "amount": p["amount"],
        });
      }

      // 🔄 Update status in assign header
      final assignHeaders = await firebase
          .collection(Constants.assign_header_table)
          .where("retailer_id", isEqualTo: retailerId)
          .get();

      for (var doc in assignHeaders.docs) {
        await doc.reference.update({"status": "returned"});
      }
      List<String> ids = receiptIds.split(',').map((e) => e.trim()).toList();

      for (String id in ids) {
        await firebase.collection(Constants.receipt_table).doc(id).update({
          "status": "1",
        });
      }

      return {"success": true, "bill_no": billNo, "id": id};
    } catch (e) {
      return {"success": false, "error": e.toString()};
    }
  }

  Future<Map<String, dynamic>> getReturnDetail(String billNo) async {
    try {
      final headerCollection = firebase.collection(
        Constants.return_header_table,
      );

      final query = await headerCollection.doc(billNo).get();

      if (!query.exists) {
        return {
          "success": false,
          "error": "No return found for bill_no $billNo",
        };
      }

      final headerDoc = query;
      final headerData = headerDoc.data();

      var retailerSnap = await firebase
          .collection(Constants.retailer_table)
          .where("retailerId", isEqualTo: headerData?['retailer_id'])
          .get();

      String retailername = retailerSnap.docs.isNotEmpty
          ? retailerSnap.docs.first.data()["name"] ?? ""
          : "";
      // 📦 Get details subcollection
      final detailSnapshot = await firebase
          .collection(Constants.return_header_table)
          .doc(billNo)
          .collection("details")
          .orderBy('product_no', descending: false)
          .get();
      final details = await Future.wait(
        detailSnapshot.docs.map((doc) async {
          final d = doc.data();
          var productSnap = await firebase
              .collection(Constants.product_table)
              .where("productId", isEqualTo: d['product_id'])
              .get();

          String productName = productSnap.docs.isNotEmpty
              ? productSnap.docs.first.data()["name"] ?? ""
              : "";
          return {
            "id": doc.id,
            "product_id": d["product_id"],
            "name": productName,
            "quantity": d["quantity"],
            "return_quantity": d["return_quantity"],
            "price": d["price"],
            "amount": d["amount"],
          };
        }),
      );

      return {
        "status": true,
        "header": {
          "id": headerDoc.id,
          "bill_no": headerData?["bill_no"],
          "retailer_id": headerData?["retailer_id"],
          "receipt_ids": headerData?["receipt_ids"],
          "retailer_name": retailername,
          "date": headerData?["date"],
          "advance": headerData?["advance"],
          "total_amount": headerData?["total_amount"],
          "final_amount": headerData?["final_amount"],
          "percentage": headerData?["percentage"],
        },
        "details": details,
      };
    } catch (e) {
      return {"status": false, "error": e.toString()};
    }
  }

  Future<bool> deleteReturnProduct(String billNo) async {
    try {
      final querySnapshot = await firebase
          .collection(Constants.return_header_table)
          .where('bill_no', isEqualTo: billNo)
          .get();

      if (querySnapshot.docs.isEmpty) {
        print('No return records found for bill_no: $billNo');
        return false;
      }

      for (var doc in querySnapshot.docs) {
        final data = doc.data();

        // --- Handle receipt updates ---
        final receiptId = (data['receiptIds'] ?? '').toString();
        if (receiptId.isNotEmpty) {
          final ids = receiptId
              .split(',')
              .map((e) => e.trim())
              .where((e) => e.isNotEmpty);
          for (final id in ids) {
            await firebase.collection(Constants.receipt_table).doc(id).update({
              "status": "0",
            });
          }
        }

        // --- Handle assign updates ---
        final assignId = (data['assignIds'] ?? '').toString();
        if (assignId.isNotEmpty) {
          final ids = assignId
              .split(',')
              .map((e) => e.trim())
              .where((e) => e.isNotEmpty);
          for (final id in ids) {
            await firebase
                .collection(Constants.assign_header_table)
                .doc(id)
                .update({"status": "assigned"});
          }
        }

        // --- Delete the return document ---
        await doc.reference.delete();
      }

      return true;
    } catch (e, stack) {
      print('Error deleting return product: $e');
      print(stack);
      return false;
    }
  }

  Future<int> getProductStatus(String productId) async {
    final querySnapshot = await firebase
        .collectionGroup("details")
        .where("productId", isEqualTo: productId)
        .get();
    if (querySnapshot.docs.isNotEmpty) {
      return 0;
    } else {
      return 1;
    }
  }
}
