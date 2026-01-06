import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:artist_hub/core/constants/app_colors.dart';
import 'package:artist_hub/core/constants/app_strings.dart';
import 'package:artist_hub/core/services/api_service.dart';
import 'package:artist_hub/core/services/shared_pref.dart';
import 'package:artist_hub/core/widgets/custom_button.dart';
import 'package:artist_hub/core/widgets/custom_textfield.dart';
import 'package:artist_hub/utils/helpers.dart';
import 'package:video_player/video_player.dart';

class UploadMediaScreen extends StatefulWidget {
  const UploadMediaScreen({super.key});

  @override
  State<UploadMediaScreen> createState() => _UploadMediaScreenState();
}

class _UploadMediaScreenState extends State<UploadMediaScreen> {
  final _formKey = GlobalKey<FormState>();
  final _captionController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  File? _selectedFile;
  String? _mediaType;
  bool _isLoading = false;
  bool _isUploading = false;
  VideoPlayerController? _videoController;

  List<Map<String, dynamic>> _recentUploads = [];

  @override
  void initState() {
    super.initState();
    _loadRecentUploads();
  }

  Future<void> _loadRecentUploads() async {
    setState(() => _isLoading = true);

    final userId = SharedPref.getUserId();
    if (userId.isEmpty) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      final result = await ApiService.getArtistMedia(artistId: int.parse(userId));
      if (result['success'] == true && result['data'] != null) {
        final List<dynamic> data = result['data'];
        setState(() {
          _recentUploads = data.take(3).map((item) {
            return {
              'id': item['id'],
              'type': item['media_type'],
              'url': item['media_url'],
              'caption': item['caption'],
              'date': item['created_at'],
            };
          }).toList();
        });
      }
    } catch (e) {
      // Silently fail for recent uploads
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _pickMedia(ImageSource source) async {
    try {
      XFile? pickedFile;

      if (_mediaType == 'image') {
        pickedFile = await _picker.pickImage(source: source);
      } else if (_mediaType == 'video') {
        pickedFile = await _picker.pickVideo(source: source);
      }

      if (pickedFile != null) {
        final file = File(pickedFile.path);

        // Check file size (limit: 50MB)
        final fileSize = await file.length();
        if (fileSize > 50 * 1024 * 1024) {
          Helpers.showSnackbar(context, 'File size should be less than 50MB', isError: true);
          return;
        }

        setState(() {
          _selectedFile = file;
        });

        // Initialize video player if video is selected
        if (_mediaType == 'video') {
          _videoController = VideoPlayerController.file(file)
            ..initialize().then((_) {
              setState(() {});
            });
        } else {
          _videoController?.dispose();
          _videoController = null;
        }
      }
    } catch (e) {
      Helpers.showSnackbar(context, 'Failed to pick media: $e', isError: true);
    }
  }

  Future<void> _uploadMedia() async {
    if (_selectedFile == null || _mediaType == null) {
      Helpers.showSnackbar(context, 'Please select media to upload', isError: true);
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    final hasInternet = await Helpers.checkInternetBeforeApiCall(context);
    if (!hasInternet) return;

    setState(() => _isUploading = true);

    final userId = SharedPref.getUserId();
    if (userId.isEmpty) {
      Helpers.showSnackbar(context, 'User not found', isError: true);
      setState(() => _isUploading = false);
      return;
    }

    try {
      final result = await ApiService.addArtistMedia(
        artistId: int.parse(userId),
        mediaType: _mediaType!,
        mediaFile: _selectedFile!,
        caption: _captionController.text.trim(),
      );

      if (result['success'] == true) {
        Helpers.showSnackbar(context, 'Media uploaded successfully');

        // Reset form
        _selectedFile = null;
        _mediaType = null;
        _captionController.clear();
        _videoController?.dispose();
        _videoController = null;

        // Reload recent uploads
        await _loadRecentUploads();

        if (!mounted) return;
        Navigator.pop(context);
      } else {
        Helpers.showSnackbar(
          context,
          result['message'] ?? 'Failed to upload media',
          isError: true,
        );
      }
    } catch (e) {
      Helpers.showSnackbar(context, 'Upload failed: $e', isError: true);
    } finally {
      setState(() => _isUploading = false);
    }
  }

  void _removeMedia() {
    setState(() {
      _selectedFile = null;
      _mediaType = null;
      _videoController?.dispose();
      _videoController = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Upload Media'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadRecentUploads,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Media type selection
            _buildMediaTypeSelector(),

            const SizedBox(height: 24),

            // Media preview
            if (_selectedFile != null) _buildMediaPreview(),

            const SizedBox(height: 24),

            // Caption field
            _buildCaptionField(),

            const SizedBox(height: 32),

            // Upload button
            _buildUploadButton(),

            const SizedBox(height: 32),

            // Recent uploads
            _buildRecentUploads(),
          ],
        ),
      ),
    );
  }

