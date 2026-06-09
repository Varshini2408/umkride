import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const UMKRideApp());
}

class UMKRideApp extends StatelessWidget {
  const UMKRideApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'UMKRide',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1A3C5E)),
        useMaterial3: true,
      ),
      home: const SplashScreen(),
    );
  }
}
