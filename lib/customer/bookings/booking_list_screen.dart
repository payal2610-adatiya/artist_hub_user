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

class BookingListScreen extends StatefulWidget {
  const BookingListScreen({super.key});

  @override
  State<BookingListScreen> createState() => _BookingListScreenState();
}

class _BookingListScreenState extends State<BookingListScreen> {
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

    final userId = SharedPref.getUserId();
    if (userId.isEmpty) {
      setState(() {
        _isLoading = false;
        _hasError = true;
      });
      return;
    }

    try {
      final result = await ApiService.getBookingsByCustomer(customerId: int.parse(userId));
      if (result['success'] == true && result['data'] != null) {
        final List<dynamic> data = result['data'];
        setState(() {
          _bookings = data.map((item) => BookingModel.fromJson(item)).toList();
          _applyFilters();
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
        final artistName = booking.artistName?.toLowerCase() ?? '';
        final eventAddress = booking.eventAddress.toLowerCase();
        final query = _searchQuery.toLowerCase();
        return artistName.contains(query) || eventAddress.contains(query);
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
      AppRoutes.customerBookingDetail,
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
      'Are you sure you want to cancel this booking? A cancellation fee may apply.',
    );

    if (!confirmed) return;

    final userId = SharedPref.getUserId();
    if (userId.isEmpty) return;

    try {
      final result = await ApiService.cancelBookingByCustomer(
        bookingId: booking.id,
        customerId: int.parse(userId),
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

  void _addReview(BookingModel booking) {
    if (booking.isCompleted && !booking.isCancelled) {
      Navigator.pushNamed(
        context,
        AppRoutes.addReview,
        arguments: {
          'bookingId': booking.id,
          'artistId': booking.artistId,
          'artistName': booking.artistName,
        },
      );
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('My Bookings'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: _showSearchDialog,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadBookings,
          ),
        ],
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

        // Bookings list
        Expanded(
          child: _filteredBookings.isEmpty
              ? NoDataWidget(
            message: 'No bookings found',
            buttonText: 'Book an Artist',
            onPressed: () {
              Navigator.pushNamed(context, AppRoutes.searchArtists);
            },
          )
              : _buildBookingsList(),
        ),
      ],
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
          _buildTabButton('past', 'Past'),
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
          foregroundColor: isSelected ? AppColors.white : AppColors.darkGrey,
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
                  color: isSelected ? AppColors.white : AppColors.primaryColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  count.toString(),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? AppColors.primaryColor : AppColors.white,
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
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _filteredBookings.length,
      itemBuilder: (context, index) {
        return _buildBookingCard(_filteredBookings[index]);
      },
    );
  }

  Widget _buildBookingCard(BookingModel booking) {
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
                  Helpers.getInitials(booking.artistName ?? 'A'),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryColor,
                  ),
                ),
              ),
            ),
            title: Text(
              booking.artistName ?? 'Artist',
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
              ],
            ),
            trailing: _buildStatusBadge(booking),
          ),

          // Divider
          const Divider(height: 1),

          // Actions
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                if (booking.isUpcoming)
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
                if (booking.isCompleted && !booking.isCancelled) ...[
                  if (booking.isUpcoming) const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _addReview(booking),
                      icon: const Icon(Icons.star_outline, size: 16),
                      label: const Text('Add Review'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.secondaryColor,
                        foregroundColor: AppColors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
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

  void _showSearchDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Search Bookings'),
        content: TextField(
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'Search by artist name or location...',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          onChanged: (value) {
            setState(() {
              _searchQuery = value;
              _applyFilters();
            });
          },
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                _searchQuery = '';
                _applyFilters();
              });
              Navigator.pop(context);
            },
            child: const Text('Clear'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}