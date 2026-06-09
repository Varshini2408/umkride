import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/app_colors.dart';
import '../utils/session_manager.dart';
import 'forgot_password_screen.dart';
import 'register_screen.dart';
import 'student/student_main.dart';
import 'driver/driver_main.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailCtrl = TextEditingController();
  final _passCtrl  = TextEditingController();
  bool _loading = false;
  bool _passVisible = false;
  String? _error;

  Future<void> _login() async {
    final email = _emailCtrl.text.trim();
    final pass  = _passCtrl.text.trim();
    if (email.isEmpty) { setState(() => _error = 'Email is required'); return; }
    if (pass.isEmpty)  { setState(() => _error = 'Password is required'); return; }
    setState(() { _loading = true; _error = null; });
    try {
      final cred = await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: pass);
      final doc = await FirebaseFirestore.instance
          .collection('users').doc(cred.user!.uid).get();
      if (doc.exists) {
        final data = doc.data()!;
        await SessionManager.saveSession(
          uid:    cred.user!.uid,
          name:   data['name'] ?? 'User',
          email:  data['email'] ?? email,
          role:   data['role'] ?? 'STUDENT',
          gender: data['gender'] ?? 'MALE',
        );
        if (!mounted) return;
        final role = data['role'] ?? 'STUDENT';
        Navigator.pushReplacement(context, MaterialPageRoute(
          builder: (_) => role == 'DRIVER' ? const DriverMain() : const StudentMain()));
      }
    } on FirebaseAuthException catch (e) {
      setState(() => _error = e.message ?? 'Login failed');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() { _emailCtrl.dispose(); _passCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Header
          Container(
            height: 220,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF0D1F35), Color(0xFF1A3C5E)],
                begin: Alignment.topLeft, end: Alignment.bottomRight,
              ),
            ),
            child: Center(
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                const SizedBox(height: 40),
                Container(
                  width: 70, height: 70,
                  decoration: const BoxDecoration(color: AppColors.gold, shape: BoxShape.circle),
                  child: const Icon(Icons.directions_car, color: AppColors.navy, size: 38),
                ),
                const SizedBox(height: 12),
                const Text('UMKRide', style: TextStyle(fontSize: 24,
                    fontWeight: FontWeight.bold, color: AppColors.white)),
              ]),
            ),
          ),
          // Form
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                const SizedBox(height: 8),
                const Text('Welcome Back', style: TextStyle(fontSize: 22,
                    fontWeight: FontWeight.bold, color: AppColors.navy)),
                const SizedBox(height: 4),
                const Text('Sign in to continue', style: TextStyle(color: AppColors.muted)),
                const SizedBox(height: 24),
                _buildInput(_emailCtrl, 'Email Address', Icons.email_outlined, false),
                const SizedBox(height: 14),
                _buildInput(_passCtrl, 'Password', Icons.lock_outline, true),
                if (_error != null) ...[
                  const SizedBox(height: 10),
                  Text(_error!, style: const TextStyle(color: AppColors.error, fontSize: 13)),
                ],
                const SizedBox(height: 6),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ForgotPasswordScreen())),
                    child: const Text('Forgot Password?',
                        style: TextStyle(color: AppColors.navy)),
                  ),
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: _loading ? null : _login,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.navy,
                    minimumSize: const Size(double.infinity, 54),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _loading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('LOGIN', style: AppTextStyles.button),
                ),
                const SizedBox(height: 20),
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const Text("Don't have an account? ",
                      style: TextStyle(color: AppColors.muted)),
                  GestureDetector(
                    onTap: () => Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const RegisterScreen())),
                    child: const Text('Register',
                        style: TextStyle(color: AppColors.navy,
                            fontWeight: FontWeight.bold)),
                  ),
                ]),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInput(TextEditingController ctrl, String hint,
      IconData icon, bool isPass) {
    return TextField(
      controller: ctrl,
      obscureText: isPass && !_passVisible,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: AppColors.muted),
        prefixIcon: Icon(icon, color: AppColors.navy),
        suffixIcon: isPass
            ? IconButton(
                icon: Icon(_passVisible ? Icons.visibility_off : Icons.visibility,
                    color: AppColors.muted),
                onPressed: () => setState(() => _passVisible = !_passVisible))
            : null,
        filled: true,
        fillColor: AppColors.lightBlue,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.navy, width: 1.5)),
      ),
    );
  }
}
