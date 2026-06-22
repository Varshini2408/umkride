import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/booking_model.dart';
import 'confirm_booking_screen.dart';

class SelectVehicleScreen extends StatefulWidget {
  final BookingModel booking;
  const SelectVehicleScreen({super.key, required this.booking});

  @override
  State<SelectVehicleScreen> createState() => _SelectVehicleScreenState();
}

class _SelectVehicleScreenState extends State<SelectVehicleScreen> {
  DateTime selectedDate = DateTime.now();
  TimeOfDay selectedTime = const TimeOfDay(hour: 10, minute: 30);
  String? selectedVehicle;
  final Color themeColor = const Color(0xFF6C5CE7);

  final List<Map<String, dynamic>> vehicles = [
    {'name': 'Car (4 seats)', 'desc': 'STOP 1', 'basePrice': 2.00, 'icon': Icons.directions_car},
    {'name': 'Van (7 seats)', 'desc': 'STOP 3', 'basePrice': 3.00, 'icon': Icons.airport_shuttle},
    {'name': 'MPV (6 seats)', 'desc': 'STOP 2', 'basePrice': 3.50, 'icon': Icons.directions_car_filled},
  ];

  double _calculateTotalPrice(double basePrice) {
    double distance = widget.booking.distance ?? 0;
    return basePrice + (distance * 0.50); // 50 cents per KM
  }

  @override
  void initState() {
    super.initState();
    widget.booking.date = selectedDate;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('Book Ride', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.black), onPressed: () => Navigator.pop(context)),
        actions: [IconButton(icon: const Icon(Icons.notifications_none, color: Colors.black), onPressed: () {})],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Select Date & Time', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 12),
            _buildPickerField(
              text: DateFormat('dd MMM yyyy', 'en').format(selectedDate),
              icon: Icons.calendar_month_outlined,
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: selectedDate,
                  firstDate: DateTime.now(),
                  lastDate: DateTime(2027),
                  builder: (context, child) {
                    return Theme(
                      data: Theme.of(context).copyWith(
                        colorScheme: ColorScheme.light(primary: themeColor),
                      ),
                      child: child!,
                    );
                  },
                );
                if (picked != null) setState(() => selectedDate = picked);
              },
            ),
            const SizedBox(height: 12),
            _buildPickerField(
              text: selectedTime.format(context),
              icon: Icons.access_time,
              onTap: () async {
                final picked = await showTimePicker(
                  context: context,
                  initialTime: selectedTime,
                  builder: (context, child) {
                    return Theme(
                      data: Theme.of(context).copyWith(
                        colorScheme: ColorScheme.light(primary: themeColor),
                      ),
                      child: child!,
                    );
                  },
                );
                if (picked != null) setState(() => selectedTime = picked);
              },
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Select Vehicle Type', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                Text('Distance: ${widget.booking.distance?.toStringAsFixed(1) ?? "0"} km', 
                  style: TextStyle(color: themeColor, fontWeight: FontWeight.bold)),
              ],
            ),
            const Text('Rate: RM 0.50 / km + Vehicle Charge', style: TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.builder(
                itemCount: vehicles.length,
                itemBuilder: (context, index) {
                  final v = vehicles[index];
                  bool isSelected = selectedVehicle == v['name'];
                  double totalPrice = _calculateTotalPrice(v['basePrice']);
                  
                  return GestureDetector(
                    onTap: () => setState(() {
                      selectedVehicle = v['name'];
                      widget.booking.vehicleType = v['name'];
                      widget.booking.price = totalPrice;
                    }),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isSelected ? themeColor.withOpacity(0.05) : Colors.white,
                        border: Border.all(color: isSelected ? themeColor : Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(v['icon'], color: Colors.black, size: 32),
                          const SizedBox(width: 15),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(v['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                                Text('Base: RM ${v['basePrice'].toStringAsFixed(2)}', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text('RM ${totalPrice.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                              const Text('Total', style: TextStyle(fontSize: 10, color: Colors.grey)),
                            ],
                          ),
                          Radio<String>(
                            value: v['name'],
                            groupValue: selectedVehicle,
                            activeColor: themeColor,
                            onChanged: (val) => setState(() {
                              selectedVehicle = val;
                              widget.booking.vehicleType = v['name'];
                              widget.booking.price = totalPrice;
                            }),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: ElevatedButton(
                onPressed: selectedVehicle == null ? null : () {
                  widget.booking.date = selectedDate;
                  widget.booking.time = selectedTime.format(context);
                  Navigator.push(context, MaterialPageRoute(builder: (_) => ConfirmBookingScreen(booking: widget.booking)));
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: themeColor,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 54),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Next', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPickerField({required String text, required IconData icon, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(10)),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [Text(text, style: const TextStyle(fontSize: 15)), Icon(icon, color: Colors.black54, size: 20)],
        ),
      ),
    );
  }
}
