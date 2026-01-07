import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'package:artist_hub/core/constants/app_colors.dart';
import 'package:artist_hub/core/services/connectivity_service.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Helpers {
  // Format date
  static String formatDate(String dateString, {String format = 'dd MMM yyyy'}) {
    try {
      final date = DateTime.parse(dateString);
      return DateFormat(format).format(date);
    } catch (e) {
      return dateString;
    }
  }

  static String formatDateTime(DateTime dateTime, {String format = 'dd MMM yyyy, hh:mm a'}) {
    return DateFormat(format).format(dateTime);
  }

  // Format price
  static String formatPrice(double price) {
    return NumberFormat.currency(
      symbol: '₹',
      decimalDigits: 0,
    ).format(price);
  }

  // Validate email
  static bool isValidEmail(String email) {
    final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    return emailRegex.hasMatch(email);
  }

  // Validate phone
  static bool isValidPhone(String phone) {
    final phoneRegex = RegExp(r'^[0-9]{10}$');
    return phoneRegex.hasMatch(phone);
  }

  // Show snackbar
  static void showSnackbar(BuildContext context, String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.errorColor : AppColors.successColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // Show confirmation dialog
  static Future<bool> showConfirmationDialog(
      BuildContext context,
      String title,
      String message,
      ) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: AppColors.primaryColor),),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryColor,
            ),
            child: const Text('Confirm', style: TextStyle(color: AppColors.white),),
          ),
        ],
      ),
    );

    return result ?? false;
  }

  // Check internet connection before API call
  static Future<bool> checkInternetBeforeApiCall(BuildContext context) async {
    final isConnected = await ConnectivityService().checkConnection();

    if (!isConnected) {
      showSnackbar(context, 'No internet connection', isError: true);
      return false;
    }

    return true;
  }

  // Loading dialog
  static void showLoadingDialog(BuildContext context, {String message = 'Loading...'}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Row(
          children: [
            const CircularProgressIndicator(color: AppColors.primaryColor),
            const SizedBox(width: 16),
            Text(message),
          ],
        ),
      ),
    );
  }

  static void hideLoadingDialog(BuildContext context) {
    Navigator.pop(context);
  }

  // Get initials from name
  static String getInitials(String name) {
    final words = name.trim().split(' ');
    if (words.length >= 2) {
      return '${words[0][0]}${words[1][0]}'.toUpperCase();
    } else if (words[0].isNotEmpty) {
      return words[0][0].toUpperCase();
    }
    return 'A';
  }

  // Get file size
  // static String formatFileSize(int bytes) {
  //   if (bytes <= 0) return "0 B";
  //   const suffixes = ["B", "KB", "MB", "GB", "TB"];
  //   final i = (log(bytes) / log(1024)).floor();
  //   return '${(bytes / pow(1024, i)).toStringAsFixed(1)} ${suffixes[i]}';
  // }

  // Generate placeholder avatar
  static Widget buildPlaceholderAvatar(String name, {double size = 40}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(size / 2),
      ),
      child: Center(
        child: Text(
          getInitials(name),
          style: TextStyle(
            color: AppColors.primaryColor,
            fontSize: size * 0.35,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  // Calculate time ago
  static String timeAgo(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inDays > 365) {
        final years = (difference.inDays / 365).floor();
        return '$years year${years > 1 ? 's' : ''} ago';
      } else if (difference.inDays > 30) {
        final months = (difference.inDays / 30).floor();
        return '$months month${months > 1 ? 's' : ''} ago';
      } else if (difference.inDays > 0) {
        return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
      } else if (difference.inHours > 0) {
        return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
      } else if (difference.inMinutes > 0) {
        return '${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''} ago';
      } else {
        return 'Just now';
      }
    } catch (e) {
      return dateString;
    }
  }

  // Create rating stars
  static Widget buildRatingStars(double rating, {double size = 16}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        return Icon(
          index < rating.floor() ? Icons.star : Icons.star_border,
          color: AppColors.secondaryColor,
          size: size,
        );
      }),
    );
  }

  // Parse API response
  static Map<String, dynamic> parseApiResponse(String response) {
    try {
      return json.decode(response);
    } catch (e) {
      return {
        'status': false,
        'message': 'Failed to parse response',
        'data': null,
      };
    }
  }

  // Validate required fields
  static String? validateRequired(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }

  // Save to shared preferences
  static Future<void> saveToPrefs(String key, String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, value);
  }

  static Future<String?> getFromPrefs(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(key);
  }

  // Get base64 from file
  static Future<String?> fileToBase64(File file) async {
    try {
      final bytes = await file.readAsBytes();
      return base64Encode(bytes);
    } catch (e) {
      return null;
    }
  }
}