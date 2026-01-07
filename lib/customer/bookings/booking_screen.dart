import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:artist_hub/core/constants/app_colors.dart';
import 'package:artist_hub/core/services/api_service.dart';
import 'package:artist_hub/core/services/shared_pref.dart';
import 'package:artist_hub/core/widgets/custom_button.dart';
import 'package:artist_hub/core/widgets/custom_textfield.dart';
import 'package:artist_hub/models/artist_model.dart';
import 'package:artist_hub/utils/helpers.dart';

import '../../core/routes/app_routes.dart';

class BookingScreen extends StatefulWidget {
  final ArtistModel artist;

  const BookingScreen({super.key, required this.artist});

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _eventAddressController = TextEditingController();
  final _paymentIdController = TextEditingController();

  DateTime? _selectedDate;
  String _selectedPaymentMethod = 'cash';
  bool _isLoading = false;
  String? _errorMessage;

  // Calculate total amount
  int get _totalAmount {
    final artistPrice = int.tryParse(widget.artist.price?.toString() ?? '0') ?? 0;
    return artistPrice; // Remove service fee if not needed
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.primaryColor,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _submitBooking() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedDate == null) {
      Helpers.showSnackbar(context, 'Please select a booking date', isError: true);
      return;
    }

    // Check if date is in the past
    if (_selectedDate!.isBefore(DateTime.now())) {
      Helpers.showSnackbar(context, 'Please select a future date', isError: true);
      return;
    }

    final userId = await SharedPref.getUserId();
    if (userId.isEmpty) {
      Helpers.showSnackbar(context, 'Please login to book an artist', isError: true);
      return;
    }

    // Validate payment ID for online payment
    if (_selectedPaymentMethod == 'online' &&
        _paymentIdController.text.trim().isEmpty) {
      Helpers.showSnackbar(context, 'Payment ID is required for online payment', isError: true);
      return;
    }

    final hasInternet = await Helpers.checkInternetBeforeApiCall(context);
    if (!hasInternet) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      print('Submitting booking...');
      print('Customer ID: $userId');
      print('Artist ID: ${widget.artist.id}');
      print('Date: ${DateFormat('yyyy-MM-dd').format(_selectedDate!)}');
      print('Payment Method: $_selectedPaymentMethod');

      final result = await ApiService.addBooking(
        customerId: int.parse(userId),
        artistId: widget.artist.id!,
        bookingDate: DateFormat('yyyy-MM-dd').format(_selectedDate!),
        eventAddress: _eventAddressController.text.trim(),
        paymentType: _selectedPaymentMethod,
        paymentId: _selectedPaymentMethod == 'online'
            ? _paymentIdController.text.trim()
            : '',
      );

      print('Booking result: $result');

