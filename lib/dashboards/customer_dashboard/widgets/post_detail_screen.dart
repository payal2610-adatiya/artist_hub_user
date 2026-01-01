import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:artist_hub/core/services/url_helper.dart';
import 'package:artist_hub/providers/auth_provider.dart';
import 'package:artist_hub/core/constants/app_colors.dart';
import 'package:artist_hub/core/services/like_services.dart';

class PostDetailsBottomSheet extends StatefulWidget {
  final dynamic post;
  final bool isLiked;
  final int likesCount;
  final int mediaId; // Add this parameter
  final VoidCallback onLikeTapped;

  const PostDetailsBottomSheet({
    Key? key,
    required this.post,
    required this.isLiked,
    required this.likesCount,
    required this.mediaId, // Add this parameter
    required this.onLikeTapped,
  }) : super(key: key);

  @override
  State<PostDetailsBottomSheet> createState() => _PostDetailsBottomSheetState();
}

class _PostDetailsBottomSheetState extends State<PostDetailsBottomSheet> {
  late bool _isLiked;
  late int _likesCount;
  List<dynamic> _comments = [];
  bool _loadingComments = false;
  final TextEditingController _commentController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _isLiked = widget.isLiked;
    _likesCount = widget.likesCount;

    // Debug: Check mediaId
    print('PostDetailsBottomSheet initState - mediaId: ${widget.mediaId}');
    print('Post data: ${widget.post}');

