import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../utils/app_colors.dart';
import '../../utils/session_manager.dart';

class DriverDashboard extends StatefulWidget {
  const DriverDashboard({super.key});
  @override
  State<DriverDashboard> createState() => _DriverDashboardState();
}

class _DriverDashboardState extends State<DriverDashboard> {
  String _firstName = '', _initial = '';
  bool _isOnline = false;

  @override
  void initState() { super.initState(); _loadUser(); }

  Future<void> _loadUser() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final doc = await FirebaseFirestore.instance
        .collection('users').doc(uid).get();
    if (doc.exists && mounted) {
      final name = doc.data()?['name'] ?? 'Driver';
      final firstName = name.toString().split(' ')[0];
      await SessionManager.saveSession(
        uid:    uid, name: name,
        email:  doc.data()?['email'] ?? '',
        role:   doc.data()?['role'] ?? 'DRIVER',
        gender: doc.data()?['gender'] ?? 'MALE',
      );
      setState(() {
        _firstName = firstName;
        _initial   = firstName.isNotEmpty ? firstName[0].toUpperCase() : 'D';
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
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Welcome back,',
                            style: TextStyle(
                                fontSize: 13, color: Color(0xFF8BAECF))),
                        const SizedBox(height: 2),
                        Text(_firstName.isEmpty ? '...' : _firstName,
                            style: const TextStyle(
                                fontSize: 26, fontWeight: FontWeight.bold,
                                color: Colors.white)),
                      ],
                    ),
                  ),
                  Container(
                    width: 48, height: 48,
                    decoration: const BoxDecoration(
                        color: AppColors.gold, shape: BoxShape.circle),
                    alignment: Alignment.center,
                    child: Text(_initial,
                        style: const TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold,
                            color: AppColors.navy)),
                  ),
                ],
              ),
            ),
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(children: [
              // Online toggle card
              Container(
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withOpacity(0.06),
                          blurRadius: 8, offset: const Offset(0, 2))
                    ]),
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 16),
                child: Row(children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('STATUS', style: AppTextStyles.label),
                        const SizedBox(height: 4),
                        Text(
                          _isOnline
                              ? 'Online — Waiting for rides'
                              : 'Offline',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold,
                              color: _isOnline
                                  ? AppColors.success
                                  : AppColors.error),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: _isOnline,
                    activeColor: AppColors.success,
                    onChanged: (v) => setState(() => _isOnline = v),
                  ),
                ]),
              ),
              const SizedBox(height: 16),
              // Stats
              Row(children: [
                _statCard('⭐', '5.0', 'Rating'),
                const SizedBox(width: 10),
                _statCard('🚗', '0', 'Total Rides'),
                const SizedBox(width: 10),
                _statCard('💰', 'RM 0', 'Today'),
              ]),
              const SizedBox(height: 16),
              // Waiting
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withOpacity(0.06),
                          blurRadius: 8, offset: const Offset(0, 2))
                    ]),
                padding: const EdgeInsets.all(30),
                child: const Column(children: [
                  Icon(Icons.directions_car,
                      size: 56, color: AppColors.muted),
                  SizedBox(height: 12),
                  Text('Go Online to Receive Rides',
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold,
                          color: AppColors.navy)),
                  SizedBox(height: 6),
                  Text('Toggle the switch above to start',
                      style: TextStyle(
                          fontSize: 13, color: AppColors.muted)),
                ]),
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
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 6, offset: const Offset(0, 2))
            ]),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 22)),
            const SizedBox(height: 4),
            Text(value,
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold,
                    color: AppColors.navy)),
            Text(label,
                style: const TextStyle(
                    fontSize: 10, color: AppColors.muted)),
          ],
        ),
      ),
    );
  }
}