      if (result['success'] == true) {
        Helpers.showSnackbar(context, 'Booking successful!');

        // Navigate back to bookings list
        Navigator.pushNamedAndRemoveUntil(
          context,
          AppRoutes.customerDashboard,
              (route) => false,
        );
        Navigator.pushNamed(context, AppRoutes.customerBookings);
      } else {
        setState(() {
          _errorMessage = result['message'] ?? 'Booking failed';
        });
        Helpers.showSnackbar(context, _errorMessage!, isError: true);
      }
    } catch (e) {
      print('Booking error: $e');
      setState(() {
        _errorMessage = 'Error: ${e.toString()}';
      });
      Helpers.showSnackbar(context, _errorMessage!, isError: true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Book Artist'),
        backgroundColor: AppColors.primaryColor,
        foregroundColor: AppColors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Artist Info
              _buildArtistInfo(),

              const SizedBox(height: 24),

              // Booking Date
              _buildDatePicker(),

              const SizedBox(height: 20),

              // Event Address
// In BookingScreen, update the CustomTextField for event address:
              CustomTextField(
                controller: _eventAddressController,
                labelText: 'Event Address *',
                hintText: 'Enter venue address (e.g., Wedding Hall, Mumbai)',
                maxLines: 3,
                prefixIcon: const Icon(Icons.location_on_outlined),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter event address';
                  }
                  if (value.length < 5) { // Reduced from 10 to 5
                    return 'Address is too short. Please provide more details';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Payment Method
              _buildPaymentMethod(),

              // Payment ID (if online)
              _buildPaymentIdField(),

              const SizedBox(height: 30),

              // Booking Summary
              _buildBookingSummary(),

              const SizedBox(height: 30),

              // Error message
              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(
                      color: AppColors.errorColor,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),

              // Confirm Booking Button
              CustomButton(
                text: 'Confirm Booking',
                onPressed: _submitBooking,
                isLoading: _isLoading,
                backgroundColor: AppColors.primaryColor,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildArtistInfo() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
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
                  Helpers.getInitials(widget.artist.name ?? 'A'),
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
                    widget.artist.name ?? 'Artist',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  if (widget.artist.category != null && widget.artist.category!.isNotEmpty)
                    Text(
                      widget.artist.category!,
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.grey,
                      ),
                    ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.star, color: AppColors.secondaryColor, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        widget.artist.avgRating?.toStringAsFixed(1) ?? '0.0',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textColor,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '(${widget.artist.totalReviews ?? 0} reviews)',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.grey,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Text(
              '₹${widget.artist.price ?? '0'}',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDatePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Booking Date *',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.textColor,
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () => _selectDate(context),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.lightGrey),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  color: AppColors.primaryColor,
                ),
                const SizedBox(width: 12),
                Text(
                  _selectedDate != null
                      ? DateFormat('dd MMM yyyy').format(_selectedDate!)
                      : 'Select date',
                  style: TextStyle(
                    fontSize: 16,
                    color: _selectedDate != null
                        ? AppColors.textColor
                        : AppColors.grey,
                  ),
                ),
                const Spacer(),
                Icon(
                  Icons.arrow_drop_down,
                  color: AppColors.grey,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentMethod() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Payment Method *',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.textColor,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.lightGrey),
          ),
          child: Column(
            children: [
              RadioListTile(
                title: const Text('Cash on Delivery'),
                value: 'cash',
                groupValue: _selectedPaymentMethod,
                onChanged: (value) {
                  setState(() {
                    _selectedPaymentMethod = value.toString();
                  });
                },
                activeColor: AppColors.primaryColor,
              ),
              RadioListTile(
                title: const Text('Online Payment'),
                value: 'online',
                groupValue: _selectedPaymentMethod,
                onChanged: (value) {
                  setState(() {
                    _selectedPaymentMethod = value.toString();
                  });
                },
                activeColor: AppColors.primaryColor,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentIdField() {
    if (_selectedPaymentMethod != 'online') return const SizedBox();

    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: CustomTextField(
        controller: _paymentIdController,
        labelText: 'Payment Transaction ID *',
        hintText: 'Enter payment transaction ID',
        prefixIcon: const Icon(Icons.payment),
        validator: (value) {
          if (_selectedPaymentMethod == 'online' &&
              (value == null || value.isEmpty)) {
            return 'Payment ID is required for online payment';
          }
          return null;
        },
      ),
    );
  }

  Widget _buildBookingSummary() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Booking Summary',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textColor,
              ),
            ),
            const SizedBox(height: 16),
            _buildSummaryItem(
              'Artist Fee',
              '₹${widget.artist.price ?? '0'}',
            ),
            const Divider(height: 24),
            _buildSummaryItem(
              'Total Amount',
              '₹$_totalAmount',
              isTotal: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isTotal ? 18 : 16,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              color: AppColors.textColor,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: isTotal ? 20 : 16,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.w600,
              color: isTotal ? AppColors.primaryColor : AppColors.textColor,
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _eventAddressController.dispose();
    _paymentIdController.dispose();
    super.dispose();
  }
}