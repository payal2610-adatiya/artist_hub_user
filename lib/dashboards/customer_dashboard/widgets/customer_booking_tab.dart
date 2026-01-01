import 'package:flutter/material.dart';

import '../../../customer/bookings/booking_list_screen.dart';
import '../../../customer/profile/customer_profile_screen.dart';

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