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
    print('=== DEBUG: Parsing Artist JSON ===');
    print('Raw JSON: $json');

    // Safely parse ID
    int id;
    try {
      if (json['id'] != null) {
        id = int.tryParse(json['id'].toString()) ?? 0;
      } else {
        id = 0;
      }
    } catch (e) {
      print('Error parsing ID: $e');
      id = 0;
    }

    // Safely parse price - check multiple locations
    String? price;

    // 1. Check direct price field
    if (json['price'] != null) {
      price = json['price'].toString();
      print('Found price in "price" field: $price');
    }

    // 2. Check profile price
    if ((price == null || price.isEmpty) && json['profile'] is Map) {
      final profilePrice = json['profile']['price']?.toString();
      if (profilePrice != null && profilePrice.isNotEmpty) {
        price = profilePrice;
        print('Found price in "profile": $price');
      }
    }

    // 3. Check artist_profile
    if ((price == null || price.isEmpty) && json['artist_profile'] is Map) {
      final artistProfilePrice = json['artist_profile']['price']?.toString();
      if (artistProfilePrice != null && artistProfilePrice.isNotEmpty) {
        price = artistProfilePrice;
        print('Found price in "artist_profile": $price');
      }
    }

    // 4. If still no price, check for other possible field names
    if (price == null || price.isEmpty) {
      final possiblePriceFields = [
        'amount',
        'fee',
        'artist_price',
        'booking_price',
        'rate',
        'charges'
      ];

      for (var field in possiblePriceFields) {
        if (json[field] != null) {
          price = json[field].toString();
          print('Found price in "$field": $price');
          break;
        }
      }
    }

    // 5. Set default if still no price
    if (price == null || price.isEmpty) {
      price = '0';
      print('No price found, setting default: 0');
    }

    // Safely parse category - check multiple locations
    String? category;

    if (json['category'] != null) {
      category = json['category'].toString();
    } else if (json['profile'] is Map && json['profile']['category'] != null) {
      category = json['profile']['category'].toString();
    }

    // Safely parse experience
    String? experience;

    if (json['experience'] != null) {
      experience = json['experience'].toString();
    } else if (json['profile'] is Map && json['profile']['experience'] != null) {
      experience = json['profile']['experience'].toString();
    }

    // Safely parse description
    String? description;

    if (json['description'] != null) {
      description = json['description'].toString();
    } else if (json['profile'] is Map && json['profile']['description'] != null) {
      description = json['profile']['description'].toString();
    }

    // Safely parse total reviews
    int totalReviews = 0;
    try {
      if (json['total_reviews'] != null) {
        totalReviews = int.tryParse(json['total_reviews'].toString()) ?? 0;
      }
    } catch (e) {
      print('Error parsing total_reviews: $e');
    }

    // Safely parse average rating
    double avgRating = 0.0;
    try {
      if (json['avg_rating'] != null) {
        avgRating = double.tryParse(json['avg_rating'].toString()) ?? 0.0;
      }
    } catch (e) {
      print('Error parsing avg_rating: $e');
    }

    // Safely parse total posts
    int totalPosts = 0;
    try {
      if (json['total_posts'] != null) {
        totalPosts = int.tryParse(json['total_posts'].toString()) ?? 0;
      }
    } catch (e) {
      print('Error parsing total_posts: $e');
    }

    // Parse recent reviews
    List<dynamic> recentReviews = [];
    if (json['recent_reviews'] is List) {
      recentReviews = json['recent_reviews'];
    }

    // Parse profile
    Map<String, dynamic>? profile;
    if (json['profile'] is Map) {
      profile = Map<String, dynamic>.from(json['profile']);
    }

    print('=== PARSED ARTIST ===');
    print('ID: $id');
    print('Name: ${json['name']}');
    print('Price: $price');
    print('Category: $category');
    print('Avg Rating: $avgRating');

    return ArtistModel(
      id: id,
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      address: json['address']?.toString() ?? '',
      category: category,
      experience: experience,
      price: price,
      description: description,
      totalReviews: totalReviews,
      avgRating: avgRating,
      totalPosts: totalPosts,
      recentReviews: recentReviews,
      profile: profile,
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
      'profile': profile,
    };
  }
}