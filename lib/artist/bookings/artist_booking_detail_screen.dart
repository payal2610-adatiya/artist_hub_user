import 'package:flutter/material.dart';
import 'package:artist_hub/core/constants/app_colors.dart';
import 'package:artist_hub/core/services/api_service.dart';
import 'package:artist_hub/core/services/shared_pref.dart';
import 'package:artist_hub/core/widgets/custom_button.dart';
import 'package:artist_hub/models/booking_model.dart';
import 'package:artist_hub/utils/helpers.dart';

class ArtistBookingDetailScreen extends StatefulWidget {
  final BookingModel booking;

  const ArtistBookingDetailScreen({super.key, required this.booking});

  @override
  State<ArtistBookingDetailScreen> createState() => _ArtistBookingDetailScreenState();
}

class _ArtistBookingDetailScreenState extends State<ArtistBookingDetailScreen> {
  bool _isLoading = false;

  Future<void> _cancelBooking() async {
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

    setState(() => _isLoading = true);

    final userId = SharedPref.getUserId();
    if (userId.isEmpty) {
      Helpers.showSnackbar(context, 'User not found', isError: true);
      setState(() => _isLoading = false);
      return;
    }

    try {
      final result = await ApiService.cancelBookingByArtist(
        bookingId: widget.booking.id,
        artistId: int.parse(userId),
        cancelReason: reason,
      );

      if (result['success'] == true) {
        Helpers.showSnackbar(context, 'Booking cancelled successfully');
        if (!mounted) return;
        Navigator.pop(context);
      } else {
        Helpers.showSnackbar(
          context,
          result['message'] ?? 'Failed to cancel booking',
          isError: true,
        );
      }
    } catch (e) {
      Helpers.showSnackbar(context, 'Error: $e', isError: true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _markAsCompleted() async {
    final confirmed = await Helpers.showConfirmationDialog(
      context,
      'Mark as Completed',
      'Mark this booking as completed?',
    );

    if (!confirmed) return;

    // Note: You'll need to add an update booking status API endpoint
    Helpers.showSnackbar(context, 'Update functionality coming soon');
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

  void _contactCustomer() {
    // Implement contact functionality
    Helpers.showSnackbar(context, 'Contact functionality coming soon');
  }

  void _viewOnMap() {
    // Implement map functionality
    Helpers.showSnackbar(context, 'Map functionality coming soon');
  }

  Color _getStatusColor() {
    if (widget.booking.isCancelled) return AppColors.errorColor;
    if (widget.booking.isCompleted) return AppColors.successColor;
    if (widget.booking.paymentStatus == 'paid') return AppColors.successColor;
    return AppColors.warningColor;
  }

  String _getStatusText() {
    if (widget.booking.isCancelled) return 'Cancelled';
    if (widget.booking.isCompleted) return 'Completed';
    if (widget.booking.paymentStatus == 'paid') return 'Paid & Confirmed';
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

            // Customer info
            _buildCustomerInfo(),

            const SizedBox(height: 24),

            // Event details
            _buildEventDetails(),

            const SizedBox(height: 24),

            // Payment info
            _buildPaymentInfo(),

            const SizedBox(height: 24),

            // Actions
            if (widget.booking.isUpcoming) _buildActionButtons(),
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
                  widget.booking.isCancelled
                      ? Icons.cancel
                      : widget.booking.isCompleted
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
                      'Booking #${widget.booking.id}',
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
          if (widget.booking.isCancelled && widget.booking.cancelReason != null)
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
                      'Cancellation Reason: ${widget.booking.cancelReason}',
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

  Widget _buildCustomerInfo() {
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
            'Customer Information',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textColor,
            ),
          ),
          const SizedBox(height: 16),
          _buildInfoRow(
            icon: Icons.person,
            label: 'Name',
            value: widget.booking.customerName ?? 'Not provided',
          ),
          const SizedBox(height: 12),
          _buildInfoRow(
            icon: Icons.email,
            label: 'Email',
            value: widget.booking.customerEmail ?? 'Not provided',
          ),
          const SizedBox(height: 12),
          _buildInfoRow(
            icon: Icons.phone,
            label: 'Phone',
            value: widget.booking.customerPhone ?? 'Not provided',
          ),
          const SizedBox(height: 16),
          CustomButton(
            text: 'Contact Customer',
            onPressed: _contactCustomer,
            backgroundColor: AppColors.primaryColor,
          ),
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
            value: Helpers.formatDate(widget.booking.bookingDate, format: 'dd MMM yyyy, EEEE'),
          ),
          const SizedBox(height: 12),
          _buildInfoRow(
            icon: Icons.access_time,
            label: 'Time',
            value: Helpers.formatDate(widget.booking.bookingDate, format: 'hh:mm a'),
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
                      widget.booking.eventAddress,
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
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: _viewOnMap,
            icon: const Icon(Icons.map_outlined),
            label: const Text('View on Map'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primaryColor,
              side: const BorderSide(color: AppColors.primaryColor),
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
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
            value: widget.booking.paymentStatus == 'paid' ? 'Paid' : 'Pending',
            valueColor: widget.booking.paymentStatus == 'paid'
                ? AppColors.successColor
                : AppColors.warningColor,
          ),
          const SizedBox(height: 12),
          if (widget.booking.paymentId != null)
            _buildInfoRow(
              icon: Icons.receipt,
              label: 'Transaction ID',
              value: widget.booking.paymentId!,
            ),
          const SizedBox(height: 12),
          _buildInfoRow(
            icon: Icons.date_range,
            label: 'Booked On',
            value: Helpers.formatDate(widget.booking.createdAt),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
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
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: valueColor ?? AppColors.textColor,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: CustomButton(
                text: 'Mark as Completed',
                onPressed: _markAsCompleted,
                backgroundColor: AppColors.successColor,
                isLoading: _isLoading,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: CustomButton(
                text: 'Cancel Booking',
                onPressed: _cancelBooking,
                backgroundColor: AppColors.errorColor,
                isLoading: _isLoading,
              ),
            ),
          ],
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