import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:artist_hub/core/constants/app_colors.dart';
import 'package:artist_hub/core/routes/app_routes.dart';
import 'package:artist_hub/core/services/api_service.dart';
import 'package:artist_hub/core/services/shared_pref.dart';
import 'package:artist_hub/core/widgets/custom_button.dart';
import 'package:artist_hub/utils/helpers.dart';

class UploadMediaScreen extends StatefulWidget {
  const UploadMediaScreen({Key? key}) : super(key: key);

  @override
  _UploadMediaScreenState createState() => _UploadMediaScreenState();
}

class _UploadMediaScreenState extends State<UploadMediaScreen> {
  final TextEditingController _captionController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  File? _selectedMedia;
  String? _mediaType;
  bool _isUploading = false;
  bool _isLoading = false;
  int _totalPosts = 0;
  int _imageCount = 0;
  int _videoCount = 0;

  @override
  void initState() {
    super.initState();
    _loadMediaStats();
  }

  Future<void> _loadMediaStats() async {
    final userId = SharedPref.getUserId();
    if (userId.isEmpty) return;

    setState(() => _isLoading = true);

    try {
      final result = await ApiService.getArtistMedia(artistId: int.parse(userId));

      if (result['success'] == true && result['data'] != null) {
        final List<dynamic> data = result['data'];
        setState(() {
          _totalPosts = data.length;
          _imageCount = data.where((item) => item['media_type'] == 'image').length;
          _videoCount = data.where((item) => item['media_type'] == 'video').length;
        });
      }
    } catch (e) {
      print('Error loading media stats: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );
      if (image != null) {
        final file = File(image.path);
        final sizeInMB = await file.length() / (1024 * 1024);

        if (sizeInMB > 50) {
          Helpers.showSnackbar(context, 'Image size must be less than 50MB', isError: true);
          return;
        }

        setState(() {
          _selectedMedia = file;
          _mediaType = 'image';
        });
      }
    } catch (e) {
      Helpers.showSnackbar(context, 'Failed to pick image: $e', isError: true);
    }
  }

  Future<void> _pickVideo() async {
    try {
      final XFile? video = await _picker.pickVideo(
        source: ImageSource.gallery,
        maxDuration: const Duration(minutes: 5),
      );
      if (video != null) {
        final videoFile = File(video.path);
        final sizeInMB = await videoFile.length() / (1024 * 1024);

        if (sizeInMB > 100) {
          Helpers.showSnackbar(context, 'Video size must be less than 100MB', isError: true);
          return;
        }

        setState(() {
          _selectedMedia = videoFile;
          _mediaType = 'video';
        });
      }
    } catch (e) {
      Helpers.showSnackbar(context, 'Failed to pick video: $e', isError: true);
    }
  }

  Future<void> _uploadMedia() async {
    if (_selectedMedia == null || _mediaType == null) {
      Helpers.showSnackbar(context, 'Please select media to upload', isError: true);
      return;
    }

    final userId = SharedPref.getUserId();
    if (userId.isEmpty) {
      Helpers.showSnackbar(context, 'Please login to upload media', isError: true);
      return;
    }

    setState(() => _isUploading = true);

    try {
      final result = await ApiService.addArtistMedia(
        artistId: int.parse(userId),
        mediaType: _mediaType!,
        mediaFile: _selectedMedia!,
        caption: _captionController.text.trim(),
      );

      if (result['success'] == true) {
        Helpers.showSnackbar(context, 'Media uploaded successfully!', isError: false);

        // Reset form
        setState(() {
          _selectedMedia = null;
          _mediaType = null;
          _captionController.clear();
        });

        // Refresh stats
        await _loadMediaStats();

        // Navigate back or show success
        Navigator.pop(context, true);
      } else {
        Helpers.showSnackbar(
            context,
            result['message'] ?? 'Upload failed',
            isError: true
        );
      }
    } catch (e) {
      Helpers.showSnackbar(context, 'Upload failed: $e', isError: true);
    } finally {
      setState(() => _isUploading = false);
    }
  }

  void _viewMediaGallery() {
    final userId = SharedPref.getUserId();
    if (userId.isNotEmpty) {
      Navigator.pushNamed(
        context,
        AppRoutes.mediaGallery,
        arguments: {
          'artistId': int.parse(userId),
          'artistName': SharedPref.getUserName() ?? 'My Portfolio',
          'isOwnGallery': true,
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: IconThemeData(color: Colors.white),
        title: const Text('Upload Media', style: TextStyle(color: Colors.white)),
        backgroundColor: AppColors.primaryColor,
        elevation: 1,
        actions: [
          IconButton(
            icon: const Icon(Icons.photo_library, color: Colors.white),
            onPressed: _viewMediaGallery,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Media Preview
            Container(
              width: double.infinity,
              height: 200,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: AppColors.backgroundColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.lightGrey),
              ),
              child: _selectedMedia != null
                  ? ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: _mediaType == 'image'
                    ? Image.file(
                  _selectedMedia!,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return _buildPlaceholder('Failed to load image');
                  },
                )
                    : Stack(
                  children: [
                    Center(
                      child: Icon(
                        Icons.videocam,
                        size: 60,
                        color: AppColors.primaryColor.withOpacity(0.7),
                      ),
                    ),
                    Positioned(
                      bottom: 10,
                      right: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'VIDEO',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              )
                  : _buildPlaceholder('No media selected'),
            ),

            // Media Selection Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isUploading ? null : _pickImage,
                    icon: const Icon(Icons.image),
                    label: const Text('Pick Image'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primaryColor,
                      side: BorderSide(color: AppColors.primaryColor),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isUploading ? null : _pickVideo,
                    icon: const Icon(Icons.videocam),
                    label: const Text('Pick Video'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.secondaryColor,
                      side: BorderSide(color: AppColors.secondaryColor),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Caption
            TextField(
              controller: _captionController,
              maxLines: 3,
              enabled: !_isUploading,
              decoration: InputDecoration(
                labelText: 'Caption',
                hintText: 'Add a caption for your media...',
                alignLabelWithHint: true,

                labelStyle: const TextStyle(
                  color: AppColors.primaryColor,
                ),

                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(
                    color: AppColors.primaryColor,
                    width: 1.2,
                  ),
                ),

                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(
                    color: AppColors.primaryColor,
                    width: 1.2,
                  ),
                ),

                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(
                    color: AppColors.primaryColor,
                    width: 1.8,
                  ),
                ),

                disabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: AppColors.primaryColor.withOpacity(0.4),
                    width: 1.2,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 30),

            // Upload Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isUploading
                    ? null
                    : () {
                  _uploadMedia();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isUploading
                    ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
                    : const Text(
                  'UPLOAD MEDIA',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            // Quick Stats
            if (_totalPosts > 0)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.lightGrey),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatItem('Total Posts', _totalPosts.toString()),
                    _buildStatItem('Images', _imageCount.toString()),
                    _buildStatItem('Videos', _videoCount.toString()),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholder(String text) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.cloud_upload,
          size: 60,
          color: AppColors.primaryColor,
        ),
        const SizedBox(height: 16),
        Text(
          text,
          style: TextStyle(
            fontSize: 16,
            color: AppColors.primaryColor,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Upload images or videos from your gallery',
          style: TextStyle(
            fontSize: 14,
            color: AppColors.primaryColor,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.primaryColor,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: AppColors.grey,
          ),
        ),
      ],
    );
  }
}