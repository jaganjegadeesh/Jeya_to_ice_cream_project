// ignore_for_file: constant_identifier_names, non_constant_identifier_names

import "package:aj_maintain/service/service.dart";

Future<String?> getUserData() async {
  dynamic userData = await Db.getData();

  return userData?['role'] as String?;
}
class Constants {
  static const String table_prefix = "aj_maintain_";
  static const String company_table = "${table_prefix}company";
  static const String user_table = "${table_prefix}user";
  static const String product_table = "${table_prefix}product";
  static const String assign_header_table = "${table_prefix}assign_header";
  static const String return_header_table = "${table_prefix}return_header";
  static const String retailer_table = "${table_prefix}retailer";
  static const String receipt_table = "${table_prefix}receipt";

  static Future<String?> get login_user_role async => await getUserData();
}
