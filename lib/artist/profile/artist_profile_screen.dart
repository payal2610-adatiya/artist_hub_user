import 'package:flutter/material.dart';
import 'package:artist_hub/core/constants/app_colors.dart';
import 'package:artist_hub/core/routes/app_routes.dart';
import 'package:artist_hub/core/services/api_service.dart';
import 'package:artist_hub/core/services/shared_pref.dart';
import 'package:artist_hub/core/widgets/custom_button.dart';
import 'package:artist_hub/core/widgets/loading_widget.dart';
import 'package:artist_hub/models/artist_model.dart';
import 'package:artist_hub/utils/helpers.dart';

import 'edit_artist_profile_screen.dart';

class ArtistProfileScreen extends StatefulWidget {
  const ArtistProfileScreen({super.key});

  @override
  State<ArtistProfileScreen> createState() => _ArtistProfileScreenState();
}

class _ArtistProfileScreenState extends State<ArtistProfileScreen> {
  ArtistModel? _artist;
  Map<String, dynamic>? _profile;
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    final userId = SharedPref.getUserId();
    if (userId.isEmpty) {
      setState(() {
        _isLoading = false;
        _hasError = true;
      });
      return;
    }

    try {
      // Load artist details
      final artistResult = await ApiService.getArtistDetails(int.parse(userId));
      if (artistResult['success'] == true && artistResult['data'] != null) {
        setState(() {
          _artist = ArtistModel.fromJson(artistResult['data']);
        });
      }

      // Load artist profile
      final profileResult = await ApiService.getArtistProfile(userId: int.parse(userId));
      if (profileResult['success'] == true && profileResult['data'] != null) {
        if (profileResult['data'] is List && (profileResult['data'] as List).isNotEmpty) {
          setState(() {
            _profile = (profileResult['data'] as List).first;
          });
        } else if (profileResult['data'] is Map) {
          setState(() {
            _profile = profileResult['data'];
          });
        }
      }
    } catch (e) {
      setState(() {
        _hasError = true;
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _navigateToEditProfile() {
    Navigator.pushReplacement(
      context, MaterialPageRoute(builder: (context) => const EditArtistProfileScreen())
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primaryColor,
        title: const Text('Artist Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: _navigateToEditProfile,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadProfile,
          ),
        ],
      ),
      body: _isLoading
          ? const LoadingWidget(message: 'Loading profile...')
          : _hasError
          ? _buildErrorState()
          : _buildProfileContent(),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            size: 64,
            color: AppColors.errorColor,
          ),
          const SizedBox(height: 16),
          const Text(
            'Failed to load profile',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textColor,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Please check your connection and try again',
            style: TextStyle(
              color: AppColors.darkGrey,
            ),
          ),
          const SizedBox(height: 24),
          CustomButton(
            text: 'Retry',
            onPressed: _loadProfile,
          ),
        ],
      ),
    );
  }

  Widget _buildProfileContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Profile header
          _buildProfileHeader(),

          const SizedBox(height: 24),

          // Profile completion
          _buildProfileCompletion(),

          const SizedBox(height: 24),

          // About section
          _buildAboutSection(),

          const SizedBox(height: 24),

          // Contact info
          _buildContactInfo(),

          const SizedBox(height: 24),

          // Stats section
          _buildStatsSection(),

          const SizedBox(height: 24),

          // Actions
          _buildActionButtons(),
        ],
      ),
    );
  }

  Widget _buildProfileHeader() {
    final userName = _artist?.name ?? SharedPref.getUserName();
    final userEmail = _artist?.email ?? '';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Profile picture
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppColors.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(40),
                  border: Border.all(
                    color: AppColors.primaryColor.withOpacity(0.2),
                    width: 2,
                  ),
                ),
                child: Center(
                  child: Text(
                    Helpers.getInitials(userName),
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryColor,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 20),

              // Name and info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      userName,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      userEmail,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.darkGrey,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (_artist?.category != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          _artist!.category!,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: AppColors.primaryColor,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Rating and experience
          Row(
            children: [
              Expanded(
                child: _buildInfoItem(
                  icon: Icons.star,
                  label: 'Rating',
                  value: (_artist?.avgRating ?? 0).toStringAsFixed(1),
                  color: AppColors.secondaryColor,
                ),
              ),
              Expanded(
                child: _buildInfoItem(
                  icon: Icons.work,
                  label: 'Experience',
                  value: _profile?['experience'] ?? 'Not set',
                  color: AppColors.gold,
                ),
              ),
              Expanded(
                child: _buildInfoItem(
                  icon: Icons.currency_rupee,
                  label: 'Price',
                  value: _profile?['price'] != null
                      ? '₹${_profile!['price']}'
                      : 'Not set',
                  color: AppColors.successColor,
                ),
              ),
            ],
          ),

        ],
      ),
    );
  }

  Widget _buildInfoItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.darkGrey,
          ),
        ),
      ],
    );
  }

  Widget _buildProfileCompletion() {
    final isProfileComplete = _profile != null;
    final completionPercentage = isProfileComplete ? 100 : 50;
    final missingFields = isProfileComplete
        ? 'Profile complete!'
        : 'Complete your profile to get more bookings';

    return Container(
      padding: const EdgeInsets.all(16),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Profile Status',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textColor,
                ),
              ),
              Text(
                '$completionPercentage%',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: completionPercentage == 100
                      ? AppColors.successColor
                      : AppColors.primaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: completionPercentage / 100,
            backgroundColor: AppColors.lightGrey,
            color: completionPercentage == 100
                ? AppColors.successColor
                : AppColors.primaryColor,
            borderRadius: BorderRadius.circular(4),
            minHeight: 8,
          ),
          const SizedBox(height: 8),
          Text(
            missingFields,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.darkGrey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAboutSection() {
    final description = _profile?['description'] ?? 'No description added';
    final category = _profile?['category'] ?? 'Not specified';
    final experience = _profile?['experience'] ?? 'Not specified';
    final price = _profile?['price'] ?? 'Not specified';

    return Container(
      padding: const EdgeInsets.all(16),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'About Me',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textColor,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            description,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.darkGrey,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 20),
          const Divider(height: 1, color: AppColors.lightGrey),
          const SizedBox(height: 16),
          _buildDetailItem(
            icon: Icons.category,
            label: 'Category',
            value: category,
          ),
          const SizedBox(height: 12),
          _buildDetailItem(
            icon: Icons.work_history,
            label: 'Experience',
            value: experience,
          ),
          const SizedBox(height: 12),
          _buildDetailItem(
            icon: Icons.currency_rupee,
            label: 'Starting Price',
            value: price != 'Not specified' ? '₹$price' : price,
          ),
        ],
      ),
    );
  }

  Widget _buildDetailItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.primaryColor),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.darkGrey,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textColor,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildContactInfo() {
    final phone = _artist?.phone ?? 'Not provided';
    final address = _artist?.address ?? 'Not provided';
    final email = _artist?.email ?? '';

    return Container(
      padding: const EdgeInsets.all(16),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Contact Information',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textColor,
            ),
          ),
          const SizedBox(height: 12),
          _buildContactItem(
            icon: Icons.phone,
            label: 'Phone',
            value: phone,
            onTap: () {
              if (phone != 'Not provided') {
                // Launch phone dialer
              }
            },
          ),
          const SizedBox(height: 12),
          _buildContactItem(
            icon: Icons.email,
            label: 'Email',
            value: email,
            onTap: () {
              // Launch email client
            },
          ),
          const SizedBox(height: 12),
          _buildContactItem(
            icon: Icons.location_on,
            label: 'Address',
            value: address,
            onTap: () {
              if (address != 'Not provided') {
                // Launch maps
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildContactItem({
    required IconData icon,
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: value != 'Not provided' && value.isNotEmpty ? onTap : null,
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.primaryColor),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.darkGrey,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: value == 'Not provided' || value.isEmpty
                        ? AppColors.darkGrey
                        : AppColors.primaryColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSection() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.2,
      children: [
        _buildStatCard(
          title: 'Total Bookings',
          value: _artist?.totalReviews.toString() ?? '0',
          icon: Icons.calendar_today,
          color: AppColors.primaryColor,
        ),
        _buildStatCard(
          title: 'Total Posts',
          value: _artist?.totalPosts.toString() ?? '0',
          icon: Icons.image,
          color: AppColors.secondaryColor,
        ),
        _buildStatCard(
          title: 'Avg. Rating',
          value: _artist?.avgRating.toStringAsFixed(1) ?? '0.0',
          icon: Icons.star,
          color: AppColors.gold,
        ),
        // _buildStatCard(
        //   title: 'Member Since',
        //   value: _artist != null
        //       ? Helpers.formatDate( format: 'MMM yyyy')
        //       : 'N/A',
        //   icon: Icons.person_add,
        //   color: AppColors.successColor,
        // ),
      ],
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
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
      child: Column(
        mainAxisSize: MainAxisSize.min, // ⭐ FIX
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 20, color: color),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 22, // slightly smaller
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis, // ⭐ prevents overflow
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.darkGrey,
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildActionButtons() {
    return Column(
      children: [
        CustomButton(
          text: 'Edit Profile',
          onPressed: _navigateToEditProfile,
          backgroundColor: AppColors.primaryColor,
        ),
        const SizedBox(height: 12),
        CustomButton(
          text: 'View Portfolio',
          onPressed: () {
            final userId = SharedPref.getUserId();
            Navigator.pushNamed(
              context,
              AppRoutes.mediaGallery,
              arguments: {
                'artistId': int.parse(userId),
                'artistName': _artist?.name ?? 'My Portfolio',
              },
            );
          },
          backgroundColor: AppColors.secondaryColor,
        ),
        const SizedBox(height: 12),
// Add to _buildActionButtons() method
        OutlinedButton(
          onPressed: () async {
            final confirmed = await Helpers.showConfirmationDialog(
              context,
              'Logout',
              'Are you sure you want to logout?',
            );

            if (!confirmed) return;

            await SharedPref.clearUserData();
            if (!mounted) return;

            Navigator.pushNamedAndRemoveUntil(
              context,
              AppRoutes.roleSelection,
                  (route) => false,
            );
          },
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.errorColor,
            side: const BorderSide(color: AppColors.errorColor),
            minimumSize: const Size(double.infinity, 50),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text(
            'Logout',
            style: TextStyle(fontSize: 16),
          ),
        ),      ],
    );
  }
}