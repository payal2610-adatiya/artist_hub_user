import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:artist_hub/core/constants/app_colors.dart';
import 'package:artist_hub/core/routes/app_routes.dart';
import 'package:artist_hub/core/services/api_service.dart';
import 'package:artist_hub/core/services/shared_pref.dart';
import 'package:artist_hub/core/widgets/custom_button.dart';
import 'package:artist_hub/core/widgets/loading_widget.dart';
import 'package:artist_hub/models/artist_model.dart';
import 'package:artist_hub/models/review_model.dart';
import 'package:artist_hub/utils/helpers.dart';

import '../reviews/add_review_screen.dart';

// Portfolio Item Model with like/comment data
class PortfolioItem {
  final int id;
  final int artistId;
  final String mediaType;
  final String mediaUrl;
  final String? caption;
  final int likeCount;
  final int commentCount;
  final int shareCount;
  final bool isLiked;
  final DateTime createdAt;

  PortfolioItem({
    required this.id,
    required this.artistId,
    required this.mediaType,
    required this.mediaUrl,
    this.caption,
    required this.likeCount,
    required this.commentCount,
    required this.shareCount,
    required this.isLiked,
    required this.createdAt,
  });

// Update the PortfolioItem.fromJson() method in ArtistDetailScreen
  factory PortfolioItem.fromJson(Map<String, dynamic> json) {
    // Safe parsing for ID
    int? id;
    try {
      if (json['media_id'] != null) {
        id = int.tryParse(json['media_id'].toString()) ??
            int.tryParse(json['id'].toString()) ?? 0;
      } else if (json['id'] != null) {
        id = int.tryParse(json['id'].toString()) ?? 0;
      } else {
        id = 0;
      }
    } catch (e) {
      print('Error parsing ID: $e');
      id = 0;
    }

    // Safe parsing for other fields
    int? artistId;
    try {
      artistId = int.tryParse(json['artist_id']?.toString() ?? '0') ?? 0;
    } catch (e) {
      artistId = 0;
    }

    // Safe parsing for counts
    int likeCount = 0;
    try {
      if (json['total_likes'] != null) {
        likeCount = int.tryParse(json['total_likes'].toString()) ?? 0;
      } else if (json['like_count'] != null) {
        likeCount = int.tryParse(json['like_count'].toString()) ?? 0;
      }
    } catch (e) {
      likeCount = 0;
    }

    int commentCount = 0;
    try {
      if (json['total_comments'] != null) {
        commentCount = int.tryParse(json['total_comments'].toString()) ?? 0;
      } else if (json['comment_count'] != null) {
        commentCount = int.tryParse(json['comment_count'].toString()) ?? 0;
      }
    } catch (e) {
      commentCount = 0;
    }

    int shareCount = 0;
    try {
      if (json['total_shares'] != null) {
        shareCount = int.tryParse(json['total_shares'].toString()) ?? 0;
      } else if (json['share_count'] != null) {
        shareCount = int.tryParse(json['share_count'].toString()) ?? 0;
      }
    } catch (e) {
      shareCount = 0;
    }

    // Parse date safely
    DateTime createdAt;
    try {
      if (json['created_at'] != null) {
        createdAt = DateTime.parse(json['created_at'].toString());
      } else {
        createdAt = DateTime.now();
      }
    } catch (e) {
      createdAt = DateTime.now();
    }

    return PortfolioItem(
      id: id,
      artistId: artistId,
      mediaType: json['media_type']?.toString() ?? 'image',
      mediaUrl: json['media_url']?.toString() ?? '',
      caption: json['caption']?.toString(),
      likeCount: likeCount,
      commentCount: commentCount,
      shareCount: shareCount,
      isLiked: json['is_liked'] == true ||
          json['is_liked'] == 1 ||
          json['is_liked'] == '1' ||
          json['liked'] == true, // Check both field names
      createdAt: createdAt,
    );
  }
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'artist_id': artistId,
      'media_type': mediaType,
      'media_url': mediaUrl,
      'caption': caption,
      'like_count': likeCount,
      'comment_count': commentCount,
      'share_count': shareCount,
      'is_liked': isLiked,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

// Comment Model
class PortfolioComment {
  final int id;
  final int userId;
  final String userName;
  final int mediaId;
  final String comment;
  final DateTime createdAt;

