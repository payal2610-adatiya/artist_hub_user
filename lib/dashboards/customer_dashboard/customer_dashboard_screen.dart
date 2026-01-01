import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:artist_hub/core/constants/app_colors.dart';
import 'package:artist_hub/models/artist_model.dart';
import 'package:artist_hub/providers/artist_provider.dart';
import 'package:artist_hub/providers/auth_provider.dart';
import 'package:artist_hub/customer/search/search_artist_screen.dart';
import 'package:artist_hub/customer/bookings/booking_list_screen.dart';
import 'package:artist_hub/customer/profile/customer_profile_screen.dart';
import 'package:artist_hub/customer/bookings/booking_screen.dart';
import 'package:artist_hub/core/services/api_service.dart';
import 'package:http/http.dart' as http;

// Enhanced Helper class for URL construction
class UrlHelper {
  static const String baseUrl = 'https://prakrutitech.xyz/gaurang/';

  static String getMediaUrl(String? relativePath) {
    if (relativePath == null || relativePath.isEmpty || relativePath == 'ghfd') {
      return '';
    }

    if (relativePath.startsWith('http')) {
      return relativePath;
    }

    String path = relativePath;
    if (path.startsWith('/')) {
      path = path.substring(1);
    }

    if (path.startsWith('uploads/')) {
      return '$baseUrl$path';
    }

    return '$baseUrl/uploads/$path';
  }
}

