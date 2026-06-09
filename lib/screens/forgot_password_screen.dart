import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/app_colors.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});
  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailCtrl = TextEditingController();
  bool _loading = false;
  bool _emailSent = false;
  String? _error;

  Future<void> _sendResetEmail() async {
    final email = _emailCtrl.text.trim();
    if (email.isEmpty) {
      setState(() => _error = 'Please enter your email address');
      return;
    }
    if (!email.contains('@')) {
      setState(() => _error = 'Please enter a valid email address');
      return;
    }
    setState(() { _loading = true; _error = null; });
    try {
      // Check if email exists in Firestore first
      final query = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();
      if (query.docs.isEmpty) {
        setState(() {
          _loading = false;
          _error = 'No UMKRide account found with this email address.';
        });
        return;
      }
      // Email exists - send reset email
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      if (mounted) setState(() { _emailSent = true; _loading = false; });
    } on FirebaseAuthException catch (e) {
      setState(() {
        _loading = false;
        switch (e.code) {
          case 'invalid-email':
            _error = 'Please enter a valid email address.';
            break;
          default:
            _error = e.message ?? 'Something went wrong. Please try again.';
        }
      });
    } catch (e) {
      setState(() { _loading = false; _error = 'Something went wrong. Please try again.'; });
    }
  }

  @override
  void dispose() { _emailCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(children: [
        // Header
        Container(
          height: 180,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF0D1F35), Color(0xFF1A3C5E)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
                const SizedBox(width: 8),
                const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Forgot Password',
                        style: TextStyle(fontSize: 22,
                            fontWeight: FontWeight.bold, color: Colors.white)),
                    Text('Reset your account password',
                        style: TextStyle(color: AppColors.gold, fontSize: 13)),
                  ],
                ),
              ]),
            ),
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: _emailSent ? _buildSuccessView() : _buildFormView(),
          ),
        ),
      ]),
    );
  }

  Widget _buildFormView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 16),
        // Icon
        Center(
          child: Container(
            width: 80, height: 80,
            decoration: BoxDecoration(
              color: AppColors.gold.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.lock_reset, size: 40, color: AppColors.gold),
          ),
        ),
        const SizedBox(height: 24),
        const Text('Reset Your Password',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold,
                color: AppColors.navy)),
        const SizedBox(height: 8),
        const Text(
          'Enter your registered email address and we will send you a link to reset your password.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 13, color: AppColors.muted, height: 1.5),
        ),
        const SizedBox(height: 32),
        // Email input
        TextField(
          controller: _emailCtrl,
          keyboardType: TextInputType.emailAddress,
          decoration: InputDecoration(
            hintText: 'Enter your email address',
            hintStyle: const TextStyle(color: AppColors.muted),
            prefixIcon: const Icon(Icons.email_outlined, color: AppColors.navy),
            filled: true,
            fillColor: AppColors.lightBlue,
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.navy, width: 1.5)),
          ),
        ),
        if (_error != null) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.error.withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.error.withOpacity(0.3)),
            ),
            child: Row(children: [
              const Icon(Icons.error_outline, color: AppColors.error, size: 18),
              const SizedBox(width: 8),
              Expanded(child: Text(_error!,
                  style: const TextStyle(color: AppColors.error, fontSize: 13))),
            ]),
          ),
        ],
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: _loading ? null : _sendResetEmail,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.navy,
            minimumSize: const Size(double.infinity, 54),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
          ),
          child: _loading
              ? const SizedBox(height: 22, width: 22,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2.5))
              : const Text('SEND RESET EMAIL',
                  style: TextStyle(fontSize: 15,
                      fontWeight: FontWeight.bold, color: Colors.white)),
        ),
        const SizedBox(height: 16),
        Center(
          child: GestureDetector(
            onTap: () => Navigator.pop(context),
            child: const Text('Back to Login',
                style: TextStyle(color: AppColors.navy,
                    fontWeight: FontWeight.bold, fontSize: 14)),
          ),
        ),
      ],
    );
  }

  Widget _buildSuccessView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 24),
        // Success icon
        Center(
          child: Container(
            width: 90, height: 90,
            decoration: BoxDecoration(
              color: AppColors.success.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.mark_email_read_outlined,
                size: 48, color: AppColors.success),
          ),
        ),
        const SizedBox(height: 24),
        const Text('Email Sent!',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold,
                color: AppColors.navy)),
        const SizedBox(height: 12),
        Text(
          'A password reset link has been sent to:\n${_emailCtrl.text.trim()}',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 14, color: AppColors.muted, height: 1.6),
        ),
        const SizedBox(height: 24),
        // Steps card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 8, offset: const Offset(0, 2))],
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Next Steps:', style: TextStyle(
                  fontSize: 14, fontWeight: FontWeight.bold,
                  color: AppColors.navy)),
              SizedBox(height: 12),
              _StepItem(number: '1', text: 'Check your email inbox'),
              SizedBox(height: 8),
              _StepItem(number: '2', text: 'Click the reset link in the email'),
              SizedBox(height: 8),
              _StepItem(number: '3', text: 'Enter your new password'),
              SizedBox(height: 8),
              _StepItem(number: '4', text: 'Come back and login with new password'),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Resend option
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.lightBlue,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(children: [
            const Icon(Icons.info_outline, color: AppColors.navy, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text("Didn't receive the email? Check your spam folder or",
                  style: const TextStyle(fontSize: 12, color: AppColors.muted)),
            ),
          ]),
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: () => setState(() { _emailSent = false; }),
          child: const Text('Resend Email',
              style: TextStyle(color: AppColors.navy,
                  fontWeight: FontWeight.bold)),
        ),
        const SizedBox(height: 8),
        ElevatedButton(
          onPressed: () => Navigator.pop(context),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.navy,
            minimumSize: const Size(double.infinity, 54),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
          ),
          child: const Text('BACK TO LOGIN',
              style: TextStyle(fontSize: 15,
                  fontWeight: FontWeight.bold, color: Colors.white)),
        ),
      ],
    );
  }
}

class _StepItem extends StatelessWidget {
  final String number;
  final String text;
  const _StepItem({required this.number, required this.text});
  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Container(
        width: 24, height: 24,
        decoration: const BoxDecoration(
            color: AppColors.navy, shape: BoxShape.circle),
        alignment: Alignment.center,
        child: Text(number,
            style: const TextStyle(fontSize: 11,
                fontWeight: FontWeight.bold, color: Colors.white)),
      ),
      const SizedBox(width: 10),
      Text(text, style: const TextStyle(
          fontSize: 13, color: AppColors.darkText)),
    ]);
  }
}
