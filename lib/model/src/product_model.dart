// ignore_for_file: non_constant_identifier_names

class Product {
  final String productId;
  final String product_no;
  final String name;
  final String price;
  final String createdDateTime;
  final String updateDateTime;

  Product({
    required this.productId,
    required this.product_no,
    required this.name,
    required this.price,
    required this.updateDateTime,
    required this.createdDateTime,
  });


   factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      productId: json['productId'] ?? '',
      product_no: json['product_no'] ?? '',
      name: json['name'] ?? '',
      price: json['price'] ?? '',
      updateDateTime: json['updateDateTime'] ?? '',
      createdDateTime: json['createdDateTime'] ?? '',
    );
  }
  @override
  String toString() {
    return 'UserModel(productId: $productId,product_no: $product_no, name: $name, price: $price, updateDateTime: $updateDateTime, createdDateTime: $createdDateTime)';
  }
}