// Enhanced Like Service
class LikeService {
  static Future<Map<String, dynamic>> toggleLike(int userId, int mediaId) async {
    try {
      final response = await http.post(
        Uri.parse('https://prakrutitech.xyz/gaurang/like.php'),
        body: {
          'user_id': userId.toString(),
          'media_id': mediaId.toString(),
        },
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return {
        'status': false,
        'message': 'Server error: ${response.statusCode}',
      };
    } catch (e) {
      return {
        'status': false,
        'message': 'Network error: $e',
      };
    }
  }

  static Future<Map<String, dynamic>> addComment({
    required int userId,
    required int mediaId,
    required String comment,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('https://prakrutitech.xyz/gaurang/add_comments.php'),
        body: {
          'user_id': userId.toString(),
          'media_id': mediaId.toString(),
          'comment': comment,
        },
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return {
        'status': false,
        'message': 'Server error: ${response.statusCode}',
      };
    } catch (e) {
      return {
        'status': false,
        'message': 'Network error: $e',
      };
    }
  }

  static Future<Map<String, dynamic>> getComments(int mediaId) async {
    try {
      final response = await http.get(
        Uri.parse('https://prakrutitech.xyz/gaurang/view_comments.php?media_id=$mediaId'),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return {
        'status': false,
        'message': 'Server error: ${response.statusCode}',
      };
    } catch (e) {
      return {
        'status': false,
        'message': 'Network error: $e',
      };
    }
  }
}

class CustomerDashboardScreen extends StatefulWidget {
  const CustomerDashboardScreen({Key? key}) : super(key: key);

  @override
  State<CustomerDashboardScreen> createState() => _CustomerDashboardScreenState();
}

class _CustomerDashboardScreenState extends State<CustomerDashboardScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    CustomerHomeTab(),
    SearchArtistScreen(),
    CustomerBookingsTab(),
    CustomerProfileTab(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ArtistProvider>().fetchArtists();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: _screens[_currentIndex],
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.textColor.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Container(
          height: 72,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(Icons.home_outlined, 'Home', 0),
              _buildNavItem(Icons.search_outlined, 'Search', 1),
              _buildNavItem(Icons.calendar_today_outlined, 'Bookings', 2),
              _buildNavItem(Icons.person_outline, 'Profile', 3),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index) {
    bool isSelected = _currentIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: isSelected ? AppColors.primaryColor.withOpacity(0.1) : Colors.transparent,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? AppColors.primaryColor : AppColors.textColor.withOpacity(0.6),
              size: isSelected ? 24 : 22,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? AppColors.primaryColor : AppColors.textColor.withOpacity(0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/* ================= HOME TAB ================= */

class CustomerHomeTab extends StatefulWidget {
  const CustomerHomeTab({Key? key}) : super(key: key);

  @override
  State<CustomerHomeTab> createState() => _CustomerHomeTabState();
}

class _CustomerHomeTabState extends State<CustomerHomeTab> {
  List<dynamic> _artistPosts = [];
  bool _isLoadingPosts = false;
  final Map<int, bool> _postLikedStatus = {};
  final Map<int, int> _postLikesCount = {};

  @override
  void initState() {
    super.initState();
    _loadArtistPosts();
  }

  void _safeSetState(VoidCallback fn) {
    if (mounted) setState(fn);
  }

  Future<void> _loadArtistPosts() async {
    try {
      _safeSetState(() => _isLoadingPosts = true);

      final response = await ApiService.getArtistMedia();

      if (!mounted) return;

      if (response['status'] == true) {
        final posts = response['data'] ?? [];
        _safeSetState(() {
          _artistPosts = posts;
          for (var post in posts) {
            try {
              // FIXED: Handle both string and int IDs
              final id = post['id'] is int ? post['id'] : int.tryParse(post['id']?.toString() ?? '0') ?? 0;
              final likes = post['likes_count'] is int
                  ? post['likes_count']
                  : int.tryParse(post['likes_count']?.toString() ?? '0') ?? 0;
              _postLikesCount[id] = likes;
              _postLikedStatus[id] = false;
            } catch (e) {
              debugPrint('Error parsing post data: $e');
            }
          }
        });
      }
    } catch (e) {
      if (!mounted) return;
      debugPrint('Error loading posts: $e');
    } finally {
      if (mounted) {
        _safeSetState(() => _isLoadingPosts = false);
      }
    }
  }

  Future<void> _toggleLike(int postId, int mediaId) async {
    final user = context.read<AuthProvider>().user;
    if (user == null) return;

    final currentLiked = _postLikedStatus[postId] ?? false;
    final currentCount = _postLikesCount[postId] ?? 0;

    _safeSetState(() {
      _postLikedStatus[postId] = !currentLiked;
      _postLikesCount[postId] = currentLiked ? currentCount - 1 : currentCount + 1;
    });

    final result = await LikeService.toggleLike(user.id!, mediaId);

    if (!result['status'] && mounted) {
      _safeSetState(() {
        _postLikedStatus[postId] = currentLiked;
        _postLikesCount[postId] = currentCount;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'Failed to update like'),
          backgroundColor: Colors.red,
        ),
      );
    } else if (mounted) {
      final totalLikes = result['total_likes'] is int
          ? result['total_likes']
          : int.tryParse(result['total_likes']?.toString() ?? '0') ?? _postLikesCount[postId]!;
      _safeSetState(() => _postLikesCount[postId] = totalLikes);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;

    return RefreshIndicator(
      onRefresh: _loadArtistPosts,
      color: AppColors.primaryColor,
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            backgroundColor: AppColors.card,
            expandedHeight: 200,
            floating: false,
            pinned: true,
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              collapseMode: CollapseMode.pin,
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      AppColors.card,
                      AppColors.background,
                    ],
                  ),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 40),
                    Text(
                      'Welcome back,',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textColor.withOpacity(0.8),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user?.name ?? 'User',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textColor,
                        fontFamily: 'Playfair',
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.gold.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.gold.withOpacity(0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.brush_outlined, size: 16, color: AppColors.gold),
                          const SizedBox(width: 8),
                          Text(
                            'Inspire, Create, Connect',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.textColor.withOpacity(0.8),
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                const _SearchBar(),
                const SizedBox(height: 24),
                const _CategoriesSection(),
                const SizedBox(height: 24),
                const _AllArtistsSection(),
                const SizedBox(height: 24),
                _ArtistPostsSection(
                  posts: _artistPosts,
                  isLoading: _isLoadingPosts,
                  postLikedStatus: _postLikedStatus,
                  postLikesCount: _postLikesCount,
                  onLikeTapped: _toggleLike,
                ),
                const SizedBox(height: 40),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

/* ================= SEARCH BAR ================= */

class _SearchBar extends StatelessWidget {
  const _SearchBar();

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SearchArtistScreen())),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: AppColors.textColor.withOpacity(0.05),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
            border: Border.all(color: AppColors.accentColor),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.gold.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.search_rounded, color: AppColors.gold, size: 22),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Search Artists',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Find by name, category, or location',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textColor.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios_rounded, size: 18, color: AppColors.textColor.withOpacity(0.4)),
            ],
          ),
        ),
      ),
    );
  }
}

