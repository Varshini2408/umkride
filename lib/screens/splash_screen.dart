import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../utils/app_colors.dart';
import '../utils/session_manager.dart';
import 'login_screen.dart';
import 'student/student_main.dart';
import 'driver/driver_main.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnim;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200));
    _scaleAnim = Tween<double>(begin: 0.5, end: 1.0).animate(
        CurvedAnimation(parent: _controller, curve: Curves.elasticOut));
    _fadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeIn));
    _controller.forward();
    Future.delayed(const Duration(seconds: 3), _navigate);
  }

  Future<void> _navigate() async {
    if (!mounted) return;
    final loggedIn = await SessionManager.isLoggedIn();
    final user = FirebaseAuth.instance.currentUser;
    if (!loggedIn || user == null) {
      _go(const LoginScreen());
      return;
    }
    final role = await SessionManager.getRole();
    if (role == 'DRIVER') {
      _go(const DriverMain());
    } else {
      _go(const StudentMain());
    }
  }

  void _go(Widget screen) {
    if (!mounted) return;
    Navigator.pushReplacement(context,
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => screen,
          transitionsBuilder: (_, anim, __, child) =>
              FadeTransition(opacity: anim, child: child),
          transitionDuration: const Duration(milliseconds: 500),
        ));
  }

  @override
  void dispose() { _controller.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0D1F35), Color(0xFF1A3C5E), Color(0xFF2A5C8A)],
            begin: Alignment.topLeft, end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: FadeTransition(
            opacity: _fadeAnim,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ScaleTransition(
                  scale: _scaleAnim,
                  child: Container(
                    width: 100, height: 100,
                    decoration: const BoxDecoration(
                      color: AppColors.gold, shape: BoxShape.circle),
                    child: const Icon(Icons.directions_car,
                        color: AppColors.navy, size: 54),
                  ),
                ),
                const SizedBox(height: 28),
                const Text('UMKRide',
                    style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold,
                        color: AppColors.white, letterSpacing: 2)),
                const SizedBox(height: 8),
                const Text('Your Campus Ride',
                    style: TextStyle(fontSize: 14, color: AppColors.gold,
                        letterSpacing: 1)),
                const SizedBox(height: 60),
                SizedBox(
                  width: 180,
                  child: LinearProgressIndicator(
                    backgroundColor: const Color(0xFF2A5C8A),
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.gold),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
