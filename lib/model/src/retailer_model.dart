class RetailerModel {
  final String retailerId;
  final String name;
  final String phone;
  final String password; 
  final String percentage;

  RetailerModel({
    required this.retailerId,
    required this.name,
    required this.phone,
    required this.password,
    required this.percentage,
  });

  factory RetailerModel.fromJson(Map<String, dynamic> json) {
    return RetailerModel(
      retailerId: json['retailerId'],
      name: json['name'],
      phone: json['phone'],
      password: json['password'],
      percentage: (json['percentage'] ?? '0').toString(),
    );
  }
  
}
