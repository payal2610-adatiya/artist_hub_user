import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:video_player/video_player.dart';
import 'package:artist_hub/core/constants/app_colors.dart';
import 'package:artist_hub/core/services/api_service.dart';
import 'package:artist_hub/core/services/shared_pref.dart';
import 'package:artist_hub/core/widgets/loading_widget.dart';
import 'package:artist_hub/models/media_model.dart';
import 'package:artist_hub/utils/helpers.dart';

class MediaDetailScreen extends StatefulWidget {
  final MediaModel media;

  const MediaDetailScreen({super.key, required this.media});

  @override
  State<MediaDetailScreen> createState() => _MediaDetailScreenState();
}

class _MediaDetailScreenState extends State<MediaDetailScreen> {
  late VideoPlayerController _videoController;
  bool _isVideoInitialized = false;
  bool _isLiked = false;
  int _likeCount = 0;
  int _commentCount = 0;
  int _shareCount = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _likeCount = widget.media.likeCount;
    _loadMediaDetails();

    if (widget.media.isVideo) {
      _initializeVideoPlayer();
    }
  }

  Future<void> _loadMediaDetails() async {
    setState(() => _isLoading = true);

    try {
      // Load additional media stats (likes, comments, shares)
      // This would require additional API endpoints
      // For now, we'll use the data from the media model

      // Check if current user has liked this media
      final userId = SharedPref.getUserId();
      if (userId.isNotEmpty) {
        // Check like status (would need API endpoint)
      }

    } catch (e) {
      // Silently fail
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _initializeVideoPlayer() async {
    _videoController = VideoPlayerController.network(widget.media.mediaUrl)
      ..initialize().then((_) {
        setState(() {
          _isVideoInitialized = true;
        });
      });
  }

  Future<void> _toggleLike() async {
    final userId = SharedPref.getUserId();
    if (userId.isEmpty) {
      Helpers.showSnackbar(context, 'Please login to like', isError: true);
      return;
    }

    final hasInternet = await Helpers.checkInternetBeforeApiCall(context);
    if (!hasInternet) return;

    try {
      final result = await ApiService.toggleLike(
        userId: int.parse(userId),
        mediaId: widget.media.id,
      );

      if (result['success'] == true) {
        setState(() {
          _isLiked = !_isLiked;
          _likeCount = result['data']?['total_likes'] ?? _likeCount;
        });
      }
    } catch (e) {
      Helpers.showSnackbar(context, 'Failed to like', isError: true);
    }
  }

  Future<void> _shareMedia() async {
    // Implement share functionality
    Helpers.showSnackbar(context, 'Share functionality coming soon');
  }

  void _viewComments() {
    // Navigate to comments screen
    Helpers.showSnackbar(context, 'Comments coming soon');
  }

  void _deleteMedia() async {
    final confirmed = await Helpers.showConfirmationDialog(
      context,
      'Delete Media',
      'Are you sure you want to delete this media? This action cannot be undone.',
    );

    if (!confirmed) return;

    final userId = SharedPref.getUserId();
    if (userId.isEmpty) {
      Helpers.showSnackbar(context, 'User not found', isError: true);
      return;
    }

    final hasInternet = await Helpers.checkInternetBeforeApiCall(context);
    if (!hasInternet) return;

    // Note: You'll need to add a delete media API endpoint
    Helpers.showSnackbar(context, 'Delete functionality coming soon');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.black,
      body: SafeArea(
        child: Column(
          children: [
            // App bar
            _buildAppBar(),

            // Media content
            Expanded(
              child: _buildMediaContent(),
            ),

            // Media info and actions
            _buildMediaInfo(),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Container(
      color: Colors.black.withOpacity(0.5),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.white),
            onPressed: () => Navigator.pop(context),
          ),
          Expanded(
            child: Text(
              widget.media.artistName,
              style: const TextStyle(
                color: AppColors.white,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.more_vert, color: AppColors.white),
            onPressed: () {
              _showMoreOptions();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMediaContent() {
    if (_isLoading) {
      return const LoadingWidget();
    }

    return GestureDetector(
      onTap: () {
        if (widget.media.isVideo && _isVideoInitialized) {
          setState(() {
            if (_videoController.value.isPlaying) {
              _videoController.pause();
            } else {
              _videoController.play();
            }
          });
        }
      },
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Media display
          if (widget.media.isImage)
            CachedNetworkImage(
              imageUrl: widget.media.mediaUrl,
              width: double.infinity,
              fit: BoxFit.contain,
              placeholder: (context, url) => Container(
                color: AppColors.black,
                child: const Center(
                  child: CircularProgressIndicator(
                    color: AppColors.primaryColor,
                  ),
                ),
              ),
              errorWidget: (context, url, error) => Container(
                color: AppColors.black,
                child: const Center(
                  child: Icon(
                    Icons.broken_image,
                    color: AppColors.white,
                    size: 48,
                  ),
                ),
              ),
            )
          else if (widget.media.isVideo && _isVideoInitialized)
            VideoPlayer(_videoController)
          else if (widget.media.isVideo)
              Container(
                color: AppColors.black,
                child: const Center(
                  child: CircularProgressIndicator(
                    color: AppColors.primaryColor,
                  ),
                ),
              ),

          // Play/pause button for video
          if (widget.media.isVideo && _isVideoInitialized)
            AnimatedOpacity(
              opacity: _videoController.value.isPlaying ? 0 : 1,
              duration: const Duration(milliseconds: 300),
              child: IconButton(
                icon: const Icon(
                  Icons.play_arrow,
                  size: 64,
                  color: AppColors.white,
                ),
                onPressed: () {
                  _videoController.play();
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMediaInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.5),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Actions row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  IconButton(
                    icon: Icon(
                      _isLiked ? Icons.favorite : Icons.favorite_border,
                      color: _isLiked ? Colors.red : AppColors.white,
                    ),
                    onPressed: _toggleLike,
                  ),
                  Text(
                    _likeCount.toString(),
                    style: const TextStyle(color: AppColors.white),
                  ),
                  const SizedBox(width: 20),
                  IconButton(
                    icon: const Icon(Icons.comment_outlined, color: AppColors.white),
                    onPressed: _viewComments,
                  ),
                  Text(
                    _commentCount.toString(),
                    style: const TextStyle(color: AppColors.white),
                  ),
                  const SizedBox(width: 20),
                  IconButton(
                    icon: const Icon(Icons.share_outlined, color: AppColors.white),
                    onPressed: _shareMedia,
                  ),
                  Text(
                    _shareCount.toString(),
                    style: const TextStyle(color: AppColors.white),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.bookmark_border, color: AppColors.white),
                onPressed: () {
                  // Save to favorites
                },
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Caption
          if (widget.media.caption.isNotEmpty)
            Text(
              widget.media.caption,
              style: const TextStyle(
                color: AppColors.white,
                fontSize: 14,
              ),
            ),

          const SizedBox(height: 8),

          // Upload date
          Text(
            Helpers.formatDateTime(widget.media.createdAt),
            style: const TextStyle(
              color: AppColors.lightGrey,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  void _showMoreOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      builder: (context) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 16),
            const Text(
              'Options',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textColor,
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.download, color: AppColors.textColor),
              title: const Text('Download'),
              onTap: () {
                Navigator.pop(context);
                // Implement download
              },
            ),
            ListTile(
              leading: const Icon(Icons.report_problem, color: AppColors.textColor),
              title: const Text('Report'),
              onTap: () {
                Navigator.pop(context);
                // Implement report
              },
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: AppColors.errorColor),
              title: const Text(
                'Delete',
                style: TextStyle(color: AppColors.errorColor),
              ),
              onTap: () {
                Navigator.pop(context);
                _deleteMedia();
              },
            ),
            const SizedBox(height: 16),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    if (widget.media.isVideo) {
      _videoController.dispose();
    }
    super.dispose();
  }
}