  PortfolioComment({
    required this.id,
    required this.userId,
    required this.userName,
    required this.mediaId,
    required this.comment,
    required this.createdAt,
  });

  factory PortfolioComment.fromJson(Map<String, dynamic> json) {
    return PortfolioComment(
      id: int.parse(json['id'].toString()),
      userId: int.parse(json['user_id']?.toString() ?? '0'),
      userName: json['user_name']?.toString() ?? 'User',
      mediaId: int.parse(json['media_id']?.toString() ?? '0'),
      comment: json['comment']?.toString() ?? '',
      createdAt: DateTime.parse(json['created_at']?.toString() ?? DateTime.now().toIso8601String()),
    );
  }
}

class ArtistDetailScreen extends StatefulWidget {
  final int artistId;

  const ArtistDetailScreen({super.key, required this.artistId});

  @override
  State<ArtistDetailScreen> createState() => _ArtistDetailScreenState();
}

class _ArtistDetailScreenState extends State<ArtistDetailScreen> {
  ArtistModel? _artist;
  List<ReviewModel> _reviews = [];
  List<PortfolioItem> _portfolio = [];
  bool _isLoading = true;
  bool _hasError = false;
  int _selectedTab = 0; // 0: About, 1: Portfolio, 2: Reviews

  // State for portfolio interactions
  Map<int, bool> _portfolioLikes = {};
  Map<int, int> _portfolioLikeCounts = {};
  Map<int, int> _portfolioCommentCounts = {};
  Map<int, bool> _portfolioCommentVisibility = {};
  Map<int, List<PortfolioComment>> _portfolioComments = {};
  Map<int, TextEditingController> _portfolioCommentControllers = {};

  @override
  void initState() {
    super.initState();
    _loadArtistDetails();
  }

  @override
  void dispose() {
    // Dispose all comment controllers
    _portfolioCommentControllers.values.forEach((controller) => controller.dispose());
    super.dispose();
  }

  Future<void> _loadArtistDetails() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      // Load artist details
      final artistResult = await ApiService.getArtistDetails(widget.artistId);
      if (artistResult['success'] == true && artistResult['data'] != null) {
        setState(() {
          _artist = ArtistModel.fromJson(artistResult['data']);
        });
      }

      // Load reviews
      final reviewsResult = await ApiService.getReviewsByArtist(artistId: widget.artistId);
      if (reviewsResult['success'] == true && reviewsResult['data'] != null) {
        final List<dynamic> data = reviewsResult['data'];
        setState(() {
          _reviews = data.map((item) => ReviewModel.fromJson(item)).toList();
        });
      }

