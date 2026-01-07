// lib/artist/media/media_gallery_screen.dart
import 'package:flutter/material.dart';
import 'package:artist_hub/core/constants/app_colors.dart';
import 'package:artist_hub/core/routes/app_routes.dart';
import 'package:artist_hub/core/services/api_service.dart';
import 'package:artist_hub/core/services/shared_pref.dart';
import 'package:artist_hub/core/widgets/loading_widget.dart';
import 'package:artist_hub/core/widgets/no_data_widget.dart';
import 'package:artist_hub/models/media_model.dart';
import 'package:artist_hub/utils/helpers.dart';

class MediaGalleryScreen extends StatefulWidget {
  final int artistId;
  final String artistName;

  const MediaGalleryScreen({
    super.key,
    required this.artistId,
    required this.artistName,
  });

  @override
  State<MediaGalleryScreen> createState() => _MediaGalleryScreenState();
}

class _MediaGalleryScreenState extends State<MediaGalleryScreen> {
  List<MediaModel> _mediaList = [];
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';
  bool _isOwnMedia = false;

  @override
  void initState() {
    super.initState();
    _checkOwnership();
    _loadMedia();
  }

  Future<void> _checkOwnership() async {
    final userId = await SharedPref.getUserId();
    setState(() {
      _isOwnMedia = userId == widget.artistId.toString();
    });
  }

  Future<void> _loadMedia() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
      _errorMessage = '';
    });

    try {
      // Try different endpoints
      Map<String, dynamic> result;

      // First try: Get media by artist ID
      result = await ApiService.getArtistMedia(artistId: widget.artistId);

      // If that fails, try getting all media
      if (!result['success'] || (result['data'] as List).isEmpty) {
        result = await ApiService.getAllMedia();

        // Filter by artist ID if we got all media
        if (result['success'] && result['data'] is List) {
          final allMedia = (result['data'] as List)
              .map((item) => MediaModel.fromJson(item))
              .where((media) => media.artistId == widget.artistId)
              .toList();

          setState(() {
            _mediaList = allMedia;
          });
          return;
        }
      }

      if (result['success'] == true) {
        final data = result['data'];
        if (data is List) {
          List<MediaModel> media = [];

          for (var item in data) {
            try {
              media.add(MediaModel.fromJson(item));
            } catch (e) {
              print('Error parsing media item: $e');
            }
          }

          setState(() {
            _mediaList = media;
            _hasError = false;
          });
        } else {
          setState(() {
            _mediaList = [];
            _hasError = true;
            _errorMessage = 'No media data received';
          });
        }
      } else {
        setState(() {
          _hasError = true;
          _errorMessage = result['message'] ?? 'Failed to load media';
          _mediaList = [];
        });
      }
    } catch (e) {
      setState(() {
        _hasError = true;
        _errorMessage = 'Error: ${e.toString()}';
        _mediaList = [];
      });
      print('Load media error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _openMediaDetail(MediaModel media) {
    Navigator.pushNamed(
      context,
      AppRoutes.mediaDetail,
      arguments: {
        'media': media.toJson(),
        'isOwnMedia': _isOwnMedia,
        'artistName': widget.artistName,
      },
    );
  }

  Future<void> _deleteMedia(MediaModel media) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Media'),
        content: const Text('Are you sure you want to delete this media?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.errorColor,
            ),
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
        mediaId: media.id,
        artistId: int.parse(userId),
      );

      if (result['success'] == true) {
        Helpers.showSnackbar(context, 'Media deleted successfully');
        await _loadMedia(); // Refresh list
      } else {
        Helpers.showSnackbar(
          context,
          result['message'] ?? 'Failed to delete media',
          isError: true,
        );
      }
    } catch (e) {
      Helpers.showSnackbar(context, 'Error: ${e.toString()}', isError: true);
    }
  }

  Widget _buildMediaGrid() {
    if (_mediaList.isEmpty) {
      return NoDataWidget(
        message: 'No media found',
        buttonText: 'Upload Media',
        onPressed: () {
          Navigator.pushNamed(context, AppRoutes.uploadMedia);
        },
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.8,
      ),
      itemCount: _mediaList.length,
      itemBuilder: (context, index) {
        return _buildMediaCard(_mediaList[index]);
      },
    );
  }

  Widget _buildMediaCard(MediaModel media) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => _openMediaDetail(media),
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Media thumbnail
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(12),
                ),
                child: Container(
                  color: AppColors.lightGrey,
                  child: media.mediaUrl.isNotEmpty
                      ? Image.network(
                    media.mediaUrl,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Center(
                        child: CircularProgressIndicator(
                          value: loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded /
                              loadingProgress.expectedTotalBytes!
                              : null,
                          color: AppColors.primaryColor,
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return Center(
                        child: Icon(
                          media.isVideo ? Icons.videocam : Icons.image,
                          color: AppColors.grey,
                          size: 48,
                        ),
                      );
                    },
                  )
                      : Center(
                    child: Icon(
                      media.isVideo ? Icons.videocam : Icons.image,
                      color: AppColors.grey,
                      size: 48,
                    ),
                  ),
                ),
              ),
            ),
            // Media info
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        media.isVideo ? Icons.videocam : Icons.image,
                        size: 14,
                        color: AppColors.darkGrey,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        media.isVideo ? 'Video' : 'Image',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.darkGrey,
                        ),
                      ),
                      const Spacer(),
                      Row(
                        children: [
                          const Icon(
                            Icons.favorite,
                            size: 12,
                            color: Colors.red,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            media.likeCount.toString(),
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.darkGrey,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  if (media.caption.isNotEmpty)
                    Text(
                      media.caption.length > 30
                          ? '${media.caption.substring(0, 30)}...'
                          : media.caption,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textColor,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  const SizedBox(height: 4),
                  Text(
                    Helpers.timeAgo(media.createdAt.toString()),
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.grey,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.artistName}\'s Gallery'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadMedia,
            tooltip: 'Refresh',
          ),
          if (_isOwnMedia)
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () {
                Navigator.pushNamed(context, AppRoutes.uploadMedia);
              },
              tooltip: 'Upload Media',
            ),
        ],
      ),
      body: _isLoading
          ? const LoadingWidget(message: 'Loading media...')
          : _hasError
          ? Center(
        child: NoDataWidget(
          message: _errorMessage,
          buttonText: 'Retry',
          onPressed: _loadMedia,
        ),
      )
          : _buildMediaGrid(),
      floatingActionButton: _isOwnMedia
          ? FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(context, AppRoutes.uploadMedia);
        },
        backgroundColor: AppColors.primaryColor,
        child: const Icon(Icons.add, color: Colors.white),
      )
          : null,
    );
  }
}