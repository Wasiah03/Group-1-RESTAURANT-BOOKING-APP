import 'package:flutter/foundation.dart';
import '../database_helper.dart';
import '../models/booking.dart';

class BookingProvider extends ChangeNotifier {
  List<Booking> _bookings = [];
  bool _isLoading = false;

  List<Booking> get bookings => _bookings;
  bool get isLoading => _isLoading;

  Future<void> fetchBookings({int? userId}) async {
    try {
      _isLoading = true;
      notifyListeners();

      _bookings = await DatabaseHelper.instance.getBookings(userId: userId);

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      print('Error fetching bookings: $e');
      _bookings = [];
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Booking?> getBookingById(int id) async {
    try {
      return await DatabaseHelper.instance.getBooking(id);
    } catch (e) {
      print('Error getting booking by id: $e');
      return null;
    }
  }

  Future<bool> addBooking(Booking booking) async {
    try {
      final id = await DatabaseHelper.instance.insertBooking(booking);
      if (id > 0) {
        await fetchBookings(userId: booking.userId);
        return true;
      }
      return false;
    } catch (e) {
      print('Error adding booking: $e');
      return false;
    }
  }

  Future<bool> updateBooking(Booking booking) async {
    try {
      final result = await DatabaseHelper.instance.updateBooking(booking);
      if (result > 0) {
        // Refresh bookings list
        await fetchBookings();
        return true;
      }
      return false;
    } catch (e) {
      print('Error updating booking: $e');
      return false;
    }
  }

  Future<bool> deleteBooking(int id) async {
    try {
      final result = await DatabaseHelper.instance.deleteBooking(id);
      if (result > 0) {
        await fetchBookings();
        return true;
      }
      return false;
    } catch (e) {
      print('Error deleting booking: $e');
      return false;
    }
  }
}