/* ================= CATEGORIES SECTION ================= */

class _CategoriesSection extends StatelessWidget {
  const _CategoriesSection();

  @override
  Widget build(BuildContext context) {
    final categories = [
      {'name': 'Singers', 'icon': Icons.mic_rounded, 'color': Colors.blue},
      {'name': 'Musicians', 'icon': Icons.music_note_rounded, 'color': Colors.green},
      {'name': 'Painters', 'icon': Icons.brush_rounded, 'color': Colors.orange},
      {'name': 'Dancers', 'icon': Icons.directions_run_rounded, 'color': Colors.purple},
      {'name': 'Photographers', 'icon': Icons.camera_alt_rounded, 'color': Colors.red},
      {'name': 'Performers', 'icon': Icons.theater_comedy_rounded, 'color': Colors.teal},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle('Explore Categories'),
        const SizedBox(height: 16),
        SizedBox(
          height: 100,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: categories.length,
            separatorBuilder: (_, i) => const SizedBox(width: 12),
            itemBuilder: (_, i) {
              final category = categories[i];
              return _CategoryCard(
                name: category['name'] as String,
                icon: category['icon'] as IconData,
                color: category['color'] as Color,
              );
            },
          ),
        ),
      ],
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final String name;
  final IconData icon;
  final Color color;