  Widget _buildMediaTypeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Select Media Type',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.textColor,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildMediaTypeButton(
                type: 'image',
                label: 'Image',
                icon: Icons.image,
                color: AppColors.primaryColor,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMediaTypeButton(
                type: 'video',
                label: 'Video',
                icon: Icons.videocam,
                color: AppColors.secondaryColor,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMediaTypeButton({
    required String type,
    required String label,
    required IconData icon,
    required Color color,
  }) {
    final isSelected = _mediaType == type;

    return ElevatedButton(
      onPressed: () {
        setState(() => _mediaType = type);
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected ? color : color.withOpacity(0.1),
        foregroundColor: isSelected ? AppColors.white : color,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(vertical: 16),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 24),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: isSelected ? AppColors.white : color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMediaPreview() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Media Preview',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.textColor,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          height: 200,
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Stack(
            children: [
              // Media display
              if (_mediaType == 'image' && _selectedFile != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(
                    _selectedFile!,
                    width: double.infinity,
                    height: double.infinity,
                    fit: BoxFit.cover,
                  ),
                )
              else if (_mediaType == 'video' && _videoController != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: VideoPlayer(_videoController!),
                )
              else
                const Center(
                  child: Icon(
                    Icons.media_bluetooth_off,
                    size: 48,
                    color: AppColors.lightGrey,
                  ),
                ),

              // Play button for video
              if (_mediaType == 'video' && _videoController != null)
                Center(
                  child: IconButton(
                    icon: Icon(
                      _videoController!.value.isPlaying
                          ? Icons.pause
                          : Icons.play_arrow,
                      size: 48,
                      color: AppColors.white,
                    ),
                    onPressed: () {
                      setState(() {
                        if (_videoController!.value.isPlaying) {
                          _videoController!.pause();
                        } else {
                          _videoController!.play();
                        }
                      });
                    },
                  ),
                ),

              // Remove button
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.close, color: AppColors.white),
                    onPressed: _removeMedia,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildPickButton(
              label: 'Camera',
              icon: Icons.camera_alt,
              source: ImageSource.camera,
              color: AppColors.primaryColor,
            ),
            const SizedBox(width: 12),
            _buildPickButton(
              label: 'Gallery',
              icon: Icons.photo_library,
              source: ImageSource.gallery,
              color: AppColors.secondaryColor,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPickButton({
    required String label,
    required IconData icon,
    required ImageSource source,
    required Color color,
  }) {
    return Expanded(
      child: ElevatedButton.icon(
        onPressed: _mediaType == null
            ? null
            : () => _pickMedia(source),
        icon: Icon(icon, size: 20),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: color.withOpacity(0.1),
          foregroundColor: color,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }

  Widget _buildCaptionField() {
    return Form(
      key: _formKey,
      child: CustomTextField(
        controller: _captionController,
        labelText: 'Caption (Optional)',
        hintText: 'Add a caption for your media...',
        maxLines: 3,
        prefixIcon: const Icon(Icons.description_outlined, color: AppColors.darkGrey),
        validator: (value) {
          if (value != null && value.trim().length > 500) {
            return 'Caption cannot exceed 500 characters';
          }
          return null;
        },
      ),
    );
  }

  Widget _buildUploadButton() {
    return Column(
      children: [
        CustomButton(
          text: _isUploading ? 'Uploading...' : 'Upload Media',
          onPressed:  _uploadMedia,
          isLoading: _isUploading,
          backgroundColor: _selectedFile == null
              ? AppColors.grey
              : AppColors.primaryColor,
        ),
        // const SizedBox(height: 8),
        // if (_selectedFile != null)
        //   // Text(
        //   //   'File size: ${Helpers.formatFileSize(_selectedFile!.lengthSync())}',
        //   //   style: const TextStyle(
        //   //     fontSize: 12,
        //   //     color: AppColors.darkGrey,
        //   //   ),
        //   ),
      ],
    );
  }

  Widget _buildRecentUploads() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_recentUploads.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Recent Uploads',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.textColor,
          ),
        ),
        const SizedBox(height: 12),
        Column(
          children: _recentUploads.map((upload) {
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
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
              child: Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: AppColors.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      upload['type'] == 'image'
                          ? Icons.image
                          : Icons.videocam,
                      color: AppColors.primaryColor,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          upload['caption'] ?? 'No caption',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textColor,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          Helpers.timeAgo(upload['date']),
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.darkGrey,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.visibility_outlined, size: 20),
                    onPressed: () {
                      // Navigate to media detail
                    },
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _captionController.dispose();
    _videoController?.dispose();
    super.dispose();
  }
}