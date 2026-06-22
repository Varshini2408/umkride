import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'notification_helper.dart';
import 'active_ride_screen.dart';

class WaitingScreen extends StatefulWidget {
  final String rideId;
  final String pickup;
  final String dropoff;
  final double fare;
  final String payment;
  const WaitingScreen({
    super.key,
    required this.rideId,
    required this.pickup,
    required this.dropoff,
    required this.fare,
    required this.payment,
  });
  @override
  State<WaitingScreen> createState() => _WaitingScreenState();
}

class _WaitingScreenState extends State<WaitingScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulse;
  bool _navigating = false;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
        vsync: this, duration: const Duration(seconds: 1))
      ..repeat(reverse: true);
    _sendBookingNotification();
  }

  Future<void> _sendBookingNotification() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    await NotificationHelper.send(
      toUid: uid,
      title: '🚗 Booking Confirmed!',
      message:
          'Your ride from ${widget.pickup} to ${widget.dropoff} has been submitted. Waiting for a driver...',
    );
  }

  Future<void> _cancelRide() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Cancel Ride'),
        content: const Text('Are you sure you want to cancel?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('No')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Yes, Cancel',
                  style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirm == true && mounted) {
      await FirebaseFirestore.instance
          .collection('rides')
          .doc(widget.rideId)
          .update({'status': 'CANCELLED'});
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) {
        await NotificationHelper.send(
          toUid: uid,
          title: '❌ Ride Cancelled',
          message: 'Your ride from ${widget.pickup} has been cancelled.',
        );
      }
      if (mounted) Navigator.pop(context);
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F5FF),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('rides')
            .doc(widget.rideId)
            .snapshots(),
        builder: (context, snap) {
          if (snap.hasData && snap.data!.exists && !_navigating) {
            final data = snap.data!.data() as Map<String, dynamic>;
            final status = data['status'] ?? 'PENDING';
            if (status == 'ACCEPTED') {
              _navigating = true;
              WidgetsBinding.instance.addPostFrameCallback((_) async {
                // Send notification to student
                final uid = FirebaseAuth.instance.currentUser?.uid;
                if (uid != null) {
                  await NotificationHelper.send(
                    toUid: uid,
                    title: '✅ Driver Found!',
                    message:
                        'A driver has accepted your ride! They are on the way.',
                  );
                }
                if (mounted) {
                  Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                          builder: (_) => ActiveRideScreen(
                                rideId: widget.rideId,
                                driverUid: data['driverUid'] ?? '',
                                pickup: widget.pickup,
                                dropoff: widget.dropoff,
                                fare: widget.fare,
                                payment: widget.payment,
                              )));
                }
              });
            }
            if (status == 'CANCELLED' && !_navigating) {
              _navigating = true;
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text('Ride was cancelled'),
                      backgroundColor: Colors.red));
                  Navigator.pop(context);
                }
              });
            }
          }
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(children: [
                const SizedBox(height: 40),
                AnimatedBuilder(
                  animation: _pulse,
                  builder: (_, __) => Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: 140 + _pulse.value * 20,
                        height: 140 + _pulse.value * 20,
                        decoration: BoxDecoration(
                            color: const Color(0xFF1A3C5E)
                                .withOpacity(0.05 + _pulse.value * 0.05),
                            shape: BoxShape.circle),
                      ),
                      Container(
                        width: 110 + _pulse.value * 10,
                        height: 110 + _pulse.value * 10,
                        decoration: BoxDecoration(
                            color: const Color(0xFF1A3C5E).withOpacity(0.1),
                            shape: BoxShape.circle),
                      ),
                      Container(
                        width: 90,
                        height: 90,
                        decoration: const BoxDecoration(
                            color: Color(0xFF1A3C5E), shape: BoxShape.circle),
                        child: const Icon(Icons.directions_car,
                            color: Color(0xFFC9A84C), size: 44),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                const Text('Looking for a Driver...',
                    style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A3C5E))),
                const SizedBox(height: 8),
                const Text(
                    'Please wait while we find you the best driver',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 13,
                        color: Color(0xFF9DB0C8),
                        height: 1.5)),
                const SizedBox(height: 32),
                // Ride info
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black.withOpacity(0.06),
                            blurRadius: 8,
                            offset: const Offset(0, 2))
                      ]),
                  child: Column(children: [
                    _row(Icons.circle, Colors.green, 'From', widget.pickup),
                    const Divider(height: 20),
                    _row(Icons.location_on, Colors.red, 'To', widget.dropoff),
                    const Divider(height: 20),
                    Row(children: [
                      const Icon(Icons.receipt_outlined,
                          color: Color(0xFF1A3C5E), size: 18),
                      const SizedBox(width: 10),
                      const Text('Fare',
                          style: TextStyle(color: Color(0xFF9DB0C8))),
                      const Spacer(),
                      Text('RM ${widget.fare.toStringAsFixed(2)}',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1A3C5E),
                              fontSize: 16)),
                    ]),
                    const SizedBox(height: 10),
                    Row(children: [
                      const Icon(Icons.payment,
                          color: Color(0xFF1A3C5E), size: 18),
                      const SizedBox(width: 10),
                      const Text('Payment',
                          style: TextStyle(color: Color(0xFF9DB0C8))),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 3),
                        decoration: BoxDecoration(
                            color: const Color(0xFFC9A84C).withOpacity(0.15),
                            borderRadius: BorderRadius.circular(8)),
                        child: Text(widget.payment,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFC9A84C),
                                fontSize: 12)),
                      ),
                    ]),
                  ]),
                ),
                const Spacer(),
                OutlinedButton(
                  onPressed: _cancelRide,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Cancel Ride',
                      style: TextStyle(
                          fontSize: 15, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 20),
              ]),
            ),
          );
        },
      ),
    );
  }

  Widget _row(IconData icon, Color color, String label, String value) {
    return Row(children: [
      Icon(icon, color: color, size: 16),
      const SizedBox(width: 10),
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label,
            style: const TextStyle(
                fontSize: 10,
                color: Color(0xFF9DB0C8),
                fontWeight: FontWeight.bold)),
        Text(value,
            style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF0D1F35),
                fontWeight: FontWeight.w500)),
      ]),
    ]);
  }
}
