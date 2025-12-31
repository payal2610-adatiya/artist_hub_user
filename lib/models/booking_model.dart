class BookingModel {
  int? id;
  int? customerId;
  int? artistId;
  String? bookingDate;
  String? eventAddress;
  String? status;
  String? paymentStatus;
  String? paymentId;
  String? cancelledBy;
  String? cancelReason;
  String? createdAt;
  String? customerName;
  String? customerEmail;
  String? customerPhone;
  String? artistName;
  String? artistEmail;

  BookingModel({
    this.id,
    this.customerId,
    this.artistId,
    this.bookingDate,
    this.eventAddress,
    this.status,
    this.paymentStatus,
    this.paymentId,
    this.cancelledBy,
    this.cancelReason,
    this.createdAt,
    this.customerName,
    this.customerEmail,
    this.customerPhone,
    this.artistName,
    this.artistEmail,
  });

  factory BookingModel.fromJson(Map<String, dynamic> json) {
    return BookingModel(
      id: int.tryParse(json['id'].toString()) ?? 0,
      customerId: int.tryParse(json['customer_id'].toString()) ?? 0,
      artistId: int.tryParse(json['artist_id'].toString()) ?? 0,
      bookingDate: json['booking_date']?.toString() ?? '',
      eventAddress: json['event_address']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      paymentStatus: json['payment_status']?.toString() ?? '',
      paymentId: json['payment_id']?.toString() ?? '',
      cancelledBy: json['cancelled_by']?.toString() ?? '',
      cancelReason: json['cancel_reason']?.toString() ?? '',
      createdAt: json['created_at']?.toString() ?? '',
      customerName: json['customer_name']?.toString() ?? '',
      customerEmail: json['customer_email']?.toString() ?? '',
      customerPhone: json['customer_phone']?.toString() ?? '',
      artistName: json['artist_name']?.toString() ?? '',
      artistEmail: json['artist_email']?.toString() ?? '',
    );
  }
}