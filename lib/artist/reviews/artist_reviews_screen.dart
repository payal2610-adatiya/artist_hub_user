import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:artist_hub/core/constants/app_colors.dart';
import 'package:artist_hub/core/constants/app_strings.dart';
import 'package:artist_hub/models/review_model.dart';
import 'package:artist_hub/providers/auth_provider.dart';
import 'package:artist_hub/providers/review_provider.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';

class ArtistReviewsScreen extends StatefulWidget {
  const ArtistReviewsScreen({Key? key}) : super(key: key);

  @override
  _ArtistReviewsScreenState createState() => _ArtistReviewsScreenState();
}

class _ArtistReviewsScreenState extends State<ArtistReviewsScreen> {
  double _averageRating = 0.0;
  int _totalReviews = 0;

  @override
  void initState() {
    super.initState();
    _loadReviews();
  }

  void _loadReviews() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final reviewProvider = Provider.of<ReviewProvider>(context, listen: false);

    if (authProvider.userId != null) {
      reviewProvider.fetchReviewsByArtist(authProvider.userId!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final reviewProvider = Provider.of<ReviewProvider>(context);
    final reviews = reviewProvider.reviews;

    // Calculate average rating
    if (reviews.isNotEmpty) {
      final totalRating = reviews.fold(0.0, (sum, review) => sum + (review.rating ?? 0).toDouble());
      _averageRating = totalRating / reviews.length;
      _totalReviews = reviews.length;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Reviews'),
        backgroundColor: AppColors.white,
        elevation: 1,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Rating Summary
            Card(
              color: AppColors.white,
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Text(
                      _averageRating.toStringAsFixed(1),
                      style: TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    RatingBarIndicator(
                      rating: _averageRating,
                      itemBuilder: (context, index) => Icon(
                        Icons.star,
                        color: AppColors.secondaryColor,
                      ),
                      itemCount: 5,
                      itemSize: 30,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '$_totalReviews Reviews',
                      style: TextStyle(
                        fontSize: 16,
                        color: AppColors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Reviews List
            Text(
              'All Reviews',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textColor,
              ),
            ),
            const SizedBox(height: 12),

            if (reviewProvider.isLoading)
              const Center(child: CircularProgressIndicator())
            else if (reviews.isEmpty)
              Container(
                padding: const EdgeInsets.symmetric(vertical: 40),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.star_outline,
                      size: 60,
                      color: AppColors.lightGrey,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No reviews yet',
                      style: TextStyle(
                        color: AppColors.grey,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              )
            else
              Column(
                children: reviews.map((review) => _buildReviewCard(review)).toList(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildReviewCard(ReviewModel review) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      color: AppColors.white,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  review.customerName ?? 'Customer',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textColor,
                  ),
                ),
                RatingBarIndicator(
                  rating: (review.rating ?? 0).toDouble(),
                  itemBuilder: (context, index) => Icon(
                    Icons.star,
                    color: AppColors.secondaryColor,
                    size: 16,
                  ),
                  itemCount: 5,
                  itemSize: 16,
                ),
              ],
            ),

            const SizedBox(height: 12),

            Text(
              review.comment ?? '',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textColor,
                height: 1.5,
              ),
            ),

            const SizedBox(height: 12),

            Text(
              review.createdAt ?? '',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}