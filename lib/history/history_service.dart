import '../models/booking_model.dart';

class HistoryService {
  // Simulasi database dalam memori
  static final List<BookingModel> _history = [];

  static void addBooking(BookingModel booking) {
    // Simpan salinan booking ke dalam senarai history
    _history.insert(0, BookingModel(
      pickupLocation: booking.pickupLocation,
      pickupLatLng: booking.pickupLatLng,
      destinationLocation: booking.destinationLocation,
      destinationLatLng: booking.destinationLatLng,
      date: booking.date,
      time: booking.time,
      vehicleType: booking.vehicleType,
      price: booking.price,
      distance: booking.distance,
    ));
  }

  static List<BookingModel> getHistory() {
    return _history;
  }
}
