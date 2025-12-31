import 'package:flutter/material.dart';
import 'package:artist_hub/core/services/api_service.dart';
import 'package:artist_hub/models/review_model.dart';

class ReviewProvider with ChangeNotifier {
  List<ReviewModel> _reviews = [];
  ReviewModel? _selectedReview;
  bool _isLoading = false;
  String? _errorMessage;

  List<ReviewModel> get reviews => _reviews;
  ReviewModel? get selectedReview => _selectedReview;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> fetchReviewsByArtist(int artistId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await ApiService.getReviews(artistId: artistId);

      _isLoading = false;

      if (response['status'] == true) {
        final List<dynamic> data = response['data'] ?? [];
        _reviews = data.map((reviewJson) => ReviewModel.fromJson(reviewJson)).toList();
        notifyListeners();
      } else {
        _errorMessage = response['message'];
        notifyListeners();
      }
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Failed to fetch reviews: $e';
      notifyListeners();
    }
  }

  Future<bool> addReview({
    required int bookingId,
    required int artistId,
    required int customerId,
    required int rating,
    required String comment,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await ApiService.addReview(
        bookingId: bookingId,
        artistId: artistId,
        customerId: customerId,
        rating: rating,
        comment: comment,
      );

      _isLoading = false;

      if (response['status'] == true) {
        final reviewData = response['data'];
        if (reviewData != null) {
          final newReview = ReviewModel.fromJson(reviewData);
          _reviews.insert(0, newReview);
          notifyListeners();
        }
        return true;
      } else {
        _errorMessage = response['message'];
        notifyListeners();
        return false;
      }
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Failed to add review: $e';
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}