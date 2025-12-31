class ReviewModel {
  int? id;
  int? bookingId;
  int? artistId;
  int? customerId;
  int? rating;
  String? comment;
  String? createdAt;
  String? customerName;
  String? artistName;

  ReviewModel({
    this.id,
    this.bookingId,
    this.artistId,
    this.customerId,
    this.rating,
    this.comment,
    this.createdAt,
    this.customerName,
    this.artistName,
  });

  factory ReviewModel.fromJson(Map<String, dynamic> json) {
    return ReviewModel(
      id: int.tryParse(json['id'].toString()) ?? 0,
      bookingId: int.tryParse(json['booking_id'].toString()) ?? 0,
      artistId: int.tryParse(json['artist_id'].toString()) ?? 0,
      customerId: int.tryParse(json['customer_id'].toString()) ?? 0,
      rating: int.tryParse(json['rating'].toString()) ?? 0,
      comment: json['comment']?.toString() ?? '',
      createdAt: json['created_at']?.toString() ?? '',
      customerName: json['customer_name']?.toString() ?? '',
      artistName: json['artist_name']?.toString() ?? '',
    );
  }
}