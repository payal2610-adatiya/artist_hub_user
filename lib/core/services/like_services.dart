// lib/core/services/like_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;

class LikeService {
  static const String _baseUrl = 'https://prakrutitech.xyz/gaurang/';

  static Future<Map<String, dynamic>> toggleLike(int userId, int mediaId) async {
    try {
      print('Toggling like: userId=$userId, mediaId=$mediaId');

      final response = await http.post(
        Uri.parse('$_baseUrl/like.php'),
        body: {
          'user_id': userId.toString(),
          'media_id': mediaId.toString(),
        },
      );

      print('Like response: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        print('Decoded response: $decoded');
        return decoded;
      }
      return {
        'status': false,
        'message': 'Server error: ${response.statusCode}',
      };
    } catch (e) {
      print('Like error: $e');
      return {
        'status': false,
        'message': 'Network error: $e',
      };
    }
  }

  static Future<Map<String, dynamic>> addComment({
    required int userId,
    required int mediaId,
    required String comment,
  }) async {
    try {
      print('Adding comment: userId=$userId, mediaId=$mediaId, comment=$comment');

      final response = await http.post(
        Uri.parse('$_baseUrl/add_comments.php'),
        body: {
          'user_id': userId.toString(),
          'media_id': mediaId.toString(),
          'comment': comment,
        },
      );

      print('Comment response: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        print('Decoded comment response: $decoded');
        return decoded;
      }
      return {
        'status': false,
        'message': 'Server error: ${response.statusCode}',
      };
    } catch (e) {
      print('Comment error: $e');
      return {
        'status': false,
        'message': 'Network error: $e',
      };
    }
  }

  static Future<Map<String, dynamic>> getComments(int mediaId) async {
    try {
      print('Getting comments for mediaId: $mediaId');

      final response = await http.get(
        Uri.parse('$_baseUrl/view_comments.php?media_id=$mediaId'),
      );

      print('Get comments response: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        print('Decoded comments: $decoded');
        return decoded;
      }
      return {
        'status': false,
        'message': 'Server error: ${response.statusCode}',
      };
    } catch (e) {
      print('Get comments error: $e');
      return {
        'status': false,
        'message': 'Network error: $e',
      };
    }
  }
}