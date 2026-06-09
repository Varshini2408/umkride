import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/app_colors.dart';
import 'login_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameCtrl    = TextEditingController();
  final _emailCtrl   = TextEditingController();
  final _phoneCtrl   = TextEditingController();
  final _passCtrl    = TextEditingController();
  final _confirmCtrl = TextEditingController();
  String _role   = 'STUDENT';
  String _gender = 'MALE';
  bool _terms   = false;
  bool _loading = false;
  bool _passVisible = false;
  String? _error;

  Future<void> _register() async {
    final name    = _nameCtrl.text.trim();
    final email   = _emailCtrl.text.trim();
    final phone   = _phoneCtrl.text.trim();
    final pass    = _passCtrl.text.trim();
    final confirm = _confirmCtrl.text.trim();
    if (name.isEmpty)  { setState(() => _error = 'Name is required'); return; }
    if (email.isEmpty) { setState(() => _error = 'Email is required'); return; }
    if (phone.isEmpty) { setState(() => _error = 'Phone is required'); return; }
    if (pass.isEmpty)  { setState(() => _error = 'Password is required'); return; }
    if (pass != confirm) { setState(() => _error = 'Passwords do not match'); return; }
    if (pass.length < 6) { setState(() => _error = 'Password must be at least 6 characters'); return; }
    if (!_terms) { setState(() => _error = 'Please accept Terms & Conditions'); return; }
    setState(() { _loading = true; _error = null; });
    try {
      final cred = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: pass);
      final uid = cred.user!.uid;
      final userData = <String, dynamic>{
        'uid': uid, 'name': name, 'email': email,
        'phone': phone, 'role': _role, 'gender': _gender,
        'createdAt': FieldValue.serverTimestamp(),
      };
      if (_role == 'DRIVER') {
        userData['verificationStatus'] = 'APPROVED';
        userData['isOnline'] = false;
        userData['rating']   = 5.0;
        userData['totalRides'] = 0;
      }
      await FirebaseFirestore.instance.collection('users').doc(uid).set(userData);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Account created! Please login.'),
              backgroundColor: AppColors.success));
      Navigator.pushReplacement(context,
          MaterialPageRoute(builder: (_) => const LoginScreen()));
    } on FirebaseAuthException catch (e) {
      setState(() => _error = e.message ?? 'Registration failed');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose(); _emailCtrl.dispose(); _phoneCtrl.dispose();
    _passCtrl.dispose(); _confirmCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Header
          Container(
            height: 140,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF0D1F35), Color(0xFF1A3C5E)],
                begin: Alignment.topLeft, end: Alignment.bottomRight,
              ),
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.pop(context)),
                  const SizedBox(width: 8),
                  const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Create Account', style: TextStyle(fontSize: 22,
                          fontWeight: FontWeight.bold, color: Colors.white)),
                      Text('Join UMKRide today',
                          style: TextStyle(color: AppColors.gold, fontSize: 13)),
                    ],
                  ),
                ]),
              ),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                _buildInput(_nameCtrl, 'Full Name', Icons.person_outline),
                const SizedBox(height: 12),
                _buildInput(_emailCtrl, 'Email Address', Icons.email_outlined),
                const SizedBox(height: 12),
                _buildInput(_phoneCtrl, 'Phone Number', Icons.phone_outlined,
                    keyboard: TextInputType.phone),
                const SizedBox(height: 12),
                _buildInput(_passCtrl, 'Password', Icons.lock_outline, isPass: true),
                const SizedBox(height: 12),
                _buildInput(_confirmCtrl, 'Confirm Password', Icons.lock_outline, isPass: true),
                const SizedBox(height: 16),
                // Role
                const Text('SELECT ROLE', style: AppTextStyles.label),
                const SizedBox(height: 8),
                Row(children: [
                  _toggleBtn('STUDENT', _role == 'STUDENT', () => setState(() => _role = 'STUDENT')),
                  const SizedBox(width: 10),
                  _toggleBtn('DRIVER', _role == 'DRIVER', () => setState(() => _role = 'DRIVER')),
                ]),
                const SizedBox(height: 16),
                // Gender
                const Text('GENDER', style: AppTextStyles.label),
                const SizedBox(height: 8),
                Row(children: [
                  _toggleBtn('MALE', _gender == 'MALE', () => setState(() => _gender = 'MALE')),
                  const SizedBox(width: 10),
                  _toggleBtn('FEMALE', _gender == 'FEMALE', () => setState(() => _gender = 'FEMALE')),
                ]),
                const SizedBox(height: 16),
                Row(children: [
                  Checkbox(
                    value: _terms,
                    activeColor: AppColors.navy,
                    onChanged: (v) => setState(() => _terms = v ?? false)),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _showTerms(),
                      child: const Text.rich(TextSpan(children: [
                        TextSpan(text: 'I agree to the ',
                            style: TextStyle(color: AppColors.muted)),
                        TextSpan(text: 'Terms & Conditions',
                            style: TextStyle(color: AppColors.navy,
                                fontWeight: FontWeight.bold)),
                      ])),
                    ),
                  ),
                ]),
                if (_error != null) ...[
                  const SizedBox(height: 8),
                  Text(_error!, style: const TextStyle(
                      color: AppColors.error, fontSize: 13)),
                ],
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _loading ? null : _register,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.navy,
                    minimumSize: const Size(double.infinity, 54),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _loading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('CREATE ACCOUNT', style: AppTextStyles.button),
                ),
                const SizedBox(height: 16),
                Center(child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Text.rich(TextSpan(children: [
                    TextSpan(text: 'Already have an account? ',
                        style: TextStyle(color: AppColors.muted)),
                    TextSpan(text: 'Login',
                        style: TextStyle(color: AppColors.navy,
                            fontWeight: FontWeight.bold)),
                  ])),
                )),
                const SizedBox(height: 20),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInput(TextEditingController ctrl, String hint, IconData icon,
      {bool isPass = false, TextInputType keyboard = TextInputType.text}) {
    return TextField(
      controller: ctrl, obscureText: isPass && !_passVisible,
      keyboardType: keyboard,
      decoration: InputDecoration(
        hintText: hint, hintStyle: const TextStyle(color: AppColors.muted),
        prefixIcon: Icon(icon, color: AppColors.navy),
        suffixIcon: isPass ? IconButton(
            icon: Icon(_passVisible ? Icons.visibility_off : Icons.visibility,
                color: AppColors.muted),
            onPressed: () => setState(() => _passVisible = !_passVisible)) : null,
        filled: true, fillColor: AppColors.lightBlue,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.navy, width: 1.5)),
      ),
    );
  }

  Widget _toggleBtn(String label, bool selected, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 46,
          decoration: BoxDecoration(
            color: selected ? AppColors.navy : AppColors.lightBlue,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: selected ? AppColors.navy : AppColors.muted),
          ),
          alignment: Alignment.center,
          child: Text(label, style: TextStyle(
              fontWeight: FontWeight.bold, fontSize: 13,
              color: selected ? Colors.white : AppColors.navy)),
        ),
      ),
    );
  }

  void _showTerms() {
    showDialog(context: context, builder: (_) => AlertDialog(
      title: const Text('Terms & Conditions'),
      content: const Text('By using UMKRide, you agree to use this service responsibly within UMK campus. Drivers must have a valid license. Students must respect drivers.'),
      actions: [
        TextButton(onPressed: () { setState(() => _terms = true); Navigator.pop(context); },
            child: const Text('I Agree', style: TextStyle(color: AppColors.navy))),
        TextButton(onPressed: () => Navigator.pop(context),
            child: const Text('Close')),
      ],
    ));
  }
}