  const _CategoryCard({required this.name, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 160,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.textColor.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(color: AppColors.accentColor),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1F2937),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  'Browse artists',
                  style: TextStyle(
                    fontSize: 12,
                    color: color.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/* ================= ALL ARTISTS SECTION ================= */

class _AllArtistsSection extends StatelessWidget {
  const _AllArtistsSection();

  @override
  Widget build(BuildContext context) {
    return Consumer<ArtistProvider>(
      builder: (_, provider, __) {
        if (provider.isLoading) {
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

        if (provider.artists.isEmpty) {
          return _buildEmptyState();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _SectionTitle('Featured Artists'),
            const SizedBox(height: 16),
            SizedBox(
              height: 260,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: provider.artists.length > 4 ? 4 : provider.artists.length,
                separatorBuilder: (_, i) => const SizedBox(width: 16),
                itemBuilder: (_, index) {
                  final artist = provider.artists[index];
                  return _ArtistCard(artist: artist);
                },
              ),
            ),
            if (provider.artists.length > 4)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Center(
                  child: TextButton(
                    onPressed: () {},
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'View All ${provider.artists.length} Artists',
                          style: TextStyle(
                            color: AppColors.primaryColor,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(Icons.arrow_forward_rounded, size: 18, color: AppColors.primaryColor),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.accentColor),
      ),
      child: Column(
        children: [
          Icon(Icons.people_outline_rounded, size: 64, color: AppColors.textColor.withOpacity(0.3)),
          const SizedBox(height: 16),
          const Text(
            'No Artists Available',
            style: TextStyle(fontSize: 18, color: Color(0xFF1F2937), fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              'Check back soon for amazing artists in your area',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
            ),
          ),
        ],
      ),
    );
  }
}

/* ================= ARTIST CARD - FIXED OVERFLOW ================= */

class _ArtistCard extends StatelessWidget {
  final ArtistModel artist;

  const _ArtistCard({required this.artist});

  @override
  Widget build(BuildContext context) {
    final iconData = _getArtistIcon(artist.category);
    final iconColor = _getCategoryColor(artist.category);

    return GestureDetector(
      onTap: () {
        showModalBottomSheet(
          isScrollControlled: true,
          context: context,
          backgroundColor: Colors.transparent,
          builder: (_) => ArtistDetailsBottomSheet(artist: artist),
        );
      },
      child: Container(
        width: 200,
        constraints: const BoxConstraints(
          maxHeight: 260, // Fixed height constraint
        ),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppColors.textColor.withOpacity(0.05),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(color: AppColors.accentColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min, // Important: prevents overflow
          children: [
            Container(
              height: 140,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
                color: iconColor.withOpacity(0.1),
              ),
              child: Center(
                child: Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: iconColor.withOpacity(0.2),
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Icon(iconData, size: 32, color: iconColor),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      artist.name ?? 'Artist',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1F2937),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(iconData, size: 14, color: AppColors.textColor.withOpacity(0.6)),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            artist.category ?? 'Artist',
                            style: TextStyle(fontSize: 13, color: AppColors.textColor.withOpacity(0.6)),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: Colors.amber.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Icon(Icons.star_rounded, size: 14, color: Colors.amber),
                              ),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      artist.avgRating?.toStringAsFixed(1) ?? '4.5',
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF1F2937),
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Text(
                                      '${artist.totalReviews ?? 0} reviews',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: Color(0xFF9CA3AF),
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        Flexible(
                          child: Text(
                            '₹${artist.price ?? 0}',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primaryColor,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
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

  IconData _getArtistIcon(String? category) {
    if (category == null) return Icons.person_rounded;
    final lowerCategory = category.toLowerCase();
    if (lowerCategory.contains('singer')) return Icons.mic_rounded;
    if (lowerCategory.contains('music')) return Icons.music_note_rounded;
    if (lowerCategory.contains('painter')) return Icons.brush_rounded;
    if (lowerCategory.contains('dancer')) return Icons.directions_run_rounded;
    if (lowerCategory.contains('photo')) return Icons.camera_alt_rounded;
    if (lowerCategory.contains('actor')) return Icons.theater_comedy_rounded;
    if (lowerCategory.contains('designer')) return Icons.palette_rounded;
    if (lowerCategory.contains('writer')) return Icons.edit_rounded;
    return Icons.person_rounded;
  }

  Color _getCategoryColor(String? category) {
    if (category == null) return AppColors.primaryColor;
    final lowerCategory = category.toLowerCase();
    if (lowerCategory.contains('singer')) return Colors.blue;
    if (lowerCategory.contains('music')) return Colors.green;
    if (lowerCategory.contains('painter')) return Colors.orange;
    if (lowerCategory.contains('dancer')) return Colors.purple;
    if (lowerCategory.contains('photo')) return Colors.red;
    if (lowerCategory.contains('actor')) return Colors.teal;
    if (lowerCategory.contains('designer')) return Colors.pink;
    if (lowerCategory.contains('writer')) return Colors.brown;
    return AppColors.primaryColor;
  }
}

/* ================= ARTIST POSTS SECTION ================= */

class _ArtistPostsSection extends StatelessWidget {
  final List<dynamic> posts;
  final bool isLoading;
  final Map<int, bool> postLikedStatus;
  final Map<int, int> postLikesCount;
  final Function(int, int) onLikeTapped;

  const _ArtistPostsSection({
    required this.posts,
    required this.isLoading,
    required this.postLikedStatus,
    required this.postLikesCount,
    required this.onLikeTapped,
  });

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
        const _SectionTitle('Recent Posts'),
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
            return _PostCard(
              post: post,
              isLiked: postLikedStatus[postId] ?? false,
              likesCount: postLikesCount[postId] ?? 0,
              onLikeTapped: () {
                final mediaId = post['media_id'] is int ? post['media_id'] : int.tryParse(post['media_id']?.toString() ?? '0') ?? 0;
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
}

/* ================= POST CARD ================= */

class _PostCard extends StatelessWidget {
  final dynamic post;
  final bool isLiked;
  final int likesCount;
  final VoidCallback onLikeTapped;

  const _PostCard({required this.post, required this.isLiked, required this.likesCount, required this.onLikeTapped});

  @override
  Widget build(BuildContext context) {
    final mediaUrl = post['media_url']?.toString() ?? '';
    final mediaType = post['media_type']?.toString() ?? 'image';
    final fullImageUrl = UrlHelper.getMediaUrl(mediaUrl);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showPostDetails(context),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            boxShadow: [BoxShadow(color: AppColors.textColor.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 3))],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Stack(
              children: [
                Container(
                  color: AppColors.background,
                  child: fullImageUrl.isNotEmpty
                      ? Image.network(
                    fullImageUrl,
                    width: double.infinity,
                    height: double.infinity,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        color: AppColors.accentColor,
                        child: Center(
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.primaryColor,
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                                : null,
                          ),
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: AppColors.accentColor,
                        child: Center(
                          child: Icon(
                            mediaType == 'video' ? Icons.videocam_rounded : Icons.photo_rounded,
                            size: 32,
                            color: AppColors.textColor.withOpacity(0.3),
                          ),
                        ),
                      );
                    },
                  )
                      : Container(
                    color: AppColors.accentColor,
                    child: Center(
                      child: Icon(
                        mediaType == 'video' ? Icons.videocam_rounded : Icons.photo_rounded,
                        size: 32,
                        color: AppColors.textColor.withOpacity(0.3),
                      ),
                    ),
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.center,
                      colors: [Colors.black.withOpacity(0.4), Colors.transparent],
                    ),
                  ),
                ),
                if (mediaType == 'video')
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.play_arrow_rounded, size: 16, color: Colors.white),
                    ),
                  ),
                Positioned(
                  bottom: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.card.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: onLikeTapped,
                          child: Icon(
                            isLiked ? Icons.favorite_rounded : Icons.favorite_outline_rounded,
                            size: 14,
                            color: isLiked ? Colors.red : AppColors.textColor.withOpacity(0.6),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          likesCount.toString(),
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF1F2937)),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showPostDetails(BuildContext context) {
    showModalBottomSheet(
      isScrollControlled: true,
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => PostDetailsBottomSheet(
        post: post,
        isLiked: isLiked,
        likesCount: likesCount,
        onLikeTapped: onLikeTapped,
      ),
    );
  }
}

/* ================= POST DETAILS BOTTOM SHEET ================= */

class PostDetailsBottomSheet extends StatefulWidget {
  final dynamic post;
  final bool isLiked;
  final int likesCount;
  final VoidCallback onLikeTapped;

  const PostDetailsBottomSheet({
    Key? key,
    required this.post,
    required this.isLiked,
    required this.likesCount,
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
    _loadComments();
  }

  Future<void> _loadComments() async {
    setState(() => _loadingComments = true);
    final mediaId = widget.post['media_id'] is int ? widget.post['media_id'] : int.tryParse(widget.post['media_id']?.toString() ?? '0') ?? 0;
    final result = await LikeService.getComments(mediaId);
    if (result['status'] == true && mounted) {
      setState(() => _comments = result['data'] ?? []);
    }
    setState(() => _loadingComments = false);
  }

  Future<void> _addComment() async {
    if (_commentController.text.isEmpty) return;

    final user = Provider.of<AuthProvider>(context, listen: false).user;
    if (user == null) return;

    final mediaId = widget.post['media_id'] is int ? widget.post['media_id'] : int.tryParse(widget.post['media_id']?.toString() ?? '0') ?? 0;
    final result = await LikeService.addComment(
      userId: user.id!,
      mediaId: mediaId,
      comment: _commentController.text,
    );

    if (result['status'] == true && mounted) {
      _commentController.clear();
      await _loadComments();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      });
    }
  }

  void _sharePost() {
    // Implement sharing logic
    final mediaUrl = UrlHelper.getMediaUrl(widget.post['media_url']?.toString() ?? '');
    // You can use share_plus package for actual sharing
  }

  void _handleLike() {
    widget.onLikeTapped();
    setState(() {
      _isLiked = !_isLiked;
      _likesCount = _isLiked ? _likesCount + 1 : _likesCount - 1;
    });
  }

  @override
  Widget build(BuildContext context) {
    final mediaUrl = widget.post['media_url']?.toString() ?? '';
    final caption = widget.post['caption']?.toString() ?? '';
    final createdAt = widget.post['created_at']?.toString() ?? '';
    final mediaType = widget.post['media_type']?.toString() ?? 'image';
    final fullImageUrl = UrlHelper.getMediaUrl(mediaUrl);

    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: const BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.accentColor))),
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
                    child: Icon(Icons.close_rounded, size: 20, color: AppColors.textColor.withOpacity(0.6)),
                  ),
                ),
                const SizedBox(width: 16),
                Text('Post Details', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textColor)),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    mediaType == 'video' ? 'Video' : 'Image',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primaryColor),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Column(
              children: [
                Container(
                  height: 300,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    image: fullImageUrl.isNotEmpty ? DecorationImage(image: NetworkImage(fullImageUrl), fit: BoxFit.cover) : null,
                  ),
                  child: fullImageUrl.isEmpty
                      ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(color: AppColors.accentColor, shape: BoxShape.circle),
                          child: Icon(
                            mediaType == 'video' ? Icons.videocam_rounded : Icons.photo_rounded,
                            size: 40,
                            color: AppColors.textColor.withOpacity(0.3),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text('Media not available', style: TextStyle(color: AppColors.textColor.withOpacity(0.6))),
                      ],
                    ),
                  )
                      : null,
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.background,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              Column(
                                children: [
                                  IconButton(
                                    onPressed: _handleLike,
                                    icon: Icon(
                                      _isLiked ? Icons.favorite_rounded : Icons.favorite_outline_rounded,
                                      color: _isLiked ? Colors.red : AppColors.textColor.withOpacity(0.6),
                                      size: 28,
                                    ),
                                  ),
                                  Text(_likesCount.toString(), style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textColor)),
                                ],
                              ),
                              Column(
                                children: [
                                  IconButton(
                                    onPressed: () {},
                                    icon: Icon(Icons.comment_rounded, color: AppColors.textColor.withOpacity(0.6), size: 28),
                                  ),
                                  Text(_comments.length.toString(), style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textColor)),
                                ],
                              ),
                              Column(
                                children: [
                                  IconButton(
                                    onPressed: _sharePost,
                                    icon: Icon(Icons.share_rounded, color: AppColors.textColor.withOpacity(0.6), size: 28),
                                  ),
                                  Text('Share', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textColor)),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (caption.isNotEmpty) ...[
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 8),
                                  child: Text(caption, style: TextStyle(fontSize: 15, color: AppColors.textColor, height: 1.6)),
                                ),
                                const SizedBox(height: 16),
                              ],
                              const Divider(),
                              const SizedBox(height: 8),
                              Text('Comments (${_comments.length})', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textColor)),
                              const SizedBox(height: 8),
                              Expanded(
                                child: _loadingComments
                                    ? Center(child: CircularProgressIndicator(color: AppColors.primaryColor))
                                    : _comments.isEmpty
                                    ? Center(child: Text('No comments yet', style: TextStyle(color: AppColors.textColor.withOpacity(0.6))))
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
                                          Text(comment['name'] ?? 'User', style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.textColor)),
                                          const SizedBox(height: 4),
                                          Text(comment['comment'] ?? '', style: TextStyle(color: AppColors.textColor.withOpacity(0.8))),
                                          const SizedBox(height: 4),
                                          Text(
                                            _formatDate(comment['created_at']?.toString() ?? ''),
                                            style: TextStyle(fontSize: 11, color: AppColors.textColor.withOpacity(0.5)),
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
                                    hintStyle: TextStyle(color: AppColors.textColor.withOpacity(0.5)),
                                    border: InputBorder.none,
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                                  ),
                                  style: TextStyle(color: AppColors.textColor),
                                ),
                              ),
                              IconButton(
                                onPressed: _addComment,
                                icon: Icon(Icons.send_rounded, color: AppColors.primaryColor),
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
      return '${_getMonthName(date.month)} ${date.day}, ${date.year} at ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateString;
    }
  }

  String _getMonthName(int month) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[month - 1];
  }
}

