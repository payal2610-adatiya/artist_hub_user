// lib/artist/media/media_detail_screen.dart
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
  final Map<String, dynamic> arguments;

  const MediaDetailScreen({super.key, required this.arguments});

  @override
  State<MediaDetailScreen> createState() => _MediaDetailScreenState();
}

class _MediaDetailScreenState extends State<MediaDetailScreen> {
  late MediaModel _media;
  late VideoPlayerController _videoController;
  bool _isVideoInitialized = false;
  bool _isLiked = false;
  int _likeCount = 0;
  int _commentCount = 0;
  int _shareCount = 0;
  bool _isLoading = true;
  bool _isOwnMedia = false;

  @override
  void initState() {
    super.initState();
    _media = MediaModel.fromJson(widget.arguments['media']);
    _isOwnMedia = widget.arguments['isOwnMedia'] ?? false;
    _likeCount = _media.likeCount;
    _commentCount = _media.commentCount;
    _shareCount = _media.shareCount;

    _loadMediaDetails();

    if (_media.isVideo) {
      _initializeVideoPlayer();
    }
  }

  Future<void> _loadMediaDetails() async {
    setState(() => _isLoading = true);

    try {
      // Load fresh media details
      final result = await ApiService.getMediaDetails(_media.id);

      if (result['success'] == true && result['data'] != null) {
        final mediaData = result['data'];
        if (mediaData is List && mediaData.isNotEmpty) {
          final updatedMedia = MediaModel.fromJson(mediaData[0]);
          setState(() {
            _likeCount = updatedMedia.likeCount;
            _commentCount = updatedMedia.commentCount;
            _shareCount = updatedMedia.shareCount;
            _media.caption = updatedMedia.caption;
          });
        }
      }

      // Check if current user has liked this media
      final userId = SharedPref.getUserId();
      if (userId.isNotEmpty) {
        // You would need an API endpoint to check like status
        // For now, we'll assume not liked
      }

    } catch (e) {
      print('Error loading media details: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _initializeVideoPlayer() async {
    _videoController = VideoPlayerController.networkUrl(
      Uri.parse(_media.mediaUrl),
    );

    await _videoController.initialize().then((_) {
      if (mounted) {
        setState(() {
          _isVideoInitialized = true;
        });
      }
    }).catchError((error) {
      print('Error initializing video player: $error');
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
        mediaId: _media.id,
      );

      if (result['success'] == true) {
        final data = result['data'];
        if (data != null) {
          setState(() {
            _isLiked = data['like_status'] == 'liked';
            _likeCount = data['total_likes'] ?? _likeCount;
          });

          Helpers.showSnackbar(context, 'Post ${_isLiked ? 'liked' : 'unliked'}');
        }
      }
    } catch (e) {
      Helpers.showSnackbar(context, 'Failed to like', isError: true);
    }
  }

  Future<void> _shareMedia() async {
    // Implement share functionality
    Helpers.showSnackbar(context, 'Share functionality coming soon');
  }

  Future<void> _viewComments() async {
    // Navigate to comments screen
    Helpers.showSnackbar(context, 'Comments coming soon');
  }

  Future<void> _deleteMedia() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Media'),
        content: const Text('Are you sure you want to delete this media? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.errorColor),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final userId = SharedPref.getUserId();
    if (userId.isEmpty) {
      Helpers.showSnackbar(context, 'Please login first', isError: true);
      return;
    }

    final hasInternet = await Helpers.checkInternetBeforeApiCall(context);
    if (!hasInternet) return;

    try {
      final result = await ApiService.deleteArtistMedia(
        mediaId: _media.id,
        artistId: int.parse(userId),
      );

      if (result['success'] == true) {
        Helpers.showSnackbar(context, 'Media deleted successfully');
        Navigator.pop(context, true); // Return success
      } else {
        Helpers.showSnackbar(
          context,
          result['message'] ?? 'Failed to delete media',
          isError: true,
        );
      }
    } catch (e) {
      Helpers.showSnackbar(context, 'Error: $e', isError: true);
    }
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
              child: _isLoading ? const LoadingWidget() : _buildMediaContent(),
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
              widget.arguments['artistName'] ?? 'Media',
              style: const TextStyle(
                color: AppColors.white,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (_isOwnMedia)
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: _deleteMedia,
              tooltip: 'Delete Media',
            ),
        ],
      ),
    );
  }

  Widget _buildMediaContent() {
    return GestureDetector(
      onTap: () {
        if (_media.isVideo && _isVideoInitialized) {
          setState(() {
            if (_videoController.value.isPlaying) {
              _videoController.pause();
            } else {
              _videoController.play();
            }
          });
        }
      },
      child: Center(
        child: _media.isImage
            ? InteractiveViewer(
          panEnabled: true,
          boundaryMargin: const EdgeInsets.all(20),
          minScale: 0.5,
          maxScale: 4,
          child: CachedNetworkImage(
            imageUrl: _media.mediaUrl,
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
          ),
        )
            : _media.isVideo && _isVideoInitialized
            ? Stack(
          alignment: Alignment.center,
          children: [
            VideoPlayer(_videoController),
            if (!_videoController.value.isPlaying)
              Icon(
                Icons.play_arrow,
                size: 64,
                color: AppColors.white.withOpacity(0.7),
              ),
          ],
        )
            : _media.isVideo
            ? Container(
          color: AppColors.black,
          child: const Center(
            child: CircularProgressIndicator(
              color: AppColors.primaryColor,
            ),
          ),
        )
            : Container(
          color: AppColors.black,
          child: const Center(
            child: Icon(
              Icons.broken_image,
              color: AppColors.white,
              size: 48,
            ),
          ),
        ),
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
          // Stats row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem(Icons.favorite, _likeCount.toString(), _isLiked ? Colors.red : null),
              _buildStatItem(Icons.comment, _commentCount.toString(), null),
              _buildStatItem(Icons.share, _shareCount.toString(), null),
              _buildStatItem(Icons.visibility, '0', null), // View count if available
            ],
          ),

          const SizedBox(height: 16),

          // Actions row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              IconButton(
                icon: Icon(
                  _isLiked ? Icons.favorite : Icons.favorite_border,
                  color: _isLiked ? Colors.red : AppColors.white,
                ),
                onPressed: _toggleLike,
                tooltip: 'Like',
              ),
              IconButton(
                icon: const Icon(Icons.comment_outlined, color: AppColors.white),
                onPressed: _viewComments,
                tooltip: 'Comments',
              ),
              IconButton(
                icon: const Icon(Icons.share_outlined, color: AppColors.white),
                onPressed: _shareMedia,
                tooltip: 'Share',
              ),
              IconButton(
                icon: const Icon(Icons.bookmark_border, color: AppColors.white),
                onPressed: () {
                  // Save to favorites
                },
                tooltip: 'Save',
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Caption
          if (_media.caption.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                _media.caption,
                style: const TextStyle(
                  color: AppColors.white,
                  fontSize: 14,
                ),
              ),
            ),

          const SizedBox(height: 8),

          // Upload date
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              Helpers.timeAgo(_media.createdAt.toIso8601String()),
              style: const TextStyle(
                color: AppColors.lightGrey,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String count, Color? color) {
    return Column(
      children: [
        Icon(icon, color: color ?? AppColors.white, size: 20),
        const SizedBox(height: 4),
        Text(
          count,
          style: const TextStyle(
            color: AppColors.white,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    if (_media.isVideo && _isVideoInitialized) {
      _videoController.dispose();
    }
    super.dispose();
  }
}