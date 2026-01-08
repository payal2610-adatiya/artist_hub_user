import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:artist_hub/core/constants/api_endpoints.dart';

class ApiService {
  static const String baseUrl = "https://prakrutitech.xyz/gaurang/";

  static const Duration timeout = Duration(seconds: 30);
// Add this to your Helpers class or create a test file
  Future<void> testMediaApi() async {
    try {
      print('Testing Media API Endpoints...');

      // Test 1: view_artist_media_by_id.php
      final response1 = await http.get(
        Uri.parse('https://prakrutitech.xyz/gaurang/view_artist_media_by_id.php?artist_id=26'),
      );
      print('Test 1 - view_artist_media_by_id.php:');
      print('Status: ${response1.statusCode}');
      print('Body: ${response1.body}');

      // Test 2: get_media.php
      final response2 = await http.get(
        Uri.parse('https://prakrutitech.xyz/gaurang/get_media.php'),
      );
      print('\nTest 2 - get_media.php:');
      print('Status: ${response2.statusCode}');
      print('Body: ${response2.body}');

      // Test 3: view_artist_media.php
      final response3 = await http.get(
        Uri.parse('https://prakrutitech.xyz/gaurang/view_artist_media.php?artist_id=26'),
      );
      print('\nTest 3 - view_artist_media.php:');
      print('Status: ${response3.statusCode}');
      print('Body: ${response3.body}');

    } catch (e) {
      print('API Test Error: $e');
    }
  }
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
  // In ApiService class, update these methods

// Fix: Use correct endpoint for artist media
// Replace your current getArtistMedia method with this:
  static Future<Map<String, dynamic>> getArtistMedia({required int artistId}) async {
    try {
      print('🔍 Fetching media for artist ID: $artistId');

      // First, let's try the correct endpoint - based on your PHP file
      final response = await http.get(
        Uri.parse('${baseUrl}view_artist_media_by_id.php?artist_id=$artistId'),
      ).timeout(timeout);

      print('📡 Response status: ${response.statusCode}');
      print('📡 Response body: ${response.body}');

      final data = _parseResponse(response);

      // Check different response structures
      if (data['status'] == true || data['success'] == true) {
        print('✅ API Success');

        // Handle different data structures
        dynamic mediaData;

        if (data['data'] != null) {
          mediaData = data['data'];
        } else if (data['media'] != null) {
          mediaData = data['media'];
        } else {
          mediaData = [];
        }

        // Make sure it's a list
        if (mediaData is! List) {
          if (mediaData is Map) {
            mediaData = [mediaData];
          } else {
            mediaData = [];
          }
        }

        print('📦 Number of media items: ${mediaData.length}');
        if (mediaData.isNotEmpty && mediaData[0] is Map) {
          print('📦 First item keys: ${(mediaData[0] as Map).keys.toList()}');
        }

        return {
          'success': true,
          'message': data['message'] ?? 'Media fetched successfully',
          'data': mediaData,
        };
      } else {
        print('❌ API Failed: ${data['message']}');
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to fetch media',
          'data': [],
        };
      }
    } catch (e) {
      print('❌ Network Error: $e');
      return {
        'success': false,
        'message': 'Network error: $e',
        'data': [],
      };
    }
  }
// Alternative: Try get_media.php endpoint
  static Future<Map<String, dynamic>> getAllMedia() async {
    try {
      final response = await http.get(
        Uri.parse('${baseUrl}get_media.php'),
      ).timeout(timeout);

      final data = _parseResponse(response);

      if (data['status'] == true) {
        return {
          'success': true,
          'message': data['message'] ?? 'All media fetched successfully',
          'data': data['data'] ?? [],
        };
      }

      return {
        'success': false,
        'message': data['message'] ?? 'Failed to fetch media',
        'data': [],
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: $e',
        'data': [],
      };
    }
  }

