class UserModel {
  int id;
  String name;
  String email;
  String phone;
  String address;
  String role;
  int isApproved;
  int isActive;
  String createdAt;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.address,
    required this.role,
    required this.isApproved,
    required this.isActive,
    required this.createdAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: int.parse(json['id'].toString()),
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      address: json['address'] ?? '',
      role: json['role'] ?? '',
      isApproved: int.parse(json['is_approved'].toString()),
      isActive: int.parse(json['is_active'].toString()),
      createdAt: json['created_at'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'address': address,
      'role': role,
      'is_approved': isApproved,
      'is_active': isActive,
      'created_at': createdAt,
    };
  }
}