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

class ArtistMediaDetailScreen extends StatefulWidget {
  final MediaModel media;
  final bool isOwnMedia;

  const ArtistMediaDetailScreen({
    super.key,
    required this.media,
    this.isOwnMedia = true,
  });

  @override
  State<ArtistMediaDetailScreen> createState() => _ArtistMediaDetailScreenState();
}

class _ArtistMediaDetailScreenState extends State<ArtistMediaDetailScreen> {
  late MediaModel _media;
  late VideoPlayerController? _videoController;
  bool _isVideoInitialized = false;
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
    } else {
      _videoController = null;
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
        } else if (mediaData is Map) {
          setState(() {
            _likeCount = mediaData['like_count'] ?? _likeCount;
            _commentCount = mediaData['comment_count'] ?? _commentCount;
            _shareCount = mediaData['share_count'] ?? _shareCount;
          });
        }
      }
    } catch (e) {
      print('Error loading media details: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadComments() async {
    setState(() => _isCommentsLoading = true);

    try {
      final result = await ApiService.getComments(mediaId: _media.id);

      if (result['success'] == true && result['data'] != null) {
        final data = result['data'];

        if (data is List) {
          setState(() {
            _comments = data
                .where((item) => item is Map)
                .map((comment) => Comment.fromJson(comment))
                .toList();
          });
        } else if (data is Map && data['comments'] is List) {
          setState(() {
            _comments = (data['comments'] as List)
                .where((item) => item is Map)
                .map((comment) => Comment.fromJson(comment))
                .toList();
          });
        }
      }
    } catch (e) {
      print('Error loading comments: $e');
    } finally {
      if (mounted) {
        setState(() => _isCommentsLoading = false);
      }
    }
  }

  Future<void> _initializeVideoPlayer() async {
    try {
      _videoController = VideoPlayerController.network(_media.mediaUrl)
        ..addListener(() {
          if (mounted) setState(() {});
        })
        ..setLooping(true)
        ..initialize().then((_) {
          if (mounted) {
            setState(() {
              _isVideoInitialized = true;
            });
          }
        });
    } catch (e) {
      print('Error initializing video player: $e');
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

  Future<void> _deleteComment(Comment comment) async {
    if (!widget.isOwnMedia) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Comment'),
        content: const Text('Are you sure you want to delete this comment?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.errorColor),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    // Call delete comment API if available
    Helpers.showSnackbar(context, 'Comment deleted');

    setState(() {
      _comments.removeWhere((c) => c.id == comment.id);
      if (_commentCount > 0) _commentCount--;
    });
  }

  Future<void> _deleteMedia() async {
    if (!widget.isOwnMedia) return;

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
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.errorColor),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final userId = await SharedPref.getUserId();
    if (userId.isEmpty) {
      Helpers.showSnackbar(context, 'Please login first', isError: true);
      return;
    }

    try {
      final result = await ApiService.deleteArtistMedia(
        mediaId: _media.id,
        artistId: int.parse(userId),
      );

      if (result['success'] == true) {
        Helpers.showSnackbar(context, 'Media deleted successfully');
        Navigator.pop(context, true); // Return true to refresh gallery
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

  Widget _buildMediaContent() {
    return GestureDetector(
      onTap: () {
        if (_media.isVideo && _isVideoInitialized && _videoController != null) {
          setState(() {
            if (_videoController!.value.isPlaying) {
              _videoController!.pause();
            } else {
              _videoController!.play();
            }
          });
        }
      },
      child: Center(
        child: _media.isImage
            ? InteractiveViewer(
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
            : _media.isVideo && _isVideoInitialized && _videoController != null
            ? AspectRatio(
          aspectRatio: _videoController!.value.aspectRatio,
          child: Stack(
            alignment: Alignment.center,
            children: [
              VideoPlayer(_videoController!),
              if (!_videoController!.value.isPlaying)
                Icon(
                  Icons.play_arrow,
                  size: 64,
                  color: AppColors.white.withOpacity(0.7),
                ),
            ],
          ),
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
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Comments (${_comments.length})',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textColor,
                ),
              ),
              if (widget.isOwnMedia)
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: AppColors.errorColor),
                  onPressed: _deleteMedia,
                  tooltip: 'Delete Media',
                ),
            ],
          ),
        ),

        // Add comment input
        // Padding(
        //   padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        //   child: Row(
        //     children: [
        //       Expanded(
        //         child: TextField(
        //           controller: _commentController,
        //           decoration: InputDecoration(
        //             hintText: 'Add a comment...',
        //             border: OutlineInputBorder(
        //               borderRadius: BorderRadius.circular(20),
        //             ),
        //             contentPadding: const EdgeInsets.symmetric(
        //               horizontal: 16,
        //               vertical: 12,
        //             ),
        //           ),
        //         ),
        //       ),
        //       IconButton(
        //         icon: const Icon(Icons.send, color: AppColors.primaryColor),
        //         onPressed: _addComment,
        //       ),
        //     ],
        //   ),
        // ),

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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      comment.userName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textColor,
                      ),
                    ),
                    if (widget.isOwnMedia)
                      IconButton(
                        icon: const Icon(Icons.delete, size: 16),
                        color: AppColors.errorColor,
                        onPressed: () => _deleteComment(comment),
                      ),
                  ],
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
                  Helpers.timeAgo(comment.createdAt.toString()),
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
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          widget.isOwnMedia ? 'My Media' : 'Media Detail',
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: AppColors.primaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          if (widget.isOwnMedia)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: _deleteMedia,
              tooltip: 'Delete Media',
            ),
        ],
      ),
      body: _isLoading
          ? const LoadingWidget()
          : Column(
        children: [
          // Media content
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  Container(
                    color: AppColors.black,
                    constraints: BoxConstraints(
                      maxHeight: MediaQuery.of(context).size.height * 0.6,
                    ),
                    child: _buildMediaContent(),
                  ),
                  const SizedBox(height: 16),
                  _buildStatsInfo(),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),

          // Comments section
          Container(
            height: MediaQuery.of(context).size.height * 0.4,
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: _buildCommentsSection(),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsInfo() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Stats
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem(Icons.favorite, '$_likeCount\nLikes'),
              _buildStatItem(Icons.comment, '$_commentCount\nComments'),
              _buildStatItem(Icons.share, '$_shareCount\nShares'),
            ],
          ),
          const SizedBox(height: 16),

          // Caption
          if (_media.caption.isNotEmpty)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Caption:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textColor,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _media.caption,
                  style: const TextStyle(
                    color: AppColors.darkGrey,
                    fontSize: 14,
                  ),
                ),
              ],
            ),

          const SizedBox(height: 8),

          // Upload date
          Text(
            'Uploaded ${Helpers.timeAgo(_media.createdAt.toString())}',
            style: const TextStyle(
              color: AppColors.grey,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String text) {
    return Column(
      children: [
        Icon(icon, color: AppColors.primaryColor, size: 24),
        const SizedBox(height: 4),
        Text(
          text,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.darkGrey,
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _videoController?.dispose();
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
      id: int.tryParse(json['id'].toString()) ?? 0,
      userId: int.tryParse(json['user_id'].toString()) ?? 0,
      userName: json['user_name']?.toString() ?? 'User',
      mediaId: int.tryParse(json['media_id'].toString()) ?? 0,
      comment: json['comment']?.toString() ?? '',
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ?? DateTime.now(),
    );
  }
}