import 'package:artist_hub/dashboards/customer_dashboard/widgets/post_card.dart';
import 'package:artist_hub/dashboards/customer_dashboard/widgets/section_title.dart';
import 'package:flutter/material.dart';
import 'package:artist_hub/core/constants/app_colors.dart';

class ArtistPostsSection extends StatelessWidget {
  final List<dynamic> posts;
  final bool isLoading;
  final Map<int, bool> postLikedStatus;
  final Map<int, int> postLikesCount;
  final Function(int, int) onLikeTapped;

  const ArtistPostsSection({
    Key? key,
    required this.posts,
    required this.isLoading,
    required this.postLikedStatus,
    required this.postLikesCount,
    required this.onLikeTapped,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Container(
        height: 200,
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.accentColor),
        ),
        child: Center(child: CircularProgressIndicator(color: AppColors.primaryColor)),
      );
    }

    if (posts.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 40),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.accentColor),
        ),
        child: Column(
          children: [
            Icon(Icons.photo_library_outlined, size: 64, color: AppColors.textColor.withOpacity(0.3)),
            const SizedBox(height: 16),
            const Text('No Posts Yet', style: TextStyle(fontSize: 18, color: Color(0xFF1F2937), fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'Follow artists to see their latest work',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle('Recent Posts'),
        const SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: posts.length > 6 ? 6 : posts.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 1,
          ),
          itemBuilder: (context, index) {
            final post = posts[index];
            final postId = post['id'] is int ? post['id'] : int.tryParse(post['id']?.toString() ?? '0') ?? 0;

            // Get mediaId from post - handle all possible field names
            final mediaId = _extractMediaId(post);

            // Debug print
            print('ArtistPostsSection - Index: $index, PostId: $postId, MediaId: $mediaId');

            // Check if this post has mediaId
            if (mediaId == 0) {
              print('WARNING: No mediaId found for post: ${post.keys.toList()}');
            }

            return PostCard(
              post: post,
              isLiked: postLikedStatus[postId] ?? false,
              likesCount: postLikesCount[postId] ?? 0,
              mediaId: mediaId, // This must be passed
              onLikeTapped: () {
                print('Like tapped for postId: $postId, mediaId: $mediaId');
                if (mediaId == 0) {
                  print('ERROR: Cannot like - mediaId is 0');
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Cannot like post: Media ID not found'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }
                onLikeTapped(postId, mediaId);
              },
            );
          },
        ),
        if (posts.length > 6)
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Center(
              child: ElevatedButton.icon(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.card,
                  foregroundColor: AppColors.primaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: AppColors.primaryColor, width: 1.5),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
                icon: const Icon(Icons.collections_rounded, size: 18),
                label: const Text('View All Posts', style: TextStyle(fontWeight: FontWeight.w600)),
              ),
            ),
          ),
      ],
    );
  }

  // Helper method to extract mediaId from post
  int _extractMediaId(dynamic post) {
    try {
      // Check for media_id (with underscore)
      if (post['media_id'] != null) {
        if (post['media_id'] is int) return post['media_id'];
        if (post['media_id'] is String) {
          final parsed = int.tryParse(post['media_id']);
          if (parsed != null) return parsed;
        }
      }

      // Check for mediaid (without underscore)
      if (post['mediaid'] != null) {
        if (post['mediaid'] is int) return post['mediaid'];
        if (post['mediaid'] is String) {
          final parsed = int.tryParse(post['mediaid']);
          if (parsed != null) return parsed;
        }
      }

      // Check for mediaId (camelCase)
      if (post['mediaId'] != null) {
        if (post['mediaId'] is int) return post['mediaId'];
        if (post['mediaId'] is String) {
          final parsed = int.tryParse(post['mediaId']);
          if (parsed != null) return parsed;
        }
      }

      // Check for id (as fallback)
      if (post['id'] != null) {
        if (post['id'] is int) return post['id'];
        if (post['id'] is String) {
          final parsed = int.tryParse(post['id']);
          if (parsed != null) return parsed;
        }
      }

      return 0;
    } catch (e) {
      print('Error extracting mediaId: $e');
      return 0;
    }
  }
}