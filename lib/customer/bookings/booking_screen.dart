import 'package:flutter/material.dart';
import 'package:artist_hub/core/constants/app_colors.dart';
import 'package:artist_hub/core/services/api_service.dart';
import 'package:artist_hub/core/services/shared_pref.dart';
import 'package:artist_hub/core/widgets/custom_button.dart';
import 'package:artist_hub/core/widgets/custom_textfield.dart';
import 'package:artist_hub/utils/helpers.dart';

class BookingScreen extends StatefulWidget {
  final int artistId;
  final String artistName;

  const BookingScreen({
    super.key,
    required this.artistId,
    required this.artistName,
  });

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _eventAddressController = TextEditingController();
  final _specialRequestController = TextEditingController();
  final _paymentIdController = TextEditingController();

  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  String _selectedPaymentType = 'cash';
  bool _isLoading = false;
  bool _isSubmitting = false;

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            primaryColor: AppColors.primaryColor,
            colorScheme: const ColorScheme.light(primary: AppColors.primaryColor),
            buttonTheme: const ButtonThemeData(textTheme: ButtonTextTheme.primary),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedDate) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            primaryColor: AppColors.primaryColor,
            colorScheme: const ColorScheme.light(primary: AppColors.primaryColor),
            buttonTheme: const ButtonThemeData(textTheme: ButtonTextTheme.primary),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedTime) {
      setState(() => _selectedTime = picked);
    }
  }

  Future<void> _submitBooking() async {
    if (!_formKey.currentState!.validate()) return;

    final hasInternet = await Helpers.checkInternetBeforeApiCall(context);
    if (!hasInternet) return;

    setState(() => _isSubmitting = true);

    final customerId = SharedPref.getUserId();
    if (customerId.isEmpty) {
      Helpers.showSnackbar(context, 'User not found', isError: true);
      setState(() => _isSubmitting = false);
      return;
    }

    // Combine date and time
    final bookingDateTime = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );

    // Format date as YYYY-MM-DD for API
    final formattedDate = '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}';

    try {
      final result = await ApiService.addBooking(
        customerId: int.parse(customerId),
        artistId: widget.artistId,
        bookingDate: formattedDate,
        eventAddress: _eventAddressController.text.trim(),
        paymentType: _selectedPaymentType,
        paymentId: _selectedPaymentType == 'online' ? _paymentIdController.text.trim() : '',
      );

      if (result['success'] == true) {
        Helpers.showSnackbar(context, 'Booking confirmed successfully!');

        if (!mounted) return;
        Navigator.pop(context);

        // Navigate to booking details or bookings list
        // Navigator.pushNamed(context, AppRoutes.customerBookingDetail,
        //   arguments: {'booking': result['data']});
      } else {
        Helpers.showSnackbar(
          context,
          result['message'] ?? 'Failed to create booking',
          isError: true,
        );
      }
    } catch (e) {
      Helpers.showSnackbar(context, 'Error: $e', isError: true);
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Book Artist'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Artist info
              _buildArtistInfo(),

              const SizedBox(height: 24),

              // Booking details header
              const Text(
                'Booking Details',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textColor,
                ),
              ),
              const SizedBox(height: 16),

              // Date and time selection
              _buildDateTimeSelection(),

              const SizedBox(height: 20),

              // Event address
              CustomTextField(
                controller: _eventAddressController,
                labelText: 'Event Address',
                hintText: 'Enter the event location',
                maxLines: 2,
                prefixIcon: const Icon(Icons.location_on_outlined, color: AppColors.darkGrey),
                validator: (value) => Helpers.validateRequired(value, 'Event address'),
              ),

              const SizedBox(height: 20),

              // Special requests
              CustomTextField(
                controller: _specialRequestController,
                labelText: 'Special Requests (Optional)',
                hintText: 'Any special requirements or notes...',
                maxLines: 3,
                prefixIcon: const Icon(Icons.note_outlined, color: AppColors.darkGrey),
              ),

              const SizedBox(height: 24),

              // Payment section
              _buildPaymentSection(),

              const SizedBox(height: 32),

              // Submit button
              CustomButton(
                text: _isSubmitting ? 'Processing...' : 'Confirm Booking',
                onPressed:  _submitBooking,
                isLoading: _isSubmitting,
                backgroundColor: AppColors.primaryColor,
              ),

              const SizedBox(height: 16),

              // Terms and conditions
              _buildTermsAndConditions(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildArtistInfo() {
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
      child: Row(
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
                Helpers.getInitials(widget.artistName),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
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
                  widget.artistName,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textColor,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'You are booking this artist for your event',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.darkGrey,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateTimeSelection() {
    final formattedDate = '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}';
    final formattedTime = '${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Date & Time',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.textColor,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: InkWell(
                onTap: () => _selectDate(context),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.lightGrey),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.calendar_today, color: AppColors.primaryColor),
                      const SizedBox(width: 12),
                      Text(
                        formattedDate,
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.textColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: InkWell(
                onTap: () => _selectTime(context),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.lightGrey),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.access_time, color: AppColors.primaryColor),
                      const SizedBox(width: 12),
                      Text(
                        formattedTime,
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.textColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        const Text(
          'Note: Please ensure the artist is available on the selected date',
          style: TextStyle(
            fontSize: 11,
            color: AppColors.darkGrey,
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Payment Method',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.textColor,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildPaymentOption(
                type: 'cash',
                label: 'Pay Cash',
                icon: Icons.money,
                color: AppColors.successColor,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildPaymentOption(
                type: 'online',
                label: 'Pay Online',
                icon: Icons.payment,
                color: AppColors.primaryColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        if (_selectedPaymentType == 'online') ...[
          CustomTextField(
            controller: _paymentIdController,
            labelText: 'Transaction ID',
            hintText: 'Enter your payment transaction ID',
            prefixIcon: const Icon(Icons.receipt_outlined, color: AppColors.darkGrey),
            validator: (value) {
              if (_selectedPaymentType == 'online' && (value == null || value.isEmpty)) {
                return 'Transaction ID is required for online payment';
              }
              return null;
            },
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.primaryColor.withOpacity(0.2)),
            ),
            child: const Text(
              'Note: Please complete the payment first and then enter the transaction ID here',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.primaryColor,
              ),
            ),
          ),
        ] else ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.successColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.successColor.withOpacity(0.2)),
            ),
            child: const Text(
              'You will pay cash to the artist at the time of the event',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.successColor,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildPaymentOption({
    required String type,
    required String label,
    required IconData icon,
    required Color color,
  }) {
    final isSelected = _selectedPaymentType == type;

    return InkWell(
      onTap: () {
        setState(() => _selectedPaymentType = type);
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.2) : AppColors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : AppColors.lightGrey,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: isSelected ? color : AppColors.darkGrey),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: isSelected ? color : AppColors.textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTermsAndConditions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Checkbox(
              value: true,
              onChanged: null,
              activeColor: AppColors.primaryColor,
            ),
            const Expanded(
              child: Text(
                'I agree to the terms and conditions',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.darkGrey,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.lightGrey),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Important Notes:',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textColor,
                ),
              ),
              SizedBox(height: 4),
              Text(
                '• Booking can be cancelled up to 24 hours before the event\n'
                    '• 50% refund for cancellations within 24 hours\n'
                    '• Artist may request advance payment\n'
                    '• Please arrive at the venue on time',
                style: TextStyle(
                  fontSize: 11,
                  color: AppColors.darkGrey,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}