import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:artist_hub/core/constants/app_colors.dart';
import 'package:artist_hub/core/services/api_service.dart';
import 'package:artist_hub/core/services/shared_pref.dart';
import 'package:artist_hub/core/widgets/custom_button.dart';
import 'package:artist_hub/core/widgets/custom_textfield.dart';
import 'package:artist_hub/utils/helpers.dart';

class AddReviewScreen extends StatefulWidget {
  final int bookingId;
  final int artistId;
  final String artistName;

  const AddReviewScreen({
    super.key,
    required this.bookingId,
    required this.artistId,
    required this.artistName,
  });

  @override
  State<AddReviewScreen> createState() => _AddReviewScreenState();
}

class _AddReviewScreenState extends State<AddReviewScreen> {
  final _formKey = GlobalKey<FormState>();
  final _commentController = TextEditingController();

  double _rating = 0.0;
  bool _isSubmitting = false;
  bool _hasSubmitted = false;

  Future<void> _submitReview() async {
    if (!_formKey.currentState!.validate()) return;
    if (_rating == 0.0) {
      Helpers.showSnackbar(context, 'Please select a rating', isError: true);
      return;
    }

    final hasInternet = await Helpers.checkInternetBeforeApiCall(context);
    if (!hasInternet) return;

    setState(() => _isSubmitting = true);

    final customerId = SharedPref.getUserId();
    if (customerId.isEmpty) {
      Helpers.showSnackbar(context, 'User not found', isError: true);
      setState(() => _isSubmitting = false);
      return;
    }

    try {
      final result = await ApiService.addReview(
        bookingId: widget.bookingId,
        artistId: widget.artistId,
        customerId: int.parse(customerId),
        rating: _rating.round(),
        comment: _commentController.text.trim(),
      );

      if (result['success'] == true) {
        setState(() => _hasSubmitted = true);
        Helpers.showSnackbar(context, 'Review submitted successfully!');

        // Wait a moment and then go back
        await Future.delayed(const Duration(seconds: 1));
        if (!mounted) return;
        Navigator.pop(context);
      } else {
        Helpers.showSnackbar(
          context,
          result['message'] ?? 'Failed to submit review',
          isError: true,
        );
      }
    } catch (e) {
      Helpers.showSnackbar(context, 'Error: $e', isError: true);
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Add Review'),
      ),
      body: _hasSubmitted
          ? _buildSuccessScreen()
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Artist info
              _buildArtistInfo(),

              const SizedBox(height: 32),

              // Rating section
              _buildRatingSection(),

              const SizedBox(height: 24),

              // Comment section
              _buildCommentSection(),

              const SizedBox(height: 32),

              // Submit button
              CustomButton(
                text: _isSubmitting ? 'Submitting...' : 'Submit Review',
                onPressed:  _submitReview,
                isLoading: _isSubmitting,
                backgroundColor: AppColors.primaryColor,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildArtistInfo() {
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
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: AppColors.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(30),
            ),
            child: Center(
              child: Text(
                Helpers.getInitials(widget.artistName),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryColor,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.artistName,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textColor,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Please share your experience',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.darkGrey,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'Booking #${widget.bookingId}',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.primaryColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRatingSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Rate your experience',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.textColor,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'How would you rate this artist?',
          style: TextStyle(
            fontSize: 14,
            color: AppColors.darkGrey,
          ),
        ),
        const SizedBox(height: 20),

        Center(
          child: Column(
            children: [
              // Star rating
              RatingBar.builder(
                initialRating: _rating,
                minRating: 1,
                direction: Axis.horizontal,
                allowHalfRating: false,
                itemCount: 5,
                itemSize: 48,
                itemPadding: const EdgeInsets.symmetric(horizontal: 4),
                itemBuilder: (context, _) => const Icon(
                  Icons.star,
                  color: AppColors.secondaryColor,
                ),
                onRatingUpdate: (rating) {
                  setState(() => _rating = rating);
                },
              ),
              const SizedBox(height: 16),

              // Rating text
              Text(
                _getRatingText(),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: _getRatingColor(),
                ),
              ),
              const SizedBox(height: 8),

              // Rating description
              Text(
                _getRatingDescription(),
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.darkGrey,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _getRatingText() {
    if (_rating == 0) return 'Select a rating';
    if (_rating == 1) return 'Poor';
    if (_rating == 2) return 'Fair';
    if (_rating == 3) return 'Good';
    if (_rating == 4) return 'Very Good';
    return 'Excellent';
  }

  Color _getRatingColor() {
    if (_rating == 0) return AppColors.darkGrey;
    if (_rating == 1) return AppColors.errorColor;
    if (_rating == 2) return AppColors.warningColor;
    if (_rating == 3) return Colors.orange;
    if (_rating == 4) return Colors.lightGreen;
    return AppColors.successColor;
  }

  String _getRatingDescription() {
    if (_rating == 0) return 'Tap the stars to rate';
    if (_rating == 1) return 'Very disappointed';
    if (_rating == 2) return 'Could be better';
    if (_rating == 3) return 'Met expectations';
    if (_rating == 4) return 'Exceeded expectations';
    return 'Outstanding experience';
  }

  Widget _buildCommentSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Share your experience',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.textColor,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Tell others about your experience with this artist',
          style: TextStyle(
            fontSize: 14,
            color: AppColors.darkGrey,
          ),
        ),
        const SizedBox(height: 16),

        CustomTextField(
          controller: _commentController,
          labelText: 'Your Review',
          hintText: 'What did you like about this artist? What could be improved?\n\nBe specific and helpful for other customers...',
          maxLines: 5,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please share your experience';
            }
            if (value.trim().length < 10) {
              return 'Please write at least 10 characters';
            }
            if (value.trim().length > 500) {
              return 'Review cannot exceed 500 characters';
            }
            return null;
          },
        ),

        const SizedBox(height: 8),

        // Character counter
        Align(
          alignment: Alignment.centerRight,
          child: Text(
            '${_commentController.text.length}/500',
            style: TextStyle(
              fontSize: 12,
              color: _commentController.text.length > 500
                  ? AppColors.errorColor
                  : AppColors.darkGrey,
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Tips for good reviews
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.primaryColor.withOpacity(0.2)),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Tips for a helpful review:',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryColor,
                ),
              ),
              SizedBox(height: 4),
              Text(
                '• Be specific about what you liked or didn\'t like\n'
                    '• Mention the artist\'s professionalism and talent\n'
                    '• Talk about the event setup and punctuality\n'
                    '• Keep it honest and constructive\n'
                    '• Avoid personal information',
                style: TextStyle(
                  fontSize: 11,
                  color: AppColors.primaryColor,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSuccessScreen() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.check_circle,
              size: 80,
              color: AppColors.successColor,
            ),
            const SizedBox(height: 24),
            const Text(
              'Review Submitted!',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: AppColors.textColor,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Thank you for sharing your experience.',
              style: TextStyle(
                fontSize: 16,
                color: AppColors.darkGrey,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Your review helps other customers make better decisions.',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.darkGrey,
              ),
            ),
            const SizedBox(height: 32),
            CustomButton(
              text: 'Go Back',
              onPressed: () => Navigator.pop(context),
              backgroundColor: AppColors.primaryColor,
            ),
          ],
        ),
      ),
    );
  }
}