import 'package:flutter/material.dart';
import 'package:artist_hub/core/services/api_service.dart';
import 'package:artist_hub/models/booking_model.dart';

class BookingProvider with ChangeNotifier {
  List<BookingModel> _bookings = [];
  BookingModel? _selectedBooking;
  bool _isLoading = false;
  String? _errorMessage;

  List<BookingModel> get bookings => _bookings;
  BookingModel? get selectedBooking => _selectedBooking;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> fetchBookingsByCustomer(int customerId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await ApiService.getBookings(customerId: customerId);

      _isLoading = false;

      if (response['status'] == true) {
        final List<dynamic> data = response['data'] ?? [];
        _bookings = data.map((bookingJson) => BookingModel.fromJson(bookingJson)).toList();
        notifyListeners();
      } else {
        _errorMessage = response['message'];
        notifyListeners();
      }
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Failed to fetch bookings: $e';
      notifyListeners();
    }
  }

  Future<void> fetchBookingsByArtist(int artistId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await ApiService.getBookings(artistId: artistId);

      _isLoading = false;

      if (response['status'] == true) {
        final List<dynamic> data = response['data'] ?? [];
        _bookings = data.map((bookingJson) => BookingModel.fromJson(bookingJson)).toList();
        notifyListeners();
      } else {
        _errorMessage = response['message'];
        notifyListeners();
      }
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Failed to fetch bookings: $e';
      notifyListeners();
    }
  }

  Future<bool> addBooking({
    required int customerId,
    required int artistId,
    required String bookingDate,
    required String eventAddress,
    required String paymentType,
    String paymentId = '',
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await ApiService.addBooking(
        customerId: customerId,
        artistId: artistId,
        bookingDate: bookingDate,
        eventAddress: eventAddress,
        paymentType: paymentType,
        paymentId: paymentId,
      );

      _isLoading = false;

      if (response['status'] == true) {
        final bookingData = response['data'];
        if (bookingData != null) {
          final newBooking = BookingModel.fromJson(bookingData);
          _bookings.insert(0, newBooking);
          notifyListeners();
        }
        return true;
      } else {
        _errorMessage = response['message'];
        notifyListeners();
        return false;
      }
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Failed to add booking: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> cancelBookingByCustomer({
    required int bookingId,
    required int customerId,
    required String cancelReason,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await ApiService.cancelBookingByCustomer(
        bookingId: bookingId,
        customerId: customerId,
        cancelReason: cancelReason,
      );

      _isLoading = false;

      if (response['status'] == true) {
        // Update the booking in the list
        final index = _bookings.indexWhere((b) => b.id == bookingId);
        if (index != -1) {
          _bookings[index] = BookingModel.fromJson(response['data']);
          notifyListeners();
        }
        return true;
      } else {
        _errorMessage = response['message'];
        notifyListeners();
        return false;
      }
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Failed to cancel booking: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> cancelBookingByArtist({
    required int bookingId,
    required int artistId,
    required String cancelReason,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await ApiService.cancelBookingByArtist(
        bookingId: bookingId,
        artistId: artistId,
        cancelReason: cancelReason,
      );

      _isLoading = false;

      if (response['status'] == true) {
        // Update the booking in the list
        final index = _bookings.indexWhere((b) => b.id == bookingId);
        if (index != -1) {
          _bookings[index] = BookingModel.fromJson(response['data']);
          notifyListeners();
        }
        return true;
      } else {
        _errorMessage = response['message'];
        notifyListeners();
        return false;
      }
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Failed to cancel booking: $e';
      notifyListeners();
      return false;
    }
  }

  void setSelectedBooking(BookingModel booking) {
    _selectedBooking = booking;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}