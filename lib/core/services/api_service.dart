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
  // Update your ApiService with these methods
  static Future<Map<String, dynamic>> deleteArtistMedia({
    required int mediaId,
    required int artistId,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiEndpoints.baseUrl}delete_artist_media.php'),
        body: {
          'media_id': mediaId.toString(),
          'artist_id': artistId.toString(),
        },
      ).timeout(timeout);

      final data = _parseResponse(response);

      if (data['status'] == true) {
        return {
          'success': true,
          'message': data['message'] ?? 'Media deleted successfully',
          'data': data['data'],
        };
      }

      return {
        'success': false,
        'message': data['message'] ?? 'Failed to delete media',
        'data': null,
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: $e',
        'data': null,
      };
    }
  }

  static Future<Map<String, dynamic>> updateMediaCaption({
    required int mediaId,
    required int artistId,
    required String caption,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiEndpoints.baseUrl}update_artist_media.php'),
        body: {
          'media_id': mediaId.toString(),
          'artist_id': artistId.toString(),
          'caption': caption,
        },
      ).timeout(timeout);

      final data = _parseResponse(response);

      if (data['status'] == true) {
        return {
          'success': true,
          'message': data['message'] ?? 'Caption updated successfully',
          'data': data['data'],
        };
      }

      return {
        'success': false,
        'message': data['message'] ?? 'Failed to update caption',
        'data': null,
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: $e',
        'data': null,
      };
    }
  }

  static Future<Map<String, dynamic>> getMediaDetails(int mediaId) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiEndpoints.baseUrl}view_artist_media_by_id.php?media_id=$mediaId'),
      ).timeout(timeout);

      final data = _parseResponse(response);

      if (data['status'] == true) {
        return {
          'success': true,
          'message': data['message'] ?? 'Media details fetched successfully',
          'data': data['data'],
        };
      }

      return {
        'success': false,
        'message': data['message'] ?? 'Failed to fetch media details',
        'data': null,
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: $e',
        'data': null,
      };
    }
  }

  // ============ AUTHENTICATION ============
  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
    required String role,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(ApiEndpoints.login),
        body: {
          'email': email,
          'password': password,
          'role': role,
        },
      ).timeout(timeout);

      final data = _parseResponse(response);

      if (data['status'] == true) {
        return {
          'success': true,
          'message': data['message'] ?? 'Login successful',
          'data': data['data'] ?? data,
        };
      }

      return {
        'success': false,
        'message': data['message'] ?? 'Login failed',
        'data': null,
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: $e',
        'data': null,
      };
    }
  }

  static Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
    required String phone,
    required String address,
    required String role,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(ApiEndpoints.register),
        body: {
          'name': name,
          'email': email,
          'password': password,
          'phone': phone,
          'address': address,
          'role': role,
        },
      ).timeout(timeout);

      final data = _parseResponse(response);

      if (data['status'] == true) {
        return {
          'success': true,
          'message': data['message'] ?? 'Registration successful',
          'data': data['data'] ?? data,
        };
      }

      return {
        'success': false,
        'message': data['message'] ?? 'Registration failed',
        'data': null,
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: $e',
        'data': null,
      };
    }
  }

  // ============ ARTIST PROFILE ============
  static Future<Map<String, dynamic>> addArtistProfile({
    required int userId,
    required String category,
    required String experience,
    required String price,
    required String description,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(ApiEndpoints.addArtistProfile),
        body: {
          'user_id': userId.toString(),
          'category': category,
          'experience': experience,
          'price': price,
          'description': description,
        },
      ).timeout(timeout);

      final data = _parseResponse(response);

      if (data['status'] == true) {
        return {
          'success': true,
          'message': data['message'] ?? 'Profile added successfully',
          'data': data['data'] ?? data,
        };
      }

      return {
        'success': false,
        'message': data['message'] ?? 'Failed to add profile',
        'data': null,
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: $e',
        'data': null,
      };
    }
  }

  static Future<Map<String, dynamic>> updateArtistProfile({
    required int userId,
    required String category,
    required String experience,
    required String price,
    required String description,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(ApiEndpoints.updateArtistProfile),
        body: {
          'user_id': userId.toString(),
          'category': category,
          'experience': experience,
          'price': price,
          'description': description,
        },
      ).timeout(timeout);

      final data = _parseResponse(response);

      if (data['status'] == true) {
        return {
          'success': true,
          'message': data['message'] ?? 'Profile updated successfully',
          'data': data['data'] ?? data,
        };
      }

      return {
        'success': false,
        'message': data['message'] ?? 'Failed to update profile',
        'data': null,
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: $e',
        'data': null,
      };
    }
  }

  static Future<Map<String, dynamic>> getArtistProfile({required int userId}) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiEndpoints.viewArtistProfile}?user_id=$userId'),
      ).timeout(timeout);

      final data = _parseResponse(response);

      if (data['status'] == true) {
        return {
          'success': true,
          'message': data['message'] ?? 'Profile fetched successfully',
          'data': data['data'] ?? data,
        };
      }

      return {
        'success': false,
        'message': data['message'] ?? 'Failed to fetch profile',
        'data': null,
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: $e',
        'data': null,
      };
    }
  }

  static Future<Map<String, dynamic>> getArtistDetails(int artistId) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiEndpoints.artistDetails}?artist_id=$artistId'),
      ).timeout(timeout);

      final data = _parseResponse(response);

      if (data['status'] == true) {
        return {
          'success': true,
          'message': data['message'] ?? 'Artist details fetched successfully',
          'data': data['data'] ?? data,
        };
      }

      return {
        'success': false,
        'message': data['message'] ?? 'Failed to fetch artist details',
        'data': null,
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: $e',
        'data': null,
      };
    }
  }

  // ============ ARTIST MEDIA ============
  // In your getArtistMedia method in ApiService:
  static Future<Map<String, dynamic>> getArtistMedia({required int artistId}) async {
    try {
      print('Fetching media for artist ID: $artistId');
      final response = await http.get(
        Uri.parse('${ApiEndpoints.baseUrl}view_artist_media.php?artist_id=$artistId'),
      ).timeout(timeout);

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      final data = _parseResponse(response);

      if (data['status'] == true) {
        return {
          'success': true,
          'message': data['message'] ?? 'Media fetched successfully',
          'data': data['data'] ?? data,
        };
      }

      return {
        'success': false,
        'message': data['message'] ?? 'Failed to fetch media',
        'data': null,
      };
    } catch (e) {
      print('Error fetching media: $e');
      return {
        'success': false,
        'message': 'Network error: $e',
        'data': null,
      };
    }
  }
  static Future<Map<String, dynamic>> addArtistMedia({
    required int artistId,
    required String mediaType,
    required File mediaFile,
    String caption = '',
  }) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse(ApiEndpoints.addArtistMedia),
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

      if (data['status'] == true) {
        return {
          'success': true,
          'message': data['message'] ?? 'Media uploaded successfully',
          'data': data['data'] ?? data,
        };
      }

      return {
        'success': false,
        'message': data['message'] ?? 'Failed to upload media',
        'data': null,
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Upload failed: $e',
        'data': null,
      };
    }
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
    try {
      final response = await http.post(
        Uri.parse(ApiEndpoints.addBooking),
        body: {
          'customer_id': customerId.toString(),
          'artist_id': artistId.toString(),
          'booking_date': bookingDate,
          'event_address': eventAddress,
          'payment_type': paymentType,
          'payment_id': paymentId,
        },
      ).timeout(timeout);

      final data = _parseResponse(response);

      if (data['status'] == true) {
        return {
          'success': true,
          'message': data['message'] ?? 'Booking added successfully',
          'data': data['data'] ?? data,
        };
      }

      return {
        'success': false,
        'message': data['message'] ?? 'Failed to add booking',
        'data': null,
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: $e',
        'data': null,
      };
    }
  }

  static Future<Map<String, dynamic>> getBookingsByArtist({required int artistId}) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiEndpoints.viewBooking}?artist_id=$artistId'),
      ).timeout(timeout);

      final data = _parseResponse(response);

      if (data['status'] == true) {
        return {
          'success': true,
          'message': data['message'] ?? 'Bookings fetched successfully',
          'data': data['data'] ?? data,
        };
      }

      return {
        'success': false,
        'message': data['message'] ?? 'Failed to fetch bookings',
        'data': null,
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: $e',
        'data': null,
      };
    }
  }

  static Future<Map<String, dynamic>> getBookingsByCustomer({required int customerId}) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiEndpoints.viewBookingById}?customer_id=$customerId'),
      ).timeout(timeout);

      final data = _parseResponse(response);

      if (data['status'] == true) {
        return {
          'success': true,
          'message': data['message'] ?? 'Bookings fetched successfully',
          'data': data['data'] ?? data,
        };
      }

      return {
        'success': false,
        'message': data['message'] ?? 'Failed to fetch bookings',
        'data': null,
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: $e',
        'data': null,
      };
    }
  }

  static Future<Map<String, dynamic>> cancelBookingByArtist({
    required int bookingId,
    required int artistId,
    required String cancelReason,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(ApiEndpoints.artistBookingCancel),
        body: {
          'booking_id': bookingId.toString(),
          'artist_id': artistId.toString(),
          'cancel_reason': cancelReason,
        },
      ).timeout(timeout);

      final data = _parseResponse(response);

      if (data['status'] == true) {
        return {
          'success': true,
          'message': data['message'] ?? 'Booking cancelled successfully',
          'data': data['data'] ?? data,
        };
      }

      return {
        'success': false,
        'message': data['message'] ?? 'Failed to cancel booking',
        'data': null,
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: $e',
        'data': null,
      };
    }
  }

  static Future<Map<String, dynamic>> cancelBookingByCustomer({
    required int bookingId,
    required int customerId,
    required String cancelReason,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(ApiEndpoints.customerBookingCancel),
        body: {
          'booking_id': bookingId.toString(),
          'customer_id': customerId.toString(),
          'cancel_reason': cancelReason,
        },
      ).timeout(timeout);

      final data = _parseResponse(response);

      if (data['status'] == true) {
        return {
          'success': true,
          'message': data['message'] ?? 'Booking cancelled successfully',
          'data': data['data'] ?? data,
        };
      }

      return {
        'success': false,
        'message': data['message'] ?? 'Failed to cancel booking',
        'data': null,
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: $e',
        'data': null,
      };
    }
  }

  // ============ REVIEWS ============
  static Future<Map<String, dynamic>> addReview({
    required int bookingId,
    required int artistId,
    required int customerId,
    required int rating,
    required String comment,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(ApiEndpoints.addReview),
        body: {
          'booking_id': bookingId.toString(),
          'artist_id': artistId.toString(),
          'customer_id': customerId.toString(),
          'rating': rating.toString(),
          'comment': comment,
        },
      ).timeout(timeout);

      final data = _parseResponse(response);

      if (data['status'] == true) {
        return {
          'success': true,
          'message': data['message'] ?? 'Review added successfully',
          'data': data['data'] ?? data,
        };
      }

      return {
        'success': false,
        'message': data['message'] ?? 'Failed to add review',
        'data': null,
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: $e',
        'data': null,
      };
    }
  }

  static Future<Map<String, dynamic>> getReviewsByArtist({required int artistId}) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiEndpoints.viewReview}?artist_id=$artistId'),
      ).timeout(timeout);

      final data = _parseResponse(response);

      if (data['status'] == true) {
        return {
          'success': true,
          'message': data['message'] ?? 'Reviews fetched successfully',
          'data': data['data'] ?? data,
        };
      }

      return {
        'success': false,
        'message': data['message'] ?? 'Failed to fetch reviews',
        'data': null,
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: $e',
        'data': null,
      };
    }
  }

  // ============ COMMENTS ============
  static Future<Map<String, dynamic>> addComment({
    required int userId,
    required int mediaId,
    required String comment,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(ApiEndpoints.addComment),
        body: {
          'user_id': userId.toString(),
          'media_id': mediaId.toString(),
          'comment': comment,
        },
      ).timeout(timeout);

      final data = _parseResponse(response);

      if (data['status'] == true) {
        return {
          'success': true,
          'message': data['message'] ?? 'Comment added successfully',
          'data': data['data'] ?? data,
        };
      }

      return {
        'success': false,
        'message': data['message'] ?? 'Failed to add comment',
        'data': null,
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: $e',
        'data': null,
      };
    }
  }

  static Future<Map<String, dynamic>> getComments({
    required int mediaId,
    int limit = 50,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiEndpoints.viewComments}?media_id=$mediaId&limit=$limit'),
      ).timeout(timeout);

      final data = _parseResponse(response);

      if (data['status'] == true) {
        return {
          'success': true,
          'message': data['message'] ?? 'Comments fetched successfully',
          'data': data['data'] ?? data,
        };
      }

      return {
        'success': false,
        'message': data['message'] ?? 'Failed to fetch comments',
        'data': null,
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: $e',
        'data': null,
      };
    }
  }

  // ============ LIKES ============
  static Future<Map<String, dynamic>> toggleLike({
    required int userId,
    required int mediaId,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(ApiEndpoints.like),
        body: {
          'user_id': userId.toString(),
          'media_id': mediaId.toString(),
        },
      ).timeout(timeout);

      final data = _parseResponse(response);

      if (data['status'] == true) {
        return {
          'success': true,
          'message': data['message'] ?? 'Like toggled successfully',
          'data': data['data'] ?? data,
        };
      }

      return {
        'success': false,
        'message': data['message'] ?? 'Failed to toggle like',
        'data': null,
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: $e',
        'data': null,
      };
    }
  }

  // ============ ARTISTS LIST ============
  static Future<Map<String, dynamic>> getAllArtists() async {
    try {
      final response = await http.get(
        Uri.parse(ApiEndpoints.customerViewArtist),
      ).timeout(timeout);

      final data = _parseResponse(response);

      if (data['status'] == true) {
        return {
          'success': true,
          'message': data['message'] ?? 'Artists fetched successfully',
          'data': data['data'] ?? data,
        };
      }

      return {
        'success': false,
        'message': data['message'] ?? 'Failed to fetch artists',
        'data': null,
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: $e',
        'data': null,
      };
    }
  }

  // ============ USER MANAGEMENT ============
  static Future<Map<String, dynamic>> updateUser({
    required int id,
    required String name,
    required String phone,
    required String address,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(ApiEndpoints.updateUser),
        body: {
          'id': id.toString(),
          'name': name,
          'phone': phone,
          'address': address,
        },
      ).timeout(timeout);

      final data = _parseResponse(response);

      if (data['status'] == true) {
        return {
          'success': true,
          'message': data['message'] ?? 'Profile updated successfully',
          'data': data['data'] ?? data,
        };
      }

      return {
        'success': false,
        'message': data['message'] ?? 'Failed to update profile',
        'data': null,
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: $e',
        'data': null,
      };
    }
  }

  // ============ FEEDBACK ============
  static Future<Map<String, dynamic>> addFeedback({
    required int userId,
    required String message,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(ApiEndpoints.addFeedback),
        body: {
          'user_id': userId.toString(),
          'message': message,
        },
      ).timeout(timeout);

      final data = _parseResponse(response);

      if (data['status'] == true) {
        return {
          'success': true,
          'message': data['message'] ?? 'Feedback submitted successfully',
          'data': data['data'] ?? data,
        };
      }

      return {
        'success': false,
        'message': data['message'] ?? 'Failed to submit feedback',
        'data': null,
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: $e',
        'data': null,
      };
    }
  }
}