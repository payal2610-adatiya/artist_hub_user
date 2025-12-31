class UserModel {
  int? id;
  String? name;
  String? email;
  String? phone;
  String? address;
  String? role;
  int? isApproved;
  int? isActive;
  String? createdAt;
  String? token; // Add token field

  UserModel({
    this.id,
    this.name,
    this.email,
    this.phone,
    this.address,
    this.role,
    this.isApproved,
    this.isActive,
    this.createdAt,
    this.token,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: int.tryParse(json['id'].toString()) ?? 0,
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      address: json['address']?.toString() ?? '',
      role: json['role']?.toString() ?? '',
      isApproved: int.tryParse(json['is_approved'].toString()) ?? 0,
      isActive: int.tryParse(json['is_active'].toString()) ?? 1,
      createdAt: json['created_at']?.toString() ?? '',
      token: json['token']?.toString(),
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
      'token': token,
    };
  }

  // Add copyWith method for updating user data
  UserModel copyWith({
    int? id,
    String? name,
    String? email,
    String? phone,
    String? address,
    String? role,
    int? isApproved,
    int? isActive,
    String? createdAt,
    String? token,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      role: role ?? this.role,
      isApproved: isApproved ?? this.isApproved,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      token: token ?? this.token,
    );
  }
}