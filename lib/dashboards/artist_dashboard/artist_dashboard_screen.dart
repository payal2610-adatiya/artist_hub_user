// import 'package:flutter/material.dart';
// import 'package:artist_hub/core/constants/app_colors.dart';
// import 'package:artist_hub/core/constants/app_strings.dart';
// import 'package:artist_hub/core/routes/app_routes.dart';
// import 'package:artist_hub/core/services/api_service.dart';
// import 'package:artist_hub/core/services/shared_pref.dart';
// import 'package:artist_hub/core/widgets/loading_widget.dart';
// import 'package:artist_hub/core/widgets/no_data_widget.dart';
// import 'package:artist_hub/models/artist_model.dart';
// import 'package:artist_hub/models/booking_model.dart';
// import 'package:artist_hub/utils/helpers.dart';
//
// class ArtistDashboardScreen extends StatefulWidget {
//   const ArtistDashboardScreen({super.key});
//
//   @override
//   State<ArtistDashboardScreen> createState() => _ArtistDashboardScreenState();
// }
//
// class _ArtistDashboardScreenState extends State<ArtistDashboardScreen> {
//   ArtistModel? _artist;
//   List<BookingModel> _recentBookings = [];
//   bool _isLoading = true;
//   bool _hasError = false;
//
//   @override
//   void initState() {
//     super.initState();
//     _loadDashboardData();
//   }
//
//   Future<void> _loadDashboardData() async {
//     setState(() {
//       _isLoading = true;
//       _hasError = false;
//     });
//
//     final userId = SharedPref.getUserId();
//     if (userId.isEmpty) {
//       setState(() {
//         _isLoading = false;
//         _hasError = true;
//       });
//       return;
//     }
//
//     try {
//       // Load artist details
//       final artistResult = await ApiService.getArtistDetails(int.parse(userId));
//       if (artistResult['success'] == true && artistResult['data'] != null) {
//         setState(() {
//           _artist = ArtistModel.fromJson(artistResult['data']);
//         });
//       }
//
//       // Load recent bookings
//       final bookingsResult = await ApiService.getBookingsByArtist(artistId: int.parse(userId));
//       if (bookingsResult['success'] == true && bookingsResult['data'] != null) {
//         final List<dynamic> bookingsData = bookingsResult['data'];
//         setState(() {
//           _recentBookings = bookingsData
//               .map((item) => BookingModel.fromJson(item))
//               .where((booking) => booking.isUpcoming)
//               .take(3)
//               .toList();
//         });
//       }
//     } catch (e) {
//       setState(() {
//         _hasError = true;
//       });
//     } finally {
//       setState(() => _isLoading = false);
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: AppColors.background,
//       appBar: AppBar(
//         backgroundColor: AppColors.primaryColor,
//         title: const Text('Artist Hub',style: TextStyle(color: AppColors.white),),
//
//       ),
//       body: _isLoading
//           ? const LoadingWidget(message: 'Loading dashboard...')
//           : _hasError
//           ? NoDataWidget(
//         message: 'Failed to load dashboard data',
//         buttonText: 'Retry',
//         onPressed: _loadDashboardData,
//       )
//           : _buildDashboardContent(),
//       bottomNavigationBar: _buildBottomNavigationBar(),
//     );
//   }
//
//   Widget _buildDashboardContent() {
//     return SingleChildScrollView(
//       padding: const EdgeInsets.all(16),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           // Welcome section
//           _buildWelcomeSection(),
//
//           const SizedBox(height: 24),
//
//           // Stats cards
//           _buildStatsSection(),
//
//           const SizedBox(height: 24),
//
//           // Quick actions
//           _buildQuickActions(),
//
//           const SizedBox(height: 24),
//
//           // Recent bookings
//           _buildRecentBookings(),
//
//           const SizedBox(height: 24),
//
//           // Profile completion
//           _buildProfileCompletion(),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildWelcomeSection() {
//     final userName = SharedPref.getUserName();
//     final timeOfDay = _getTimeOfDay();
//
//     return Container(
//       padding: const EdgeInsets.all(20),
//       decoration: BoxDecoration(
//         color: AppColors.primaryColor,
//         borderRadius: BorderRadius.circular(16),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.1),
//             blurRadius: 10,
//             offset: const Offset(0, 4),
//           ),
//         ],
//       ),
//       child: Row(
//         children: [
//           // Avatar
//           Container(
//             width: 60,
//             height: 60,
//             decoration: BoxDecoration(
//               color: AppColors.white,
//               borderRadius: BorderRadius.circular(30),
//             ),
//             child: Center(
//               child: Text(
//                 Helpers.getInitials(userName),
//                 style: const TextStyle(
//                   fontSize: 24,
//                   fontWeight: FontWeight.w600,
//                   color: AppColors.primaryColor,
//                 ),
//               ),
//             ),
//           ),
//           const SizedBox(width: 16),
//
//           // Welcome text
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   'Good $timeOfDay,',
//                   style: const TextStyle(
//                     fontSize: 14,
//                     color: AppColors.white,
//                   ),
//                 ),
//                 Text(
//                   userName,
//                   style: const TextStyle(
//                     fontSize: 22,
//                     fontWeight: FontWeight.w600,
//                     color: AppColors.white,
//                   ),
//                 ),
//                 const SizedBox(height: 4),
//                 Text(
//                   'Ready to showcase your talent?',
//                   style: TextStyle(
//                     fontSize: 14,
//                     color: AppColors.white.withOpacity(0.8),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildStatsSection() {
//     return GridView.count(
//       shrinkWrap: true,
//       physics: const NeverScrollableScrollPhysics(),
//       crossAxisCount: 2,
//       crossAxisSpacing: 12,
//       mainAxisSpacing: 12,
//       childAspectRatio: 1.2,
//       children: [
//         _buildStatCard(
//           icon: Icons.calendar_today,
//           title: AppStrings.totalBookings,
//           value: _artist?.totalReviews.toString() ?? '0',
//           color: AppColors.primaryColor,
//         ),
//         _buildStatCard(
//           icon: Icons.people,
//           title: AppStrings.totalCustomers,
//           value: (_artist?.totalReviews ?? 0).toString(),
//           color: AppColors.secondaryColor,
//         ),
//         _buildStatCard(
//           title: 'Total Posts',
//           value: _artist?.totalPosts.toString() ?? '0',
//           icon: Icons.image,
//           color: AppColors.secondaryColor,
//         ),
//         _buildStatCard(
//           icon: Icons.star,
//           title: AppStrings.rating,
//           value: _artist?.avgRating.toStringAsFixed(1) ?? '0.0',
//           color: Colors.orange,
//         ),
//       ],
//     );
//   }
//
//   Widget _buildStatCard({
//     required IconData icon,
//     required String title,
//     required String value,
//     required Color color,
//   }) {
//     return Container(
//       padding: const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         color: AppColors.white,
//         borderRadius: BorderRadius.circular(16),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.05),
//             blurRadius: 8,
//             offset: const Offset(0, 2),
//           ),
//         ],
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//         children: [
//           Container(
//             width: 40,
//             height: 40,
//             decoration: BoxDecoration(
//               color: color.withOpacity(0.1),
//               borderRadius: BorderRadius.circular(10),
//             ),
//             child: Icon(icon, color: color, size: 24),
//           ),
//
//           Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               FittedBox(
//                 fit: BoxFit.scaleDown,
//                 child: Text(
//                   value,
//                   style: TextStyle(
//                     fontSize: 24,
//                     fontWeight: FontWeight.w700,
//                     color: color,
//                   ),
//                 ),
//               ),
//               const SizedBox(height: 2),
//               Text(
//                 title,
//                 style: const TextStyle(
//                   fontSize: 12,
//                   color: AppColors.darkGrey,
//                 ),
//                 maxLines: 1,
//                 overflow: TextOverflow.ellipsis,
//               ),
//             ],
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildQuickActions() {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         const Text(
//           'Quick Actions',
//           style: TextStyle(
//             fontSize: 18,
//             fontWeight: FontWeight.w600,
//             color: AppColors.textColor,
//           ),
//         ),
//         const SizedBox(height: 12),
//         GridView.count(
//           shrinkWrap: true,
//           physics: const NeverScrollableScrollPhysics(),
//           crossAxisCount: 2,
//           crossAxisSpacing: 12,
//           mainAxisSpacing: 12,
//           childAspectRatio: 2.5,
//           children: [
//             _buildActionButton(
//               icon: Icons.add_photo_alternate,
//               label: AppStrings.uploadMedia,
//               color: AppColors.primaryColor,
//               onTap: () {
//                 Navigator.pushNamed(context, AppRoutes.uploadMedia);
//               },
//             ),
//             _buildActionButton(
//               icon: Icons.calendar_today,
//               label: AppStrings.manageBookings,
//               color: AppColors.secondaryColor,
//               onTap: () {
//                 Navigator.pushNamed(context, AppRoutes.artistBookings);
//               },
//             ),
//             _buildActionButton(
//               icon: Icons.person,
//               label: AppStrings.viewProfile,
//               color: AppColors.gold,
//               onTap: () {
//                 Navigator.pushNamed(context, AppRoutes.artistProfile);
//               },
//             ),
//             _buildActionButton(
//               icon: Icons.star,
//               label: AppStrings.seeReviews,
//               color: Colors.orange,
//               onTap: () {
//                 Navigator.pushNamed(context, AppRoutes.artistReviews);
//               },
//             ),
//           ],
//         ),
//       ],
//     );
//   }
//
//   Widget _buildActionButton({
//     required IconData icon,
//     required String label,
//     required Color color,
//     required VoidCallback onTap,
//   }) {
//     return ElevatedButton(
//       onPressed: onTap,
//       style: ElevatedButton.styleFrom(
//         backgroundColor: color.withOpacity(0.1),
//         foregroundColor: color,
//         shape: RoundedRectangleBorder(
//           borderRadius: BorderRadius.circular(12),
//         ),
//         elevation: 0,
//         padding: const EdgeInsets.symmetric(horizontal: 12),
//       ),
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           Icon(icon, size: 20),
//           const SizedBox(width: 8),
//           Flexible(
//             child: Text(
//               label,
//               style: TextStyle(
//                 fontSize: 12,
//                 fontWeight: FontWeight.w500,
//                 color: color,
//               ),
//               overflow: TextOverflow.ellipsis,
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildRecentBookings() {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Row(
//           mainAxisAlignment: MainAxisAlignment.spaceBetween,
//           children: [
//             const Text(
//               AppStrings.recentBookings,
//               style: TextStyle(
//                 fontSize: 18,
//                 fontWeight: FontWeight.w600,
//                 color: AppColors.textColor,
//               ),
//             ),
//             if (_recentBookings.isNotEmpty)
//               TextButton(
//                 onPressed: () {
//                   Navigator.pushNamed(context, AppRoutes.artistBookings);
//                 },
//                 child: const Text(
//                   AppStrings.viewAll,
//                   style: TextStyle(
//                     color: AppColors.primaryColor,
//                     fontWeight: FontWeight.w500,
//                   ),
//                 ),
//               ),
//           ],
//         ),
//         const SizedBox(height: 12),
//         if (_recentBookings.isEmpty)
//           Container(
//             padding: const EdgeInsets.all(20),
//             decoration: BoxDecoration(
//               color: AppColors.white,
//               borderRadius: BorderRadius.circular(12),
//             ),
//             child: const Column(
//               children: [
//                 Icon(
//                   Icons.calendar_today_outlined,
//                   size: 48,
//                   color: AppColors.lightGrey,
//                 ),
//                 SizedBox(height: 12),
//                 Text(
//                   'No upcoming bookings',
//                   style: TextStyle(
//                     color: AppColors.darkGrey,
//                   ),
//                 ),
//               ],
//             ),
//           )
//         else
//           Column(
//             children: _recentBookings
//                 .map((booking) => _buildBookingCard(booking))
//                 .toList(),
//           ),
//       ],
//     );
//   }
//
//   Widget _buildBookingCard(BookingModel booking) {
//     return Container(
//       margin: const EdgeInsets.only(bottom: 12),
//       padding: const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         color: AppColors.white,
//         borderRadius: BorderRadius.circular(12),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.05),
//             blurRadius: 6,
//             offset: const Offset(0, 2),
//           ),
//         ],
//       ),
//       child: Row(
//         children: [
//           // Date
//           Container(
//             width: 60,
//             padding: const EdgeInsets.symmetric(vertical: 8),
//             decoration: BoxDecoration(
//               color: AppColors.primaryColor.withOpacity(0.1),
//               borderRadius: BorderRadius.circular(8),
//             ),
//             child: Column(
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: [
//                 Text(
//                   Helpers.formatDate(booking.bookingDate, format: 'dd'),
//                   style: const TextStyle(
//                     fontSize: 20,
//                     fontWeight: FontWeight.w700,
//                     color: AppColors.primaryColor,
//                   ),
//                 ),
//                 Text(
//                   Helpers.formatDate(booking.bookingDate, format: 'MMM'),
//                   style: const TextStyle(
//                     fontSize: 12,
//                     color: AppColors.primaryColor,
//                   ),
//                 ),
//               ],
//             ),
//           ),
//           const SizedBox(width: 16),
//
//           // Booking details
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   booking.customerName ?? 'Customer',
//                   style: const TextStyle(
//                     fontSize: 16,
//                     fontWeight: FontWeight.w600,
//                     color: AppColors.textColor,
//                   ),
//                 ),
//                 const SizedBox(height: 4),
//                 Text(
//                   booking.eventAddress,
//                   style: const TextStyle(
//                     fontSize: 12,
//                     color: AppColors.darkGrey,
//                   ),
//                   maxLines: 1,
//                   overflow: TextOverflow.ellipsis,
//                 ),
//                 const SizedBox(height: 8),
//                 Row(
//                   children: [
//                     Container(
//                       padding: const EdgeInsets.symmetric(
//                         horizontal: 8,
//                         vertical: 2,
//                       ),
//                       decoration: BoxDecoration(
//                         color: booking.paymentStatus == 'paid'
//                             ? AppColors.successColor.withOpacity(0.1)
//                             : AppColors.warningColor.withOpacity(0.1),
//                         borderRadius: BorderRadius.circular(4),
//                       ),
//                       child: Text(
//                         booking.paymentStatus == 'paid' ? 'Paid' : 'Pending',
//                         style: TextStyle(
//                           fontSize: 10,
//                           fontWeight: FontWeight.w500,
//                           color: booking.paymentStatus == 'paid'
//                               ? AppColors.successColor
//                               : AppColors.warningColor,
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildProfileCompletion() {
//     final isProfileComplete = _artist?.category != null;
//     final completionPercentage = isProfileComplete ? 100 : 50;
//
//     return Container(
//       padding: const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         color: AppColors.white,
//         borderRadius: BorderRadius.circular(12),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.05),
//             blurRadius: 6,
//             offset: const Offset(0, 2),
//           ),
//         ],
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           const Text(
//             'Profile Completion',
//             style: TextStyle(
//               fontSize: 16,
//               fontWeight: FontWeight.w600,
//               color: AppColors.textColor,
//             ),
//           ),
//           const SizedBox(height: 12),
//           LinearProgressIndicator(
//             value: completionPercentage / 100,
//             backgroundColor: AppColors.lightGrey,
//             color: AppColors.primaryColor,
//             borderRadius: BorderRadius.circular(4),
//           ),
//           const SizedBox(height: 8),
//           Row(
//             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//             children: [
//               Text(
//                 '$completionPercentage% Complete',
//                 style: const TextStyle(
//                   fontSize: 12,
//                   color: AppColors.darkGrey,
//                 ),
//               ),
//               if (!isProfileComplete)
//                 TextButton(
//                   onPressed: () {
//                     Navigator.pushNamed(context, AppRoutes.artistProfile);
//                   },
//                   child: const Text(
//                     'Complete Now',
//                     style: TextStyle(
//                       fontSize: 12,
//                       color: AppColors.primaryColor,
//                       fontWeight: FontWeight.w500,
//                     ),
//                   ),
//                 ),
//             ],
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildBottomNavigationBar() {
//     return BottomNavigationBar(
//       currentIndex: 0,
//       type: BottomNavigationBarType.fixed,
//       backgroundColor: AppColors.white,
//       selectedItemColor: AppColors.primaryColor,
//       unselectedItemColor: AppColors.darkGrey,
//       showSelectedLabels: true,
//       showUnselectedLabels: true,
//       items: const [
//         BottomNavigationBarItem(
//           icon: Icon(Icons.home),
//           label: 'Home',
//         ),
//         BottomNavigationBarItem(
//           icon: Icon(Icons.photo_library),
//           label: 'Portfolio',
//         ),
//         BottomNavigationBarItem(
//           icon: Icon(Icons.calendar_today),
//           label: 'Bookings',
//         ),
//         BottomNavigationBarItem(
//           icon: Icon(Icons.person),
//           label: 'Profile',
//         ),
//       ],
//       onTap: (index) {
//         final userId = SharedPref.getUserId();
//         switch (index) {
//           case 0:
//           // Already on home
//             break;
//           case 1:
//             Navigator.pushNamed(
//               context,
//               AppRoutes.mediaGallery,
//               arguments: {
//                 'artistId': int.parse(userId),
//                 'artistName': SharedPref.getUserName(),
//               },
//             );
//             break;
//           case 2:
//             Navigator.pushNamed(context, AppRoutes.artistBookings);
//             break;
//           case 3:
//             Navigator.pushNamed(context, AppRoutes.artistProfile);
//             break;
//         }
//       },
//     );
//   }
//   String _getTimeOfDay() {
//     final hour = DateTime.now().hour;
//     if (hour < 12) return 'Morning';
//     if (hour < 17) return 'Afternoon';
//     if (hour < 21) return 'Evening';
//     return 'Night';
//   }
// }
import 'package:flutter/material.dart';
import 'package:artist_hub/core/constants/app_colors.dart';
import 'package:artist_hub/core/constants/app_strings.dart';
import 'package:artist_hub/core/routes/app_routes.dart';
import 'package:artist_hub/core/services/api_service.dart';
import 'package:artist_hub/core/services/shared_pref.dart';
import 'package:artist_hub/core/widgets/loading_widget.dart';
import 'package:artist_hub/core/widgets/no_data_widget.dart';
import 'package:artist_hub/models/artist_model.dart';
import 'package:artist_hub/models/booking_model.dart';
import 'package:artist_hub/utils/helpers.dart';

class ArtistDashboardScreen extends StatefulWidget {
  const ArtistDashboardScreen({super.key});

  @override
  State<ArtistDashboardScreen> createState() => _ArtistDashboardScreenState();
}

class _ArtistDashboardScreenState extends State<ArtistDashboardScreen> {
  ArtistModel? _artist;
  List<BookingModel> _recentBookings = [];
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
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

      // Load recent bookings
      final bookingsResult = await ApiService.getBookingsByArtist(artistId: int.parse(userId));
      if (bookingsResult['success'] == true && bookingsResult['data'] != null) {
        final List<dynamic> bookingsData = bookingsResult['data'];
        setState(() {
          _recentBookings = bookingsData
              .map((item) => BookingModel.fromJson(item))
              .where((booking) => booking.isUpcoming)
              .take(3)
              .toList();
        });
      }
    } catch (e) {
      print('Error loading dashboard data: $e');
      setState(() {
        _hasError = true;
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primaryColor,
        title: const Text(
          'Artist Hub',
          style: TextStyle(color: Colors.white), // Fixed: Use Colors.white
        ),
        elevation: 0,
      ),
      body: _isLoading
          ? const LoadingWidget(message: 'Loading dashboard...')
          : _hasError
          ? NoDataWidget(
        message: 'Failed to load dashboard data',
        buttonText: 'Retry',
        onPressed: _loadDashboardData,
      )
          : RefreshIndicator(
        color: AppColors.primaryColor,
        onRefresh: _loadDashboardData,
        child: _buildDashboardContent(),
      ),

      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildDashboardContent() {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildWelcomeSection(),
          const SizedBox(height: 24),
          _buildStatsSection(),
          const SizedBox(height: 24),
          _buildQuickActions(),
          const SizedBox(height: 24),
          _buildRecentBookings(),
          const SizedBox(height: 24),
          _buildProfileCompletion(),
        ],
      ),
    );
  }

  Widget _buildWelcomeSection() {
    final userName = SharedPref.getUserName() ?? 'Artist';
    final timeOfDay = _getTimeOfDay();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.primaryColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(30),
            ),
            child: Center(
              child: Text(
                Helpers.getInitials(userName),
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryColor,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),

          // Welcome text
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Good $timeOfDay,',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.white,
                  ),
                ),
                Text(
                  userName,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Ready to showcase your talent?',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.8),
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
          icon: Icons.calendar_today,
          title: AppStrings.totalBookings,
          value: _artist?.totalReviews.toString() ?? '0',
          color: AppColors.primaryColor,
        ),
        _buildStatCard(
          icon: Icons.people,
          title: AppStrings.totalCustomers,
          value: (_artist?.totalReviews ?? 0).toString(),
          color: AppColors.secondaryColor,
        ),
        _buildStatCard(
          icon: Icons.image,
          title: AppStrings.totalPosts,
          value: _artist?.totalPosts.toString() ?? '0',
          color: AppColors.gold,
        ),
        _buildStatCard(
          icon: Icons.star,
          title: AppStrings.rating,
          value: _artist?.avgRating.toStringAsFixed(1) ?? '0.0',
          color: Colors.orange,
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 24),
          ),

          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  value,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.darkGrey,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quick Actions',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.textColor,
          ),
        ),
        const SizedBox(height: 12),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 2.5,
          children: [
            _buildActionButton(
              icon: Icons.add_photo_alternate,
              label: AppStrings.uploadMedia,
              color: AppColors.primaryColor,
              onTap: () {
                Navigator.pushNamed(context, AppRoutes.uploadMedia);
              },
            ),
            _buildActionButton(
              icon: Icons.calendar_today,
              label: AppStrings.manageBookings,
              color: AppColors.secondaryColor,
              onTap: () {
                Navigator.pushNamed(context, AppRoutes.artistBookings);
              },
            ),
            _buildActionButton(
              icon: Icons.person,
              label: AppStrings.viewProfile,
              color: AppColors.gold,
              onTap: () {
                Navigator.pushNamed(context, AppRoutes.artistProfile);
              },
            ),
            _buildActionButton(
              icon: Icons.star,
              label: AppStrings.seeReviews,
              color: Colors.orange,
              onTap: () {
                Navigator.pushNamed(context, AppRoutes.artistReviews);
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: color.withOpacity(0.1),
        foregroundColor: color,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: color,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentBookings() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              AppStrings.recentBookings,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textColor,
              ),
            ),
            if (_recentBookings.isNotEmpty)
              TextButton(
                onPressed: () {
                  Navigator.pushNamed(context, AppRoutes.artistBookings);
                },
                child: const Text(
                  AppStrings.viewAll,
                  style: TextStyle(
                    color: AppColors.primaryColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        if (_recentBookings.isEmpty)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Column(
              children: [
                Icon(
                  Icons.calendar_today_outlined,
                  size: 48,
                  color: AppColors.lightGrey,
                ),
                SizedBox(height: 12),
                Text(
                  'No upcoming bookings',
                  style: TextStyle(
                    color: AppColors.darkGrey,
                  ),
                ),
              ],
            ),
          )
        else
          Column(
            children: _recentBookings
                .map((booking) => _buildBookingCard(booking))
                .toList(),
          ),
      ],
    );
  }

  Widget _buildBookingCard(BookingModel booking) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Date
          Container(
            width: 60,
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  Helpers.formatDate(booking.bookingDate, format: 'dd'),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryColor,
                  ),
                ),
                Text(
                  Helpers.formatDate(booking.bookingDate, format: 'MMM'),
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.primaryColor,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),

          // Booking details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  booking.customerName ?? 'Customer',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  booking.eventAddress,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.darkGrey,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: booking.paymentStatus == 'paid'
                            ? AppColors.successColor.withOpacity(0.1)
                            : AppColors.warningColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        booking.paymentStatus == 'paid' ? 'Paid' : 'Pending',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: booking.paymentStatus == 'paid'
                              ? AppColors.successColor
                              : AppColors.warningColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileCompletion() {
    final isProfileComplete = _artist?.category != null;
    final completionPercentage = isProfileComplete ? 100 : 50;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
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
            'Profile Completion',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textColor,
            ),
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: completionPercentage / 100,
            backgroundColor: AppColors.lightGrey,
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryColor),
            borderRadius: BorderRadius.circular(4),
            minHeight: 8,
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$completionPercentage% Complete',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.darkGrey,
                ),
              ),
              if (!isProfileComplete)
                TextButton(
                  onPressed: () {
                    Navigator.pushNamed(context, AppRoutes.artistProfile);
                  },
                  child: const Text(
                    'Complete Now',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.primaryColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavigationBar() {
    return BottomNavigationBar(
      currentIndex: 0,
      type: BottomNavigationBarType.fixed,
      backgroundColor: Colors.white,
      selectedItemColor: AppColors.primaryColor,
      unselectedItemColor: AppColors.darkGrey,
      showSelectedLabels: true,
      showUnselectedLabels: true,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.photo_library),
          label: 'Portfolio',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.calendar_today),
          label: 'Bookings',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person),
          label: 'Profile',
        ),
      ],
      onTap: (index) {
        final userId = SharedPref.getUserId();
        if (userId.isEmpty) return;

        switch (index) {
          case 0:
          // Already on home
            break;
          case 1:
            Navigator.pushNamed(
              context,
              AppRoutes.mediaGallery,
              arguments: {
                'artistId': int.parse(userId),
                'artistName': SharedPref.getUserName() ?? 'My Portfolio',
                'isOwnGallery': true,
              },
            );
            break;
          case 2:
            Navigator.pushNamed(context, AppRoutes.artistBookings);
            break;
          case 3:
            Navigator.pushNamed(context, AppRoutes.artistProfile);
            break;
        }
      },
    );
  }

  String _getTimeOfDay() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Morning';
    if (hour < 17) return 'Afternoon';
    if (hour < 21) return 'Evening';
    return 'Night';
  }
}