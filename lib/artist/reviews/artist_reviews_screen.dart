import 'package:flutter/material.dart';
import 'package:artist_hub/core/constants/app_colors.dart';
import 'package:artist_hub/core/constants/app_strings.dart';
import 'package:artist_hub/core/services/api_service.dart';
import 'package:artist_hub/core/services/shared_pref.dart';
import 'package:artist_hub/core/widgets/loading_widget.dart';
import 'package:artist_hub/core/widgets/no_data_widget.dart';
import 'package:artist_hub/models/review_model.dart';
import 'package:artist_hub/utils/helpers.dart';

class ArtistReviewsScreen extends StatefulWidget {
  const ArtistReviewsScreen({super.key});

  @override
  State<ArtistReviewsScreen> createState() => _ArtistReviewsScreenState();
}

class _ArtistReviewsScreenState extends State<ArtistReviewsScreen> {
  List<ReviewModel> _reviews = [];
  double _averageRating = 0.0;
  int _totalReviews = 0;
  Map<int, int> _ratingDistribution = {};
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _loadReviews();
  }

  Future<void> _loadReviews() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    final userId = SharedPref.getUserId();
    if (userId.isEmpty) {
      setState(() {
        _isLoading = false;
        _hasError = true;
      });
      return;
    }

    try {
      final result = await ApiService.getReviewsByArtist(artistId: int.parse(userId));
      if (result['success'] == true && result['data'] != null) {
        final List<dynamic> data = result['data'];
        setState(() {
          _reviews = data.map((item) => ReviewModel.fromJson(item)).toList();
          _calculateStats();
        });
      } else {
        setState(() => _hasError = true);
      }
    } catch (e) {
      setState(() => _hasError = true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _calculateStats() {
    if (_reviews.isEmpty) {
      _averageRating = 0.0;
      _totalReviews = 0;
      _ratingDistribution = {5: 0, 4: 0, 3: 0, 2: 0, 1: 0};
      return;
    }

    // Calculate average rating
    final totalRating = _reviews.fold(0.0, (sum, review) => sum + review.rating);
    _averageRating = totalRating / _reviews.length;
    _totalReviews = _reviews.length;

    // Calculate rating distribution
    _ratingDistribution = {5: 0, 4: 0, 3: 0, 2: 0, 1: 0};
    for (final review in _reviews) {
      _ratingDistribution[review.rating] = (_ratingDistribution[review.rating] ?? 0) + 1;
    }
  }

  Widget _buildRatingStars(double rating, {double size = 20}) {
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

  Widget _buildRatingBar(int stars, int count) {
    final percentage = _totalReviews > 0 ? (count / _totalReviews * 100) : 0;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 60,
            child: Row(
              children: [
                Text(
                  '$stars',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textColor,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.star, size: 16, color: AppColors.secondaryColor),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: LinearProgressIndicator(
              value: percentage / 100,
              backgroundColor: AppColors.lightGrey,
              color: AppColors.secondaryColor,
              borderRadius: BorderRadius.circular(4),
              minHeight: 8,
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 40,
            child: Text(
              '${percentage.round()}%',
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.darkGrey,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Reviews & Ratings'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadReviews,
          ),
        ],
      ),
      body: _isLoading
          ? const LoadingWidget(message: 'Loading reviews...')
          : _hasError
          ? NoDataWidget(
        message: 'Failed to load reviews',
        buttonText: 'Retry',
        onPressed: _loadReviews,
      )
          : _buildContent(),
    );
  }

  Widget _buildContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Rating overview
          _buildRatingOverview(),

          const SizedBox(height: 24),

          // Rating distribution
          _buildRatingDistribution(),

          const SizedBox(height: 24),

          // Reviews list
          _buildReviewsList(),
        ],
      ),
    );
  }

  Widget _buildRatingOverview() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Average rating
          Row(
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppColors.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(40),
                  border: Border.all(
                    color: AppColors.primaryColor.withOpacity(0.2),
                    width: 2,
                  ),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _averageRating.toStringAsFixed(1),
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primaryColor,
                        ),
                      ),
                      const Text(
                        '/5',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.darkGrey,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${_averageRating.toStringAsFixed(1)} out of 5',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    _buildRatingStars(_averageRating),
                    const SizedBox(height: 8),
                    Text(
                      '$_totalReviews ${_totalReviews == 1 ? 'review' : 'reviews'}',
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.darkGrey,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRatingDistribution() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Rating Distribution',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textColor,
            ),
          ),
          const SizedBox(height: 16),
          Column(
            children: [
              _buildRatingBar(5, _ratingDistribution[5] ?? 0),
              _buildRatingBar(4, _ratingDistribution[4] ?? 0),
              _buildRatingBar(3, _ratingDistribution[3] ?? 0),
              _buildRatingBar(2, _ratingDistribution[2] ?? 0),
              _buildRatingBar(1, _ratingDistribution[1] ?? 0),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildReviewsList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'All Reviews',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.textColor,
          ),
        ),
        const SizedBox(height: 12),
        if (_reviews.isEmpty)
          Container(
            padding: const EdgeInsets.all(40),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                const Icon(
                  Icons.reviews_outlined,
                  size: 64,
                  color: AppColors.lightGrey,
                ),
                const SizedBox(height: 16),
                const Text(
                  'No reviews yet',
                  style: TextStyle(
                    fontSize: 16,
                    color: AppColors.darkGrey,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Reviews from customers will appear here',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.darkGrey.withOpacity(0.8),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          )
        else
          Column(
            children: _reviews.map((review) => _buildReviewCard(review)).toList(),
          ),
      ],
    );
  }

  Widget _buildReviewCard(ReviewModel review) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              // Customer avatar
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Center(
                  child: Text(
                    Helpers.getInitials(review.customerName ?? 'C'),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryColor,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Customer info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review.customerName ?? 'Customer',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      Helpers.timeAgo(review.createdAt),
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.darkGrey,
                      ),
                    ),
                  ],
                ),
              ),

              // Rating
              _buildRatingStars(review.rating.toDouble(), size: 16),
            ],
          ),

          const SizedBox(height: 12),

          // Review text
          Text(
            review.comment,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textColor,
              height: 1.5,
            ),
          ),

          const SizedBox(height: 12),

          // Booking reference
          if (review.bookingId > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.lightGrey.withOpacity(0.3),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'Booking #${review.bookingId}',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.darkGrey,
                ),
              ),
            ),
        ],
      ),
    );
  }
}