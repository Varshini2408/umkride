import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/booking_model.dart';
import 'waiting_screen.dart';

class PaymentScreen extends StatefulWidget {
  final BookingModel booking;
  const PaymentScreen({super.key, required this.booking});
  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  String? selectedMethod;
  bool _loading = false;
  final Color themeColor = const Color(0xFF6C5CE7);

  final List<Map<String, dynamic>> paymentMethods = [
    {'id': 'cash', 'name': 'Tunai (Cash)', 'icon': Icons.payments_outlined},
    {'id': 'online', 'name': 'Online Banking', 'icon': Icons.account_balance_outlined},
    {'id': 'tng', 'name': "Touch n Go eWallet", 'icon': Icons.account_balance_wallet_outlined},
  ];

  Future<void> _confirmPayment() async {
    if (selectedMethod == null) return;
    setState(() => _loading = true);
    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;
      final ref = await FirebaseFirestore.instance.collection('rides').add({
        'studentUid':      uid,
        'driverUid':       null,
        'pickupAddress':   widget.booking.pickupLocation ?? '',
        'dropoffAddress':  widget.booking.destinationLocation ?? '',
        'status':          'PENDING',
        'paymentMethod':   selectedMethod,
        'genderPreference': widget.booking.genderPreference ?? 'ANY',
        'fareEstimate':    widget.booking.price ?? 5.0,
        'vehicleType':     widget.booking.vehicleType ?? '',
        'distance':        widget.booking.distance ?? 0.0,
        'createdAt':       FieldValue.serverTimestamp(),
      });
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => WaitingScreen(
          rideId:  ref.id,
          pickup:  widget.booking.pickupLocation ?? '',
          dropoff: widget.booking.destinationLocation ?? '',
          fare:    (widget.booking.price ?? 5.0).toDouble(),
          payment: selectedMethod!,
        )),
        (route) => route.isFirst,
      );
    } catch (e) {
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: $e'), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('Pilih Kaedah Bayaran',
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () => Navigator.pop(context)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: themeColor.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: themeColor.withOpacity(0.2)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Jumlah Perlu Dibayar',
                    style: TextStyle(fontWeight: FontWeight.w500)),
                Text(
                  'RM ${widget.booking.price?.toStringAsFixed(2) ?? "0.00"}',
                  style: TextStyle(color: themeColor,
                      fontWeight: FontWeight.bold, fontSize: 18),
                ),
              ],
            ),
          ),
          const SizedBox(height: 30),
          const Text('Kaedah Bayaran',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              itemCount: paymentMethods.length,
              itemBuilder: (context, index) {
                final method = paymentMethods[index];
                bool isSelected = selectedMethod == method['id'];
                return GestureDetector(
                  onTap: () => setState(() => selectedMethod = method['id']),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isSelected ? themeColor.withOpacity(0.05) : Colors.white,
                      border: Border.all(
                          color: isSelected ? themeColor : Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(children: [
                      Icon(method['icon'],
                          color: isSelected ? themeColor : Colors.black54),
                      const SizedBox(width: 16),
                      Text(method['name'],
                          style: TextStyle(
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            color: isSelected ? themeColor : Colors.black,
                          )),
                      const Spacer(),
                      if (isSelected)
                        Icon(Icons.check_circle, color: themeColor)
                      else
                        const Icon(Icons.circle_outlined, color: Colors.grey),
                    ]),
                  ),
                );
              },
            ),
          ),
          ElevatedButton(
            onPressed: (selectedMethod == null || _loading) ? null : _confirmPayment,
            style: ElevatedButton.styleFrom(
              backgroundColor: themeColor,
              minimumSize: const Size(double.infinity, 54),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: _loading
                ? const CircularProgressIndicator(color: Colors.white)
                : const Text('BAYAR & CARI PEMANDU',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold,
                        color: Colors.white)),
          ),
        ]),
      ),
    );
  }
}
