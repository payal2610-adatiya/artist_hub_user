// class BookingModel {
//   int id;
//   int customerId;
//   int artistId;
//   String bookingDate;
//   String eventAddress;
//   String status;
//   String paymentStatus;
//   String? paymentId;
//   String? cancelledBy;
//   String? cancelReason;
//   String createdAt;
//   String? customerName;
//   String? customerEmail;
//   String? customerPhone;
//   String? artistName;
//   String? artistEmail;
//
//   BookingModel({
//     required this.id,
//     required this.customerId,
//     required this.artistId,
//     required this.bookingDate,
//     required this.eventAddress,
//     required this.status,
//     required this.paymentStatus,
//     this.paymentId,
//     this.cancelledBy,
//     this.cancelReason,
//     required this.createdAt,
//     this.customerName,
//     this.customerEmail,
//     this.customerPhone,
//     this.artistName,
//     this.artistEmail,
//   });
//
//
//   //NEW
//   factory BookingModel.fromJson(Map<String, dynamic> json) {
//     print('Parsing booking JSON: $json');
//
//     // Parse ID - handle different field names
//     int? id;
//     try {
//       if (json['booking_id'] != null) {
//         id = int.tryParse(json['booking_id'].toString());
//       }
//       if (id == null && json['id'] != null) {
//         id = int.tryParse(json['id'].toString());
//       }
//       id ??= 0;
//     } catch (e) {
//       print('Error parsing booking ID: $e');
//       id = 0;
//     }
//
//     // Parse dates
//     DateTime bookingDate;
//     try {
//       if (json['booking_date'] != null) {
//         bookingDate = DateTime.parse(json['booking_date'].toString());
//       } else {
//         bookingDate = DateTime.now();
//       }
//     } catch (e) {
//       print('Error parsing booking date: $e');
//       bookingDate = DateTime.now();
//     }
//
//     DateTime createdAt;
//     try {
//       if (json['created_at'] != null) {
//         createdAt = DateTime.parse(json['created_at'].toString());
//       } else {
//         createdAt = DateTime.now();
//       }
//     } catch (e) {
//       print('Error parsing created at: $e');
//       createdAt = DateTime.now();
//     }
//
//     return BookingModel(
//       id: id,
//       customerId: int.tryParse(json['customer_id']?.toString() ?? '0') ?? 0,
//       artistId: int.tryParse(json['artist_id']?.toString() ?? '0') ?? 0,
//       bookingDate: json['booking_date'] ?? '',
//       eventAddress: json['event_address']?.toString() ?? '',
//       status: json['status']?.toString() ?? 'booked',
//       paymentStatus: json['payment_status']?.toString() ?? 'pending',
//       paymentId: json['payment_id']?.toString(),
//       cancelReason: json['cancel_reason']?.toString(),
//       cancelledBy: json['cancelled_by']?.toString(),
//       createdAt: json['created_at'] ?? '',
//       customerName: json['customer_name']?.toString(),
//       customerEmail: json['customer_email']?.toString(),
//       customerPhone: json['customer_phone']?.toString(),
//       artistName: json['artist_name']?.toString(),
//       artistEmail: json['artist_email']?.toString(),
//     );
//   }
//
//   Map<String, dynamic> toJson() {
//     return {
//       'id': id,
//       'customer_id': customerId,
//       'artist_id': artistId,
//       'booking_date': bookingDate,
//       'event_address': eventAddress,
//       'status': status,
//       'payment_status': paymentStatus,
//       'payment_id': paymentId,
//       'cancelled_by': cancelledBy,
//       'cancel_reason': cancelReason,
//       'created_at': createdAt,
//       'customer_name': customerName,
//       'customer_email': customerEmail,
//       'customer_phone': customerPhone,
//       'artist_name': artistName,
//       'artist_email': artistEmail,
//     };
//   }
//
//   bool get isUpcoming => status == 'booked';
//   bool get isCompleted => status == 'completed';
//   bool get isCancelled => status == 'cancelled';
// }
// models/booking_model.dart
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
  bool hasReview; // Add this field

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
    this.hasReview = false, // Default to false
  });

  factory BookingModel.fromJson(Map<String, dynamic> json) {
    print('Parsing booking JSON: $json');

    // Parse ID - handle different field names
    int? id;
    try {
      if (json['booking_id'] != null) {
        id = int.tryParse(json['booking_id'].toString());
      }
      if (id == null && json['id'] != null) {
        id = int.tryParse(json['id'].toString());
      }
      id ??= 0;
    } catch (e) {
      print('Error parsing booking ID: $e');
      id = 0;
    }

    // Parse customer and artist IDs
    int? customerId;
    try {
      customerId = int.tryParse(json['customer_id']?.toString() ?? '0');
    } catch (e) {
      customerId = 0;
    }

    int? artistId;
    try {
      artistId = int.tryParse(json['artist_id']?.toString() ?? '0');
    } catch (e) {
      artistId = 0;
    }

    // Check if booking has review
    bool hasReview = false;
    try {
      if (json['has_review'] != null) {
        hasReview = json['has_review'] == true ||
            json['has_review'] == 1 ||
            json['has_review'] == '1';
      } else if (json['review_id'] != null) {
        hasReview = int.tryParse(json['review_id'].toString()) != null;
      }
    } catch (e) {
      hasReview = false;
    }

    return BookingModel(
      id: id,
      customerId: customerId ?? 0,
      artistId: artistId ?? 0,
      bookingDate: json['booking_date']?.toString() ?? '',
      eventAddress: json['event_address']?.toString() ?? '',
      status: json['status']?.toString() ?? 'booked',
      paymentStatus: json['payment_status']?.toString() ?? 'pending',
      paymentId: json['payment_id']?.toString(),
      cancelReason: json['cancel_reason']?.toString(),
      cancelledBy: json['cancelled_by']?.toString(),
      createdAt: json['created_at']?.toString() ?? '',
      customerName: json['customer_name']?.toString(),
      customerEmail: json['customer_email']?.toString(),
      customerPhone: json['customer_phone']?.toString(),
      artistName: json['artist_name']?.toString(),
      artistEmail: json['artist_email']?.toString(),
      hasReview: hasReview,
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
      'has_review': hasReview,
    };
  }

  bool get isUpcoming => status.toLowerCase() == 'booked';
  bool get isCompleted => status.toLowerCase() == 'completed';
  bool get isCancelled => status.toLowerCase() == 'cancelled';
  bool get canAddReview => isCompleted && !hasReview;
}