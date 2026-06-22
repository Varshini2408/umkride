import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/booking_model.dart';
import 'payment_screen.dart';

class ConfirmBookingScreen extends StatelessWidget {
  final BookingModel booking;
  const ConfirmBookingScreen({super.key, required this.booking});

  @override
  Widget build(BuildContext context) {
    const Color themeColor = Color(0xFF6C5CE7);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('Confirm Booking', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.black), onPressed: () => Navigator.pop(context)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade200),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  _infoRow('From', booking.pickupLocation ?? '', Icons.circle, Colors.blue.shade200),
                  const Divider(height: 30),
                  _infoRow('To', booking.destinationLocation ?? '', Icons.circle, Colors.red.shade200),
                  const Divider(height: 30),
                  _infoRow('Distance', '${booking.distance?.toStringAsFixed(1) ?? "0"} km', Icons.straighten, Colors.orange.shade300),
                  const Divider(height: 30),
                  _infoRow('Date', DateFormat('dd MMM yyyy', 'en').format(booking.date ?? DateTime.now()), null, null),
                  const Divider(height: 30),
                  _infoRow('Time', booking.time ?? '', null, null),
                  const Divider(height: 30),
                  _infoRow('Vehicle', booking.vehicleType ?? '', Icons.directions_car, Colors.black87),
                  const Divider(height: 30),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total Payment', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16)),
                      Text('RM ${booking.price?.toStringAsFixed(2) ?? '0.00'}', 
                        style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 22, color: themeColor)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
              decoration: BoxDecoration(color: themeColor.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
              child: const Text(
                'Please confirm your ride details before proceeding to payment.',
                textAlign: TextAlign.center,
                style: TextStyle(color: themeColor, fontWeight: FontWeight.w500),
              ),
            ),
            const Spacer(),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => PaymentScreen(booking: booking)),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: themeColor,
                minimumSize: const Size(double.infinity, 54),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Confirm & Pay', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value, IconData? icon, Color? iconColor) {
    return Row(
      children: [
        SizedBox(width: 80, child: Text(label, style: const TextStyle(color: Colors.black54, fontWeight: FontWeight.w500))),
        const SizedBox(width: 10),
        if (icon != null) ...[
          Icon(icon, color: iconColor, size: 12),
          const SizedBox(width: 8),
        ],
        Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15), textAlign: TextAlign.right)),
      ],
    );
  }
}
