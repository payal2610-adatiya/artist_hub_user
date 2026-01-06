class ReviewModel {
  int id;
  int bookingId;
  int artistId;
  int customerId;
  int rating;
  String comment;
  String createdAt;
  String? customerName;
  String? customerEmail;
  String? artistName;

  ReviewModel({
    required this.id,
    required this.bookingId,
    required this.artistId,
    required this.customerId,
    required this.rating,
    required this.comment,
    required this.createdAt,
    this.customerName,
    this.customerEmail,
    this.artistName,
  });

  factory ReviewModel.fromJson(Map<String, dynamic> json) {
    return ReviewModel(
      id: int.parse(json['id'].toString()),
      bookingId: int.parse(json['booking_id'].toString()),
      artistId: int.parse(json['artist_id'].toString()),
      customerId: int.parse(json['customer_id'].toString()),
      rating: int.parse(json['rating'].toString()),
      comment: json['comment'] ?? '',
      createdAt: json['created_at'] ?? '',
      customerName: json['customer_name'],
      customerEmail: json['customer_email'],
      artistName: json['artist_name'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'booking_id': bookingId,
      'artist_id': artistId,
      'customer_id': customerId,
      'rating': rating,
      'comment': comment,
      'created_at': createdAt,
      'customer_name': customerName,
      'customer_email': customerEmail,
      'artist_name': artistName,
    };
  }

  String get ratingStars {
    return '★' * rating + '☆' * (5 - rating);
  }
}