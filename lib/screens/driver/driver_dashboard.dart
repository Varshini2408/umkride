import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../utils/app_colors.dart';
import '../../utils/session_manager.dart';

class DriverDashboard extends StatefulWidget {
  final bool isOnline;
  final Function(bool) onToggle;
  const DriverDashboard({super.key, required this.isOnline, required this.onToggle});
  @override
  State<DriverDashboard> createState() => _DriverDashboardState();
}

class _DriverDashboardState extends State<DriverDashboard> {
  String _firstName = '', _initial = '';
  int _totalRides = 0;
  double _rating = 5.0;

  @override
  void initState() { super.initState(); _loadUser(); }

  Future<void> _loadUser() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
    if (doc.exists && mounted) {
      final name = doc.data()?['name'] ?? 'Driver';
      final firstName = name.toString().split(' ')[0];
      await SessionManager.saveSession(uid: uid, name: name,
          email: doc.data()?['email'] ?? '',
          role: doc.data()?['role'] ?? 'DRIVER',
          gender: doc.data()?['gender'] ?? 'MALE');
      setState(() {
        _firstName  = firstName;
        _initial    = firstName.isNotEmpty ? firstName[0].toUpperCase() : 'D';
        _totalRides = (doc.data()?['totalRides'] ?? 0) as int;
        _rating     = (doc.data()?['rating'] ?? 5.0).toDouble();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(children: [
        Container(
          height: 200,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF0D1F35), Color(0xFF1A3C5E), Color(0xFF2A5C8A)],
              begin: Alignment.topLeft, end: Alignment.bottomRight,
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 20),
              child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Expanded(child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Welcome back,',
                        style: TextStyle(fontSize: 13, color: Color(0xFF8BAECF))),
                    Text(_firstName.isEmpty ? '...' : _firstName,
                        style: const TextStyle(fontSize: 26,
                            fontWeight: FontWeight.bold, color: Colors.white)),
                  ],
                )),
                Container(width: 48, height: 48,
                    decoration: const BoxDecoration(
                        color: AppColors.gold, shape: BoxShape.circle),
                    alignment: Alignment.center,
                    child: Text(_initial, style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold,
                        color: AppColors.navy))),
              ]),
            ),
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(children: [
              // Online toggle
              Container(
                decoration: BoxDecoration(color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06),
                        blurRadius: 8, offset: const Offset(0, 2))]),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Row(children: [
                  Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('STATUS', style: AppTextStyles.label),
                      const SizedBox(height: 4),
                      Text(widget.isOnline
                          ? 'Online — Waiting for rides' : 'Offline',
                          style: TextStyle(fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: widget.isOnline
                                  ? AppColors.success : AppColors.error)),
                    ],
                  )),
                  Switch(
                    value: widget.isOnline,
                    activeColor: AppColors.success,
                    onChanged: widget.onToggle,
                  ),
                ]),
              ),
              const SizedBox(height: 14),
              // Stats
              Row(children: [
                _statCard('⭐', _rating.toStringAsFixed(1), 'Rating'),
                const SizedBox(width: 10),
                _statCard('🚗', '$_totalRides', 'Total Rides'),
                const SizedBox(width: 10),
                _statCard('💰', 'RM 0', 'Today'),
              ]),
              const SizedBox(height: 14),
              if (!widget.isOnline)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(30),
                  decoration: BoxDecoration(color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06),
                          blurRadius: 8, offset: const Offset(0, 2))]),
                  child: const Column(children: [
                    Icon(Icons.directions_car, size: 56, color: AppColors.muted),
                    SizedBox(height: 12),
                    Text('Go Online to Receive Rides',
                        style: TextStyle(fontSize: 16,
                            fontWeight: FontWeight.bold, color: AppColors.navy)),
                    SizedBox(height: 6),
                    Text('Toggle the switch above to start',
                        style: TextStyle(fontSize: 13, color: AppColors.muted)),
                  ]),
                )
              else
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                      color: AppColors.success.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                          color: AppColors.success.withOpacity(0.3))),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.wifi, color: AppColors.success),
                      SizedBox(width: 10),
                      Text('Listening for ride requests...',
                          style: TextStyle(fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: AppColors.success)),
                    ],
                  ),
                ),
            ]),
          ),
        ),
      ]),
    );
  }

  Widget _statCard(String emoji, String value, String label) {
    return Expanded(
      child: Container(
        height: 90,
        decoration: BoxDecoration(color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05),
                blurRadius: 6, offset: const Offset(0, 2))]),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Text(emoji, style: const TextStyle(fontSize: 22)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontSize: 18,
              fontWeight: FontWeight.bold, color: AppColors.navy)),
          Text(label, style: const TextStyle(fontSize: 10, color: AppColors.muted)),
        ]),
      ),
    );
  }
}
