class BookingModel {
  int id;
  int customerId;
  int artistId;
  String bookingDate;
  String eventAddress;
  String status;
  String paymentStatus;
  String? paymentId;
  String? cancelledBy;
  String? cancelReason;
  String createdAt;
  String? customerName;
  String? customerEmail;
  String? customerPhone;
  String? artistName;
  String? artistEmail;

  BookingModel({
    required this.id,
    required this.customerId,
    required this.artistId,
    required this.bookingDate,
    required this.eventAddress,
    required this.status,
    required this.paymentStatus,
    this.paymentId,
    this.cancelledBy,
    this.cancelReason,
    required this.createdAt,
    this.customerName,
    this.customerEmail,
    this.customerPhone,
    this.artistName,
    this.artistEmail,
  });

  factory BookingModel.fromJson(Map<String, dynamic> json) {
    return BookingModel(
      id: int.parse(json['id'].toString()),
      customerId: int.parse(json['customer_id'].toString()),
      artistId: int.parse(json['artist_id'].toString()),
      bookingDate: json['booking_date'] ?? '',
      eventAddress: json['event_address'] ?? '',
      status: json['status'] ?? '',
      paymentStatus: json['payment_status'] ?? '',
      paymentId: json['payment_id'],
      cancelledBy: json['cancelled_by'],
      cancelReason: json['cancel_reason'],
      createdAt: json['created_at'] ?? '',
      customerName: json['customer_name'],
      customerEmail: json['customer_email'],
      customerPhone: json['customer_phone'],
      artistName: json['artist_name'],
      artistEmail: json['artist_email'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'customer_id': customerId,
      'artist_id': artistId,
      'booking_date': bookingDate,
      'event_address': eventAddress,
      'status': status,
      'payment_status': paymentStatus,
      'payment_id': paymentId,
      'cancelled_by': cancelledBy,
      'cancel_reason': cancelReason,
      'created_at': createdAt,
      'customer_name': customerName,
      'customer_email': customerEmail,
      'customer_phone': customerPhone,
      'artist_name': artistName,
      'artist_email': artistEmail,
    };
  }

  bool get isUpcoming => status == 'booked';
  bool get isCompleted => status == 'completed';
  bool get isCancelled => status == 'cancelled';
}