/* ================= ARTIST DETAILS BOTTOM SHEET ================= */

class ArtistDetailsBottomSheet extends StatelessWidget {
  final ArtistModel artist;
  const ArtistDetailsBottomSheet({Key? key, required this.artist}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final iconData = _getArtistIcon(artist.category);
    final iconColor = _getCategoryColor(artist.category);

    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: const BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.accentColor))),
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
                    child: Icon(Icons.close_rounded, size: 20, color: AppColors.textColor.withOpacity(0.6)),
                  ),
                ),
                const SizedBox(width: 16),
                Text('Artist Details', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textColor)),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 20,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: iconColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: iconColor.withOpacity(0.2),
                              width: 2,
                            ),
                          ),
                          child: Center(
                            child: Icon(
                              iconData,
                              size: 40,
                              color: iconColor,
                            ),
                          ),
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                artist.name ?? 'Artist',
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1F2937),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: iconColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  artist.category ?? 'Artist',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: iconColor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.accentColor, width: 2),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: Colors.amber.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Icon(
                                      Icons.star_rounded,
                                      size: 20,
                                      color: Colors.amber,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Rating',
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: Color(0xFF64748B),
                                        ),
                                      ),
                                      Text(
                                        artist.avgRating?.toStringAsFixed(1) ?? '4.5',
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF1F2937),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Padding(
                                padding: const EdgeInsets.only(left: 42),
                                child: Text(
                                  '${artist.totalReviews ?? 0} reviews',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: Color(0xFF94A3B8),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          width: 1,
                          height: 60,
                          color: AppColors.accentColor,
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              const Text(
                                'Starting Price',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF64748B),
                                ),
                              ),
                              Text(
                                '₹${artist.price ?? 0}',
                                style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primaryColor,
                                ),
                              ),
                              const Text(
                                'per session',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF94A3B8),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (artist.description != null && artist.description!.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    const Text(
                      'About Artist',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        artist.description!,
                        style: const TextStyle(
                          fontSize: 15,
                          color: Color(0xFF475569),
                          height: 1.6,
                        ),
                      ),
                    ),
                  ],
                  if (artist.experience != null && artist.experience!.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.accentColor, width: 2),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.primaryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(
                              Icons.work_history_rounded,
                              size: 24,
                              color: Color(0xFF475569),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Experience',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF64748B),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${artist.experience} years',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1F2937),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 32),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: AppColors.primaryColor,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                              side: BorderSide(color: AppColors.primaryColor, width: 2),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 18),
                          ),
                          onPressed: () => Navigator.pop(context),
                          child: const Text(
                            'Close',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryColor,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            elevation: 0,
                          ),
                          onPressed: () {
                            Navigator.pop(context);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => BookingScreen(artist: artist),
                              ),
                            );
                          },
                          child: const Text(
                            'Book Now',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getArtistIcon(String? category) {
    if (category == null) return Icons.person_rounded;
    final lowerCategory = category.toLowerCase();
    if (lowerCategory.contains('singer')) return Icons.mic_rounded;
    if (lowerCategory.contains('music')) return Icons.music_note_rounded;
    if (lowerCategory.contains('painter')) return Icons.brush_rounded;
    if (lowerCategory.contains('dancer')) return Icons.directions_run_rounded;
    if (lowerCategory.contains('photo')) return Icons.camera_alt_rounded;
    if (lowerCategory.contains('actor')) return Icons.theater_comedy_rounded;
    if (lowerCategory.contains('designer')) return Icons.palette_rounded;
    if (lowerCategory.contains('writer')) return Icons.edit_rounded;
    return Icons.person_rounded;
  }

  Color _getCategoryColor(String? category) {
    if (category == null) return AppColors.primaryColor;
    final lowerCategory = category.toLowerCase();
    if (lowerCategory.contains('singer')) return Colors.blue;
    if (lowerCategory.contains('music')) return Colors.green;
    if (lowerCategory.contains('painter')) return Colors.orange;
    if (lowerCategory.contains('dancer')) return Colors.purple;
    if (lowerCategory.contains('photo')) return Colors.red;
    if (lowerCategory.contains('actor')) return Colors.teal;
    if (lowerCategory.contains('designer')) return Colors.pink;
    if (lowerCategory.contains('writer')) return Colors.brown;
    return AppColors.primaryColor;
  }
}

/* ================= OTHER TABS ================= */

class CustomerBookingsTab extends StatelessWidget {
  const CustomerBookingsTab({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) => const BookingListScreen();
}

class CustomerProfileTab extends StatelessWidget {
  const CustomerProfileTab({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) => const CustomerProfileScreen();
}

/* ================= COMMON ================= */

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: AppColors.textColor,
        fontFamily: 'Playfair',
      ),
    );
  }
}