      // Load portfolio with stats
      await _loadPortfolioWithStats();

    } catch (e) {
      setState(() => _hasError = true);
      print('Error loading artist details: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadPortfolioWithStats() async {
    try {
      // First get portfolio items
      final portfolioResult = await ApiService.getArtistMedia(artistId: widget.artistId);

      if (portfolioResult['success'] == true && portfolioResult['data'] != null) {
        final dynamic data = portfolioResult['data'];
        final List<PortfolioItem> portfolioItems = [];

        if (data is List) {
          for (var item in data) {
            try {
              if (item is Map<String, dynamic>) {
                // Log the raw data for debugging
                print('Raw portfolio item: $item');

                final portfolioItem = PortfolioItem.fromJson(item);
                portfolioItems.add(portfolioItem);

                // Initialize state for this portfolio item
                _portfolioLikes[portfolioItem.id] = portfolioItem.isLiked;
                _portfolioLikeCounts[portfolioItem.id] = portfolioItem.likeCount;
                _portfolioCommentCounts[portfolioItem.id] = portfolioItem.commentCount;
                _portfolioCommentVisibility[portfolioItem.id] = false;
                _portfolioComments[portfolioItem.id] = [];
                _portfolioCommentControllers[portfolioItem.id] = TextEditingController();

                // Load initial comments for this item (only if we have comments)
                if (portfolioItem.commentCount > 0) {
                  await _loadCommentsForPortfolio(portfolioItem.id);
                }
              }
            } catch (e) {
              print('Error parsing portfolio item: $e');
              print('Item data: $item');
            }
          }

          setState(() {
            _portfolio = portfolioItems;
          });
        }
      } else {
        print('Failed to load portfolio: ${portfolioResult['message']}');
      }
    } catch (e) {
      print('Error loading portfolio: $e');
    }
  }
  Future<void> _loadCommentsForPortfolio(int mediaId) async {
    try {
      final commentsResult = await ApiService.getComments(mediaId: mediaId);
      if (commentsResult['success'] == true && commentsResult['data'] != null) {
        final data = commentsResult['data'];
        if (data is Map && data['comments'] is List) {
          final comments = (data['comments'] as List)
              .map((comment) => PortfolioComment.fromJson(comment))
              .toList();

          setState(() {
            _portfolioComments[mediaId] = comments;
          });
        }
      }
    } catch (e) {
      print('Error loading comments for media $mediaId: $e');
    }
  }

  Future<void> _toggleLike(int mediaId) async {
    try {
      final userId = await SharedPref.getUserId();
      if (userId.isEmpty) {
        Helpers.showSnackbar(context, 'Please login to like', isError: true);
        return;
      }

      print('Toggle Like - User ID: $userId, Media ID: $mediaId');

      // Check internet connection
      final hasInternet = await Helpers.checkInternetBeforeApiCall(context);
      if (!hasInternet) {
        print('No internet connection');
        return;
      }

      // Call API
      final result = await ApiService.toggleLike(
        userId: int.parse(userId),
        mediaId: mediaId,
      );

      print('Toggle Like API Response: $result');

      if (result['success'] == true) {
        final data = result['data'];
        if (data != null) {
          final isLiked = data['like_status'] == 'liked';
          final totalLikes = int.tryParse(data['total_likes']?.toString() ?? '0') ??
              (_portfolioLikeCounts[mediaId] ?? 0);

          print('Like status updated: isLiked=$isLiked, totalLikes=$totalLikes');

          setState(() {
            _portfolioLikes[mediaId] = isLiked;
            _portfolioLikeCounts[mediaId] = totalLikes;

            // Update the portfolio item in the list
            final index = _portfolio.indexWhere((item) => item.id == mediaId);
            if (index != -1) {
              final updatedItem = PortfolioItem(
                id: _portfolio[index].id,
                artistId: _portfolio[index].artistId,
                mediaType: _portfolio[index].mediaType,
                mediaUrl: _portfolio[index].mediaUrl,
                caption: _portfolio[index].caption,
                likeCount: totalLikes,
                commentCount: _portfolio[index].commentCount,
                shareCount: _portfolio[index].shareCount,
                isLiked: isLiked,
                createdAt: _portfolio[index].createdAt,
              );
              _portfolio[index] = updatedItem;
            }
          });

          Helpers.showSnackbar(context, 'Post ${isLiked ? 'liked' : 'unliked'}');
        } else {
          print('Toggle Like API returned success but no data');
          Helpers.showSnackbar(context, 'Like action completed', isError: false);
        }
      } else {
        final errorMessage = result['message'] ?? 'Failed to toggle like';
        print('Toggle Like API Error: $errorMessage');
        Helpers.showSnackbar(context, errorMessage, isError: true);
      }
    } catch (e) {
      print('Toggle Like Exception: $e');
      Helpers.showSnackbar(context, 'Failed to like: $e', isError: true);
    }
  }
  Future<void> _addComment(int mediaId) async {
    final controller = _portfolioCommentControllers[mediaId];
    if (controller == null) return;

    final comment = controller.text.trim();
    if (comment.isEmpty) {
      Helpers.showSnackbar(context, 'Please enter a comment', isError: true);
      return;
    }

    final userId = await SharedPref.getUserId();
    if (userId.isEmpty) {
      Helpers.showSnackbar(context, 'Please login to comment', isError: true);
      return;
    }

    final hasInternet = await Helpers.checkInternetBeforeApiCall(context);
    if (!hasInternet) return;

    try {
      final result = await ApiService.addComment(
        userId: int.parse(userId),
        mediaId: mediaId,
        comment: comment,
      );

      if (result['success'] == true) {
        controller.clear();
        Helpers.showSnackbar(context, 'Comment added successfully');

        // Reload comments
        await _loadCommentsForPortfolio(mediaId);

        // Update comment count
        setState(() {
          _portfolioCommentCounts[mediaId] = (_portfolioCommentCounts[mediaId] ?? 0) + 1;

          // Update the portfolio item in the list
          final index = _portfolio.indexWhere((item) => item.id == mediaId);
          if (index != -1) {
            final updatedItem = PortfolioItem(
              id: _portfolio[index].id,
              artistId: _portfolio[index].artistId,
              mediaType: _portfolio[index].mediaType,
              mediaUrl: _portfolio[index].mediaUrl,
              caption: _portfolio[index].caption,
              likeCount: _portfolio[index].likeCount,
              commentCount: _portfolioCommentCounts[mediaId]!,
              shareCount: _portfolio[index].shareCount,
              isLiked: _portfolio[index].isLiked,
              createdAt: _portfolio[index].createdAt,
            );
            _portfolio[index] = updatedItem;
          }
        });
      } else {
        Helpers.showSnackbar(
          context,
          result['message'] ?? 'Failed to add comment',
          isError: true,
        );
      }
    } catch (e) {
      Helpers.showSnackbar(context, 'Error: $e', isError: true);
    }
  }

  Future<void> _toggleCommentsVisibility(int mediaId) {
    setState(() {
      _portfolioCommentVisibility[mediaId] = !(_portfolioCommentVisibility[mediaId] ?? false);
    });
    return Future.value();
  }

  void _bookArtist() {
    if (_artist != null) {
      Navigator.pushNamed(
        context,
        AppRoutes.createBooking,
        arguments: {
          'artist': _artist!.toJson(),
        },
      );
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        iconTheme: IconThemeData(color: Colors.white),
        backgroundColor: AppColors.primaryColor,
        title: Text(_artist?.name ?? 'Artist Details',style: TextStyle(color: Colors.white),),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadArtistDetails,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const LoadingWidget(message: 'Loading artist details...')
          : _hasError || _artist == null
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: AppColors.errorColor,
            ),
            const SizedBox(height: 16),
            const Text(
              'Failed to load artist details',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textColor,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Please check your connection and try again',
              style: TextStyle(
                color: AppColors.darkGrey,
              ),
            ),
            const SizedBox(height: 24),
            CustomButton(
              text: 'Retry',
              onPressed: _loadArtistDetails,
            ),
          ],
        ),
      )
          : _buildContent(),
      bottomNavigationBar: _artist != null
          ? SafeArea(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.white,
            border: Border(top: BorderSide(color: AppColors.lightGrey)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Starting from',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.darkGrey,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '₹${_artist!.price ?? 'Contact for price'}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryColor,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 150,
                child: CustomButton(
                  text: 'Book Now',
                  onPressed: _bookArtist,
                  backgroundColor: AppColors.primaryColor,
                ),
              ),
            ],
          ),
        ),
      )
          : null,
    );
  }

  Widget _buildContent() {
    return SingleChildScrollView(
      child: Column(
        children: [
          // Artist header
          _buildArtistHeader(),

          // Tab bar
          _buildTabBar(),

          // Tab content
          _buildTabContent(),
        ],
      ),
    );
  }

  Widget _buildArtistHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Artist avatar
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
                  child: Text(
                    Helpers.getInitials(_artist!.name ?? 'A'),
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryColor,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 20),

              // Artist info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _artist!.name ?? 'Artist',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textColor,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 2,
                    ),
                    const SizedBox(height: 4),
                    if (_artist!.category != null && _artist!.category!.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          _artist!.category!,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: AppColors.primaryColor,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _buildRatingStars(_artist!.avgRating ?? 0.0),
                        const SizedBox(width: 8),
                        Text(
                          '${(_artist!.avgRating ?? 0.0).toStringAsFixed(1)} (${_artist!.totalReviews ?? 0} reviews)',
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.darkGrey,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Stats
// In _buildArtistHeader method, update the stats Row:
          Wrap(
            spacing: 20,
            runSpacing: 10,
            alignment: WrapAlignment.spaceAround,
            children: [
              _buildStatItem('Experience', _artist!.experience ?? 'N/A'),
              //_buildStatItem('Bookings', (_artist!.totalBookings ?? 0).toString()),
            //  _buildStatItem('Posts', _portfolio.length.toString()),
            ],
          ),        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Container(
      constraints: const BoxConstraints(minWidth: 80),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.primaryColor,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.darkGrey,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: AppColors.white,
      child: Row(
        children: [
          Expanded(
            child: _buildTabButton(0, 'About'),
          ),
          Expanded(
            child: _buildTabButton(1, 'Portfolio (${_portfolio.length})'),
          ),
          Expanded(
            child: _buildTabButton(2, 'Reviews (${_reviews.length})'),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton(int index, String label) {
    final isSelected = _selectedTab == index;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          setState(() => _selectedTab = index);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isSelected ? AppColors.primaryColor : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected ? AppColors.primaryColor : AppColors.darkGrey,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTabContent() {
    switch (_selectedTab) {
      case 0:
        return _buildAboutTab();
      case 1:
        return _buildPortfolioTab();
      case 2:
        return _buildReviewsTab();
      default:
        return const SizedBox();
    }
  }

  Widget _buildAboutTab() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'About',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textColor,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _artist!.description ?? 'No description available',
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.darkGrey,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Contact Information',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textColor,
            ),
          ),
          const SizedBox(height: 12),
          _buildContactItem(
            icon: Icons.phone,
            label: 'Phone',
            value: _artist!.phone ?? 'Not available',
          ),
          const SizedBox(height: 12),
          _buildContactItem(
            icon: Icons.email,
            label: 'Email',
            value: _artist!.email ?? 'Not available',
          ),
          const SizedBox(height: 12),
          _buildContactItem(
            icon: Icons.location_on,
            label: 'Location',
            value: _artist!.address ?? 'Not available',
          ),
        ],
      ),
    );
  }

  Widget _buildContactItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Icon(icon, size: 20, color: AppColors.primaryColor),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.darkGrey,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textColor,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPortfolioTab() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Portfolio',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textColor,
            ),
          ),
          const SizedBox(height: 12),
          if (_portfolio.isEmpty)
            Container(
              padding: const EdgeInsets.all(40),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.photo_library_outlined,
                    size: 64,
                    color: AppColors.lightGrey,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'No portfolio items',
                    style: TextStyle(
                      fontSize: 16,
                      color: AppColors.darkGrey,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Artist hasn\'t uploaded any portfolio items yet',
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
              children: _portfolio.map((item) => _buildPortfolioItem(item)).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildPortfolioItem(PortfolioItem item) {
    final mediaUrl = item.mediaUrl.startsWith('http')
        ? item.mediaUrl
        : 'https://prakrutitech.xyz/gaurang/${item.mediaUrl}';

    final isLiked = _portfolioLikes[item.id] ?? false;
    final likeCount = _portfolioLikeCounts[item.id] ?? 0;
    final commentCount = _portfolioCommentCounts[item.id] ?? 0;
    final showComments = _portfolioCommentVisibility[item.id] ?? false;
    final comments = _portfolioComments[item.id] ?? [];
    final commentController = _portfolioCommentControllers[item.id];

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Media content
          GestureDetector(
            onTap: () {
              // Open full screen view or detail screen
              Navigator.pushNamed(
                context,
                AppRoutes.mediaDetail,
                arguments: {
                  'media': {
                    'id': item.id,
                    'media_type': item.mediaType,
                    'media_url': mediaUrl,
                    'caption': item.caption,
                    'like_count': likeCount,
                    'comment_count': commentCount,
                    'artist_name': _artist?.name,
                  },
                  'artistName': _artist?.name,
                },
              );
            },
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              child: Container(
                height: 250,
                color: AppColors.lightGrey,
                child: item.mediaType == 'image'
                    ? CachedNetworkImage(
                  imageUrl: mediaUrl,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Center(
                    child: CircularProgressIndicator(
                      color: AppColors.primaryColor,
                    ),
                  ),
                  errorWidget: (context, url, error) => Center(
                    child: Icon(
                      Icons.broken_image,
                      color: AppColors.grey,
                      size: 48,
                    ),
                  ),
                )
                    : Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.videocam,
                        size: 64,
                        color: AppColors.secondaryColor,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Video Content',
                        style: TextStyle(
                          color: AppColors.secondaryColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Caption and stats
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (item.caption != null && item.caption!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      item.caption!,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textColor,
                      ),
                    ),
                  ),
// In _buildPortfolioItem method, update the Row widget:
                Row(
                  children: [
                    // Like button and count
                    GestureDetector(
                      onTap: () => _toggleLike(item.id),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isLiked ? Icons.favorite : Icons.favorite_border,
                              color: isLiked ? Colors.red : AppColors.grey,
                              size: 20,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              likeCount.toString(),
                              style: TextStyle(
                                fontSize: 14,
                                color: isLiked ? Colors.red : AppColors.darkGrey,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Comment button and count
                    GestureDetector(
                      onTap: () => _toggleCommentsVisibility(item.id),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.comment_outlined,
                              color: showComments ? AppColors.primaryColor : AppColors.grey,
                              size: 20,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              commentCount.toString(),
                              style: TextStyle(
                                fontSize: 14,
                                color: showComments ? AppColors.primaryColor : AppColors.darkGrey,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const Spacer(),

                    // Date - wrap in Flexible to prevent overflow
                    Flexible(
                      child: Text(
                        Helpers.timeAgo(item.createdAt.toString()),
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.grey,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),              ],
            ),
          ),

          // Comments section
          if (showComments)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: _buildCommentsSection(item.id, comments, commentController),
            ),
        ],
      ),
    );
  }

  Widget _buildCommentsSection(int mediaId, List<PortfolioComment> comments, TextEditingController? controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Comments list
        if (comments.isNotEmpty)
          Column(
            children: comments.map((comment) => _buildCommentItem(comment)).toList(),
          )
        else
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Center(
              child: Text(
                'No comments yet',
                style: TextStyle(
                  color: AppColors.grey,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ),

        const SizedBox(height: 12),

        // Add comment input
        if (controller != null)
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  decoration: InputDecoration(
                    hintText: 'Write a comment...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: BorderSide(color: AppColors.lightGrey),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    filled: true,
                    fillColor: AppColors.backgroundColor,
                  ),
                  maxLines: 1,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.primaryColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: IconButton(
                  icon: const Icon(Icons.send, color: Colors.white, size: 20),
                  onPressed: () => _addComment(mediaId),
                  padding: const EdgeInsets.all(8),
                ),
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildCommentItem(PortfolioComment comment) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.backgroundColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: AppColors.primaryColor.withOpacity(0.1),
            child: Text(
              Helpers.getInitials(comment.userName),
              style: TextStyle(
                fontSize: 12,
                color: AppColors.primaryColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  comment.userName,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  comment.comment,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.darkGrey,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  Helpers.timeAgo(comment.createdAt.toString()),
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppColors.grey,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Widget _buildReviewsTab() {
  //   return Padding(
  //     padding: const EdgeInsets.all(20),
  //     child: Column(
  //       crossAxisAlignment: CrossAxisAlignment.start,
  //       children: [
  //         const Text(
  //           'Reviews',
  //           style: TextStyle(
  //             fontSize: 18,
  //             fontWeight: FontWeight.w600,
  //             color: AppColors.textColor,
  //           ),
  //         ),
  //         const SizedBox(height: 12),
  //         if (_reviews.isEmpty)
  //           Container(
  //             padding: const EdgeInsets.all(40),
  //             decoration: BoxDecoration(
  //               color: AppColors.white,
  //               borderRadius: BorderRadius.circular(12),
  //             ),
  //             child: Column(
  //               children: [
  //                 const Icon(
  //                   Icons.reviews_outlined,
  //                   size: 64,
  //                   color: AppColors.lightGrey,
  //                 ),
  //                 const SizedBox(height: 16),
  //                 const Text(
  //                   'No reviews yet',
  //                   style: TextStyle(
  //                     fontSize: 16,
  //                     color: AppColors.darkGrey,
  //                   ),
  //                 ),
  //                 const SizedBox(height: 8),
  //                 Text(
  //                   'Be the first to review this artist',
  //                   style: TextStyle(
  //                     fontSize: 14,
  //                     color: AppColors.darkGrey.withOpacity(0.8),
  //                   ),
  //                   textAlign: TextAlign.center,
  //                 ),
  //               ],
  //             ),
  //           )
  //         else
  //           Column(
  //             children: _reviews.map((review) => _buildReviewItem(review)).toList(),
  //           ),
  //       ],
  //     ),
  //   );
  // }
// In _buildReviewsTab() method, add this widget:
  Widget _buildReviewsTab() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Reviews',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textColor,
                ),
              ),

              // Add Review Button
              FutureBuilder<bool>(
                future: _hasCompletedBooking(),
                builder: (context, snapshot) {
                  if (snapshot.data == true) {
                    return CustomButton(
                      text: 'Write Review',
                      onPressed: () => _openAddReviewScreen(),
                      backgroundColor: AppColors.primaryColor,

                    );
                  }
                  return const SizedBox();
                },
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Add this back - you commented it out!
          if (_reviews.isEmpty)
            _buildEmptyReviews()
          else
            Column(
              children: _reviews.map((review) => _buildReviewItem(review)).toList(),
            ),
        ],
      ),
    );
  }
// Add this method to check if user has completed booking with artist
  Future<bool> _hasCompletedBooking() async {
    try {
      final userId = await SharedPref.getUserId();
      if (userId.isEmpty) return false;

      final result = await ApiService.getBookingsByCustomer(
        customerId: int.parse(userId),
      );

      if (result['success'] == true && result['data'] != null) {
        final List<dynamic> bookings = result['data'];

        // Check if any completed booking exists with this artist
        for (var booking in bookings) {
          // Convert artist_id to int
          final artistId = int.tryParse(booking['artist_id']?.toString() ?? '0');
          final status = booking['status']?.toString().toLowerCase() ?? '';

          if (artistId == widget.artistId && status == 'completed') {
            return true;
          }
        }
      }
    } catch (e) {
      print('Error checking completed bookings: $e');
    }
    return false;
  }
// Method to open Add Review Screen
  void _openAddReviewScreen() async {
    try {
      final userId = await SharedPref.getUserId();
      if (userId.isEmpty) {
        Helpers.showSnackbar(context, 'Please login to write a review', isError: true);
        return;
      }

      // Get the latest completed booking for this artist
      final result = await ApiService.getBookingsByCustomer(
        customerId: int.parse(userId),
      );

      if (result['success'] == true && result['data'] != null) {
        final List<dynamic> bookings = result['data'];

        // Find the most recent completed booking for this artist
        final List<Map<String, dynamic>> completedBookings = [];

        for (var booking in bookings) {
          final artistId = int.tryParse(booking['artist_id']?.toString() ?? '0');
          final status = booking['status']?.toString().toLowerCase() ?? '';
          final bookingId = int.tryParse(booking['id']?.toString() ?? '0');

          if (artistId == widget.artistId &&
              status == 'completed' &&
              bookingId != null &&
              bookingId > 0) {

            completedBookings.add({
              'id': bookingId,
              'booking_date': booking['booking_date']?.toString() ?? '',
              'booking': booking, // Keep the original booking data
            });
          }
        }

        if (completedBookings.isEmpty) {
          Helpers.showSnackbar(
            context,
            'No completed bookings found for this artist',
            isError: true,
          );
          return;
        }

        // Sort by date (most recent first)
        completedBookings.sort((a, b) {
          final dateA = a['booking_date'] as String;
          final dateB = b['booking_date'] as String;
          return dateB.compareTo(dateA);
        });

        final bookingData = completedBookings.first['booking'] as Map<String, dynamic>;
        final bookingId = int.tryParse(bookingData['id']?.toString() ?? '0') ?? 0;

        if (bookingId == 0) {
          Helpers.showSnackbar(context, 'Invalid booking ID', isError: true);
          return;
        }

        // Check if review already exists for this booking
        final hasReview = await _checkIfReviewExists(bookingId);
        if (hasReview) {
          Helpers.showSnackbar(
            context,
            'You have already reviewed this booking',
            isError: true,
          );
          return;
        }

        // ✅ CORRECT: Navigate to AddReviewScreen with proper parameters
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AddReviewScreen(
              bookingId: bookingId, // ✅ int
              artistId: widget.artistId, // ✅ int
              artistName: _artist?.name ?? 'Artist', // ✅ String
            ),
          ),
        ).then((_) {
          // Refresh after returning from review screen
          _loadArtistDetails();
        });
      }
    } catch (e) {
      print('Error opening add review: $e');
      Helpers.showSnackbar(context, 'Error: $e', isError: true);
    }
  }// Check if review already exists for booking
  Future<bool> _checkIfReviewExists(int bookingId) async {
    try {
      final reviewsResult = await ApiService.getReviewsByArtist(
        artistId: widget.artistId,
      );

      if (reviewsResult['success'] == true && reviewsResult['data'] != null) {
        final List<dynamic> reviews = reviewsResult['data'];
        final userId = await SharedPref.getUserId();

        return reviews.any((review) {
          return review['booking_id'] == bookingId &&
              review['customer_id'].toString() == userId;
        });
      }
    } catch (e) {
      print('Error checking review existence: $e');
    }
    return false;
  }
  Widget _buildReviewItem(ReviewModel review) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
                      overflow: TextOverflow.ellipsis,
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
              _buildRatingStars(review.rating.toDouble(), size: 16),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            review.comment,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textColor,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyReviews() {
    return Container(
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
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
          FutureBuilder<bool>(
            future: _hasCompletedBooking(),
            builder: (context, snapshot) {
              if (snapshot.data == true) {
                return Column(
                  children: [
                    const SizedBox(height: 16),
                    CustomButton(
                      text: 'Write First Review',
                      onPressed: _openAddReviewScreen,
                      backgroundColor: AppColors.primaryColor,
                    ),
                  ],
                );
              }
              return const SizedBox();
            },
          ),
        ],
      ),
    );
  }
}