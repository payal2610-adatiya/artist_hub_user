import 'package:flutter/material.dart';
import 'package:artist_hub/core/constants/app_colors.dart';
import 'package:artist_hub/core/routes/app_routes.dart';
import 'package:artist_hub/core/services/api_service.dart';
import 'package:artist_hub/core/services/shared_pref.dart';
import 'package:artist_hub/core/widgets/custom_button.dart';
import 'package:artist_hub/models/booking_model.dart';
import 'package:artist_hub/utils/helpers.dart';

class CustomerBookingDetailScreen extends StatefulWidget {
  final BookingModel booking;

  const CustomerBookingDetailScreen({super.key, required this.booking});

  @override
  State<CustomerBookingDetailScreen> createState() => _CustomerBookingDetailScreenState();
}

class _CustomerBookingDetailScreenState extends State<CustomerBookingDetailScreen> {
  bool _isLoading = false;
  BookingModel? _booking;

  @override
  void initState() {
    super.initState();
    _booking = widget.booking;
  }

  Future<void> _cancelBooking() async {
    final reason = await _showCancelDialog();
    if (reason == null || reason.isEmpty) return;

    final hasInternet = await Helpers.checkInternetBeforeApiCall(context);
    if (!hasInternet) return;

    final confirmed = await Helpers.showConfirmationDialog(
      context,
      'Cancel Booking',
      'Are you sure you want to cancel this booking?',
    );

    if (!confirmed) return;

    setState(() => _isLoading = true);

    final userId = await SharedPref.getUserId();
    if (userId.isEmpty) {
      Helpers.showSnackbar(context, 'User not found', isError: true);
      setState(() => _isLoading = false);
      return;
    }

    try {
      print('Cancelling booking: ${_booking!.id}');

      final result = await ApiService.cancelBookingByCustomer(
        bookingId: _booking!.id,
        customerId: int.parse(userId),
        cancelReason: reason,
      );

      print('Cancel result: $result');

      if (result['success'] == true) {
        Helpers.showSnackbar(context, 'Booking cancelled successfully');

        // Update booking status
        if (mounted) {
          setState(() {
            _booking = BookingModel(
              id: _booking!.id,
              customerId: _booking!.customerId,
              artistId: _booking!.artistId,
              bookingDate: _booking!.bookingDate,
              eventAddress: _booking!.eventAddress,
              status: 'cancelled',
              paymentStatus: _booking!.paymentStatus,
              paymentId: _booking!.paymentId,
              cancelReason: reason,
              cancelledBy: 'customer',
              createdAt: _booking!.createdAt,
              customerName: _booking!.customerName,
              customerEmail: _booking!.customerEmail,
              customerPhone: _booking!.customerPhone,
              artistName: _booking!.artistName,
              artistEmail: _booking!.artistEmail,
             // artistPhone: _booking!.artistPhone,
            );
          });
        }
      } else {
        Helpers.showSnackbar(
          context,
          result['message'] ?? 'Failed to cancel booking',
          isError: true,
        );
      }
    } catch (e) {
      print('Cancel error: $e');
      Helpers.showSnackbar(context, 'Error: $e', isError: true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _addReview() {
    Navigator.pushNamed(
      context,
      AppRoutes.addReview,
      arguments: {
        'bookingId': _booking!.id,
        'artistId': _booking!.artistId,
        'artistName': _booking!.artistName,
      },
    );
  }
  //
  // void _contactArtist() {
  //   final phone = _booking!.artistPhone;
  //   if (phone != null && phone.isNotEmpty) {
  //     // You can implement phone call functionality here
  //     Helpers.showSnackbar(context, 'Calling artist: $phone');
  //   } else {
  //     Helpers.showSnackbar(context, 'Artist phone number not available');
  //   }
  // }

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

  Color _getStatusColor() {
    if (_booking!.isCancelled) return AppColors.errorColor;
    if (_booking!.isCompleted) return AppColors.successColor;
    if (_booking!.paymentStatus == 'paid') return AppColors.successColor;
    return AppColors.warningColor;
  }

  String _getStatusText() {
    if (_booking!.isCancelled) return 'Cancelled';
    if (_booking!.isCompleted) return 'Completed';
    if (_booking!.paymentStatus == 'paid') return 'Paid & Confirmed';
    return 'Pending Payment';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Booking Details'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status card
            _buildStatusCard(),

            const SizedBox(height: 24),

            // Artist info
            _buildArtistInfo(),

            const SizedBox(height: 24),

            // Event details
            _buildEventDetails(),

            const SizedBox(height: 24),

            // Payment info
            _buildPaymentInfo(),

            const SizedBox(height: 24),

            // Actions
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard() {
    final statusColor = _getStatusColor();

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
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Icon(
                  _booking!.isCancelled
                      ? Icons.cancel
                      : _booking!.isCompleted
                      ? Icons.check_circle
                      : Icons.event_available,
                  size: 32,
                  color: statusColor,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Booking #${_booking!.id}',
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.darkGrey,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _getStatusText(),
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: statusColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_booking!.isCancelled && _booking!.cancelReason != null)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.errorColor.withOpacity(0.05),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.errorColor.withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: AppColors.errorColor),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Cancellation Reason: ${_booking!.cancelReason}',
                      style: TextStyle(
                        color: AppColors.errorColor,
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

  Widget _buildArtistInfo() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
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
            'Artist Information',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textColor,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: AppColors.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Center(
                  child: Text(
                    Helpers.getInitials(_booking!.artistName ?? 'A'),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryColor,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _booking!.artistName ?? 'Artist',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    // if (_booking!.artistPhone != null && _booking!.artistPhone!.isNotEmpty)
                    //   Text(
                    //     _booking!.artistPhone!,
                    //     style: const TextStyle(
                    //       fontSize: 14,
                    //       color: AppColors.darkGrey,
                    //     ),
                    //   ),
                    if (_booking!.artistEmail != null && _booking!.artistEmail!.isNotEmpty)
                      Text(
                        _booking!.artistEmail!,
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.darkGrey,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // if (_booking!.artistPhone != null && _booking!.artistPhone!.isNotEmpty)
          //   CustomButton(
          //     text: 'Contact Artist',
          //     onPressed: _contactArtist,
          //     backgroundColor: AppColors.primaryColor,
          //   ),
        ],
      ),
    );
  }

  Widget _buildEventDetails() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
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
            'Event Details',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textColor,
            ),
          ),
          const SizedBox(height: 16),
          _buildInfoRow(
            icon: Icons.calendar_today,
            label: 'Date',
            value: Helpers.formatDate(_booking!.bookingDate, format: 'dd MMM yyyy, EEEE'),
          ),
          const SizedBox(height: 12),
          _buildInfoRow(
            icon: Icons.access_time,
            label: 'Time',
            value: Helpers.formatDate(_booking!.bookingDate, format: 'hh:mm a'),
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.location_on, size: 20, color: AppColors.primaryColor),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Location',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.darkGrey,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _booking!.eventAddress,
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
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow({
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

  Widget _buildPaymentInfo() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
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
            'Payment Information',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textColor,
            ),
          ),
          const SizedBox(height: 16),
          _buildInfoRow(
            icon: Icons.payment,
            label: 'Status',
            value: _booking!.paymentStatus == 'paid' ? 'Paid' : 'Pending',
          ),
          const SizedBox(height: 12),
          if (_booking!.paymentId != null && _booking!.paymentId!.isNotEmpty)
            _buildInfoRow(
              icon: Icons.receipt,
              label: 'Transaction ID',
              value: _booking!.paymentId!,
            ),
          const SizedBox(height: 12),
          _buildInfoRow(
            icon: Icons.date_range,
            label: 'Booked On',
            value: Helpers.formatDate(_booking!.createdAt),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        if (_booking!.isUpcoming)
          CustomButton(
            text: 'Cancel Booking',
            onPressed: _cancelBooking,
            backgroundColor: AppColors.errorColor,
            isLoading: _isLoading,
          ),

        if (_booking!.isCompleted && !_booking!.isCancelled)
          CustomButton(
            text: 'Add Review',
            onPressed: _addReview,
            backgroundColor: AppColors.secondaryColor,
          ),

        const SizedBox(height: 12),

        OutlinedButton(
          onPressed: () {
            Navigator.pop(context);
          },
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.darkGrey,
            side: const BorderSide(color: AppColors.lightGrey),
            minimumSize: const Size(double.infinity, 50),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text('Go Back'),
        ),
      ],
    );
  }
}