import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../utils/app_colors.dart';
import '../../utils/session_manager.dart';

class StudentDashboard extends StatefulWidget {
  const StudentDashboard({super.key});
  @override
  State<StudentDashboard> createState() => _StudentDashboardState();
}

class _StudentDashboardState extends State<StudentDashboard> {
  String _firstName = '';
  String _initial   = '';

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
    if (doc.exists && mounted) {
      final name = doc.data()?['name'] ?? 'Student';
      final firstName = name.toString().split(' ')[0];
      await SessionManager.saveSession(
        uid: uid, name: name,
        email: doc.data()?['email'] ?? '',
        role: doc.data()?['role'] ?? 'STUDENT',
        gender: doc.data()?['gender'] ?? 'MALE',
      );
      setState(() {
        _firstName = firstName;
        _initial   = firstName.isNotEmpty ? firstName[0].toUpperCase() : 'S';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // Header
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
                          const Text('Hi,', style: TextStyle(
                              fontSize: 14, color: Color(0xFF8BAECF))),
                          const SizedBox(height: 2),
                          Text(_firstName.isEmpty ? '...' : _firstName,
                              style: const TextStyle(fontSize: 26,
                                  fontWeight: FontWeight.bold, color: Colors.white)),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        DefaultTabController.of(context);
                        // Navigate to profile tab
                        final state = context.findAncestorStateOfType<State>();
                        if (state != null && state.widget is! StudentDashboard) return;
                        // Find bottom nav
                      },
                      child: Container(
                        width: 48, height: 48,
                        decoration: const BoxDecoration(
                            color: AppColors.gold, shape: BoxShape.circle),
                        alignment: Alignment.center,
                        child: Text(_initial,
                            style: const TextStyle(fontSize: 20,
                                fontWeight: FontWeight.bold, color: AppColors.navy)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(children: [
                // Quick Book card
                GestureDetector(
                  onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Coming Soon!'),
                          backgroundColor: AppColors.navy)),
                  child: Container(
                    width: double.infinity, height: 110,
                    decoration: BoxDecoration(
                      color: AppColors.gold,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [BoxShadow(color: AppColors.gold.withOpacity(0.4),
                          blurRadius: 12, offset: const Offset(0, 4))],
                    ),
                    padding: const EdgeInsets.all(20),
                    child: Row(children: [
                      const Expanded(child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('QUICK BOOK', style: TextStyle(fontSize: 10,
                              fontWeight: FontWeight.bold, color: Color(0xFF7A4800),
                              letterSpacing: 1)),
                          SizedBox(height: 4),
                          Text('Book a Ride', style: TextStyle(fontSize: 22,
                              fontWeight: FontWeight.bold, color: Color(0xFF2A1A00))),
                          SizedBox(height: 2),
                          Text('Fast • Safe • Easy', style: TextStyle(
                              fontSize: 12, color: Color(0xFF7A5820))),
                        ],
                      )),
                      const Icon(Icons.directions_car, size: 52, color: Color(0xFF7A4800)),
                    ]),
                  ),
                ),
                const SizedBox(height: 16),
                // AI Tip card
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06),
                          blurRadius: 8, offset: const Offset(0, 2))]),
                  padding: const EdgeInsets.all(16),
                  child: Row(children: [
                    Container(width: 40, height: 40,
                        decoration: BoxDecoration(color: AppColors.gold.withOpacity(0.15),
                            shape: BoxShape.circle),
                        child: const Icon(Icons.lightbulb_outline, color: AppColors.gold)),
                    const SizedBox(width: 12),
                    const Expanded(child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('AI TIP', style: TextStyle(fontSize: 10,
                            fontWeight: FontWeight.bold, color: AppColors.gold,
                            letterSpacing: 1)),
                        SizedBox(height: 2),
                        Text('Have a safe ride today!',
                            style: TextStyle(fontSize: 13, color: AppColors.darkText)),
                      ],
                    )),
                  ]),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}
