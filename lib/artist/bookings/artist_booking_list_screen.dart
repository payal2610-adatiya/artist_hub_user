import 'package:flutter/material.dart';
import 'package:artist_hub/core/constants/app_colors.dart';
import 'package:artist_hub/core/constants/app_strings.dart';
import 'package:artist_hub/core/routes/app_routes.dart';
import 'package:artist_hub/core/services/api_service.dart';
import 'package:artist_hub/core/services/shared_pref.dart';
import 'package:artist_hub/core/widgets/loading_widget.dart';
import 'package:artist_hub/core/widgets/no_data_widget.dart';
import 'package:artist_hub/models/booking_model.dart';
import 'package:artist_hub/utils/helpers.dart';

class ArtistBookingListScreen extends StatefulWidget {
  const ArtistBookingListScreen({super.key});

  @override
  State<ArtistBookingListScreen> createState() => _ArtistBookingListScreenState();
}

class _ArtistBookingListScreenState extends State<ArtistBookingListScreen> {
  List<BookingModel> _bookings = [];
  List<BookingModel> _filteredBookings = [];
  bool _isLoading = true;
  bool _hasError = false;
  String _selectedTab = 'upcoming'; // 'upcoming', 'past', 'cancelled'
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadBookings();
  }

  Future<void> _loadBookings() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      final userId = await SharedPref.getUserId();
      if (userId.isEmpty) {
        setState(() {
          _isLoading = false;
          _hasError = true;
        });
        Helpers.showSnackbar(context, 'Please login first', isError: true);
        return;
      }

      print('Loading artist bookings for user ID: $userId');

      final result = await ApiService.getBookingsByArtist(artistId: int.parse(userId));

      print('Artist Bookings API Result: ${result['success']}');
      print('Artist Bookings Data: ${result['data']}');

      if (result['success'] == true) {
        if (result['data'] is List) {
          final List<dynamic> data = result['data'];
          final List<BookingModel> bookings = [];

          for (var item in data) {
            try {
              bookings.add(BookingModel.fromJson(item));
            } catch (e) {
              print('Error parsing booking item: $e');
              print('Item data: $item');
            }
          }

          setState(() {
            _bookings = bookings;
            _applyFilters();
          });
        } else {
          print('Invalid bookings data format: ${result['data']}');
          setState(() {
            _hasError = true;
          });
        }
      } else {
        print('Failed to load bookings: ${result['message']}');
        setState(() => _hasError = true);
      }
    } catch (e) {
      print('Error loading bookings: $e');
      setState(() => _hasError = true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _applyFilters() {
    List<BookingModel> filtered = _bookings;

    // Apply tab filter
    switch (_selectedTab) {
      case 'upcoming':
        filtered = filtered.where((booking) => booking.isUpcoming).toList();
        break;
      case 'past':
        filtered = filtered.where((booking) => booking.isCompleted).toList();
        break;
      case 'cancelled':
        filtered = filtered.where((booking) => booking.isCancelled).toList();
        break;
    }

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((booking) {
        final customerName = booking.customerName?.toLowerCase() ?? '';
        final eventAddress = booking.eventAddress.toLowerCase();
        final query = _searchQuery.toLowerCase();
        return customerName.contains(query) || eventAddress.contains(query);
      }).toList();
    }

    // Sort by date (most recent first)
    filtered.sort((a, b) => b.bookingDate.compareTo(a.bookingDate));

    setState(() => _filteredBookings = filtered);
  }

  void _changeTab(String tab) {
    setState(() {
      _selectedTab = tab;
      _applyFilters();
    });
  }

  void _openBookingDetail(BookingModel booking) {
    Navigator.pushNamed(
      context,
      AppRoutes.artistBookingDetail,
      arguments: {'booking': booking},
    );
  }

  Future<void> _cancelBooking(BookingModel booking) async {
    final reason = await _showCancelDialog();
    if (reason == null || reason.isEmpty) return;

    final hasInternet = await Helpers.checkInternetBeforeApiCall(context);
    if (!hasInternet) return;

    final confirmed = await Helpers.showConfirmationDialog(
      context,
      'Cancel Booking',
      'Are you sure you want to cancel this booking? This action cannot be undone.',
    );

    if (!confirmed) return;

    final userId = await SharedPref.getUserId();
    if (userId.isEmpty) {
      Helpers.showSnackbar(context, 'Please login first', isError: true);
      return;
    }

    try {
      final result = await ApiService.cancelBookingByArtist(
        bookingId: booking.id,
        artistId: int.parse(userId),
        cancelReason: reason,
      );

      if (result['success'] == true) {
        Helpers.showSnackbar(context, 'Booking cancelled successfully');
        await _loadBookings();
      } else {
        Helpers.showSnackbar(
          context,
          result['message'] ?? 'Failed to cancel booking',
          isError: true,
        );
      }
    } catch (e) {
      Helpers.showSnackbar(context, 'Error: $e', isError: true);
    }
  }

  Future<void> _markAsCompleted(BookingModel booking) async {
    final confirmed = await Helpers.showConfirmationDialog(
      context,
      'Mark as Completed',
      'Mark this booking as completed? This will allow the customer to leave a review.',
    );

    if (!confirmed) return;

    final hasInternet = await Helpers.checkInternetBeforeApiCall(context);
    if (!hasInternet) return;

    final userId = await SharedPref.getUserId();
    if (userId.isEmpty) {
      Helpers.showSnackbar(context, 'Please login first', isError: true);
      return;
    }

    try {
      // Call the update booking API
      final result = await ApiService.updateBooking(
        bookingId: booking.id,
        status: 'completed',
      );

      if (result['success'] == true) {
        Helpers.showSnackbar(context, 'Booking marked as completed!');
        await _loadBookings(); // Refresh the list
      } else {
        Helpers.showSnackbar(
          context,
          result['message'] ?? 'Failed to update booking status',
          isError: true,
        );
      }
    } catch (e) {
      Helpers.showSnackbar(context, 'Error: $e', isError: true);
    }
  }
  // Add this method to your ApiService or create it here
  Future<Map<String, dynamic>> _updateBookingStatus({
    required int bookingId,
    required String status,
  }) async {
    try {
      // You need to implement this API endpoint on your backend
      // Example: update_bookings.php
      final response = await ApiService.updateBooking(
        bookingId: bookingId,
        status: status,
      );

      return response;
    } catch (e) {
      return {
        'success': false,
        'message': 'Error updating booking: $e',
      };
    }
  }

  Future<String?> _showCancelDialog() async {
    final TextEditingController controller = TextEditingController();

    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Booking'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Please provide a reason for cancellation:'),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Enter reason...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                Navigator.pop(context, controller.text.trim());
              }
            },
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }

  void _refreshBookings() {
    _loadBookings();
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
        backgroundColor: AppColors.primaryColor,
        title: const Text('My Bookings', style: TextStyle(color: Colors.white)),

      ),
      body: _isLoading
          ? const LoadingWidget(message: 'Loading bookings...')
          : _hasError
          ? NoDataWidget(
        message: 'Failed to load bookings',
        buttonText: 'Retry',
        onPressed: _loadBookings,
      )
          : _buildContent(),
    );
  }

  Widget _buildContent() {
    return Column(
      children: [
        // Tab bar
        _buildTabBar(),

        // Stats
        _buildStats(),

        // Search info (if searching)
        if (_searchQuery.isNotEmpty) _buildSearchInfo(),

        // Bookings list
        Expanded(
          child: _filteredBookings.isEmpty
              ? NoDataWidget(
            message: _searchQuery.isNotEmpty
                ? 'No bookings match your search'
                : 'No bookings found',
            buttonText: _searchQuery.isNotEmpty ? 'Clear Search' : 'Refresh',
            onPressed: _searchQuery.isNotEmpty
                ? () {
              setState(() {
                _searchQuery = '';
                _applyFilters();
              });
            }
                : _loadBookings,
          )
              : _buildBookingsList(),
        ),
      ],
    );
  }

  Widget _buildSearchInfo() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: AppColors.primaryColor.withOpacity(0.1),
      child: Row(
        children: [
          const Icon(Icons.search, size: 16, color: AppColors.primaryColor),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Search results for "$_searchQuery"',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.primaryColor,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 16),
            onPressed: () {
              setState(() {
                _searchQuery = '';
                _applyFilters();
              });
            },
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: AppColors.white,
      child: Row(
        children: [
          _buildTabButton('upcoming', 'Upcoming'),
          const SizedBox(width: 12),
          _buildTabButton('past', 'Completed'),
          const SizedBox(width: 12),
          _buildTabButton('cancelled', 'Cancelled'),
        ],
      ),
    );
  }

  Widget _buildTabButton(String tab, String label) {
    final isSelected = _selectedTab == tab;
    final count = _bookings.where((b) {
      switch (tab) {
        case 'upcoming':
          return b.isUpcoming;
        case 'past':
          return b.isCompleted;
        case 'cancelled':
          return b.isCancelled;
        default:
          return false;
      }
    }).length;

    return Expanded(
      child: ElevatedButton(
        onPressed: () => _changeTab(tab),
        style: ElevatedButton.styleFrom(
          backgroundColor: isSelected ? AppColors.primaryColor : AppColors.white,
          foregroundColor: isSelected ? Colors.white : AppColors.darkGrey,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(
              color: isSelected ? AppColors.primaryColor : AppColors.lightGrey,
            ),
          ),
          padding: const EdgeInsets.symmetric(vertical: 12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (count > 0) ...[
              const SizedBox(width: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white : AppColors.primaryColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  count.toString(),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? AppColors.primaryColor : Colors.white,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStats() {
    final upcoming = _bookings.where((b) => b.isUpcoming).length;
    final completed = _bookings.where((b) => b.isCompleted).length;
    final cancelled = _bookings.where((b) => b.isCancelled).length;

    return Container(
      padding: const EdgeInsets.all(16),
      color: AppColors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem('Upcoming', upcoming.toString(), AppColors.primaryColor),
          _buildStatItem('Completed', completed.toString(), AppColors.successColor),
          _buildStatItem('Cancelled', cancelled.toString(), AppColors.errorColor),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
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

  Widget _buildBookingsList() {
    return RefreshIndicator(
      color: AppColors.primaryColor,
      onRefresh: _loadBookings,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _filteredBookings.length,
        itemBuilder: (context, index) {
          return _buildBookingCard(_filteredBookings[index]);
        },
      ),
    );
  }

  Widget _buildBookingCard(BookingModel booking) {
    final isUpcoming = booking.isUpcoming;
    final isCompleted = booking.isCompleted;
    final isCancelled = booking.isCancelled;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
        children: [
          // Booking info
          ListTile(
            contentPadding: const EdgeInsets.all(16),
            onTap: () => _openBookingDetail(booking),
            leading: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: AppColors.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(25),
              ),
              child: Center(
                child: Text(
                  Helpers.getInitials(booking.customerName ?? 'C'),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryColor,
                  ),
                ),
              ),
            ),
            title: Text(
              booking.customerName ?? 'Customer',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textColor,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.calendar_today, size: 12),
                    const SizedBox(width: 4),
                    Text(
                      Helpers.formatDate(booking.bookingDate),
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.location_on, size: 12),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        booking.eventAddress,
                        style: const TextStyle(fontSize: 12),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                if (booking.customerPhone != null && booking.customerPhone!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.phone, size: 12),
                      const SizedBox(width: 4),
                      Text(
                        booking.customerPhone!,
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ],
            ),
            trailing: _buildStatusBadge(booking),
          ),

          // Divider
          const Divider(height: 1),

          // Actions (only show for upcoming bookings)
          if (isUpcoming) _buildActionButtons(booking),

          // Show review info for completed bookings
          if (isCompleted && booking.hasReview)
            _buildReviewInfo(booking),
        ],
      ),
    );
  }

  Widget _buildReviewInfo(BookingModel booking) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.successColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.successColor.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Icon(
              Icons.star,
              color: AppColors.successColor,
              size: 16,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Customer has reviewed this booking',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.successColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(BookingModel booking) {
    Color color;
    String text;

    if (booking.isCancelled) {
      color = AppColors.errorColor;
      text = 'Cancelled';
    } else if (booking.isCompleted) {
      color = AppColors.successColor;
      text = 'Completed';
    } else if (booking.paymentStatus == 'paid') {
      color = AppColors.successColor;
      text = 'Paid';
    } else {
      color = AppColors.warningColor;
      text = 'Pending';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w500,
          color: color,
        ),
      ),
    );
  }

  Widget _buildActionButtons(BookingModel booking) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => _cancelBooking(booking),
              icon: const Icon(Icons.cancel_outlined, size: 16),
              label: const Text('Cancel'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.errorColor,
                side: const BorderSide(color: AppColors.errorColor),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => _markAsCompleted(booking),
              icon: const Icon(Icons.check_circle_outline, size: 16),
              label: const Text('Complete'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.successColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}