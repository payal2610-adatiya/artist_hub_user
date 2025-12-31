import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:artist_hub/core/constants/app_colors.dart';
import 'package:artist_hub/core/constants/app_strings.dart';
import 'package:artist_hub/models/artist_model.dart';
import 'package:artist_hub/providers/auth_provider.dart';
import 'package:artist_hub/providers/booking_provider.dart';
import 'package:artist_hub/core/widgets/custom_button.dart';
import 'package:artist_hub/core/widgets/custom_textfield.dart';

class BookingScreen extends StatefulWidget {
  final ArtistModel artist;

  const BookingScreen({Key? key, required this.artist}) : super(key: key);

  @override
  _BookingScreenState createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _eventAddressController = TextEditingController();
  DateTime? _selectedDate;
  String _selectedPaymentMethod = 'cash';
  String _paymentId = '';

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
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
    if (_formKey.currentState!.validate()) {
      if (_selectedDate == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select a booking date'),
            backgroundColor: AppColors.errorColor,
          ),
        );
        return;
      }

      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final bookingProvider = Provider.of<BookingProvider>(context, listen: false);

      if (authProvider.user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please login to book an artist'),
            backgroundColor: AppColors.errorColor,
          ),
        );
        return;
      }

      final success = await bookingProvider.addBooking(
        customerId: authProvider.user!.id!,
        artistId: widget.artist.id!,
        bookingDate: DateFormat('yyyy-MM-dd').format(_selectedDate!),
        eventAddress: _eventAddressController.text.trim(),
        paymentType: _selectedPaymentMethod,
        paymentId: _paymentId,
      );

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Booking successful!'),
            backgroundColor: AppColors.successColor,
          ),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(bookingProvider.errorMessage ?? 'Booking failed'),
            backgroundColor: AppColors.errorColor,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bookingProvider = Provider.of<BookingProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Book Artist'),
        backgroundColor: AppColors.white,
        elevation: 1,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Artist Info
              Card(
                color: AppColors.white,
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
                          borderRadius: BorderRadius.circular(30),
                          color: AppColors.primaryColor.withOpacity(0.1),
                          image: const DecorationImage(
                            image: NetworkImage('https://picsum.photos/200/200'),
                            fit: BoxFit.cover,
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
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textColor,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              widget.artist.category ?? 'Category',
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
              ),

              const SizedBox(height: 24),

              // Booking Date
              Text(
                'Booking Date',
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
                            ? DateFormat('MMMM dd, yyyy').format(_selectedDate!)
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

              const SizedBox(height: 20),

              // Event Address
              CustomTextField(
                controller: _eventAddressController,
                labelText: 'Event Address',
                hintText: 'Enter venue address',
                maxLines: 3,
                prefixIcon: const Icon(Icons.location_on_outlined),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter event address';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 20),

              // Payment Method
              Text(
                'Payment Method',
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

              if (_selectedPaymentMethod == 'online')
                Padding(
                  padding: const EdgeInsets.only(top: 20),
                  child: CustomTextField(
                    controller: TextEditingController(text: _paymentId),
                    labelText: 'Payment Transaction ID',
                    hintText: 'Enter payment transaction ID',
                    prefixIcon: const Icon(Icons.payment),
                    onChanged: (value) {
                      _paymentId = value;
                    },
                    validator: (value) {
                      if (_selectedPaymentMethod == 'online' &&
                          (value == null || value.isEmpty)) {
                        return 'Payment ID is required for online payment';
                      }
                      return null;
                    },
                  ),
                ),

              const SizedBox(height: 30),

              // Booking Summary
              Card(
                color: AppColors.white,
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
                      _buildSummaryItem(
                        'Service Fee',
                        '₹200',
                      ),
                      const Divider(height: 24),
                      _buildSummaryItem(
                        'Total Amount',
                        '₹${(int.tryParse(widget.artist.price ?? '0') ?? 0) + 200}',
                        isTotal: true,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 30),

              // Confirm Booking Button
              CustomButton(
                text: 'Confirm Booking',
                onPressed: _submitBooking,
                isLoading: bookingProvider.isLoading,
              ),
            ],
          ),
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
}