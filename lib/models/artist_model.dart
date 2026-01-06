class ArtistModel {
  int id;
  String name;
  String email;
  String phone;
  String address;
  String? category;
  String? experience;
  String? price;
  String? description;
  int totalReviews;
  double avgRating;
  int totalPosts;
  List<dynamic> recentReviews;
  Map<String, dynamic>? profile;

  ArtistModel({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.address,
    this.category,
    this.experience,
    this.price,
    this.description,
    this.totalReviews = 0,
    this.avgRating = 0.0,
    this.totalPosts = 0,
    this.recentReviews = const [],
    this.profile,
  });

  factory ArtistModel.fromJson(Map<String, dynamic> json) {
    return ArtistModel(
      id: int.parse(json['id'].toString()),
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      address: json['address'] ?? '',
      category: json['category'] ?? json['profile']?['category'],
      experience: json['experience'] ?? json['profile']?['experience'],
      price: json['price'] ?? json['profile']?['price'],
      description: json['description'] ?? json['profile']?['description'],
      totalReviews: json['total_reviews'] ?? 0,
      avgRating: double.parse((json['avg_rating'] ?? 0.0).toString()),
      totalPosts: json['total_posts'] ?? 0,
      recentReviews: json['recent_reviews'] ?? [],
      profile: json['profile'] ?? {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'address': address,
      'category': category,
      'experience': experience,
      'price': price,
      'description': description,
      'total_reviews': totalReviews,
      'avg_rating': avgRating,
      'total_posts': totalPosts,
      'recent_reviews': recentReviews,
    };
  }
}