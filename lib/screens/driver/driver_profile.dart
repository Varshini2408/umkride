import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../utils/app_colors.dart';
import '../../utils/session_manager.dart';
import '../login_screen.dart';

class DriverProfile extends StatefulWidget {
  const DriverProfile({super.key});
  @override
  State<DriverProfile> createState() => _DriverProfileState();
}

class _DriverProfileState extends State<DriverProfile> {
  String _name = '', _email = '', _phone = '', _gender = '', _initial = '';

  @override
  void initState() { super.initState(); _loadProfile(); }

  Future<void> _loadProfile() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final doc = await FirebaseFirestore.instance
        .collection('users').doc(uid).get();
    if (doc.exists && mounted) {
      final d = doc.data()!;
      setState(() {
        _name    = d['name'] ?? '';
        _email   = d['email'] ?? '';
        _phone   = d['phone'] ?? '';
        _gender  = d['gender'] ?? '';
        _initial = _name.isNotEmpty ? _name[0].toUpperCase() : 'D';
      });
    }
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true),
              child: const Text('Logout',
                  style: TextStyle(color: AppColors.error))),
        ],
      ),
    );
    if (confirm == true) {
      await FirebaseAuth.instance.signOut();
      await SessionManager.clearSession();
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (_) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(children: [
        Container(
          height: 220,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF0D1F35), Color(0xFF1A3C5E)],
              begin: Alignment.topLeft, end: Alignment.bottomRight,
            ),
          ),
          child: SafeArea(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 80, height: 80,
                    decoration: const BoxDecoration(
                        color: AppColors.gold, shape: BoxShape.circle),
                    alignment: Alignment.center,
                    child: Text(_initial,
                        style: const TextStyle(
                            fontSize: 32, fontWeight: FontWeight.bold,
                            color: AppColors.navy)),
                  ),
                  const SizedBox(height: 12),
                  Text(_name,
                      style: const TextStyle(
                          fontSize: 20, fontWeight: FontWeight.bold,
                          color: Colors.white)),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 3),
                    decoration: BoxDecoration(
                        color: AppColors.gold.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20)),
                    child: const Text('DRIVER',
                        style: TextStyle(
                            fontSize: 11, fontWeight: FontWeight.bold,
                            color: AppColors.gold)),
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
              Container(
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withOpacity(0.06),
                          blurRadius: 8, offset: const Offset(0, 2))
                    ]),
                child: Column(children: [
                  _infoRow('EMAIL', _email, Icons.email_outlined),
                  const Divider(height: 1, color: AppColors.lightBlue),
                  _infoRow('PHONE', _phone, Icons.phone_outlined),
                  const Divider(height: 1, color: AppColors.lightBlue),
                  _infoRow('GENDER', _gender, Icons.person_outline),
                ]),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _logout,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.navy,
                  minimumSize: const Size(double.infinity, 54),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('LOGOUT', style: AppTextStyles.button),
              ),
            ]),
          ),
        ),
      ]),
    );
  }

  Widget _infoRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(children: [
        Icon(icon, color: AppColors.navy, size: 20),
        const SizedBox(width: 12),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 10, fontWeight: FontWeight.bold,
                  color: AppColors.muted, letterSpacing: 0.5)),
          const SizedBox(height: 2),
          Text(value.isEmpty ? '-' : value,
              style: const TextStyle(
                  fontSize: 15, color: AppColors.darkText)),
        ]),
      ]),
    );
  }
}
