// lib/customer/media/media_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:video_player/video_player.dart';
import 'package:artist_hub/core/constants/app_colors.dart';
import 'package:artist_hub/core/services/api_service.dart';
import 'package:artist_hub/core/services/shared_pref.dart';
import 'package:artist_hub/core/widgets/loading_widget.dart';
import 'package:artist_hub/models/media_model.dart';
import 'package:artist_hub/models/user_model.dart';
import 'package:artist_hub/utils/helpers.dart';

class CustomerMediaDetailScreen extends StatefulWidget {
  final MediaModel media;
  final String artistName;

  const CustomerMediaDetailScreen({
    super.key,
    required this.media,
    required this.artistName,
  });

  @override
  State<CustomerMediaDetailScreen> createState() => _CustomerMediaDetailScreenState();
}

class _CustomerMediaDetailScreenState extends State<CustomerMediaDetailScreen> {
  late MediaModel _media;
  late VideoPlayerController _videoController;
  bool _isVideoInitialized = false;
  bool _isLiked = false;
  int _likeCount = 0;
  int _commentCount = 0;
  int _shareCount = 0;
  bool _isLoading = true;
  List<Comment> _comments = [];
  bool _isCommentsLoading = false;
  final TextEditingController _commentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _media = widget.media;
    _likeCount = _media.likeCount;
    _commentCount = _media.commentCount;
    _shareCount = _media.shareCount;

    _loadMediaDetails();
    _loadComments();

    if (_media.isVideo) {
      _initializeVideoPlayer();
    }
  }

  Future<void> _loadMediaDetails() async {
    setState(() => _isLoading = true);

    try {
      final result = await ApiService.getMediaDetails(_media.id);

      if (result['success'] == true && result['data'] != null) {
        final mediaData = result['data'];
        if (mediaData is List && mediaData.isNotEmpty) {
          final updatedMedia = MediaModel.fromJson(mediaData[0]);
          setState(() {
            _likeCount = updatedMedia.likeCount;
            _commentCount = updatedMedia.commentCount;
            _shareCount = updatedMedia.shareCount;
          });
        }
      }

      // Check if current user has liked this media
      final userId = await SharedPref.getUserId();
      if (userId.isNotEmpty) {
        // You can add a separate API call to check like status
      }
    } catch (e) {
      print('Error loading media details: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadComments() async {
    setState(() => _isCommentsLoading = true);

    try {
      final result = await ApiService.getComments(mediaId: _media.id);

      if (result['success'] == true && result['data'] != null) {
        final data = result['data'];
        if (data is Map && data['comments'] is List) {
          setState(() {
            _comments = (data['comments'] as List)
                .map((comment) => Comment.fromJson(comment))
                .toList();
          });
        }
      }
    } catch (e) {
      print('Error loading comments: $e');
    } finally {
      setState(() => _isCommentsLoading = false);
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
    final userId = await SharedPref.getUserId();
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

  Future<void> _addComment() async {
    final comment = _commentController.text.trim();
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
        mediaId: _media.id,
        comment: comment,
      );

      if (result['success'] == true) {
        _commentController.clear();
        Helpers.showSnackbar(context, 'Comment added successfully');

        // Reload comments
        await _loadComments();

        // Update comment count
        setState(() {
          _commentCount++;
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

  Future<void> _shareMedia() async {
    try {
      final result = await ApiService.toggleLike(
        userId: int.parse(await SharedPref.getUserId()),
        mediaId: _media.id,
      );

      if (result['success'] == true) {
        setState(() {
          _shareCount = (result['data']?['total_shares'] ?? _shareCount) + 1;
        });
        Helpers.showSnackbar(context, 'Post shared successfully');
      }
    } catch (e) {
      Helpers.showSnackbar(context, 'Share functionality coming soon');
    }
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

  Widget _buildCommentsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            'Comments (${_comments.length})',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textColor,
            ),
          ),
        ),

        // Add comment input
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _commentController,
                  decoration: InputDecoration(
                    hintText: 'Write a comment...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.send, color: AppColors.primaryColor),
                onPressed: _addComment,
              ),
            ],
          ),
        ),

        // Comments list
        _isCommentsLoading
            ? const Center(child: CircularProgressIndicator())
            : _comments.isEmpty
            ? const Padding(
          padding: EdgeInsets.all(16),
          child: Center(
            child: Text(
              'No comments yet',
              style: TextStyle(color: AppColors.grey),
            ),
          ),
        )
            : ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _comments.length,
          itemBuilder: (context, index) {
            return _buildCommentItem(_comments[index]);
          },
        ),
      ],
    );
  }

  Widget _buildCommentItem(Comment comment) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: AppColors.primaryColor.withOpacity(0.1),
            child: Text(
              Helpers.getInitials(comment.userName),
              style: const TextStyle(
                color: AppColors.primaryColor,
                fontWeight: FontWeight.bold,
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
                    fontWeight: FontWeight.w600,
                    color: AppColors.textColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  comment.comment,
                  style: const TextStyle(
                    color: AppColors.darkGrey,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  Helpers.timeAgo(comment.createdAt as String),
                  style: const TextStyle(
                    fontSize: 12,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.black,
      body: SafeArea(
        child: Column(
          children: [
            // App bar
            Container(
              color: Colors.black.withOpacity(0.5),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: AppColors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Expanded(
                    child: Text(
                      widget.artistName,
                      style: const TextStyle(
                        color: AppColors.white,
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),

            // Media content
            Expanded(
              child: _isLoading
                  ? const LoadingWidget()
                  : SingleChildScrollView(
                child: Column(
                  children: [
                    _buildMediaContent(),
                    const SizedBox(height: 16),
                    _buildMediaInfo(),
                    const SizedBox(height: 16),
                    Container(
                      color: AppColors.white,
                      child: _buildCommentsSection(),
                    ),
                  ],
                ),
              ),
            ),
          ],
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
              _buildStatItem(Icons.favorite, _likeCount.toString(),
                  _isLiked ? Colors.red : null),
              _buildStatItem(Icons.comment, _commentCount.toString(), null),
              _buildStatItem(Icons.share, _shareCount.toString(), null),
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
                onPressed: () {
                  // Focus on comment input
                },
                tooltip: 'Comments',
              ),
              IconButton(
                icon: const Icon(Icons.share_outlined, color: AppColors.white),
                onPressed: _shareMedia,
                tooltip: 'Share',
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
              Helpers.timeAgo(_media.createdAt.toString()),
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
    _commentController.dispose();
    super.dispose();
  }
}

// Comment model
class Comment {
  final int id;
  final int userId;
  final String userName;
  final int mediaId;
  final String comment;
  final DateTime createdAt;

  Comment({
    required this.id,
    required this.userId,
    required this.userName,
    required this.mediaId,
    required this.comment,
    required this.createdAt,
  });

  factory Comment.fromJson(Map<String, dynamic> json) {
    return Comment(
      id: int.parse(json['id'].toString()),
      userId: int.parse(json['user_id'].toString()),
      userName: json['user_name'] ?? 'User',
      mediaId: int.parse(json['media_id'].toString()),
      comment: json['comment'] ?? '',
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
    );
  }
}