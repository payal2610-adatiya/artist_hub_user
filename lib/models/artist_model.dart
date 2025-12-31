class ArtistModel {
  int? id;
  String? name;
  String? email;
  String? phone;
  String? address;
  String? category;
  String? experience;
  String? price;
  String? description;
  double? avgRating;
  int? totalReviews;
  int? totalPosts;
  List<dynamic>? recentReviews;
  Map<String, dynamic>? profile;
  String? createdAt;

  // New fields for dashboard and search
  String? imageUrl;
  double? rating;
  String? location;
  bool? isFeatured;
  bool? isAvailable;
  int? artistId; // For API consistency
  int? userId; // For user_id reference
  String? mediaUrl; // For artist media/images
  List<dynamic>? gallery; // Artist gallery images

  ArtistModel({
    this.id,
    this.name,
    this.email,
    this.phone,
    this.address,
    this.category,
    this.experience,
    this.price,
    this.description,
    this.avgRating,
    this.totalReviews,
    this.totalPosts,
    this.recentReviews,
    this.profile,
    this.createdAt,

    // New fields
    this.imageUrl,
    this.rating,
    this.location,
    this.isFeatured,
    this.isAvailable,
    this.artistId,
    this.userId,
    this.mediaUrl,
    this.gallery,
  });

  factory ArtistModel.fromJson(Map<String, dynamic> json) {
    return ArtistModel(
      id: int.tryParse(json['id'].toString()) ??
          int.tryParse(json['artist_id'].toString()) ?? 0,
      artistId: int.tryParse(json['artist_id'].toString()) ??
          int.tryParse(json['id'].toString()) ?? 0,
      userId: int.tryParse(json['user_id'].toString()),
      name: json['name']?.toString() ??
          json['artist_name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      address: json['address']?.toString() ?? '',
      category: json['category']?.toString() ?? '',
      experience: json['experience']?.toString() ?? '',
      price: json['price']?.toString() ??
          json['hourly_rate']?.toString() ??
          json['price_per_hour']?.toString() ?? '',
      description: json['description']?.toString() ?? '',

      // Rating fields
      avgRating: double.tryParse(json['avg_rating'].toString()) ??
          double.tryParse(json['rating'].toString()) ?? 0.0,
      rating: double.tryParse(json['rating'].toString()) ??
          double.tryParse(json['avg_rating'].toString()) ?? 0.0,

      totalReviews: int.tryParse(json['total_reviews'].toString()) ?? 0,
      totalPosts: int.tryParse(json['total_posts'].toString()) ?? 0,

      // Media and image fields
      imageUrl: json['image_url']?.toString() ??
          json['profile_image']?.toString() ??
          json['image']?.toString(),
      mediaUrl: json['media_url']?.toString(),

      recentReviews: json['recent_reviews'] as List<dynamic>? ?? [],
      profile: json['profile'] as Map<String, dynamic>? ?? {},

      // Location and availability
      location: json['location']?.toString() ??
          json['city']?.toString() ??
          json['address']?.toString() ?? '',
      isFeatured: json['is_featured']?.toString() == '1' ||
          json['featured']?.toString() == 'true' ||
          (json['is_featured'] is bool ? json['is_featured'] : false),
      isAvailable: json['is_available']?.toString() == '1' ||
          json['available']?.toString() == 'true' ||
          (json['is_available'] is bool ? json['is_available'] : true),

      // Gallery images
      gallery: json['gallery'] as List<dynamic>? ??
          json['images'] as List<dynamic>? ?? [],

      createdAt: json['created_at']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'artist_id': artistId,
      'user_id': userId,
      'name': name,
      'email': email,
      'phone': phone,
      'address': address,
      'category': category,
      'experience': experience,
      'price': price,
      'description': description,
      'avg_rating': avgRating,
      'rating': rating,
      'total_reviews': totalReviews,
      'total_posts': totalPosts,
      'image_url': imageUrl,
      'media_url': mediaUrl,
      'location': location,
      'is_featured': isFeatured,
      'is_available': isAvailable,
      'recent_reviews': recentReviews,
      'profile': profile,
      'gallery': gallery,
      'created_at': createdAt,
    };
  }

  // Helper methods
  double get displayRating => rating ?? avgRating ?? 0.0;

  String get displayPrice {
    if (price == null || price!.isEmpty) return '₹0';
    if (price!.contains('₹')) return price!;
    return '₹$price';
  }

  String get shortDescription {
    if (description == null || description!.isEmpty) return 'No description available';
    if (description!.length <= 100) return description!;
    return '${description!.substring(0, 100)}...';
  }

  bool get hasGallery => gallery != null && gallery!.isNotEmpty;

  String? get firstGalleryImage {
    if (gallery == null || gallery!.isEmpty) return null;
    if (gallery![0] is String) return gallery![0];
    if (gallery![0] is Map<String, dynamic>) {
      return gallery![0]['url']?.toString() ??
          gallery![0]['image_url']?.toString();
    }
    return null;
  }

  String get displayCategory {
    if (category == null || category!.isEmpty) return 'Artist';
    return category!;
  }

  // For search and filtering
  bool matchesSearch(String query) {
    final lowerQuery = query.toLowerCase();
    return name?.toLowerCase().contains(lowerQuery) == true ||
        category?.toLowerCase().contains(lowerQuery) == true ||
        description?.toLowerCase().contains(lowerQuery) == true ||
        location?.toLowerCase().contains(lowerQuery) == true;
  }

  // For sorting
  int compareByRating(ArtistModel other) {
    return (other.displayRating).compareTo(displayRating);
  }

  int compareByPrice(ArtistModel other) {
    final thisPrice = double.tryParse(price?.replaceAll('₹', '') ?? '0') ?? 0;
    final otherPrice = double.tryParse(other.price?.replaceAll('₹', '') ?? '0') ?? 0;
    return thisPrice.compareTo(otherPrice);
  }
}