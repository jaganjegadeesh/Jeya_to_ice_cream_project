import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String userId;
  final String name;
  final String email;
  final String phone;
  final String dob;
  final String gender;
  final String role;
  final String password;
  final String createdDateTime;
  final String updateDateTime;

  UserModel({
    required this.userId,
    required this.name,
    required this.email,
    required this.phone,
    required this.dob,
    required this.gender,
    required this.role,
    required this.password,
    required this.createdDateTime,
    required this.updateDateTime,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      userId: json['userId'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      dob: json['dob'] ?? '',
      gender: json['gender'] ?? '',
      role: json['role'] ?? '',
      password: json['password'] ?? '',
      createdDateTime: json['createdDateTime'] ?? '',
      updateDateTime: json['updateDateTime'] ?? '',
    );
  }
  @override
  String toString() {
    return 'UserModel(userId: $userId, name: $name, email: $email, phone: $phone,  dob: $dob, password: $password, role: $role, gender: $gender, createdDateTime: $createdDateTime, updateDateTime: $updateDateTime)';
  }
  factory UserModel.fromFirestore(DocumentSnapshot doc) {
  final data = doc.data() as Map<String, dynamic>;
  return UserModel(
    userId: data['userId'] ?? '',
    name: data['name'] ?? '',
    email: data['email'] ?? '',
    phone: data['phone'] ?? '',
    dob: data['dob'] ?? '',
    gender: data['gender'] ?? '',
    role: data['role'] ?? '',
    password: data['password'] ?? '',
    createdDateTime: data['createdDateTime'] ?? '',
    updateDateTime: data['updateDateTime'] ?? '',
  );
}
}


