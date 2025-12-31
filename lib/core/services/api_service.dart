import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:artist_hub/core/constants/api_endpoints.dart';

class ApiService {
  static const Duration timeout = Duration(seconds: 30);

  // Helper method to handle responses
  static Map<String, dynamic> _parseResponse(http.Response response) {
    try {
      return json.decode(response.body);
    } catch (e) {
      return {
        'status': false,
        'message': 'Failed to parse response',
        'error': e.toString(),
      };
    }
  }

  // Helper method to make POST requests
  static Future<Map<String, dynamic>> _postRequest(
      String endpoint,
      Map<String, dynamic> body,
      ) async {
    try {
      final response = await http.post(
        Uri.parse(ApiEndpoints.baseUrl + endpoint),
        body: body,
      ).timeout(timeout);

      final data = _parseResponse(response);
      return data;
    } catch (e) {
      return {
        'status': false,
        'message': 'Network error: $e',
      };
    }
  }

  // Helper method to make GET requests
  static Future<Map<String, dynamic>> _getRequest(String url) async {
    try {
      final response = await http.get(Uri.parse(url)).timeout(timeout);
      final data = _parseResponse(response);
      return data;
    } catch (e) {
      return {
        'status': false,
        'message': 'Network error: $e',
      };
    }
  }
// ============ CUSTOMERS ============
  static Future<Map<String, dynamic>> getCustomers() async {
    final result =
    await _getRequest(ApiEndpoints.baseUrl + 'view_customer.php');
    return result;
  }

  // ============ CANCELLATION (CUSTOMER) ============
  static Future<Map<String, dynamic>> cancelBookingByCustomer({
    required int bookingId,
    required int customerId,
    required String cancelReason,
  }) async {
    final result = await _postRequest('customer_booking_cancel.php', {
      'booking_id': bookingId.toString(),
      'customer_id': customerId.toString(),
      'cancel_reason': cancelReason,
    });

    return result;
  }