// Get media by specific media ID
  static Future<Map<String, dynamic>> getMediaById(int mediaId) async {
    try {
      final response = await http.get(
        Uri.parse('${baseUrl}view_artist_media_by_id.php?media_id=$mediaId'),
      ).timeout(timeout);

      final data = _parseResponse(response);

      if (data['status'] == true) {
        return {
          'success': true,
          'message': data['message'] ?? 'Media fetched successfully',
          'data': data['data'] ?? [],
        };
      }

      return {
        'success': false,
        'message': data['message'] ?? 'Failed to fetch media',
        'data': [],
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: $e',
        'data': [],
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
      print('=== API SERVICE: ADD ARTIST MEDIA ===');
      print('Artist ID: $artistId');
      print('Media Type: $mediaType');
      print('Caption: $caption');
      print('File Path: ${mediaFile.path}');
      print('File Size: ${await mediaFile.length()} bytes');

      // Create multipart request
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('${baseUrl}add_artist_media.php'), // Make sure this is correct!
      );

      // Add fields
      request.fields['artist_id'] = artistId.toString();
      request.fields['media_type'] = mediaType;
      if (caption.isNotEmpty) {
        request.fields['caption'] = caption;
      }

      // Add file
      request.files.add(
        await http.MultipartFile.fromPath(
          'media',  // This must match PHP $_FILES['media']
          mediaFile.path,
          filename: mediaFile.path.split('/').last,
        ),
      );

      print('📤 Sending multipart request...');
      final streamedResponse = await request.send();
      print('📤 Request sent, getting response...');

      final response = await http.Response.fromStream(streamedResponse);
      print('📤 Response Status: ${response.statusCode}');
      print('📤 Response Body: ${response.body}');

      final data = _parseResponse(response);
      print('📤 Parsed Response: $data');

      if (data['status'] == true || data['success'] == true) {
        print('✅ API: Upload successful');
        return {
          'success': true,
          'message': data['message'] ?? 'Media uploaded successfully',
          'data': data['data'] ?? data,
        };
      }

      print('❌ API: Upload failed');
      return {
        'success': false,
        'message': data['message'] ?? 'Failed to upload media',
        'data': null,
      };
    } catch (e) {
      print('❌ API Exception: $e');
      print('Stack trace: ${e.toString()}');
      return {
        'success': false,
        'message': 'Upload failed: $e',
        'data': null,
      };
    }
  }


  // ============ BOOKINGS ============

  static Future<Map<String, dynamic>> updateBooking({
    required int bookingId,
    String? status,
    String? bookingDate,
    String? eventAddress,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${baseUrl}update_bookings.php'), // Use your actual API filename
        body: {
          'booking_id': bookingId.toString(),
          if (status != null) 'status': status,
          if (bookingDate != null) 'booking_date': bookingDate,
          if (eventAddress != null) 'event_address': eventAddress,
        },
      ).timeout(timeout);

      final data = _parseResponse(response);

      if (data['status'] == true || data['success'] == true) {
        return {
          'success': true,
          'message': data['message'] ?? 'Booking updated successfully',
          'data': data['data'] ?? data,
        };
      }

      return {
        'success': false,
        'message': data['message'] ?? 'Failed to update booking',
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
  //new
  // In ApiService class, add/update these methods:

// Fix: Get bookings by customer ID
  static Future<Map<String, dynamic>> getBookingsByCustomer({required int customerId}) async {
    try {
      print('Fetching bookings for customer ID: $customerId');

      final response = await http.get(
        Uri.parse('${baseUrl}view_booking.php?customer_id=$customerId'),
      ).timeout(timeout);

      print('Bookings API Response: ${response.statusCode}');
      print('Bookings API Body: ${response.body}');

      final data = _parseResponse(response);

      if (data['status'] == true) {
        return {
          'success': true,
          'message': data['message'] ?? 'Bookings fetched successfully',
          'data': data['data'] ?? [],
        };
      }

      return {
        'success': false,
        'message': data['message'] ?? 'Failed to fetch bookings',
        'data': null,
      };
    } catch (e) {
      print('Bookings API Error: $e');
      return {
        'success': false,
        'message': 'Network error: $e',
        'data': null,
      };
    }
  }

// Fix: Cancel booking by customer
  static Future<Map<String, dynamic>> cancelBookingByCustomer({
    required int bookingId,
    required int customerId,
    required String cancelReason,
  }) async {
    try {
      print('Cancelling booking: bookingId=$bookingId, customerId=$customerId');

      final response = await http.post(
        Uri.parse('${baseUrl}customer_booking_cancel.php'),
        body: {
          'booking_id': bookingId.toString(),
          'customer_id': customerId.toString(),
          'cancel_reason': cancelReason,
        },
      ).timeout(timeout);

      print('Cancel Booking Response: ${response.statusCode}');
      print('Cancel Booking Body: ${response.body}');

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
      print('Cancel Booking API Exception: $e');
      return {
        'success': false,
        'message': 'Network error: $e',
        'data': null,
      };
    }
  }

// Fix: Add booking
  static Future<Map<String, dynamic>> addBooking({
    required int customerId,
    required int artistId,
    required String bookingDate,
    required String eventAddress,
    required String paymentType,
    String paymentId = '',
  }) async {
    try {
      print('Adding booking: customerId=$customerId, artistId=$artistId');

      final response = await http.post(
        Uri.parse('${baseUrl}add_bookings.php'),
        body: {
          'customer_id': customerId.toString(),
          'artist_id': artistId.toString(),
          'booking_date': bookingDate,
          'event_address': eventAddress,
          'payment_type': paymentType,
          'payment_id': paymentId,
        },
      ).timeout(timeout);

      print('Add Booking Response: ${response.statusCode}');
      print('Add Booking Body: ${response.body}');

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
      print('Add Booking API Exception: $e');
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