import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:artist_hub/core/constants/app_colors.dart';
import 'package:artist_hub/core/constants/app_strings.dart';
import 'package:artist_hub/providers/auth_provider.dart';
import 'package:artist_hub/providers/media_provider.dart';
import 'package:artist_hub/core/widgets/custom_button.dart';
import 'package:artist_hub/core/widgets/custom_textfield.dart';

import '../../models/media_model.dart';

class UploadMediaScreen extends StatefulWidget {
  const UploadMediaScreen({Key? key}) : super(key: key);

  @override
  _UploadMediaScreenState createState() => _UploadMediaScreenState();
}

class _UploadMediaScreenState extends State<UploadMediaScreen> {
  final TextEditingController _captionController = TextEditingController();
  File? _selectedMedia;
  String? _mediaType;
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _selectedMedia = File(image.path);
        _mediaType = 'image';
      });
    }
  }

  Future<void> _pickVideo() async {
    final XFile? video = await _picker.pickVideo(source: ImageSource.gallery);
    if (video != null) {
      setState(() {
        _selectedMedia = File(video.path);
        _mediaType = 'video';
      });
    }
  }

  Future<void> _uploadMedia() async {
    if (_selectedMedia == null || _mediaType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select media to upload'),
          backgroundColor: AppColors.errorColor,
        ),
      );
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final mediaProvider = Provider.of<MediaProvider>(context, listen: false);

    if (authProvider.userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please login to upload media'),
          backgroundColor: AppColors.errorColor,
        ),
      );
      return;
    }

    final success = await mediaProvider.addMedia(
      artistId: authProvider.userId!,
      mediaType: _mediaType!,
      mediaFile: _selectedMedia!,
      caption: _captionController.text.trim(),
    );

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Media uploaded successfully'),
          backgroundColor: AppColors.successColor,
        ),
      );
      setState(() {
        _selectedMedia = null;
        _mediaType = null;
        _captionController.clear();
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(mediaProvider.errorMessage ?? 'Upload failed'),
          backgroundColor: AppColors.errorColor,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final mediaProvider = Provider.of<MediaProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Upload Media'),
        backgroundColor: AppColors.white,
        elevation: 1,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Media Preview
            if (_selectedMedia != null)
              Container(
                width: double.infinity,
                height: 200,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: AppColors.backgroundColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.lightGrey),
                ),
                child: _mediaType == 'image'
                    ? Image.file(
                  _selectedMedia!,
                  fit: BoxFit.cover,
                )
                    : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.videocam,
                      size: 60,
                      color: AppColors.primaryColor,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Video selected',
                      style: TextStyle(
                        fontSize: 16,
                        color: AppColors.textColor,
                      ),
                    ),
                  ],
                ),
              )
            else
              Container(
                width: double.infinity,
                height: 200,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: AppColors.backgroundColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.lightGrey,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.cloud_upload,
                      size: 60,
                      color: AppColors.lightGrey,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No media selected',
                      style: TextStyle(
                        fontSize: 16,
                        color: AppColors.grey,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Upload images or videos from your gallery',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.grey,
                      ),
                    ),
                  ],
                ),
              ),

            // Media Selection Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pickImage,
                    icon: const Icon(Icons.image),
                    label: const Text('Pick Image'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primaryColor,
                      side: BorderSide(color: AppColors.primaryColor),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pickVideo,
                    icon: const Icon(Icons.videocam),
                    label: const Text('Pick Video'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.secondaryColor,
                      side: BorderSide(color: AppColors.secondaryColor),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Caption
            CustomTextField(
              controller: _captionController,
              labelText: 'Caption',
              hintText: 'Add a caption for your media...',
              maxLines: 3,
            ),

            const SizedBox(height: 30),

            // Upload Button
            CustomButton(
              text: 'Upload Media',
              onPressed: _uploadMedia,
              isLoading: mediaProvider.isLoading,
            ),

            const SizedBox(height: 30),

            // Media Gallery
            _buildMediaGallery(),
          ],
        ),
      ),
    );
  }

  Widget _buildMediaGallery() {
    final mediaProvider = Provider.of<MediaProvider>(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'My Gallery',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textColor,
          ),
        ),
        const SizedBox(height: 12),

        if (mediaProvider.isLoading)
          const Center(child: CircularProgressIndicator())
        else if (mediaProvider.mediaList.isEmpty)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 40),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.photo_library_outlined,
                  size: 60,
                  color: AppColors.lightGrey,
                ),
                const SizedBox(height: 16),
                Text(
                  'No media uploaded yet',
                  style: TextStyle(
                    color: AppColors.grey,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          )
        else
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: mediaProvider.mediaList.length,
            itemBuilder: (context, index) {
              final media = mediaProvider.mediaList[index];
              return _buildMediaItem(media);
            },
          ),
      ],
    );
  }

  Widget _buildMediaItem(MediaModel media) {
    return GestureDetector(
      onLongPress: () {
        _showDeleteDialog(media);
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: AppColors.backgroundColor,
          image: media.mediaType == 'image'
              ? DecorationImage(
            image: NetworkImage(media.mediaUrl ?? ''),
            fit: BoxFit.cover,
          )
              : null,
        ),
        child: media.mediaType == 'video'
            ? Stack(
          children: [
            Container(
              color: AppColors.primaryColor.withOpacity(0.1),
            ),
            Center(
              child: Icon(
                Icons.play_circle_filled,
                size: 40,
                color: AppColors.primaryColor,
              ),
            ),
          ],
        )
            : null,
      ),
    );
  }

  void _showDeleteDialog(MediaModel media) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Media'),
          content: const Text('Are you sure you want to delete this media?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final authProvider = Provider.of<AuthProvider>(context, listen: false);
                final mediaProvider = Provider.of<MediaProvider>(context, listen: false);

                final success = await mediaProvider.deleteMedia(
                  mediaId: media.id!,
                  artistId: authProvider.userId!,
                );

                Navigator.pop(context);

                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Media deleted successfully'),
                      backgroundColor: AppColors.successColor,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.errorColor,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }
}