  // ============ AUTHENTICATION ============
  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
    required String role,
  }) async {
    final result = await _postRequest('login.php', {
      'email': email,
      'password': password,
      'role': role,
    });

    return result;
  }

  static Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
    required String phone,
    required String address,
    required String role,
  }) async {
    final result = await _postRequest('register.php', {
      'name': name,
      'email': email,
      'password': password,
      'phone': phone,
      'address': address,
      'role': role,
    });

    return result;
  }

  // ============ ARTIST PROFILE ============
  static Future<Map<String, dynamic>> addArtistProfile({
    required int userId,
    required String category,
    required String experience,
    required String price,
    required String description,
  }) async {
    final result = await _postRequest('add_artist_profile.php', {
      'user_id': userId.toString(),
      'category': category,
      'experience': experience,
      'price': price,
      'description': description,
    });

    return result;
  }

  static Future<Map<String, dynamic>> getArtistProfile({int? userId}) async {
    String url = ApiEndpoints.baseUrl + 'view_artist_profile.php';
    if (userId != null) {
      url += '?user_id=$userId';
    }

    final result = await _getRequest(url);
    return result;
  }

  // ============ ARTIST MEDIA ============
  static Future<Map<String, dynamic>> addArtistMedia({
    required int artistId,
    required String mediaType,
    required File mediaFile,
    String caption = '',
  }) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse(ApiEndpoints.baseUrl + 'add_artist_media.php'),
      );

      request.files.add(await http.MultipartFile.fromPath(
        'media',
        mediaFile.path,
      ));

      request.fields['artist_id'] = artistId.toString();
      request.fields['media_type'] = mediaType;
      if (caption.isNotEmpty) {
        request.fields['caption'] = caption;
      }

      final streamedResponse = await request.send().timeout(timeout);
      final response = await http.Response.fromStream(streamedResponse);
      final data = _parseResponse(response);

      return data;
    } catch (e) {
      return {
        'status': false,
        'message': 'Upload failed: $e',
      };
    }
  }

  static Future<Map<String, dynamic>> getArtistMedia({int? artistId}) async {
    String url = ApiEndpoints.baseUrl + 'view_artist_media.php';
    if (artistId != null) {
      url += '?artist_id=$artistId';
    }

    final result = await _getRequest(url);
    return result;
  }

  // ============ BOOKINGS ============
  static Future<Map<String, dynamic>> addBooking({
    required int customerId,
    required int artistId,
    required String bookingDate,
    required String eventAddress,
    required String paymentType,
    String paymentId = '',
  }) async {
    final result = await _postRequest('add_bookings.php', {
      'customer_id': customerId.toString(),
      'artist_id': artistId.toString(),
      'booking_date': bookingDate,
      'event_address': eventAddress,
      'payment_type': paymentType,
      'payment_id': paymentId,
    });

    return result;
  }

  static Future<Map<String, dynamic>> getBookings({
    int? customerId,
    int? artistId,
  }) async {
    String url = ApiEndpoints.baseUrl + 'view_booking.php?';
    if (customerId != null) {
      url += 'customer_id=$customerId';
    } else if (artistId != null) {
      url += 'artist_id=$artistId';
    }

    final result = await _getRequest(url);
    return result;
  }

  // ============ REVIEWS ============
  static Future<Map<String, dynamic>> addReview({
    required int bookingId,
    required int artistId,
    required int customerId,
    required int rating,
    required String comment,
  }) async {
    final result = await _postRequest('add_review.php', {
      'booking_id': bookingId.toString(),
      'artist_id': artistId.toString(),
      'customer_id': customerId.toString(),
      'rating': rating.toString(),
      'comment': comment,
    });

    return result;
  }

  static Future<Map<String, dynamic>> getReviews({int? artistId}) async {
    String url = ApiEndpoints.baseUrl + 'view_review.php';
    if (artistId != null) {
      url += '?artist_id=$artistId';
    }

    final result = await _getRequest(url);
    return result;
  }

  // ============ COMMENTS ============
  static Future<Map<String, dynamic>> addComment({
    required int userId,
    required int mediaId,
    required String comment,
  }) async {
    final result = await _postRequest('add_comments.php', {
      'user_id': userId.toString(),
      'media_id': mediaId.toString(),
      'comment': comment,
    });

    return result;
  }

  static Future<Map<String, dynamic>> getComments({required int mediaId}) async {
    String url = ApiEndpoints.baseUrl + 'view_comments.php?media_id=$mediaId';
    final result = await _getRequest(url);
    return result;
  }

  // ============ ARTISTS ============
  static Future<Map<String, dynamic>> getArtists() async {
    final result = await _getRequest(ApiEndpoints.baseUrl + 'view_artist.php');
    return result;
  }

  static Future<Map<String, dynamic>> getArtistDetails(int artistId) async {
    String url = ApiEndpoints.baseUrl + 'artist_details.php?artist_id=$artistId';
    final result = await _getRequest(url);
    return result;
  }

  // ============ CANCELLATION ============
  static Future<Map<String, dynamic>> cancelBookingByArtist({
    required int bookingId,
    required int artistId,
    required String cancelReason,
  }) async {
    final result = await _postRequest('artist_booking_cancel.php', {
      'booking_id': bookingId.toString(),
      'artist_id': artistId.toString(),
      'cancel_reason': cancelReason,
    });

    return result;
  }

  // ============ USERS ============
  static Future<Map<String, dynamic>> getUsers({int? id}) async {
    String url = ApiEndpoints.baseUrl + 'view_user.php';
    if (id != null) {
      url += '?id=$id';
    }

    final result = await _getRequest(url);
    return result;
  }

  static Future<Map<String, dynamic>> updateUser({
    required int id,
    required String name,
    required String phone,
    required String address,
  }) async {
    final result = await _postRequest('update_user.php', {
      'id': id.toString(),
      'name': name,
      'phone': phone,
      'address': address,
    });

    return result;
  }
}