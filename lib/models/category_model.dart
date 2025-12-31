class CategoryModel {
  String? id;
  String? name;
  String? icon;
  int? artistCount;
  bool? isActive;

  CategoryModel({
    this.id,
    this.name,
    this.icon,
    this.artistCount,
    this.isActive,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id']?.toString(),
      name: json['name'],
      icon: json['icon'],
      artistCount: json['artistCount'] ?? json['artist_count'] ?? 0,
      isActive: json['isActive'] ?? json['is_active'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'icon': icon,
      'artistCount': artistCount,
      'isActive': isActive,
    };
  }
}