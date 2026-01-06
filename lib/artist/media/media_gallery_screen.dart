import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:artist_hub/core/constants/app_colors.dart';
import 'package:artist_hub/core/constants/app_strings.dart';
import 'package:artist_hub/core/routes/app_routes.dart';
import 'package:artist_hub/core/services/api_service.dart';
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
  String _selectedFilter = 'all'; // 'all', 'images', 'videos'

  @override
  void initState() {
    super.initState();
    _loadMedia();
  }

  Future<void> _loadMedia() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      final result = await ApiService.getArtistMedia(artistId: widget.artistId);
      if (result['success'] == true && result['data'] != null) {
        final List<dynamic> data = result['data'];
        setState(() {
          _mediaList = data.map((item) => MediaModel.fromJson(item)).toList();
        });
      } else {
        setState(() => _hasError = true);
      }
    } catch (e) {
      setState(() => _hasError = true);
    } finally {
      setState(() => _isLoading = false);
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

  void _openMediaDetail(MediaModel media) {
    Navigator.pushNamed(
      context,
      AppRoutes.mediaDetail,
      arguments: {'media': media},
    );
  }

  void _uploadNewMedia() {
    Navigator.pushNamed(context, AppRoutes.uploadMedia);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(widget.artistName),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _uploadNewMedia,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadMedia,
          ),
        ],
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
      floatingActionButton: FloatingActionButton(
        onPressed: _uploadNewMedia,
        backgroundColor: AppColors.primaryColor,
        foregroundColor: AppColors.white,
        child: const Icon(Icons.add),
      ),
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
                '${_filteredMedia.length} items',
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.darkGrey,
                ),
              ),
              Text(
                'Total: ${_mediaList.length}',
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.darkGrey,
                ),
              ),
            ],
          ),
        ),

        // Media grid
        Expanded(
          child: _filteredMedia.isEmpty
              ? NoDataWidget(
            message: 'No media found',
            buttonText: 'Upload Media',
            onPressed: _uploadNewMedia,
          )
              : _buildMediaGrid(),
        ),
      ],
    );
  }

  Widget _buildFilterChips() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
    );
  }

  Widget _buildFilterChip(String value, String label, IconData icon) {
    final isSelected = _selectedFilter == value;

    return FilterChip(
      selected: isSelected,
      onSelected: (selected) {
        setState(() => _selectedFilter = value);
      },
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16),
          const SizedBox(width: 4),
          Text(label),
        ],
      ),
      selectedColor: AppColors.primaryColor,
      checkmarkColor: AppColors.white,
      labelStyle: TextStyle(
        color: isSelected ? AppColors.white : AppColors.textColor,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isSelected ? AppColors.primaryColor : AppColors.lightGrey,
        ),
      ),
    );
  }

  Widget _buildMediaGrid() {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
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
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Media thumbnail
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: media.isImage
                  ? CachedNetworkImage(
                imageUrl: media.mediaUrl,
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
                placeholder: (context, url) => Container(
                  color: AppColors.primaryColor.withOpacity(0.1),
                  child: const Center(
                    child: Icon(
                      Icons.image,
                      color: AppColors.primaryColor,
                    ),
                  ),
                ),
                errorWidget: (context, url, error) => Container(
                  color: AppColors.lightGrey,
                  child: const Center(
                    child: Icon(Icons.broken_image),
                  ),
                ),
              )
                  : Container(
                color: AppColors.secondaryColor.withOpacity(0.1),
                child: Stack(
                  children: [
                    const Center(
                      child: Icon(
                        Icons.videocam,
                        size: 32,
                        color: AppColors.secondaryColor,
                      ),
                    ),
                    Positioned(
                      bottom: 4,
                      right: 4,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Icon(
                          Icons.play_arrow,
                          size: 16,
                          color: AppColors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Like count overlay
            if (media.likeCount > 0)
              Positioned(
                top: 4,
                left: 4,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
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
                      const SizedBox(width: 2),
                      Text(
                        media.likeCount.toString(),
                        style: const TextStyle(
                          fontSize: 10,
                          color: AppColors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // Media type indicator
            Positioned(
              top: 4,
              right: 4,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  media.isImage ? Icons.image : Icons.videocam,
                  size: 12,
                  color: AppColors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}