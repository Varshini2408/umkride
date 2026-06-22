class LatLngFake {
  final double latitude;
  final double longitude;
  const LatLngFake(this.latitude, this.longitude);
}

class BookingModel {
  String? pickupLocation;
  LatLngFake? pickupLatLng;
  String? destinationLocation;
  LatLngFake? destinationLatLng;
  DateTime? date;
  String? time;
  String? vehicleType;
  double? price;
  double? distance; // Jarak dalam KM
  String? genderPreference;

  BookingModel({
    this.pickupLocation,
    this.pickupLatLng,
    this.destinationLocation,
    this.destinationLatLng,
    this.date,
    this.time,
    this.vehicleType,
    this.price,
    this.distance,
    this.genderPreference,
  });
}
