import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../notification_helper.dart';
import 'driver_active_ride_screen.dart';

class IncomingRideScreen extends StatefulWidget {
  final String rideId;
  final Map<String, dynamic> rideData;
  const IncomingRideScreen(
      {super.key, required this.rideId, required this.rideData});
  @override
  State<IncomingRideScreen> createState() => _IncomingRideScreenState();
}

class _IncomingRideScreenState extends State<IncomingRideScreen> {
  int _countdown = 30;
  Timer? _timer;
  String _studentName  = 'Loading...';
  String _studentPhone = '';

  @override
  void initState() {
    super.initState();
    _loadStudent();
    _startTimer();
  }

  Future<void> _loadStudent() async {
    final uid = widget.rideData['studentUid'];
    if (uid == null) return;
    final doc = await FirebaseFirestore.instance
        .collection('users').doc(uid).get();
    if (doc.exists && mounted) {
      setState(() {
        _studentName  = doc.data()?['name']  ?? 'Student';
        _studentPhone = doc.data()?['phone'] ?? '';
      });
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_countdown <= 0) {
        t.cancel();
        if (mounted) Navigator.pop(context);
      } else {
        setState(() => _countdown--);
      }
    });
  }

  Future<void> _accept() async {
    _timer?.cancel();
    final driverUid = FirebaseAuth.instance.currentUser!.uid;
    final driverDoc = await FirebaseFirestore.instance
        .collection('users').doc(driverUid).get();
    final driverName = driverDoc.data()?['name'] ?? 'Driver';

    await FirebaseFirestore.instance
        .collection('rides')
        .doc(widget.rideId)
        .update({
      'status':     'ACCEPTED',
      'driverUid':  driverUid,
      'driverName': driverName,
    });

    // Notify student
    final studentUid = widget.rideData['studentUid'];
    if (studentUid != null) {
      await NotificationHelper.send(
        toUid: studentUid,
        title: '✅ Driver Found!',
        message: '$driverName has accepted your ride and is on the way!',
      );
    }

    if (!mounted) return;
    Navigator.pushReplacement(
        context,
        MaterialPageRoute(
            builder: (_) => DriverActiveRideScreen(
                  rideId:       widget.rideId,
                  studentName:  _studentName,
                  studentPhone: _studentPhone,
                  studentUid:   studentUid ?? '',
                  pickup:   widget.rideData['pickupAddress']  ?? '',
                  dropoff:  widget.rideData['dropoffAddress'] ?? '',
                  fare:     (widget.rideData['fareEstimate']  ?? 5.0).toDouble(),
                  payment:  widget.rideData['paymentMethod']  ?? 'CASH',
                )));
  }

  void _reject() {
    _timer?.cancel();
    Navigator.pop(context);
  }

  @override
  void dispose() { _timer?.cancel(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final gender = widget.rideData['genderPreference'] ?? 'ANY';
    return Scaffold(
      backgroundColor: Colors.black54,
      body: Center(
        child: Container(
          margin: const EdgeInsets.all(20),
          decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24)),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF0D1F35), Color(0xFF1A3C5E)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius:
                    BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(children: [
                const Text('New Ride Request!',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white)),
                const SizedBox(height: 12),
                Stack(alignment: Alignment.center, children: [
                  SizedBox(
                    width: 60,
                    height: 60,
                    child: CircularProgressIndicator(
                      value: _countdown / 30,
                      backgroundColor: Colors.white24,
                      valueColor: AlwaysStoppedAnimation<Color>(
                          _countdown > 10
                              ? const Color(0xFFC9A84C)
                              : Colors.red),
                      strokeWidth: 5,
                    ),
                  ),
                  Text('$_countdown',
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: _countdown > 10
                              ? const Color(0xFFC9A84C) : Colors.red)),
                ]),
              ]),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(children: [
                Row(children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: const BoxDecoration(
                        color: Color(0xFFEEF4FF), shape: BoxShape.circle),
                    alignment: Alignment.center,
                    child: Text(
                      _studentName.isNotEmpty
                          ? _studentName[0].toUpperCase() : 'S',
                      style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1A3C5E)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text(_studentName,
                        style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1A3C5E))),
                    if (_studentPhone.isNotEmpty)
                      Text(_studentPhone,
                          style: const TextStyle(
                              fontSize: 13, color: Color(0xFF9DB0C8))),
                  ]),
                  const Spacer(),
                  if (gender == 'FEMALE_ONLY')
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                          color: Colors.pink.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8)),
                      child: const Text('Female Only',
                          style: TextStyle(
                              fontSize: 10,
                              color: Colors.pink,
                              fontWeight: FontWeight.bold)),
                    ),
                ]),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                      color: const Color(0xFFF0F5FF),
                      borderRadius: BorderRadius.circular(12)),
                  child: Column(children: [
                    Row(children: [
                      const Icon(Icons.circle,
                          color: Colors.green, size: 12),
                      const SizedBox(width: 8),
                      Expanded(
                          child: Text(
                              widget.rideData['pickupAddress'] ?? '',
                              style: const TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF0D1F35)))),
                    ]),
                    const SizedBox(height: 8),
                    Row(children: [
                      const Icon(Icons.location_on,
                          color: Colors.red, size: 12),
                      const SizedBox(width: 8),
                      Expanded(
                          child: Text(
                              widget.rideData['dropoffAddress'] ?? '',
                              style: const TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF0D1F35)))),
                    ]),
                  ]),
                ),
                const SizedBox(height: 12),
                Row(children: [
                  const Icon(Icons.receipt_outlined,
                      color: Color(0xFF1A3C5E), size: 18),
                  const SizedBox(width: 8),
                  Text(
                      'RM ${(widget.rideData['fareEstimate'] ?? 0.0).toStringAsFixed(2)}',
                      style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1A3C5E))),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                        color: const Color(0xFFC9A84C).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8)),
                    child: Text(
                        widget.rideData['paymentMethod'] ?? 'CASH',
                        style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFC9A84C))),
                  ),
                ]),
                const SizedBox(height: 20),
                Row(children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _reject,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                        minimumSize: const Size(0, 52),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('REJECT',
                          style:
                              TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: _accept,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        minimumSize: const Size(0, 52),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('ACCEPT',
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white)),
                    ),
                  ),
                ]),
              ]),
            ),
          ]),
        ),
      ),
    );
  }
}