    _loadComments();
  }

  Future<void> _loadComments() async {
    setState(() => _loadingComments = true);

    // Use widget.mediaId which should be passed from PostCard
    final mediaId = widget.mediaId;

    // If mediaId is 0, try to extract from post as fallback
    int effectiveMediaId = mediaId;
    if (effectiveMediaId == 0) {
      print('WARNING: mediaId is 0, trying to extract from post...');
      effectiveMediaId = _extractMediaIdFromPost(widget.post);
      print('Extracted mediaId from post: $effectiveMediaId');
    }

    print('Loading comments for mediaId: $effectiveMediaId');

    final result = await LikeService.getComments(effectiveMediaId);

    if (result['status'] == true && mounted) {
      setState(() => _comments = result['data'] ?? []);
      print('Successfully loaded ${_comments.length} comments');
    } else {
      print('Failed to load comments: ${result['message']}');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'Failed to load comments'),
          backgroundColor: Colors.red,
        ),
      );
    }

    setState(() => _loadingComments = false);
  }

  // Helper method to extract mediaId from post
  int _extractMediaIdFromPost(dynamic post) {
    try {
      // Try to get media_id from post
      if (post['media_id'] is int) return post['media_id'];
      if (post['media_id'] is String) {
        final parsed = int.tryParse(post['media_id']?.toString() ?? '0');
        if (parsed != null) return parsed;
      }

      // Try mediaid (without underscore)
      if (post['mediaid'] is int) return post['mediaid'];
      if (post['mediaid'] is String) {
        final parsed = int.tryParse(post['mediaid']?.toString() ?? '0');
        if (parsed != null) return parsed;
      }

      // Try mediaId (camelCase)
      if (post['mediaId'] is int) return post['mediaId'];
      if (post['mediaId'] is String) {
        final parsed = int.tryParse(post['mediaId']?.toString() ?? '0');
        if (parsed != null) return parsed;
      }

      // Last resort: use id as mediaId
      if (post['id'] is int) return post['id'];
      if (post['id'] is String) {
        final parsed = int.tryParse(post['id']?.toString() ?? '0');
        if (parsed != null) return parsed;
      }

      return 0;
    } catch (e) {
      print('Error extracting mediaId from post: $e');
      return 0;
    }
  }

  Future<void> _addComment() async {
    if (_commentController.text.isEmpty) return;

    final user = Provider.of<AuthProvider>(context, listen: false).user;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please login to comment'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Use widget.mediaId which should be passed from PostCard
    final mediaId = widget.mediaId;

    // If mediaId is 0, try to extract from post
    int effectiveMediaId = mediaId;
    if (effectiveMediaId == 0) {
      effectiveMediaId = _extractMediaIdFromPost(widget.post);
    }

    if (effectiveMediaId == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Cannot add comment: Invalid media ID'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    print('Adding comment to mediaId: $effectiveMediaId');

    final result = await LikeService.addComment(
      userId: user.id!,
      mediaId: effectiveMediaId,
      comment: _commentController.text,
    );

    if (result['status'] == true && mounted) {
      _commentController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Comment added successfully'),
          backgroundColor: Colors.green,
        ),
      );
      await _loadComments();

      // Scroll to bottom after adding comment
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'Failed to add comment'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _sharePost() {
    // Implement sharing logic
    final mediaUrl = UrlHelper.getMediaUrl(widget.post['media_url']?.toString() ?? '');
    print('Sharing post: $mediaUrl');
    // You can use share_plus package for actual sharing
  }

  void _handleLike() {
    // Call the parent like handler
    widget.onLikeTapped();

    // Update local state
    setState(() {
      _isLiked = !_isLiked;
      _likesCount = _isLiked ? _likesCount + 1 : _likesCount - 1;
    });

    // Show feedback
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_isLiked ? 'Post liked!' : 'Like removed'),
        backgroundColor: _isLiked ? Colors.green : Colors.orange,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mediaUrl = widget.post['media_url']?.toString() ?? '';
    final caption = widget.post['caption']?.toString() ?? '';
    final mediaType = widget.post['media_type']?.toString() ?? 'image';
    final fullImageUrl = UrlHelper.getMediaUrl(mediaUrl);

    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: AppColors.accentColor)),
            ),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.close_rounded,
                      size: 20,
                      color: AppColors.textColor.withOpacity(0.6),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  'Post Details',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textColor,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    mediaType == 'video' ? 'Video' : 'Image',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryColor,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Content
          Expanded(
            child: Column(
              children: [
                // Media
                Container(
                  height: 300,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    image: fullImageUrl.isNotEmpty
                        ? DecorationImage(
                      image: NetworkImage(fullImageUrl),
                      fit: BoxFit.cover,
                    )
                        : null,
                  ),
                  child: fullImageUrl.isEmpty
                      ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: AppColors.accentColor,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            mediaType == 'video'
                                ? Icons.videocam_rounded
                                : Icons.photo_rounded,
                            size: 40,
                            color: AppColors.textColor.withOpacity(0.3),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Media not available',
                          style: TextStyle(
                            color: AppColors.textColor.withOpacity(0.6),
                          ),
                        ),
                      ],
                    ),
                  )
                      : null,
                ),

                // Post details and comments
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        // Action buttons
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.background,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              // Like button
                              Column(
                                children: [
                                  IconButton(
                                    onPressed: _handleLike,
                                    icon: Icon(
                                      _isLiked
                                          ? Icons.favorite_rounded
                                          : Icons.favorite_outline_rounded,
                                      color: _isLiked
                                          ? Colors.red
                                          : AppColors.textColor.withOpacity(0.6),
                                      size: 28,
                                    ),
                                  ),
                                  Text(
                                    _likesCount.toString(),
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textColor,
                                    ),
                                  ),
                                ],
                              ),

                              // Comment button
                              Column(
                                children: [
                                  IconButton(
                                    onPressed: () {
                                      // Focus on comment input
                                      FocusScope.of(context).requestFocus(
                                        FocusNode()..requestFocus(),
                                      );
                                    },
                                    icon: Icon(
                                      Icons.comment_rounded,
                                      color: AppColors.textColor.withOpacity(0.6),
                                      size: 28,
                                    ),
                                  ),
                                  Text(
                                    _comments.length.toString(),
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textColor,
                                    ),
                                  ),
                                ],
                              ),

                              // Share button
                              Column(
                                children: [
                                  IconButton(
                                    onPressed: _sharePost,
                                    icon: Icon(
                                      Icons.share_rounded,
                                      color: AppColors.textColor.withOpacity(0.6),
                                      size: 28,
                                    ),
                                  ),
                                  Text(
                                    'Share',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textColor,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Caption and comments
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Caption
                              if (caption.isNotEmpty) ...[
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 8),
                                  child: Text(
                                    caption,
                                    style: TextStyle(
                                      fontSize: 15,
                                      color: AppColors.textColor,
                                      height: 1.6,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),
                              ],

                              const Divider(),
                              const SizedBox(height: 8),

                              // Comments header
                              Text(
                                'Comments (${_comments.length})',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textColor,
                                ),
                              ),
                              const SizedBox(height: 8),

                              // Comments list
                              Expanded(
                                child: _loadingComments
                                    ? Center(
                                  child: CircularProgressIndicator(
                                    color: AppColors.primaryColor,
                                  ),
                                )
                                    : _comments.isEmpty
                                    ? Center(
                                  child: Text(
                                    'No comments yet',
                                    style: TextStyle(
                                      color: AppColors.textColor.withOpacity(0.6),
                                    ),
                                  ),
                                )
                                    : ListView.builder(
                                  controller: _scrollController,
                                  itemCount: _comments.length,
                                  itemBuilder: (context, index) {
                                    final comment = _comments[index];
                                    return Container(
                                      margin: const EdgeInsets.only(bottom: 12),
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: AppColors.background,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            comment['name'] ?? 'User',
                                            style: TextStyle(
                                              fontWeight: FontWeight.w600,
                                              color: AppColors.textColor,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            comment['comment'] ?? '',
                                            style: TextStyle(
                                              color: AppColors.textColor.withOpacity(0.8),
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            _formatDate(comment['created_at']?.toString() ?? ''),
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: AppColors.textColor.withOpacity(0.5),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Comment input
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.background,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _commentController,
                                  decoration: InputDecoration(
                                    hintText: 'Add a comment...',
                                    hintStyle: TextStyle(
                                      color: AppColors.textColor.withOpacity(0.5),
                                    ),
                                    border: InputBorder.none,
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                                  ),
                                  style: TextStyle(color: AppColors.textColor),
                                  onSubmitted: (value) => _addComment(),
                                ),
                              ),
                              IconButton(
                                onPressed: _addComment,
                                icon: Icon(
                                  Icons.send_rounded,
                                  color: AppColors.primaryColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
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

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      final now = DateTime.now();
      final difference = now.difference(date);

      // Show relative time for recent comments
      if (difference.inMinutes < 1) {
        return 'Just now';
      } else if (difference.inHours < 1) {
        return '${difference.inMinutes}m ago';
      } else if (difference.inDays < 1) {
        return '${difference.inHours}h ago';
      } else if (difference.inDays < 7) {
        return '${difference.inDays}d ago';
      } else {
        return '${_getMonthName(date.month)} ${date.day}, ${date.year}';
      }
    } catch (e) {
      return dateString;
    }
  }

  String _getMonthName(int month) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return months[month - 1];
  }
}