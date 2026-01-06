// lib/artist/media/media_gallery_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:artist_hub/core/constants/app_colors.dart';
import 'package:artist_hub/core/routes/app_routes.dart';
import 'package:artist_hub/core/services/api_service.dart';
import 'package:artist_hub/core/widgets/loading_widget.dart';
import 'package:artist_hub/core/widgets/no_data_widget.dart';
import 'package:artist_hub/models/media_model.dart';
import 'package:artist_hub/utils/helpers.dart';
import 'package:artist_hub/core/services/shared_pref.dart';

class MediaGalleryScreen extends StatefulWidget {
  final int artistId;
  final String artistName;
  final bool isOwnGallery;

  const MediaGalleryScreen({
    super.key,
    required this.artistId,
    required this.artistName,
    this.isOwnGallery = false,
  });

  @override
  State<MediaGalleryScreen> createState() => _MediaGalleryScreenState();
}

class _MediaGalleryScreenState extends State<MediaGalleryScreen> {
  List<MediaModel> _mediaList = [];
  bool _isLoading = true;
  bool _hasError = false;
  String _selectedFilter = 'all';
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadMedia();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadMedia() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      final result = await ApiService.getArtistMedia(artistId: widget.artistId);

      if (result['success'] == true && result['data'] != null) {
        final List<dynamic> data = result['data'];
        if (mounted) {
          setState(() {
            _mediaList = data.map((item) {
              // Ensure all required fields are present
              return MediaModel.fromJson({
                'id': item['id'] ?? item['media_id'] ?? 0,
                'artist_id': item['artist_id'] ?? widget.artistId,
                'artist_name': item['artist_name'] ?? widget.artistName,
                'media_type': item['media_type'] ?? 'image',
                'media_url': item['media_url'] ?? '',
                'caption': item['caption'] ?? '',
                'like_count': item['like_count'] ?? item['total_likes'] ?? 0,
                'comment_count': item['comment_count'] ?? item['total_comments'] ?? 0,
                'share_count': item['share_count'] ?? item['total_shares'] ?? 0,
                'created_at': item['created_at'] ?? DateTime.now().toIso8601String(),
              });
            }).toList();
          });
        }
      } else {
        if (mounted) {
          setState(() => _hasError = true);
        }
      }
    } catch (e) {
      print('Error loading media: $e');
      if (mounted) {
        setState(() => _hasError = true);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  List<MediaModel> get _filteredMedia {
    switch (_selectedFilter) {
      case 'images':
        return _mediaList.where((media) => media.isImage).toList();
      case 'videos':
        return _mediaList.where((media) => media.isVideo).toList();
      default:
        return _mediaList;
    }
  }

  Future<void> _openMediaDetail(MediaModel media) async {
    final result = await Navigator.pushNamed(
      context,
      AppRoutes.mediaDetail,
      arguments: {
        'media': media.toJson(),
        'artistId': widget.artistId,
        'artistName': widget.artistName,
        'isOwnMedia': widget.isOwnGallery,
      },
    );

    if (result == true && mounted) {
      _loadMedia();
    }
  }

  Future<void> _uploadNewMedia() async {
    final result = await Navigator.pushNamed(context, AppRoutes.uploadMedia);
    if (result == true && mounted) {
      _loadMedia();
    }
  }

  Future<void> _deleteMedia(MediaModel media) async {
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

    final userId = SharedPref.getUserId();
    if (userId.isEmpty) {
      Helpers.showSnackbar(context, 'Please login first', isError: true);
      return;
    }

    try {
      final result = await ApiService.deleteArtistMedia(
        mediaId: media.id,
        artistId: int.parse(userId),
      );

      if (result['success'] == true) {
        Helpers.showSnackbar(context, 'Media deleted successfully');

        if (mounted) {
          setState(() {
            _mediaList.removeWhere((m) => m.id == media.id);
          });
        }
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
      backgroundColor: AppColors.background,
      appBar:AppBar(
        iconTheme: IconThemeData(color: Colors.white),

        title: Text(
          widget.isOwnGallery ? 'My Portfolio' : widget.artistName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: AppColors.primaryColor,
        elevation: 0,

      ),
      body: _isLoading
          ? const LoadingWidget(message: 'Loading media...')
          : _hasError
          ? NoDataWidget(
        message: 'Failed to load media',
        buttonText: 'Retry',
        onPressed: _loadMedia,
      )
          : _buildGalleryContent(),
      floatingActionButton: widget.isOwnGallery
          ? FloatingActionButton(
        onPressed: _uploadNewMedia,
        backgroundColor: AppColors.primaryColor,
        foregroundColor: AppColors.white,
        child: const Icon(Icons.add),
        tooltip: 'Upload Media',
      )
          : null,
    );
  }

  Widget _buildGalleryContent() {
    return Column(
      children: [
        // Filter chips
        _buildFilterChips(),

        // Media count
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${_filteredMedia.length} ${_filteredMedia.length == 1 ? 'item' : 'items'}',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textColor,
                ),
              ),
              if (_selectedFilter != 'all')
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Total: ${_mediaList.length}',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.darkGrey,
                    ),
                  ),
                ),
            ],
          ),
        ),

        // Media grid
        Expanded(
          child: _filteredMedia.isEmpty
              ? NoDataWidget(
            message: _selectedFilter == 'all'
                ? 'No media found'
                : 'No ${_selectedFilter} found',
            buttonText: widget.isOwnGallery ? 'Upload Media' : null,
            onPressed: widget.isOwnGallery ? _uploadNewMedia : null,

          )
              : RefreshIndicator(
            onRefresh: _loadMedia,
            backgroundColor: AppColors.background,
            color: AppColors.primaryColor,
            child: _buildMediaGrid(),
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChips() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadowColor,
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.all(8),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildFilterChip('all', 'All', Icons.all_inclusive),
              const SizedBox(width: 8),
              _buildFilterChip('images', 'Images', Icons.image),
              const SizedBox(width: 8),
              _buildFilterChip('videos', 'Videos', Icons.videocam),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChip(String value, String label, IconData icon) {
    final isSelected = _selectedFilter == value;
    final count = value == 'all'
        ? _mediaList.length
        : value == 'images'
        ? _mediaList.where((m) => m.isImage).length
        : _mediaList.where((m) => m.isVideo).length;

    return ChoiceChip(
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          setState(() => _selectedFilter = value);
        }
      },
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16),
          const SizedBox(width: 6),
          Text(label),
          if (count > 0) ...[
            const SizedBox(width: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.white.withOpacity(0.2) : AppColors.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                count.toString(),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? AppColors.white : AppColors.primaryColor,
                ),
              ),
            ),
          ],
        ],
      ),
      selectedColor: AppColors.primaryColor,
      backgroundColor: AppColors.card,
      labelStyle: TextStyle(
        color: isSelected ? AppColors.white : AppColors.textColor,
        fontWeight: FontWeight.w500,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isSelected ? AppColors.primaryColor : AppColors.lightGrey,
          width: 1,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    );
  }

  Widget _buildMediaGrid() {
    return GridView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1,
      ),
      itemCount: _filteredMedia.length,
      itemBuilder: (context, index) {
        return _buildMediaItem(_filteredMedia[index]);
      },
    );
  }

  Widget _buildMediaItem(MediaModel media) {
    return GestureDetector(
      onTap: () => _openMediaDetail(media),
      onLongPress: widget.isOwnGallery
          ? () => _showMediaOptions(media)
          : null,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadowColor,
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Media thumbnail
              _buildMediaThumbnail(media),

              // Gradient overlay
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withOpacity(0.3),
                      Colors.transparent,
                      Colors.transparent,
                    ],
                  ),
                ),
              ),

              // Like count overlay
              if (media.likeCount > 0)
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.favorite,
                          size: 12,
                          color: Colors.red,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          media.likeCount.toString(),
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              // Comment count
              if (media.commentCount > 0)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.comment,
                          size: 12,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          media.commentCount.toString(),
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              // Caption overlay
              if (media.caption.isNotEmpty)
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          Colors.black.withOpacity(0.8),
                          Colors.transparent,
                        ],
                      ),
                    ),
                    child: Text(
                      media.caption,
                      style: const TextStyle(
                        fontSize: 10,
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),

              // Media type indicator
              Positioned(
                bottom: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    media.isImage ? Icons.image : Icons.videocam,
                    size: 12,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMediaThumbnail(MediaModel media) {
    if (media.isImage) {
      return CachedNetworkImage(
        imageUrl: media.mediaUrl,
        fit: BoxFit.cover,
        placeholder: (context, url) => Container(
          color: AppColors.primaryColor.withOpacity(0.1),
          child: Center(
            child: CircularProgressIndicator(
              color: AppColors.primaryColor,
              strokeWidth: 2,
            ),
          ),
        ),
        errorWidget: (context, url, error) => Container(
          color: AppColors.lightGrey,
          child: const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.broken_image, color: AppColors.grey),
                SizedBox(height: 4),
                Text(
                  'Failed to load',
                  style: TextStyle(fontSize: 8, color: AppColors.grey),
                ),
              ],
            ),
          ),
        ),
      );
    } else {
      return Container(
        color: AppColors.secondaryColor.withOpacity(0.1),
        child: const Center(
          child: Icon(
            Icons.videocam,
            size: 40,
            color: AppColors.secondaryColor,
          ),
        ),
      );
    }
  }

  void _showMediaOptions(MediaModel media) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Media Options',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textColor,
                  ),
                ),
              ),
              Divider(color: AppColors.lightGrey, height: 1),
              ListTile(
                leading: const Icon(Icons.visibility),
                title: const Text('View Details'),
                onTap: () {
                  Navigator.pop(context);
                  _openMediaDetail(media);
                },
              ),
              ListTile(
                leading: Icon(Icons.edit, color: AppColors.primaryColor),
                title: const Text('Edit Caption'),
                onTap: () {
                  Navigator.pop(context);
                  _editCaption(media);
                },
              ),
              ListTile(
                leading: Icon(Icons.delete, color: AppColors.errorColor),
                title: const Text('Delete'),
                onTap: () {
                  Navigator.pop(context);
                  _deleteMedia(media);
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  Future<void> _editCaption(MediaModel media) async {
    final TextEditingController captionController = TextEditingController(text: media.caption);

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Caption'),
        content: TextField(
          controller: captionController,
          maxLines: 3,
          maxLength: 500,
          decoration: const InputDecoration(
            hintText: 'Enter caption...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final newCaption = captionController.text.trim();
              if (newCaption != media.caption) {
                final userId = SharedPref.getUserId();
                if (userId.isEmpty) {
                  Helpers.showSnackbar(context, 'Please login first', isError: true);
                  return;
                }

                final result = await ApiService.updateMediaCaption(
                  mediaId: media.id,
                  artistId: int.parse(userId),
                  caption: newCaption,
                );

                if (result['success'] == true) {
                  Helpers.showSnackbar(context, 'Caption updated successfully');
                  _loadMedia();
                } else {
                  Helpers.showSnackbar(
                    context,
                    result['message'] ?? 'Failed to update caption',
                    isError: true,
                  );
                }
              }
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}